bool get integrationTestActive =>
    const bool.fromEnvironment('FLUTTER_TEST', defaultValue: false);
