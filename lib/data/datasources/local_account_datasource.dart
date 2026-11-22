import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:haneen_kids_vod/haneen_kids_exports.dart';

class LocalAccountDataSource {
  static const String kAccountsStorageKey = 'registered_accounts_v2';
  static const String kCurrentUserKey = 'current_user_key';
  static const String kHasSelectedChildKey = 'has_selected_child_in_session';
  static const String kOnboardingCompletedKey = 'onboarding_completed';

  final SharedPreferences _prefs;
  final String prefix;

  const LocalAccountDataSource(this._prefs, {this.prefix = ''});

  String get accountsKey => '$prefix$kAccountsStorageKey';
  String get currentUserKey => '$prefix$kCurrentUserKey';
  String get hasSelectedChildKey => '$prefix$kHasSelectedChildKey';
  String get onboardingCompletedKey => '$prefix$kOnboardingCompletedKey';

  Map<String, ParentAccount> loadRegisteredAccounts() {
    final Map<String, ParentAccount> result = {};
    String? accountsJson = _prefs.getString(accountsKey);
    if (accountsJson == null || accountsJson.isEmpty) {
      accountsJson = _prefs.getString(kAccountsStorageKey);
    }
    if (accountsJson != null && accountsJson.isNotEmpty) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(accountsJson);
        decoded.forEach((key, value) {
          result[key] =
              ParentAccount.fromJson(Map<String, dynamic>.from(value as Map));
        });
      } catch (_) {}
    }
    return result;
  }

  Future<void> saveRegisteredAccounts(
      Map<String, ParentAccount> accounts) async {
    final Map<String, dynamic> data = {};
    accounts.forEach((key, acc) {
      data[key] = acc.toJson();
    });
    final String encoded = jsonEncode(data);
    await _prefs.setString(accountsKey, encoded);
    if (prefix.isNotEmpty) {
      await _prefs.setString(kAccountsStorageKey, encoded);
    }
  }

  String? getLoggedInUserKey() => _prefs.getString(currentUserKey) ?? _prefs.getString(kCurrentUserKey);

  Future<void> setLoggedInUserKey(String? key) async {
    if (key == null || key.isEmpty) {
      await _prefs.remove(currentUserKey);
      await _prefs.remove(kCurrentUserKey);
    } else {
      await _prefs.setString(currentUserKey, key);
      await _prefs.setString(kCurrentUserKey, key);
    }
  }
}
