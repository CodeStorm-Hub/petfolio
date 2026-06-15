import 'package:flutter/widgets.dart';

import 'create_content_screen.dart';

export 'create_content_screen.dart';

class CreatePostScreen extends StatelessWidget {
  const CreatePostScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const CreateContentScreen(initialMode: ContentMode.post);
}
