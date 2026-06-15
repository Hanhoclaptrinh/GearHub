import 'package:shared_preferences/shared_preferences.dart';

class PreferencesLocalDatasource {
  static const _seenPrefix = 'shopping_preferences_onboarding_seen';

  final SharedPreferences _sharedPreferences;

  PreferencesLocalDatasource({required SharedPreferences sharedPreferences})
    : _sharedPreferences = sharedPreferences;

  bool hasSeenOnboarding(String userId) {
    return _sharedPreferences.getBool(_key(userId)) ?? false;
  }

  Future<void> markOnboardingSeen(String userId) {
    return _sharedPreferences.setBool(_key(userId), true);
  }

  Future<void> clearOnboardingSeen(String userId) {
    return _sharedPreferences.remove(_key(userId));
  }

  String _key(String userId) => '${_seenPrefix}_$userId';
}
