import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Asks for the Google Play rating once, after the app has been used for a few
/// days. It is shown right after the parent unlocked with the PIN.
/// Google decides if the window really appears. It only works when the app is
/// installed from Google Play, so on an APK from GitHub nothing is shown.
class AppRatingService {
  AppRatingService._();
  static final AppRatingService instance = AppRatingService._();

  static const int kMinDaysOfUse = 3;
  static const int kMinOpens = 5;

  Future<void> maybeAsk() async {
    if (kIsWeb) return;
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      if (p.getBool('rating_asked') ?? false) return;
      final int now = DateTime.now().millisecondsSinceEpoch;
      final int first = p.getInt('rating_first_use_ms') ?? now;
      if (p.getInt('rating_first_use_ms') == null) {
        await p.setInt('rating_first_use_ms', now);
      }
      final int opens = (p.getInt('rating_opens') ?? 0) + 1;
      await p.setInt('rating_opens', opens);
      final int days = (now - first) ~/ Duration.millisecondsPerDay;
      if (days < kMinDaysOfUse || opens < kMinOpens) return;
      final InAppReview review = InAppReview.instance;
      if (await review.isAvailable()) {
        await p.setBool('rating_asked', true);
        await review.requestReview();
      }
    } catch (_) {}
  }
}
