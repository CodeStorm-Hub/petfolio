import 'package:flutter/material.dart';
import 'package:petfolio/core/theme/app_colors.dart';

class PetBadge {
  const PetBadge({
    required this.petId,
    required this.badgeType,
    required this.unlockedAt,
  });

  final String petId;
  final String badgeType;
  final DateTime unlockedAt;

  factory PetBadge.fromJson(Map<String, dynamic> json) {
    return PetBadge(
      petId: json['pet_id'] as String,
      badgeType: json['badge_type'] as String,
      unlockedAt: DateTime.parse(json['unlocked_at'] as String),
    );
  }

  String get emoji {
    switch (badgeType) {
      case '7_day_hero': return '🔥';
      case '100_xp': return '💯';
      case 'treat_pro': return '🦴';
      case 'vaccinated': return '💉';
      default: return '🏆';
    }
  }

  Color get color {
    switch (badgeType) {
      case '7_day_hero': return AppColors.sunny;
      case '100_xp': return AppColors.poppy;
      case 'treat_pro': return AppColors.tangerine;
      case 'vaccinated': return AppColors.mint;
      default: return AppColors.lilac;
    }
  }

  String get title {
    switch (badgeType) {
      case '7_day_hero': return '7-Day';
      case '100_xp': return '100 XP';
      case 'treat_pro': return 'Treat Pro';
      case 'vaccinated': return 'Vaccinated';
      default: return badgeType;
    }
  }
}
