import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages interface language independently from child learning language
/// (Stage P0 / Sprint 3: Separation of UI Locale vs Content Learning Locale).
class LocaleController extends ChangeNotifier {
  static const String kUiLanguagePrefKey = 'app_ui_language_code';
  static const String kLearningLanguagePrefKey = 'app_learning_language_code';
  static const String kVoiceLanguagePrefKey = 'app_voice_language_code';

  static const List<String> kSupportedLanguageCodes = ['ar']; // Arabic only

  String _uiLanguageCode = 'ar';
  String _learningLanguageCode = 'ar';
  String _voiceLanguageCode = 'ar';

  String get uiLanguageCode => _uiLanguageCode;
  String get learningLanguageCode => _learningLanguageCode;
  String get voiceLanguageCode => _voiceLanguageCode;

  Locale get uiLocale => Locale(_uiLanguageCode);
  Locale get learningLocale => Locale(_learningLanguageCode);
  Locale get voiceLocale => Locale(_voiceLanguageCode);

  TextDirection get uiTextDirection =>
      _uiLanguageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr;

  void loadFromPrefs(SharedPreferences prefs) {
    final String? savedUi = prefs.getString(kUiLanguagePrefKey);
    if (savedUi != null && kSupportedLanguageCodes.contains(savedUi)) {
      _uiLanguageCode = savedUi;
    }
    final String? savedLearning = prefs.getString(kLearningLanguagePrefKey);
    if (savedLearning != null &&
        kSupportedLanguageCodes.contains(savedLearning)) {
      _learningLanguageCode = savedLearning;
    }
    final String? savedVoice = prefs.getString(kVoiceLanguagePrefKey);
    if (savedVoice != null && kSupportedLanguageCodes.contains(savedVoice)) {
      _voiceLanguageCode = savedVoice;
    }
  }

  Future<void> setUiLanguage(
    String languageCode, {
    SharedPreferences? prefs,
  }) async {
    final String normalized = languageCode.trim().toLowerCase();
    if (!kSupportedLanguageCodes.contains(normalized)) return;
    _uiLanguageCode = normalized;
    if (prefs != null) {
      await prefs.setString(kUiLanguagePrefKey, normalized);
    }
    notifyListeners();
  }

  Future<void> setLearningLanguage(
    String languageCode, {
    SharedPreferences? prefs,
  }) async {
    final String normalized = languageCode.trim().toLowerCase();
    if (!kSupportedLanguageCodes.contains(normalized)) return;
    _learningLanguageCode = normalized;
    if (prefs != null) {
      await prefs.setString(kLearningLanguagePrefKey, normalized);
    }
    notifyListeners();
  }

  Future<void> setVoiceLanguage(
    String languageCode, {
    SharedPreferences? prefs,
  }) async {
    final String normalized = languageCode.trim().toLowerCase();
    if (!kSupportedLanguageCodes.contains(normalized)) return;
    _voiceLanguageCode = normalized;
    if (prefs != null) {
      await prefs.setString(kVoiceLanguagePrefKey, normalized);
    }
    notifyListeners();
  }
}
