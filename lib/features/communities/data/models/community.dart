class Community {
  const Community({
    required this.id,
    required this.name,
    this.description,
    this.speciesFilter,
    this.avatarUrl,
    required this.memberCount,
    required this.postCount,
    required this.createdAt,
    this.isMember = false,
  });

  final String id;
  final String name;
  final String? description;
  final String? speciesFilter;
  final String? avatarUrl;
  final int memberCount;
  final int postCount;
  final DateTime createdAt;
  final bool isMember;

  factory Community.fromJson(Map<String, dynamic> j, {bool isMember = false}) =>
      Community(
        id: j['id'] as String,
        name: j['name'] as String,
        description: j['description'] as String?,
        speciesFilter: j['species_filter'] as String?,
        avatarUrl: j['avatar_url'] as String?,
        memberCount: (j['member_count'] as num?)?.toInt() ?? 0,
        postCount: (j['post_count'] as num?)?.toInt() ?? 0,
        createdAt: DateTime.parse(j['created_at'] as String),
        isMember: isMember,
      );

  Community copyWith({bool? isMember, int? memberCount, int? postCount}) =>
      Community(
        id: id,
        name: name,
        description: description,
        speciesFilter: speciesFilter,
        avatarUrl: avatarUrl,
        memberCount: memberCount ?? this.memberCount,
        postCount: postCount ?? this.postCount,
        createdAt: createdAt,
        isMember: isMember ?? this.isMember,
      );
}
