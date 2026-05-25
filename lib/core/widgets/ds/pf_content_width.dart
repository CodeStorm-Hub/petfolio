import 'package:flutter/material.dart';

import '../../layout/petfolio_breakpoints.dart';

class PfContentWidth extends StatelessWidget {
  const PfContentWidth({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final maxW = context.pfContentMaxWidth;
    if (maxW == null) return child;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxW),
        child: child,
      ),
    );
  }
}
