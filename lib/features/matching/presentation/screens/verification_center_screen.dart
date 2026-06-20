import 'package:flutter/widgets.dart';

import 'match_profile_settings_screen.dart';

export 'match_profile_settings_screen.dart';

class VerificationCenterScreen extends StatelessWidget {
  const VerificationCenterScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const MatchProfileSettingsScreen(initialTab: 1);
}
