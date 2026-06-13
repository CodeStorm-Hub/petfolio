class Appointment {
  const Appointment({
    required this.id,
    required this.petId,
    required this.title,
    required this.scheduledAt,
    required this.isCompleted,
    required this.createdAt,
    this.status = 'pending',
    this.vetName,
    this.clinicName,
    this.notes,
    this.clinicId,
    this.serviceId,
    this.reason,
    this.urgency,
    this.mediaUrl,
  });

  final String id;
  final String petId;
  final String title;
  final DateTime scheduledAt;
  final bool isCompleted;
  final DateTime createdAt;
  final String status;
  final String? vetName;
  final String? clinicName;
  final String? notes;
  final String? clinicId;
  final String? serviceId;
  final String? reason;
  final String? urgency;
  final String? mediaUrl;

  factory Appointment.fromJson(Map<String, dynamic> json) {
    final statusVal = json['status'] as String? ?? 'pending';
    final legacyCompleted = json['is_completed'] as bool?;
    final resolvedStatus = statusVal == 'upcoming' ? 'pending' : statusVal;
    return Appointment(
      id: json['id'] as String,
      petId: json['pet_id'] as String,
      title: json['title'] as String,
      scheduledAt: DateTime.parse(json['scheduled_at'] as String),
      isCompleted: resolvedStatus == 'completed' || (legacyCompleted ?? false),
      status: resolvedStatus,
      createdAt: DateTime.parse(json['created_at'] as String),
      vetName: json['vet_name'] as String?,
      clinicName: (json['location'] ?? json['clinic_name']) as String?,
      notes: json['notes'] as String?,
      clinicId: json['clinic_id'] as String?,
      serviceId: json['service_id'] as String?,
      reason: json['reason'] as String?,
      urgency: json['urgency'] as String?,
      mediaUrl: json['media_url'] as String?,
    );
  }

  Map<String, dynamic> toInsertJson({required String ownerId}) => {
        'pet_id': petId,
        'owner_id': ownerId,
        'title': title,
        'scheduled_at': scheduledAt.toUtc().toIso8601String(),
        'status': status,
        if (vetName != null) 'vet_name': vetName,
        if (clinicName != null) 'location': clinicName,
        if (notes != null) 'notes': notes,
        if (clinicId != null) 'clinic_id': clinicId,
        if (serviceId != null) 'service_id': serviceId,
        if (reason != null) 'reason': reason,
        if (urgency != null) 'urgency': urgency,
        if (mediaUrl != null) 'media_url': mediaUrl,
      };

  Map<String, dynamic> toJson() => toInsertJson(ownerId: 'test-owner');

  Appointment copyWith({
    bool? isCompleted,
    String? title,
    String? vetName,
    String? clinicName,
    String? notes,
    DateTime? scheduledAt,
    String? clinicId,
    String? serviceId,
    String? status,
    String? reason,
    String? urgency,
    String? mediaUrl,
  }) =>
      Appointment(
        id: id,
        petId: petId,
        title: title ?? this.title,
        scheduledAt: scheduledAt ?? this.scheduledAt,
        isCompleted: isCompleted ?? this.isCompleted,
        createdAt: createdAt,
        status: status ?? this.status,
        vetName: vetName ?? this.vetName,
        clinicName: clinicName ?? this.clinicName,
        notes: notes ?? this.notes,
        clinicId: clinicId ?? this.clinicId,
        serviceId: serviceId ?? this.serviceId,
        reason: reason ?? this.reason,
        urgency: urgency ?? this.urgency,
        mediaUrl: mediaUrl ?? this.mediaUrl,
      );
}
