import 'dart:io' show Platform;

bool get integrationTestActive =>
    Platform.environment.containsKey('FLUTTER_TEST') ||
    const bool.fromEnvironment('FLUTTER_TEST', defaultValue: false);
