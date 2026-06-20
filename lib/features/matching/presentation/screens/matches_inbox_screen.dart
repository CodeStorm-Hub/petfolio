import 'package:flutter/widgets.dart';

import 'match_hub_screen.dart';

export 'match_hub_screen.dart';

class MatchesInboxScreen extends StatelessWidget {
  const MatchesInboxScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const MatchHubScreen(initialTab: 0);
}
