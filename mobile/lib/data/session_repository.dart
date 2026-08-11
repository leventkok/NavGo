import 'package:shared_preferences/shared_preferences.dart';

class SessionRepository {
  SessionRepository(this._prefs);

  final SharedPreferences _prefs;

  static const _kOnboarding = 'navgo_onboarding_complete';
  static const _kDisplayName = 'navgo_display_name';
  static const _kTravelStyle = 'navgo_travel_style';
  static const _kDefaultArea = 'navgo_default_area';

  bool get onboardingComplete => _prefs.getBool(_kOnboarding) ?? false;

  String get displayName => _prefs.getString(_kDisplayName) ?? '';

  String get travelStyle => _prefs.getString(_kTravelStyle) ?? 'walk';

  /// City / region used to ground Places searches (any destination).
  String get defaultArea => _prefs.getString(_kDefaultArea) ?? '';

  Future<void> completeOnboarding({
    required String displayName,
    required String travelStyle,
    required String defaultArea,
  }) async {
    await _prefs.setString(_kDisplayName, displayName.trim());
    await _prefs.setString(_kTravelStyle, travelStyle);
    await _prefs.setString(_kDefaultArea, defaultArea.trim());
    await _prefs.setBool(_kOnboarding, true);
  }

  Future<void> setDefaultArea(String area) async {
    await _prefs.setString(_kDefaultArea, area.trim());
  }

  Future<void> resetOnboarding() async {
    await _prefs.remove(_kOnboarding);
    await _prefs.remove(_kDisplayName);
    await _prefs.remove(_kTravelStyle);
    await _prefs.remove(_kDefaultArea);
  }
}
