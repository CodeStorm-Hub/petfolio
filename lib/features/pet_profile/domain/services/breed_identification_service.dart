import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

final breedIdentificationServiceProvider =
    Provider<BreedIdentificationService>((_) => BreedIdentificationService());

class BreedIdentificationResult {
  const BreedIdentificationResult({
    required this.breed,
    required this.species,
    required this.confidence,
    this.description,
  });
  final String breed;
  final String species;
  final double confidence;
  final String? description;
}

class BreedIdentificationException implements Exception {
  const BreedIdentificationException(this.message);
  final String message;
  @override
  String toString() => message;
}

class BreedIdentificationService {
  static const _apiKey =
      String.fromEnvironment('NVIDIA_API_KEY', defaultValue: '');
  static const _url = 'https://integrate.api.nvidia.com/v1/chat/completions';
  static const _model = 'nvidia/llama-3.2-90b-vision-instruct';

  Future<BreedIdentificationResult> identifyBreed(File imageFile) async {
    if (_apiKey.isEmpty) {
      throw const BreedIdentificationException(
        'Breed identification requires an NVIDIA API key (NVIDIA_API_KEY).',
      );
    }

    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);
    final ext = imageFile.path.split('.').last.toLowerCase();
    final mimeType =
        ext == 'png' ? 'image/png' : 'image/jpeg';

    final body = jsonEncode({
      'model': _model,
      'messages': [
        {
          'role': 'user',
          'content': [
            {
              'type': 'text',
              'text':
                  'Identify the breed of the pet in this image. Respond with JSON only, no markdown, '
                  'in the format: {"breed":"<breed name>","species":"<dog|cat|rabbit|bird|other>","confidence":<0.0-1.0>,"description":"<one sentence>"}',
            },
            {
              'type': 'image_url',
              'image_url': {'url': 'data:$mimeType;base64,$base64Image'},
            },
          ],
        }
      ],
      'temperature': 0.1,
      'max_tokens': 200,
    });

    final response = await http.post(
      Uri.parse(_url),
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      },
      body: body,
    );

    if (response.statusCode != 200) {
      throw BreedIdentificationException(
          'API error ${response.statusCode}: ${response.body}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final content =
        json['choices']?[0]?['message']?['content'] as String? ?? '';

    try {
      final result = jsonDecode(content) as Map<String, dynamic>;
      return BreedIdentificationResult(
        breed: result['breed'] as String? ?? 'Unknown',
        species: result['species'] as String? ?? 'other',
        confidence: (result['confidence'] as num?)?.toDouble() ?? 0.0,
        description: result['description'] as String?,
      );
    } catch (_) {
      throw const BreedIdentificationException(
          'Could not parse breed identification response.');
    }
  }
}
