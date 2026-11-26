import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:video_player/video_player.dart';

/// Real recordings of animals (and a train horn): CC0, public domain, and two
/// CC BY-SA files (dog, cow) credited in the parent corner.
/// Files: assets/audio/real_sounds/<key>.ogg. Sources and credits are in
/// assets/audio/real_sounds/CREDITS.md and shown in the app's thanks page.
class RealSounds {
  /// Emoji (or Arabic word) to file key. Only sounds that really exist.
  static const Map<String, String> _byEmoji = {
    '🐱': 'cat', '🐈': 'cat', '🦁': 'lion', '🐯': 'lion',
    '🐦': 'bird', '🐤': 'bird', '🐥': 'bird', '🐝': 'bee',
    '🐑': 'sheep', '🐏': 'sheep', '🐓': 'rooster', '🐔': 'rooster',
    '🐴': 'horse', '🐎': 'horse', '🫏': 'donkey', '🐘': 'elephant',
    '🦆': 'duck', '🚂': 'train', '🚆': 'train',
    '🐶': 'dog', '🐕': 'dog', '🐮': 'cow', '🐄': 'cow',
  };

  static const Set<String> keys = {
    'cat', 'lion', 'bird', 'bee', 'sheep', 'rooster', 'horse', 'donkey',
    'elephant', 'duck', 'train', 'dog', 'cow',
  };

  /// Key for the first known emoji found in [text], or null.
  static String? keyFor(String text) {
    for (final entry in _byEmoji.entries) {
      if (text.contains(entry.key)) return entry.value;
    }
    return null;
  }

  static String assetFor(String key) => 'assets/audio/real_sounds/$key.ogg';

  static VideoPlayerController? _ctrl;

  /// Plays the recording and waits until it ends. Returns false when there is
  /// no recording for [text] (the caller then keeps the spoken description).
  static Future<bool> play(String text) async {
    final String? key = keyFor(text);
    if (key == null) return false;
    if (kIsWeb) return false;
    try {
      final data = await rootBundle.load(assetFor(key));
      final dir = Directory('${Directory.systemTemp.path}/haneen_real_sounds')
        ..createSync(recursive: true);
      final f = File('${dir.path}/$key.ogg');
      if (!f.existsSync() || f.lengthSync() != data.lengthInBytes) {
        await f.writeAsBytes(
            data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
            flush: true);
      }
      await stop();
      final c = VideoPlayerController.file(f,
          videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true));
      _ctrl = c;
      await c.initialize();
      final done = Completer<void>();
      void l() {
        final v = c.value;
        if (!done.isCompleted &&
            (v.isCompleted ||
                (v.duration > Duration.zero &&
                    v.position >=
                        v.duration - const Duration(milliseconds: 60)))) {
          done.complete();
        }
      }

      c.addListener(l);
      await c.setVolume(1.0);
      await c.play();
      await done.future.timeout(
          c.value.duration + const Duration(milliseconds: 500),
          onTimeout: () {});
      c.removeListener(l);
      if (_ctrl == c) {
        _ctrl = null;
        await c.dispose();
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> stop() async {
    final c = _ctrl;
    _ctrl = null;
    try {
      await c?.pause();
      await c?.dispose();
    } catch (_) {}
  }
}
