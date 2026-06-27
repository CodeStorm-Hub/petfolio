class WalkLog {
  const WalkLog({
    required this.id,
    required this.petId,
    required this.userId,
    required this.startedAt,
    required this.endedAt,
    required this.durationSeconds,
    required this.distanceMeters,
    required this.createdAt,
  });

  final String id;
  final String petId;
  final String userId;
  final DateTime startedAt;
  final DateTime endedAt;
  final int durationSeconds;
  final double distanceMeters;
  final DateTime createdAt;

  factory WalkLog.fromMap(Map<String, dynamic> map) => WalkLog(
        id: map['id'] as String,
        petId: map['pet_id'] as String,
        userId: map['user_id'] as String,
        startedAt: DateTime.parse(map['started_at'] as String),
        endedAt: DateTime.parse(map['ended_at'] as String),
        durationSeconds: map['duration_seconds'] as int,
        distanceMeters: (map['distance_meters'] as num).toDouble(),
        createdAt: DateTime.parse(map['created_at'] as String),
      );
}
