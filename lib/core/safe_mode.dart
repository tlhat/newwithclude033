import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show MethodChannel;

/// Crash-loop self-recovery. Everything stays on the phone.
///
/// The native side remembers "a risky moment started" ([risk]) and "it passed
/// without a crash" (a few calm seconds later). If the phone closed in between,
/// the next start runs one step lighter:
///   level 0: normal.
///   level 1: older Skia renderer instead of Impeller.
///   level 2: level 1 plus the spoken voice is off.
///   level 3: level 2 plus a much smaller picture cache.
/// Three calm runs in a row step the level down again, so nobody stays in a
/// lighter mode forever.
class SafeMode {
  static const MethodChannel _ch = MethodChannel('haneen/safemode');
  static int level = 0;
  static Timer? _t;

  static bool get _supported {
    if (kIsWeb) return false;
    try {
      return Platform.isAndroid && !Platform.environment.containsKey('FLUTTER_TEST');
    } catch (_) {
      return false;
    }
  }

  static bool get voiceOff => level >= 2;

  static Future<void> init() async {
    if (!_supported) return;
    try {
      level = (await _ch.invokeMethod<int>('level').timeout(const Duration(seconds: 2))) ?? 0;
    } catch (_) {
      level = 0;
    }
  }

  /// Call when something risky starts (first frame, opening a tab, first voice
  /// clip, finishing setup). If the app survives [calm] afterwards it is
  /// marked healthy.
  static void risk({Duration calm = const Duration(seconds: 6)}) {
    if (!_supported) return;
    try {
      if (_t == null) {
        _ch.invokeMethod<bool>('arm');
      }
      _t?.cancel();
      _t = Timer(calm, () {
        _t = null;
        try {
          _ch.invokeMethod<bool>('healthy');
        } catch (_) {}
      });
    } catch (_) {}
  }
}
