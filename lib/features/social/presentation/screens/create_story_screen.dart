import 'package:flutter/widgets.dart';

import 'create_content_screen.dart';

export 'create_content_screen.dart';

class CreateStoryScreen extends StatelessWidget {
  const CreateStoryScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const CreateContentScreen(initialMode: ContentMode.story);
}
