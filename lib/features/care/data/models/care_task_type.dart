import 'package:flutter/material.dart';
import 'package:petfolio/core/theme/app_colors.dart';

enum CareTaskType {
  feed,
  walk,
  med;

  String get label {
    switch (this) {
      case CareTaskType.feed: return 'Morning meal';
      case CareTaskType.walk: return 'Morning walk';
      case CareTaskType.med:  return 'Medication';
    }
  }

  String get sublabel {
    switch (this) {
      case CareTaskType.feed: return '07:30 · 280 g kibble';
      case CareTaskType.walk: return '08:10 · 28 min · 2.1 km';
      case CareTaskType.med:  return '09:00 · monthly';
    }
  }

  Color get iconColor => AppColors.meadow500;
  Color get iconTint  => const Color(0xFFDAEBE0); // meadow/T
}
