import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// What is free and what needs a subscription.
///
/// There is NO billing here. [subscribed] is a local stub: it is false for
/// everyone until a real purchase flow is wired (needs the owner's explicit
/// OK). A parent-corner switch can flip it on the phone to test the
/// unlocked view. Nothing is sent anywhere.
class Entitlements {
  /// Academy: tier 1 (تمهيدي) lessons are free, higher tiers are paid.
  static const int freeAcademyMaxTier = 1;

  /// Interactive stories: the first N are free.
  static const int freeStoryCount = 3;

  /// Brain games: the first N entries of the hub are free.
  static const int freeGameCount = 5;

  static const String _kKey = 'entitlement_stub_subscribed';

  static final ValueNotifier<bool> subscribed = ValueNotifier<bool>(false);

  static Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    subscribed.value = p.getBool(_kKey) ?? false;
  }

  static Future<void> setStubSubscribed(bool v) async {
    subscribed.value = v;
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kKey, v);
  }

  static bool academyLessonLocked(int tierLevel) =>
      !subscribed.value && tierLevel > freeAcademyMaxTier;

  static bool storyLocked(int index) =>
      !subscribed.value && index >= freeStoryCount;

  static bool gameLocked(int index) =>
      !subscribed.value && index >= freeGameCount;
}
