import 'package:flutter/material.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  /// Breakpoint constants
  static const double mobileMax = 600;
  static const double tabletMax = 1024;

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < mobileMax;

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= mobileMax && width < tabletMax;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= tabletMax;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        if (width >= tabletMax) {
          return desktop ?? tablet ?? mobile;
        } else if (width >= mobileMax) {
          return tablet ?? mobile;
        } else {
          return mobile;
        }
      },
    );
  }
}
