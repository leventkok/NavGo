import 'package:shared_preferences/shared_preferences.dart';

class SessionRepository {
  SessionRepository(this._prefs);

  final SharedPreferences _prefs;

  static const _kOnboarding = 'navgo_onboarding_complete';
  static const _kDisplayName = 'navgo_display_name';
  static const _kDefaultArea = 'navgo_default_area';
  static const _kTempo = 'navgo_tempo';
  static const _kInterests = 'navgo_interests';
  static const _kGroupType = 'navgo_group_type';
  static const _kTransportMode = 'navgo_transport_mode';
  static const _kTravelStyleLegacy = 'navgo_travel_style';

  bool get onboardingComplete => _prefs.getBool(_kOnboarding) ?? false;

  String get displayName => _prefs.getString(_kDisplayName) ?? '';

  /// City / district from GPS or manual fallback.
  String get defaultArea => _prefs.getString(_kDefaultArea) ?? '';

  /// calm | balanced | packed
  String get tempo => _prefs.getString(_kTempo) ?? 'balanced';

  /// history | food | nature | art | shopping
  List<String> get interests =>
      _prefs.getStringList(_kInterests) ?? const <String>[];

  /// solo | couple | friends | family
  String get groupType => _prefs.getString(_kGroupType) ?? 'solo';

  /// walk | transit | drive | bike
  String get transportMode => _prefs.getString(_kTransportMode) ?? 'walk';

  int get maxResultsForTempo {
    return switch (tempo) {
      'calm' => 3,
      'packed' => 7,
      _ => 5,
    };
  }

  /// Maps session transport to Routes API travel_mode.
  String get apiTravelMode {
    return switch (transportMode) {
      'transit' => 'TRANSIT',
      'drive' => 'DRIVE',
      'bike' => 'BICYCLE',
      _ => 'WALK',
    };
  }

  Future<void> completeOnboarding({
    required String displayName,
    required String defaultArea,
    required String tempo,
    required List<String> interests,
    required String groupType,
    required String transportMode,
  }) async {
    await _prefs.setString(_kDisplayName, displayName.trim());
    await _prefs.setString(_kDefaultArea, defaultArea.trim());
    await _prefs.setString(_kTempo, tempo);
    await _prefs.setStringList(_kInterests, interests);
    await _prefs.setString(_kGroupType, groupType);
    await _prefs.setString(_kTransportMode, transportMode);
    await _prefs.remove(_kTravelStyleLegacy);
    await _prefs.setBool(_kOnboarding, true);
  }

  Future<void> setDefaultArea(String area) async {
    await _prefs.setString(_kDefaultArea, area.trim());
  }

  Future<void> resetOnboarding() async {
    await _prefs.remove(_kOnboarding);
    await _prefs.remove(_kDisplayName);
    await _prefs.remove(_kDefaultArea);
    await _prefs.remove(_kTempo);
    await _prefs.remove(_kInterests);
    await _prefs.remove(_kGroupType);
    await _prefs.remove(_kTransportMode);
    await _prefs.remove(_kTravelStyleLegacy);
  }
}
