import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Runtime Feature Flags & Kill-Switches (Stage P0 / Sprint 4).
/// Allows instant disabling of experimental or Beta features without a store release.
class FeatureFlags extends ChangeNotifier {
  static const String kPrefix = 'feature_flag_';

  bool enableTimedExplorationPopup;
  bool enableVoiceAssistantBanner;
  bool enableParentFeedbackForm;
  bool enableAchievementsCenter;
  bool enableExperimentalAdaptiveHints;
  bool disableCompanionShop;

  FeatureFlags({
    this.enableTimedExplorationPopup = true,
    this.enableVoiceAssistantBanner = true,
    this.enableParentFeedbackForm = true,
    this.enableAchievementsCenter = true,
    this.enableExperimentalAdaptiveHints = true,
    this.disableCompanionShop = false,
  });

  void loadFromPrefs(SharedPreferences prefs) {
    enableTimedExplorationPopup =
        prefs.getBool('${kPrefix}timed_popup') ?? true;
    enableVoiceAssistantBanner =
        prefs.getBool('${kPrefix}voice_banner') ?? true;
    enableParentFeedbackForm =
        prefs.getBool('${kPrefix}parent_feedback') ?? true;
    enableAchievementsCenter =
        prefs.getBool('${kPrefix}achievements_center') ?? true;
    enableExperimentalAdaptiveHints =
        prefs.getBool('${kPrefix}adaptive_hints') ?? true;
    disableCompanionShop =
        prefs.getBool('${kPrefix}disable_companion_shop') ?? false;
  }

  Future<void> setFlag(
    String key,
    bool value, {
    SharedPreferences? prefs,
  }) async {
    switch (key) {
      case 'timed_popup':
        enableTimedExplorationPopup = value;
        break;
      case 'voice_banner':
        enableVoiceAssistantBanner = value;
        break;
      case 'parent_feedback':
        enableParentFeedbackForm = value;
        break;
      case 'achievements_center':
        enableAchievementsCenter = value;
        break;
      case 'adaptive_hints':
        enableExperimentalAdaptiveHints = value;
        break;
      case 'disable_companion_shop':
        disableCompanionShop = value;
        break;
      default:
        return;
    }
    if (prefs != null) {
      await prefs.setBool('$kPrefix$key', value);
    }
    notifyListeners();
  }

  /// Syncs remote feature flags from Supabase Cloud based on build version and environment.
  Future<void> syncRemoteFlags({
    required String supabaseUrl,
    required String anonKey,
    required String appVersion,
    required String environment,
    SharedPreferences? prefs,
  }) async {
    if (supabaseUrl.trim().isEmpty) return;
    try {
      final Uri uri = Uri.parse('$supabaseUrl/rest/v1/remote_feature_flags?environment=eq.$environment&select=*');
      final http.Client client = http.Client();
      try {
        final res = await client.get(
          uri,
          headers: {
            'apikey': anonKey,
            'Accept': 'application/json',
          },
        ).timeout(const Duration(seconds: 5));

        if (res.statusCode == 200) {
          final dynamic data = jsonDecode(res.body);
          if (data is List && data.isNotEmpty) {
            for (final item in data) {
              if (item is Map) {
                final String flagKey = item['flag_key']?.toString() ?? '';
                final bool isEnabled = item['is_enabled'] == true;
                if (flagKey.isNotEmpty) {
                  await setFlag(flagKey, isEnabled, prefs: prefs);
                }
              }
            }
          }
        }
      } finally {
        client.close();
      }
    } catch (_) {
      // Gracefully retain local flags if offline
    }
  }
}
