import 'dart:convert';
import 'dart:io';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;

final _apiKey = Platform.environment['NVIDIA_API_KEY'] ?? '';
const _url = 'https://integrate.api.nvidia.com/v1/chat/completions';
const _uuid = Uuid();

Future<List<Map<String, dynamic>>> generateRecommendations(Map<String, dynamic> pet) async {
  final petDetails = 'Species: ${pet['species']}, Breed: ${pet['breed'] ?? 'Unknown'}, Age: ${pet['date_of_birth'] ?? 'Unknown'}, Activity Level: ${pet['activity_level'] ?? 'Unknown'}.';
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

  if (_apiKey.isEmpty) throw Exception('NVIDIA_API_KEY environment variable is not set');
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
    throw Exception('Failed: ${response.statusCode} - ${response.body}');
  }

  final content = jsonDecode(response.body)['choices'][0]['message']['content'] as String;
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
      'is_completed': false,
      'gamification_points': item['gamificationPoints'] ?? 10,
      'notes': item['notes'] ?? '',
      'created_at': now,
      'updated_at': now,
    });
  }
  return tasks;
}

void main() async {
  final petsJson = '[{"id":"ca2ffad9-b18f-498d-b609-10d5e7a60b1e","name":"Afsan","species":"dog","breed":"Mixed breed","date_of_birth":"2023-04-14","weight_kg":"1.00","activity_level":"low"},{"id":"a1000001-0001-4000-8000-000000000002","name":"Clover","species":"rabbit","breed":"Holland Lop","date_of_birth":"2024-11-16","weight_kg":"1.80","activity_level":"low"},{"id":"a1000001-0001-4000-8000-000000000003","name":"Sunny","species":"bird","breed":"Cockatiel","date_of_birth":"2025-07-16","weight_kg":"0.09","activity_level":"moderate"},{"id":"a1000001-0001-4000-8000-000000000005","name":"Rex","species":"reptile","breed":"Bearded Dragon","date_of_birth":"2023-05-16","weight_kg":"0.45","activity_level":"low"},{"id":"a1000001-0001-4000-8000-000000000006","name":"Willow","species":"rabbit","breed":"Mini Rex","date_of_birth":"2024-05-16","weight_kg":"2.20","activity_level":"moderate"},{"id":"a1000001-0001-4000-8000-000000000007","name":"Echo","species":"bird","breed":"Budgerigar","date_of_birth":"2025-03-16","weight_kg":"0.04","activity_level":"moderate"},{"id":"4271d48b-1b75-4dfd-8bcf-176d68f8565e","name":"Montu Reza","species":"cat","breed":"Persian","date_of_birth":"2025-06-19","weight_kg":"1.50","activity_level":"moderate"},{"id":"a1000001-0001-4000-8000-000000000009","name":"Duke","species":"dog","breed":"Border Collie","date_of_birth":"2021-05-16","weight_kg":"22.00","activity_level":"very_high"},{"id":"4c0c7bb1-4319-4b11-8a29-918b8e4c3ccc","name":"Snow","species":"cat","breed":"Persian","date_of_birth":"2025-05-14","weight_kg":"1.00","activity_level":"high"},{"id":"d287308b-8f99-45e5-ae59-d38486697d31","name":"Fluffy","species":"cat","breed":"Persian","date_of_birth":"2023-05-16","weight_kg":null,"activity_level":"moderate"},{"id":"a1000001-0001-4000-8000-000000000001","name":"Cooper","species":"dog","breed":"Labrador Retriever","date_of_birth":"2022-05-16","weight_kg":"28.50","activity_level":"high"},{"id":"a1000001-0001-4000-8000-000000000004","name":"Nori","species":"fish","breed":"Betta","date_of_birth":"2025-09-16","weight_kg":null,"activity_level":"sedentary"},{"id":"a1000001-0001-4000-8000-000000000008","name":"Mochi","species":"cat","breed":"Domestic Shorthair","date_of_birth":"2020-05-16","weight_kg":"4.10","activity_level":"low"},{"id":"a1000001-0001-4000-8000-000000000010","name":"Ziggy","species":"reptile","breed":"Leopard Gecko","date_of_birth":"2022-05-16","weight_kg":"0.10","activity_level":"sedentary"},{"id":"db9dbc67-53bb-4e54-9b1d-d278f8391a7d","name":"Milo","species":"dog","breed":"Labrador Retriever","date_of_birth":null,"weight_kg":"12.50","activity_level":"moderate"},{"id":"e23b4fa6-34ed-4c89-a9ff-7efb661d6141","name":"Tommy","species":"dog","breed":"Golden Retriever","date_of_birth":"2020-05-16","weight_kg":"5.00","activity_level":"moderate"},{"id":"e462295a-ca39-4744-95e3-c9ea945b0ca5","name":"Snow","species":"cat","breed":"Persian","date_of_birth":"2024-05-17","weight_kg":"2.00","activity_level":"low"},{"id":"5c1412a0-52ae-4ccb-b1ba-493fbb80fc69","name":"Kutta","species":"dog","breed":"Labrador Retriever","date_of_birth":"2025-05-21","weight_kg":"2.00","activity_level":"high"},{"id":"c1364fe3-df17-4fbf-bfe0-3e7dfc1e0f0e","name":"Kaltu","species":"cat","breed":"Persian","date_of_birth":"2026-03-20","weight_kg":"1.00","activity_level":"moderate"},{"id":"14378b2e-5961-4d07-ab9f-48246e839e10","name":"Montu","species":"cat","breed":"Persian","date_of_birth":"2024-05-16","weight_kg":"2.00","activity_level":"moderate"},{"id":"3f19b74c-dde1-433e-aa35-32f112930f63","name":"Leo","species":"cat","breed":"Maine Coon","date_of_birth":"2025-05-22","weight_kg":"2.00","activity_level":null}]';

  final pets = jsonDecode(petsJson) as List;
  
  final existingTasksJson = '[{"pet_id":"c1364fe3-df17-4fbf-bfe0-3e7dfc1e0f0e"},{"pet_id":"14378b2e-5961-4d07-ab9f-48246e839e10"},{"pet_id":"db9dbc67-53bb-4e54-9b1d-d278f8391a7d"},{"pet_id":"3f19b74c-dde1-433e-aa35-32f112930f63"},{"pet_id":"4c0c7bb1-4319-4b11-8a29-918b8e4c3ccc"},{"pet_id":"d287308b-8f99-45e5-ae59-d38486697d31"},{"pet_id":"e462295a-ca39-4744-95e3-c9ea945b0ca5"}]';
  final existingTasks = jsonDecode(existingTasksJson) as List;
  final petsWithTasks = existingTasks.map((t) => t['pet_id']).toSet();
  
  final buffer = StringBuffer();
  buffer.writeln('INSERT INTO care_tasks (id, pet_id, task_type, title, frequency, scheduled_time, is_completed, gamification_points, notes, created_at, updated_at) VALUES ');

  int count = 0;
  for (var p in pets) {
    if (!petsWithTasks.contains(p['id'])) {
      print('Generating for ${p['name']}...');
      try {
        final tasks = await generateRecommendations(p);
        for (var t in tasks) {
          final title = t['title'].toString().replaceAll("'", "''");
          final notes = t['notes'].toString().replaceAll("'", "''");
          final st = t['scheduled_time'] == null ? "NULL" : "'${t['scheduled_time']}'";
          
          buffer.writeln("('${t['id']}', '${t['pet_id']}', '${t['task_type']}', '$title', '${t['frequency']}', $st, false, ${t['gamification_points']}, '$notes', '${t['created_at']}', '${t['updated_at']}'),");
          count++;
        }
      } catch (e) {
        print('Error generating for ${p['name']}: $e');
      }
    }
  }
  
  if (count > 0) {
    var sql = buffer.toString();
    sql = '${sql.substring(0, sql.length - 2)};'; // remove last comma
    File('inserts.sql').writeAsStringSync(sql);
    print('Generated inserts.sql with $count tasks.');
  } else {
    print('No tasks generated.');
  }
}
