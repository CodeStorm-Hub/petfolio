import 'package:flutter/foundation.dart';

bool get marionetteEnabledInThisBuild =>
    kDebugMode &&
    !const bool.fromEnvironment('FLUTTER_TEST', defaultValue: false);
