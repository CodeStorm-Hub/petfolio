class PetStats {
  const PetStats({
    required this.postCount,
    required this.followerCount,
    required this.followingCount,
  });

  final int postCount;
  final int followerCount;
  final int followingCount;

  factory PetStats.empty() => const PetStats(
        postCount: 0,
        followerCount: 0,
        followingCount: 0,
      );
}
