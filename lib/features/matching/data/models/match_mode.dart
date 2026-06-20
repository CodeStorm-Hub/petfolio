enum MatchMode {
  playdate,
  breeding;

  String get dbValue => switch (this) {
        MatchMode.playdate => 'playdate',
        MatchMode.breeding => 'breeding',
      };

  String get label => switch (this) {
        MatchMode.playdate => 'Playdate',
        MatchMode.breeding => 'Breeding',
      };

  static MatchMode fromDb(String? value) => switch (value) {
        'breeding' => MatchMode.breeding,
        _ => MatchMode.playdate,
      };
}
