class Story {
  final String id;
  final String petId;
  final String imageUrl;
  final DateTime createdAt;
  final List<String> viewedByUsers;
  
  // Joined fields for convenience in UI
  final String petName;
  final String? petAvatarUrl;
  final String petSpecies;

  const Story({
    required this.id,
    required this.petId,
    required this.imageUrl,
    required this.createdAt,
    required this.viewedByUsers,
    required this.petName,
    this.petAvatarUrl,
    required this.petSpecies,
  });

  factory Story.fromJson(Map<String, dynamic> json) {
    final pet = (json['pet'] as Map?)?.cast<String, dynamic>() ?? const {};
    return Story(
      id: json['id'] as String,
      petId: json['pet_id'] as String,
      imageUrl: json['image_url'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      viewedByUsers: (json['viewed_by_users'] as List?)?.cast<String>() ?? const [],
      petName: (pet['name'] as String?) ?? 'Unknown',
      petAvatarUrl: pet['avatar_url'] as String?,
      petSpecies: (pet['species'] as String?) ?? 'dog',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pet_id': petId,
      'image_url': imageUrl,
      'created_at': createdAt.toIso8601String(),
      'viewed_by_users': viewedByUsers,
    };
  }

  Story copyWith({
    String? id,
    String? petId,
    String? imageUrl,
    DateTime? createdAt,
    List<String>? viewedByUsers,
    String? petName,
    String? petAvatarUrl,
    String? petSpecies,
  }) {
    return Story(
      id: id ?? this.id,
      petId: petId ?? this.petId,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      viewedByUsers: viewedByUsers ?? this.viewedByUsers,
      petName: petName ?? this.petName,
      petAvatarUrl: petAvatarUrl ?? this.petAvatarUrl,
      petSpecies: petSpecies ?? this.petSpecies,
    );
  }
}
