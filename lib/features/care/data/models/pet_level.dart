import 'package:flutter/material.dart';
import 'package:petfolio/core/theme/app_colors.dart';

// ── Level ladder ─────────────────────────────────────────────────────────────
// Each entry is the XP threshold to *reach* that level.
const _thresholds = <int>[
  0,    // Lv 1 – New Paw
  100,  // Lv 2 – Curious Pup
  250,  // Lv 3 – Attentive Owner
  500,  // Lv 4 – Dedicated Keeper
  900,  // Lv 5 – Responsible Guardian
  1400, // Lv 6 – Devoted Companion
  2000, // Lv 7 – Caretaker
  2800, // Lv 8 – Pet Whisperer
  3800, // Lv 9 – Master Guardian
  5000, // Lv 10 – Legendary Caretaker
];

const _titles = <String>[
  'New Paw',
  'Curious Pup',
  'Attentive Owner',
  'Dedicated Keeper',
  'Responsible Guardian',
  'Devoted Companion',
  'Caretaker',
  'Pet Whisperer',
  'Master Guardian',
  'Legendary Caretaker',
];

class PetLevel {
  const PetLevel._({
    required this.level,
    required this.title,
    required this.currentXp,
    required this.levelStartXp,
    required this.levelEndXp,
    required this.isMaxLevel,
  });

  final int level;
  final String title;
  final int currentXp;
  final int levelStartXp;
  final int levelEndXp;
  final bool isMaxLevel;

  static PetLevel fromXp(int totalXp) {
    final xp = totalXp.clamp(0, 999999);
    final maxIdx = _thresholds.length - 1;

    int idx = maxIdx;
    for (int i = 0; i < _thresholds.length; i++) {
      if (xp < _thresholds[i]) {
        idx = i - 1;
        break;
      }
    }
    idx = idx.clamp(0, maxIdx);

    final isMax = idx == maxIdx;
    final start = _thresholds[idx];
    final end = isMax ? _thresholds[maxIdx] + 9999 : _thresholds[idx + 1];

    return PetLevel._(
      level: idx + 1,
      title: _titles[idx],
      currentXp: xp,
      levelStartXp: start,
      levelEndXp: end,
      isMaxLevel: isMax,
    );
  }

  int get xpInLevel => currentXp - levelStartXp;
  int get xpForLevel => levelEndXp - levelStartXp;
  int get xpToNext => isMaxLevel ? 0 : levelEndXp - currentXp;
  double get progress => isMaxLevel ? 1.0 : (xpInLevel / xpForLevel).clamp(0.0, 1.0);
  String get nextTitle => isMaxLevel ? title : _titles[(level).clamp(0, _titles.length - 1)];
}

// ── Badge catalog ─────────────────────────────────────────────────────────────
// Maps every real badge_type from pet_badges to display metadata.

class BadgeInfo {
  const BadgeInfo({
    required this.type,
    required this.emoji,
    required this.label,
    required this.color,
    required this.description,
  });

  final String type;
  final String emoji;
  final String label;
  final Color color;
  final String description;
}

const kBadgeCatalog = <BadgeInfo>[
  BadgeInfo(
    type: 'first_log',
    emoji: '🐾',
    label: 'First Log',
    color: AppColors.mint,
    description: 'Logged your first care activity',
  ),
  BadgeInfo(
    type: '3_day_streak',
    emoji: '🔥',
    label: '3-Day',
    color: AppColors.tangerine,
    description: '3 days in a row',
  ),
  BadgeInfo(
    type: '7_day_hero',
    emoji: '🦸',
    label: '7-Day Hero',
    color: AppColors.sunny,
    description: '7 days in a row',
  ),
  BadgeInfo(
    type: 'routine_master',
    emoji: '💯',
    label: 'Routine Master',
    color: AppColors.poppy,
    description: '14 days in a row',
  ),
  BadgeInfo(
    type: '30_day_legend',
    emoji: '👑',
    label: '30-Day Legend',
    color: AppColors.lilac,
    description: '30 days in a row',
  ),
  BadgeInfo(
    type: 'care_champion',
    emoji: '🏆',
    label: 'Care Champion',
    color: AppColors.sky,
    description: '100 total care logs',
  ),
];

BadgeInfo? badgeInfoFor(String type) {
  for (final b in kBadgeCatalog) {
    if (b.type == type) return b;
  }
  return null;
}
