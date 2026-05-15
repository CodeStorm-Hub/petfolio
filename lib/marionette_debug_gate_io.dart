import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

bool get marionetteEnabledInThisBuild =>
    kDebugMode &&
    !Platform.environment.containsKey('FLUTTER_TEST') &&
    !const bool.fromEnvironment('FLUTTER_TEST', defaultValue: false);
