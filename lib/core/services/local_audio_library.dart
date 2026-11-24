import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter/services.dart' show rootBundle;

/// Pre-generated offline voice clips bundled with the app.
///
/// Clips live in `assets/audio/<persona>/<feature>/<id>.mp3` and are listed in
/// `assets/audio/audio_index.json` (built by `tools/build_audio_index.py`).
/// The index maps a lookup key to the asset path:
///   key = first 12 hex chars of sha1("<personaId>|<normalizedText>")
///
/// If a clip is missing, callers fall back to the old ElevenLabs path.
class LocalAudioLibrary {
  static const String indexAsset = 'assets/audio/audio_index.json';

  static Map<String, String>? _index;
  static final Map<String, String> _extractedPaths = {};

  /// Test hook: replace the index without touching the asset bundle.
  static void setIndexForTesting(Map<String, String>? index) {
    _index = index;
    _extractedPaths.clear();
  }

  /// Same cleanup the speech pipeline applies, plus whitespace collapse.
  static String normalize(String text) {
    return text
        .replaceAll('«', '')
        .replaceAll('»', '')
        .replaceAll('"', '')
        .replaceAll('🎙️', '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static String keyFor(String personaId, String text) {
    final String canonical =
        '${personaId.trim().toLowerCase()}|${normalize(text)}';
    return crypto.sha1
        .convert(utf8.encode(canonical))
        .toString()
        .substring(0, 12);
  }

  static Future<Map<String, String>> _loadIndex() async {
    final Map<String, String>? cached = _index;
    if (cached != null) return cached;
    try {
      final String raw = await rootBundle.loadString(indexAsset);
      final Map<String, dynamic> decoded =
          jsonDecode(raw) as Map<String, dynamic>;
      _index = decoded.map((k, v) => MapEntry(k, v.toString()));
    } catch (_) {
      _index = <String, String>{};
    }
    return _index!;
  }

  /// Returns a playable local file path for [text] spoken by [personaId], or
  /// null when no bundled clip exists. [alternateTexts] are tried in order
  /// (for example the text with the child's name replaced by "بطل").
  static Future<String?> resolveToFile(
    String personaId,
    String text, {
    List<String> alternateTexts = const [],
  }) async {
    final Map<String, String> index = await _loadIndex();
    if (index.isEmpty) return null;
    for (final String candidate in [text, ...alternateTexts]) {
      final String key = keyFor(personaId, candidate);
      final String? asset = index[key];
      if (asset == null) continue;
      final String? path = await _extract(key, asset);
      if (path != null) return path;
    }
    return null;
  }

  static Future<String?> _extract(String key, String asset) async {
    final String? known = _extractedPaths[key];
    if (known != null && File(known).existsSync()) return known;
    try {
      final data = await rootBundle.load(asset);
      final Directory dir =
          Directory('${Directory.systemTemp.path}/haneen_local_audio');
      if (!dir.existsSync()) dir.createSync(recursive: true);
      final File f = File('${dir.path}/$key.mp3');
      if (!f.existsSync() || f.lengthSync() != data.lengthInBytes) {
        await f.writeAsBytes(
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
          flush: true,
        );
      }
      _extractedPaths[key] = f.path;
      return f.path;
    } catch (_) {
      return null;
    }
  }
}
