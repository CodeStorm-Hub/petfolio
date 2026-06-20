import 'package:flutter/widgets.dart';

import 'match_profile_settings_screen.dart';

export 'match_profile_settings_screen.dart';

class BreedingSetupScreen extends StatelessWidget {
  const BreedingSetupScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const MatchProfileSettingsScreen(initialTab: 0);
}
