class UnlockedBadge {
  const UnlockedBadge({required this.badgeType, required this.unlockedAt});

  final String badgeType;
  final DateTime unlockedAt;

  factory UnlockedBadge.fromJson(Map<String, dynamic> json) {
    final rawAt = json['unlocked_at'];
    final at = rawAt is String ? DateTime.tryParse(rawAt) : null;
    return UnlockedBadge(
      badgeType: json['badge_type'] as String,
      unlockedAt: at ?? DateTime.utc(2020),
    );
  }
}

class PetAwardsSummary {
  const PetAwardsSummary({
    required this.currentStreak,
    required this.bestStreak,
    required this.totalXp,
    required this.logsCount,
    required this.unlockedBadges,
  });

  final int currentStreak;
  final int bestStreak;
  final int totalXp;
  final int logsCount;
  final List<UnlockedBadge> unlockedBadges;

  Set<String> get unlockedTypes =>
      unlockedBadges.map((b) => b.badgeType).toSet();

  factory PetAwardsSummary.fromJson(Map<String, dynamic> json) {
    final badgesRaw = json['badges'];
    final badges = badgesRaw is List
        ? badgesRaw
            .map((e) => UnlockedBadge.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList()
        : <UnlockedBadge>[];
    return PetAwardsSummary(
      currentStreak: (json['current_streak'] as num?)?.toInt() ?? 0,
      bestStreak: (json['best_streak'] as num?)?.toInt() ?? 0,
      totalXp: (json['total_xp'] as num?)?.toInt() ?? 0,
      logsCount: (json['logs_count'] as num?)?.toInt() ?? 0,
      unlockedBadges: badges,
    );
  }

  static PetAwardsSummary get empty => const PetAwardsSummary(
        currentStreak: 0,
        bestStreak: 0,
        totalXp: 0,
        logsCount: 0,
        unlockedBadges: [],
      );
}
