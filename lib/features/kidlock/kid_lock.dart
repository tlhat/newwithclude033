import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Child lock status from the phone.
class KidLockStatus {
  final bool pinned;
  final bool deviceOwner;
  final bool defaultHome;
  final bool homeAlias;
  final bool watchdog;
  final int sdk;
  const KidLockStatus({
    this.pinned = false,
    this.deviceOwner = false,
    this.defaultHome = false,
    this.homeAlias = false,
    this.watchdog = false,
    this.sdk = 0,
  });

  factory KidLockStatus.fromMap(Map<dynamic, dynamic>? m) {
    if (m == null) return const KidLockStatus();
    return KidLockStatus(
      pinned: m['pinned'] == true,
      deviceOwner: m['deviceOwner'] == true,
      defaultHome: m['defaultHome'] == true,
      homeAlias: m['homeAlias'] == true,
      watchdog: m['watchdog'] == true,
      sdk: (m['sdk'] as num?)?.toInt() ?? 0,
    );
  }

  /// The honest strength of the lock right now, in Arabic.
  String get strengthLabel {
    if (deviceOwner) return 'قفل كامل (جهاز مخصص)';
    if (pinned && defaultHome) return 'قفل قوي (تثبيت الشاشة + شاشة رئيسية حنين)';
    if (pinned) return 'قفل متوسط (تثبيت الشاشة)';
    if (defaultHome) return 'قفل خفيف (شاشة رئيسية حنين)';
    return 'غير مفعّل';
  }
}

/// Talks to the native child lock. Nothing leaves the phone.
/// The lock is turned off only from the parent area after the parent PIN.
class KidLock {
  static const MethodChannel _ch = MethodChannel('haneen/kidlock');
  static const String _prefKey = 'kid_lock_on';
  static const String _prefWatchdog = 'kid_lock_watchdog';

  /// True while the lock is on. The shell uses it to block the Back button.
  static final ValueNotifier<bool> on = ValueNotifier<bool>(false);

  static bool get supported => !kIsWeb && Platform.isAndroid;

  static Future<KidLockStatus> status() async {
    if (!supported) return const KidLockStatus();
    try {
      return KidLockStatus.fromMap(await _ch.invokeMethod<Map<dynamic, dynamic>>('status'));
    } catch (_) {
      return const KidLockStatus();
    }
  }

  /// Reads the saved choice at app start and re-applies the lock.
  static Future<void> restore() async {
    final SharedPreferences sp = await SharedPreferences.getInstance();
    on.value = sp.getBool(_prefKey) ?? false;
    if (on.value) {
      await _call('enter', {'watchdog': sp.getBool(_prefWatchdog) ?? true});
    }
  }

  static Future<KidLockStatus> enable({bool watchdog = true}) async {
    final SharedPreferences sp = await SharedPreferences.getInstance();
    await sp.setBool(_prefKey, true);
    await sp.setBool(_prefWatchdog, watchdog);
    on.value = true;
    return _call('enter', {'watchdog': watchdog});
  }

  /// The caller must have checked the parent PIN first.
  static Future<KidLockStatus> disable() async {
    final SharedPreferences sp = await SharedPreferences.getInstance();
    await sp.setBool(_prefKey, false);
    on.value = false;
    return _call('exit', null);
  }

  static Future<KidLockStatus> setWatchdog(bool v) async {
    final SharedPreferences sp = await SharedPreferences.getInstance();
    await sp.setBool(_prefWatchdog, v);
    return _call('setWatchdog', {'on': v});
  }

  static Future<KidLockStatus> setHomeAlias(bool v) => _call('setHomeAlias', {'on': v});
  static Future<KidLockStatus> openHomeSettings() => _call('openHomeSettings', null);

  /// The caller must have checked the parent PIN first.
  static Future<KidLockStatus> releaseDeviceOwner() async {
    final SharedPreferences sp = await SharedPreferences.getInstance();
    await sp.setBool(_prefKey, false);
    on.value = false;
    return _call('releaseDeviceOwner', null);
  }

  static Future<KidLockStatus> _call(String m, Map<String, Object?>? args) async {
    if (!supported) return const KidLockStatus();
    try {
      return KidLockStatus.fromMap(await _ch.invokeMethod<Map<dynamic, dynamic>>(m, args));
    } catch (_) {
      return const KidLockStatus();
    }
  }
}
