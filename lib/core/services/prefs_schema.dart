import 'package:shared_preferences/shared_preferences.dart';

class PrefsSchema {
  PrefsSchema._();

  static const String themeMode       = 'theme_mode';
  static const String activePetPrefix = 'active_pet_id_';
  static const String cartPrefix      = 'cart_';
  static const String matchSpecies    = 'match_pref_species';
  static const String matchDistance   = 'match_pref_distance_meters';
  static const String matchAgeMin     = 'match_pref_age_min';
  static const String matchAgeMax     = 'match_pref_age_max';

  static const String _versionKey     = 'prefs_schema_version';
  static const int    _currentVersion = 1;

  static Future<void> migrate() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getInt(_versionKey) ?? 0;
    if (stored >= _currentVersion) return;
    // v0 → v1: baseline release; all readers use null-safe defaults already.
    await prefs.setInt(_versionKey, _currentVersion);
  }
}
