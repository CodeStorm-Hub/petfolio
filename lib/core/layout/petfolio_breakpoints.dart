import 'package:flutter/material.dart';

enum PetfolioWidthClass {
  compact,
  medium,
  expanded,
  large,
}

abstract final class PetfolioBreakpoints {
  static const double compactMax = 599;
  static const double mediumMax = 839;
  static const double expandedMax = 1199;

  static PetfolioWidthClass widthClassOf(double width) {
    if (width <= compactMax) return PetfolioWidthClass.compact;
    if (width <= mediumMax) return PetfolioWidthClass.medium;
    if (width <= expandedMax) return PetfolioWidthClass.expanded;
    return PetfolioWidthClass.large;
  }

  static bool useBottomNav(double width) => width <= compactMax;

  static bool useNavigationRail(double width) =>
      width > compactMax && width < 840;

  static bool useNavigationDrawer(double width) => width >= 840;

  static bool useListDetail(double width) => width >= 840;

  static int marketplaceGridColumns(double width) {
    final c = widthClassOf(width);
    return switch (c) {
      PetfolioWidthClass.compact => 2,
      PetfolioWidthClass.medium => 3,
      PetfolioWidthClass.expanded => 4,
      PetfolioWidthClass.large => 4,
    };
  }

  static double? contentMaxWidth(double width) {
    final c = widthClassOf(width);
    return switch (c) {
      PetfolioWidthClass.compact => null,
      PetfolioWidthClass.medium => 720,
      PetfolioWidthClass.expanded => 840,
      PetfolioWidthClass.large => 1040,
    };
  }
}

extension PetfolioBreakpointContext on BuildContext {
  double get pfWidth => MediaQuery.sizeOf(this).width;

  PetfolioWidthClass get pfWidthClass =>
      PetfolioBreakpoints.widthClassOf(pfWidth);

  bool get pfIsCompact => pfWidth <= PetfolioBreakpoints.compactMax;

  bool get pfIsMedium =>
      pfWidth > PetfolioBreakpoints.compactMax &&
      pfWidth <= PetfolioBreakpoints.mediumMax;

  bool get pfUseDrawer => PetfolioBreakpoints.useNavigationDrawer(pfWidth);

  bool get pfUseListDetail => PetfolioBreakpoints.useListDetail(pfWidth);

  double? get pfContentMaxWidth =>
      PetfolioBreakpoints.contentMaxWidth(pfWidth);

  T pfResponsive<T>({
    required T compact,
    T? medium,
    T? expanded,
    T? large,
  }) {
    return switch (pfWidthClass) {
      PetfolioWidthClass.compact => compact,
      PetfolioWidthClass.medium => medium ?? compact,
      PetfolioWidthClass.expanded => expanded ?? medium ?? compact,
      PetfolioWidthClass.large => large ?? expanded ?? medium ?? compact,
    };
  }
}
