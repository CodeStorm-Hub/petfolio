class CareStreak {
  const CareStreak({
    required this.petId,
    required this.currentStreak,
    this.lastCompletionDate,
    required this.bestStreak,
  });

  final String petId;
  final int currentStreak;
  final DateTime? lastCompletionDate;
  final int bestStreak;

  factory CareStreak.fromJson(Map<String, dynamic> json) {
    final rawLast = json['last_completion_date'];
    DateTime? last;
    if (rawLast is String) {
      last = DateTime.tryParse(rawLast);
    }
    return CareStreak(
      petId: json['pet_id'] as String,
      currentStreak: (json['current_streak'] as num?)?.toInt() ?? 0,
      lastCompletionDate: last,
      bestStreak: (json['best_streak'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'pet_id': petId,
        'current_streak': currentStreak,
        'last_completion_date': lastCompletionDate?.toIso8601String().split('T').first,
        'best_streak': bestStreak,
      };
}
