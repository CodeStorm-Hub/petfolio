import 'package:flutter/material.dart';

enum ActivityLevel {
  sedentary('sedentary', 'Couch potato', 'Sedentary', Icons.weekend_rounded, 1.2),
  low('low', 'Easy going', 'Low', Icons.directions_walk_rounded, 1.4),
  moderate('moderate', 'Active', 'Moderate', Icons.directions_run_rounded, 1.6),
  high('high', 'Very active', 'High', Icons.fitness_center_rounded, 1.8),
  veryHigh('very_high', 'Athlete', 'Very High', Icons.bolt_rounded, 2.0);

  const ActivityLevel(
    this.id,
    this.label,
    this.shortLabel,
    this.icon,
    this.factor,
  );

  final String id;
  final String label;
  final String shortLabel;
  final IconData icon;
  final double factor;

  static ActivityLevel? fromId(String? id) {
    if (id == null) return null;
    final normalized = id.toLowerCase();
    for (final level in values) {
      if (level.id == normalized) return level;
    }
    return null;
  }
}
