class WeightLog {
  const WeightLog({
    required this.id,
    required this.petId,
    required this.weightKg,
    required this.recordedAt,
    this.notes,
  });

  final String id;
  final String petId;
  final double weightKg;
  final DateTime recordedAt;
  final String? notes;

  factory WeightLog.fromJson(Map<String, dynamic> json) => WeightLog(
        id: json['id'] as String,
        petId: json['pet_id'] as String,
        weightKg: (json['weight_kg'] as num).toDouble(),
        recordedAt: DateTime.parse(json['recorded_at'] as String),
        notes: json['notes'] as String?,
      );

  WeightLog copyWith({
    String? id,
    String? petId,
    double? weightKg,
    DateTime? recordedAt,
    String? notes,
  }) => WeightLog(
        id: id ?? this.id,
        petId: petId ?? this.petId,
        weightKg: weightKg ?? this.weightKg,
        recordedAt: recordedAt ?? this.recordedAt,
        notes: notes ?? this.notes,
      );
}
