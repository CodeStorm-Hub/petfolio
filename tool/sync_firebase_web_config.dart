import 'dart:io';

Future<void> main() async {
  final envFile = File('.env');
  if (!await envFile.exists()) {
    stderr.writeln('.env not found. Copy .env.example and set FIREBASE_VAPID_KEY.');
    exitCode = 1;
    return;
  }

  final values = <String, String>{};
  for (final line in await envFile.readAsLines()) {
    final trimmed = line.trim();
    if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
    final idx = trimmed.indexOf('=');
    if (idx <= 0) continue;
    values[trimmed.substring(0, idx).trim()] = trimmed.substring(idx + 1).trim();
  }

  String pick(String primary, String fallback) {
    final v = values[primary];
    if (v != null && v.isNotEmpty) return v;
    return values[fallback] ?? '';
  }

  final apiKey = pick('FIREBASE_WEB_API_KEY', 'FIREBASE_API_KEY');
  final appId = pick('FIREBASE_WEB_APP_ID', 'FIREBASE_APP_ID');
  final projectId = pick('FIREBASE_PROJECT_ID', 'FIREBASE_PROJECT_ID');
  final senderId =
      pick('FIREBASE_MESSAGING_SENDER_ID', 'FIREBASE_MESSAGING_SENDER_ID');

  if ([apiKey, appId, projectId, senderId].any((v) => v.isEmpty)) {
    stderr.writeln(
      'Missing web Firebase keys in .env (FIREBASE_WEB_* or FIREBASE_*).',
    );
    exitCode = 1;
    return;
  }

  final authDomain = values['FIREBASE_AUTH_DOMAIN']?.isNotEmpty == true
      ? values['FIREBASE_AUTH_DOMAIN']!
      : '$projectId.firebaseapp.com';
  final storageBucket = values['FIREBASE_STORAGE_BUCKET']?.isNotEmpty == true
      ? values['FIREBASE_STORAGE_BUCKET']!
      : '$projectId.firebasestorage.app';

  final out = File('web/firebase-config.js');
  await out.writeAsString('''
self.FIREBASE_WEB_CONFIG = {
  apiKey: '$apiKey',
  authDomain: '$authDomain',
  projectId: '$projectId',
  storageBucket: '$storageBucket',
  messagingSenderId: '$senderId',
  appId: '$appId',
};
''');
  stdout.writeln('Wrote ${out.path}');
}
