import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:petfolio/core/models/pet.dart';
import 'package:petfolio/features/care/data/models/care_task.dart';

final careRecommendationServiceProvider = Provider<CareRecommendationService>(
  (_) => CareRecommendationService(),
);

class CareRecommendationException implements Exception {
  const CareRecommendationException(this.message, {this.cause, this.isConfigError = false});

  final String message;
  final Object? cause;
  final bool isConfigError;

  @override
  String toString() => message;
}

class CareRecommendationService {
  final _uuid = const Uuid();

  static const _apiKey = String.fromEnvironment('NVIDIA_API_KEY');
  static const _url = 'https://integrate.api.nvidia.com/v1/chat/completions';

  static const _guidedSchema = {
    'type': 'array',
    'items': {
      'type': 'object',
      'required': [
        'taskType',
        'title',
        'frequency',
        'scheduledTime',
        'gamificationPoints',
        'notes'
      ],
      'properties': {
        'taskType': {
          'type': 'string',
          'enum': [
            'feeding',
            'walk',
            'grooming',
            'medication',
            'vetVisit',
            'training',
            'playtime',
            'dental',
            'nailTrim',
            'bath',
            'other'
          ]
        },
        'title': {'type': 'string'},
        'frequency': {
          'type': 'string',
          'enum': [
            'daily',
            'twiceDaily',
            'weekly',
            'biweekly',
            'monthly',
            'asNeeded'
          ]
        },
        'scheduledTime': {'type': ['string', 'null']},
        'gamificationPoints': {'type': 'integer', 'minimum': 5, 'maximum': 30},
        'notes': {'type': 'string'}
      },
      'additionalProperties': false
    },
    'minItems': 4,
    'maxItems': 8
  };

  Future<List<CareTask>> generateRecommendations(Pet pet) async {
    // Guard before any network calls so we don't waste 3 Supabase round-trips
    // on a build that has no NVIDIA key configured.
    if (!kIsWeb && _apiKey.isEmpty) {
      throw const CareRecommendationException(
        'AI routine suggestions are not configured on this build.',
        isConfigError: true,
      );
    }

    final supabase = Supabase.instance.client;

    final vaultFuture = supabase
        .from('medical_vault')
        .select('record_type, name, frequency, next_due_at')
        .eq('pet_id', pet.id)
        .eq('is_active', true)
        .limit(10);

    final healthFuture = supabase
        .from('health_logs')
        .select('log_type, weight_kg, severity, diagnosis')
        .eq('pet_id', pet.id)
        .order('created_at', ascending: false)
        .limit(5);

    final tasksFuture = supabase
        .from('care_tasks')
        .select('task_type, title')
        .eq('pet_id', pet.id);

    final results = await Future.wait([vaultFuture, healthFuture, tasksFuture]);

    final vault = (results[0] as List)
        .map((r) => Map<String, dynamic>.from(r as Map))
        .toList();

    final healthLogs = (results[1] as List)
        .map((r) => Map<String, dynamic>.from(r as Map))
        .toList();

    final existingTasks = (results[2] as List)
        .map((r) => {'type': r['task_type'] as String?, 'title': r['title'] as String?})
        .toList();

    final prompt = _buildPrompt(
      pet: pet,
      vault: vault,
      healthLogs: healthLogs,
      existingTasks: existingTasks,
    );

    try {
      final Map<String, dynamic> body;

      if (kIsWeb) {
        // On web, proxy through the Supabase Edge Function to avoid CORS.
        final fnResp = await Supabase.instance.client.functions
            .invoke('recommend-care-tasks', body: {'prompt': prompt})
            .timeout(const Duration(seconds: 60));
        if (fnResp.status != 200) {
          final detail = fnResp.data?.toString() ?? '';
          throw CareRecommendationException(
            'The suggestion service is unavailable right now. Please try again later.',
            cause: 'Edge function ${fnResp.status}: ${detail.length > 300 ? detail.substring(0, 300) : detail}',
          );
        }
        body = (fnResp.data is Map)
            ? Map<String, dynamic>.from(fnResp.data as Map)
            : jsonDecode(jsonEncode(fnResp.data)) as Map<String, dynamic>;
      } else {
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
            'max_tokens': 1500,
            'temperature': 0.25,
            'top_p': 0.75,
            'stream': false,
            'nvext': {'guided_json': _guidedSchema},
          }),
        ).timeout(const Duration(seconds: 45));

        if (response.statusCode != 200) {
          final detail = response.body.length > 300
              ? response.body.substring(0, 300)
              : response.body;
          throw CareRecommendationException(
            'The suggestion service is unavailable right now. Please try again later.',
            cause: 'HTTP ${response.statusCode}: $detail',
          );
        }
        body = jsonDecode(response.body) as Map<String, dynamic>;
      }

      final content = body['choices'][0]['message']['content'] as String;

      final cleaned = content
          .replaceAll(RegExp(r'```json\s*'), '')
          .replaceAll(RegExp(r'```\s*'), '')
          .trim();

      final arrayMatch = RegExp(r'\[[\s\S]*\]').firstMatch(cleaned);
      final arrayStr = arrayMatch?.group(0) ?? cleaned;

      final jsonList = jsonDecode(arrayStr) as List;
      final now = DateTime.now();
      final tasks = <CareTask>[];

      for (final item in jsonList) {
        if (item is! Map) continue;
        final taskTypeStr = _pick(item, const [
              'taskType', 'task_type', 'type', 'category', 'care_type'
            ]) ??
            'other';
        final taskType = _parseTaskType(taskTypeStr);

        final rawTitle = _pick(item, const [
          'title', 'task_name', 'name', 'task_title', 'label'
        ]);
        final title = (rawTitle != null &&
                rawTitle.isNotEmpty &&
                rawTitle.toLowerCase() != 'care task')
            ? rawTitle
            : _defaultTitleForType(taskType);

        final freqStr = _pick(item, const [
              'frequency', 'schedule_frequency', 'schedule', 'recurrence'
            ]) ??
            'daily';

        final rawTime = _pick(item, const [
          'scheduledTime', 'scheduled_time', 'time', 'schedule_time'
        ]);
        final scheduledTime = _normalizeTime(rawTime);

        final points = (_numPick(item, const [
                  'gamificationPoints',
                  'gamification_points',
                  'points',
                  'xp'
                ]))
                ?.toInt() ??
            _defaultPoints(_parseFrequency(freqStr));

        final notes = _pick(item, const ['notes', 'note', 'description', 'reason']);

        tasks.add(CareTask(
          id: _uuid.v4(),
          petId: pet.id,
          taskType: taskType,
          title: title,
          frequency: _parseFrequency(freqStr),
          scheduledTime: scheduledTime,
          isCompleted: false,
          gamificationPoints: points,
          notes: notes,
          createdAt: now,
          updatedAt: now,
        ));
      }
      return tasks;
    } on CareRecommendationException {
      rethrow;
    } catch (e) {
      throw CareRecommendationException(
        'Could not generate care suggestions. Please try again.',
        cause: e,
      );
    }
  }

  static String _buildPrompt({
    required Pet pet,
    required List<Map<String, dynamic>> vault,
    required List<Map<String, dynamic>> healthLogs,
    required List<Map<String, dynamic>> existingTasks,
  }) {
    final buf = StringBuffer();

    buf.writeln('You are an expert veterinary care assistant.');
    buf.writeln();
    buf.writeln('PET PROFILE:');
    buf.writeln('- Species: ${pet.speciesEnum.name}');
    if (pet.breed != null && pet.breed!.isNotEmpty) {
      buf.writeln('- Breed: ${pet.breed}');
    }
    final age = pet.ageInYears;
    if (age != null) {
      final months = (age * 12).round();
      buf.writeln(
          '- Age: ${months < 24 ? "$months months" : "${age.toStringAsFixed(1)} years"}');
    }
    buf.writeln('- Gender: ${pet.gender.name}');
    if (pet.weightKg != null) {
      buf.writeln('- Weight: ${pet.weightKg} kg');
    }
    if (pet.activityLevel != null && pet.activityLevel!.isNotEmpty) {
      buf.writeln('- Activity level: ${pet.activityLevel}');
    }

    if (vault.isNotEmpty) {
      buf.writeln();
      buf.writeln('ACTIVE MEDICAL RECORDS:');
      for (final r in vault) {
        final type = r['record_type'] ?? '';
        final name = r['name'] ?? '';
        final freq = r['frequency'] ?? '';
        final due = r['next_due_at'] ?? '';
        buf.write('- $type: $name');
        if (freq.isNotEmpty) buf.write(', $freq');
        if (due.isNotEmpty) buf.write(', next due $due');
        buf.writeln();
      }
    }

    if (healthLogs.isNotEmpty) {
      buf.writeln();
      buf.writeln('RECENT HEALTH LOGS:');
      for (final r in healthLogs) {
        final type = r['log_type'] ?? '';
        final wt = r['weight_kg'];
        final sev = r['severity'] ?? '';
        final dx = r['diagnosis'] ?? '';
        buf.write('- $type');
        if (wt != null) buf.write(', weight ${wt}kg');
        if (sev.isNotEmpty) buf.write(', severity $sev');
        if (dx.isNotEmpty) buf.write(', $dx');
        buf.writeln();
      }
    }

    if (existingTasks.isNotEmpty) {
      buf.writeln();
      final taskStrings = existingTasks
          .map((t) => '"${t['title']}" (${t['type']})')
          .join(", ");
      buf.writeln(
          'EXISTING TASKS (DO NOT generate tasks with identical titles or overlapping intent): $taskStrings');
    }

    buf.writeln();
    buf.writeln('OUTPUT FORMAT — you MUST use these EXACT field names:');
    buf.writeln(
        '[{"taskType":"feeding","title":"Morning Feeding","frequency":"daily","scheduledTime":"08:00","gamificationPoints":12,"notes":"reason"}]');
    buf.writeln();
    buf.writeln('RULES:');
    buf.writeln(
        'taskType must be one of: feeding, walk, grooming, medication, vetVisit, training, playtime, dental, nailTrim, bath, other');
    buf.writeln(
        'title: short descriptive name like "Morning Feeding", "Evening Walk", "Weekly Grooming" — NOT generic');
    buf.writeln(
        'frequency must be one of: daily, twiceDaily, weekly, biweekly, monthly, asNeeded');
    buf.writeln('scheduledTime: "HH:MM" string or null');
    buf.writeln('gamificationPoints: integer 5-30');
    buf.writeln(
        'notes: 1-2 sentences specific to this pet\'s breed, age, and activity level');
    buf.writeln();
    buf.writeln('Generate 4-8 tasks. Mix: 2-3 daily, 1-2 weekly, 1-2 monthly.');
    buf.writeln('Return ONLY the JSON array. No markdown, no extra text.');

    return buf.toString();
  }

  static String? _pick(Map item, List<String> keys) {
    // Exact match first
    for (final k in keys) {
      final v = item[k];
      if (v is String && v.isNotEmpty) return v;
    }
    // Case-insensitive fallback against all map keys
    final lowerKeys = keys.map((k) => k.toLowerCase()).toSet();
    for (final entry in item.entries) {
      final keyLower = entry.key.toString().toLowerCase();
      if (lowerKeys.contains(keyLower)) {
        final v = entry.value;
        if (v is String && v.isNotEmpty) return v;
      }
    }
    return null;
  }

  static num? _numPick(Map item, List<String> keys) {
    for (final k in keys) {
      final v = item[k];
      if (v is num) return v;
    }
    return null;
  }

  static String? _normalizeTime(String? raw) {
    if (raw == null || raw.isEmpty || raw == 'null') return null;
    // Accept HH:MM or HH:MM:SS — keep only HH:MM
    final parts = raw.split(':');
    if (parts.length >= 2) {
      final h = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      if (h != null && m != null) {
        return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
      }
    }
    return null;
  }

  static String _defaultTitleForType(CareTaskType t) {
    switch (t) {
      case CareTaskType.feeding:
        return 'Feeding time';
      case CareTaskType.walk:
        return 'Walk';
      case CareTaskType.grooming:
        return 'Grooming session';
      case CareTaskType.medication:
        return 'Medication';
      case CareTaskType.vetVisit:
        return 'Vet visit';
      case CareTaskType.training:
        return 'Training';
      case CareTaskType.playtime:
        return 'Playtime';
      case CareTaskType.dental:
        return 'Dental care';
      case CareTaskType.nailTrim:
        return 'Nail trim';
      case CareTaskType.bath:
        return 'Bath time';
      case CareTaskType.other:
        return 'Care task';
    }
  }

  static int _defaultPoints(CareFrequency f) {
    switch (f) {
      case CareFrequency.daily:
      case CareFrequency.twiceDaily:
      case CareFrequency.asNeeded:
        return 10;
      case CareFrequency.weekly:
      case CareFrequency.biweekly:
        return 20;
      case CareFrequency.monthly:
      case CareFrequency.once:
        return 25;
    }
  }

  static CareTaskType _parseTaskType(String s) {
    switch (s.toLowerCase().replaceAll(RegExp(r'[\s_-]'), '')) {
      case 'feeding':
      case 'feed':
      case 'food':
        return CareTaskType.feeding;
      case 'walk':
      case 'walking':
      case 'exercise':
        return CareTaskType.walk;
      case 'grooming':
      case 'groom':
      case 'brush':
      case 'brushing':
        return CareTaskType.grooming;
      case 'medication':
      case 'medicine':
      case 'meds':
      case 'medicate':
        return CareTaskType.medication;
      case 'vetvisit':
      case 'vet':
      case 'vetcheck':
      case 'veterinary':
        return CareTaskType.vetVisit;
      case 'training':
      case 'train':
      case 'obedience':
        return CareTaskType.training;
      case 'playtime':
      case 'play':
      case 'playactivity':
        return CareTaskType.playtime;
      case 'dental':
      case 'teeth':
      case 'toothbrushing':
      case 'teethcleaning':
        return CareTaskType.dental;
      case 'nailtrim':
      case 'nails':
      case 'claws':
      case 'trimming':
        return CareTaskType.nailTrim;
      case 'bath':
      case 'bathing':
      case 'bathe':
      case 'shower':
        return CareTaskType.bath;
      default:
        return CareTaskType.other;
    }
  }

  static CareFrequency _parseFrequency(String s) {
    switch (s.toLowerCase().replaceAll(RegExp(r'[\s_-]'), '')) {
      case 'daily':
      case 'everyday':
      case 'eachday':
        return CareFrequency.daily;
      case 'twicedaily':
      case 'twiceaday':
      case '2xdaily':
      case '2daily':
        return CareFrequency.twiceDaily;
      case 'weekly':
      case 'onceaweek':
      case 'everyweek':
        return CareFrequency.weekly;
      case 'biweekly':
      case 'every2weeks':
      case 'everyotherweek':
      case 'fortnightly':
        return CareFrequency.biweekly;
      case 'monthly':
      case 'onceamonth':
      case 'everymonth':
        return CareFrequency.monthly;
      case 'asneeded':
      case 'whenneeded':
      case 'occasionally':
      case 'asrequired':
        return CareFrequency.asNeeded;
      default:
        return CareFrequency.daily;
    }
  }
}
