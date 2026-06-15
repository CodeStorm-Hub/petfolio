import 'package:flutter/widgets.dart';

import 'shop_profile_screen.dart';

export 'shop_profile_screen.dart';

class ShopSetupScreen extends StatelessWidget {
  const ShopSetupScreen({super.key});

  @override
  Widget build(BuildContext context) => const ShopProfileScreen(isNew: true);
}
