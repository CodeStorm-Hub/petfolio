import 'package:supabase/supabase.dart';
import 'dart:io';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

const _apiKey = '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';
const _url = 'https://integrate.api.nvidia.com/v1/chat/completions';
const _uuid = Uuid();

Future<List<Map<String, dynamic>>> generateRecommendations(Map<String, dynamic> pet) async {
  final petDetails = 'Species: ${pet['species']}, Breed: ${pet['breed'] ?? 'Unknown'}, Age: ${pet['age_in_years'] ?? 'Unknown'} years, Activity Level: ${pet['activity_level'] ?? 'Unknown'}.';
  final prompt = '''
You are an expert pet care assistant. Generate a personalized daily care routine for this pet:
$petDetails

Output exactly 3-5 care tasks in strict JSON array format. 
Each object in the array must have the following keys:
- "taskType": a string matching exactly one of: "feeding", "walk", "grooming", "medication", "vetVisit", "training", "playtime", "dental", "nailTrim", "bath", "other".
- "title": a short string (e.g., "Morning Feeding").
- "frequency": a string matching exactly one of: "daily", "twiceDaily", "asNeeded".
- "scheduledTime": an optional string in HH:MM format (e.g., "08:00"), or null if not applicable.
- "gamificationPoints": an integer between 5 and 30.
- "notes": a short explanation of why this task is recommended based on the pet's attributes.

Return ONLY the JSON array. Do not include markdown formatting like ```json or any other text.
''';

  final response = await http.post(
    Uri.parse(_url),
    headers: {
      'Authorization': 'Bearer $_apiKey',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
    body: jsonEncode({
      'model': 'google/gemma-3n-e4b-it',
      'messages': [
        {'role': 'user', 'content': prompt}
      ],
      'temperature': 0.2,
      'max_tokens': 1024,
    }),
  );

  if (response.statusCode != 200) {
    throw Exception('Failed to generate routine: ${response.statusCode} - ${response.body}');
  }

  final jsonResponse = jsonDecode(response.body);
  final content = jsonResponse['choices'][0]['message']['content'] as String;
  final cleanedContent = content.replaceAll(RegExp(r'```json\n?'), '').replaceAll(RegExp(r'```\n?'), '').trim();
  
  final List<dynamic> jsonList = jsonDecode(cleanedContent);
  final tasks = <Map<String, dynamic>>[];
  final now = DateTime.now().toUtc().toIso8601String();

  for (final item in jsonList) {
    tasks.add({
      'id': _uuid.v4(),
      'pet_id': pet['id'],
      'task_type': item['taskType'] ?? 'other',
      'title': item['title'] ?? 'Care Task',
      'frequency': item['frequency'] ?? 'daily',
      'scheduled_time': item['scheduledTime'],
      'gamification_points': item['gamificationPoints'] ?? 10,
      'notes': item['notes'],
      'created_at': now,
      'updated_at': now,
    });
  }
  return tasks;
}

void main() async {
  final env = File('.env').readAsStringSync();
  String supabaseUrl = '';
  String supabaseKey = '';
  for (var line in env.split('\n')) {
    if (line.startsWith('SUPABASE_URL=')) supabaseUrl = line.split('=')[1].trim();
    if (line.startsWith('SUPABASE_ANON_KEY=')) supabaseKey = line.split('=')[1].trim();
  }
  
  if (supabaseUrl.isEmpty || supabaseKey.isEmpty) {
    print('Missing env vars');
    return;
  }
  
  final client = SupabaseClient(supabaseUrl, supabaseKey);
  
  try {
    final pets = await client.from('pets').select();
    print('Found ${pets.length} pets.');
    
    for (var p in pets) {
      final tasks = await client.from('care_tasks').select('id').eq('pet_id', p['id']);
      if (tasks.isEmpty) {
        print('Pet ${p['name']} has no tasks. Generating...');
        final generated = await generateRecommendations(p);
        if (generated.isNotEmpty) {
          await client.from('care_tasks').insert(generated);
          print('Inserted ${generated.length} tasks for ${p['name']}.');
        }
      } else {
        print('Pet ${p['name']} already has ${tasks.length} tasks.');
      }
    }
  } catch (e) {
    print('Error: $e');
  }
}
