import 'package:flutter/widgets.dart';

import 'shop_profile_screen.dart';

export 'shop_profile_screen.dart';

class EditShopScreen extends StatelessWidget {
  const EditShopScreen({super.key});

  @override
  Widget build(BuildContext context) => const ShopProfileScreen(isNew: false);
}
