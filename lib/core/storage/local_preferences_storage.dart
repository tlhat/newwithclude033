import 'package:shared_preferences/shared_preferences.dart';

class LocalPreferencesStorage {
  final SharedPreferences prefs;
  const LocalPreferencesStorage(this.prefs);

  String? getString(String key) => prefs.getString(key);
  Future<bool> setString(String key, String value) => prefs.setString(key, value);
  bool? getBool(String key) => prefs.getBool(key);
  Future<bool> setBool(String key, bool value) => prefs.setBool(key, value);
  bool containsKey(String key) => prefs.containsKey(key);
  Future<bool> remove(String key) => prefs.remove(key);
}
