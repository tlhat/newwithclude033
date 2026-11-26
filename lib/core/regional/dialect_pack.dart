import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show AssetBundle;
import 'country_config.dart';

/// UI texts per dialect, looked up by key. A pack only lists what differs;
/// anything missing falls back to the Egyptian text, then to the default given
/// by the caller. A Gulf pack can be added later as one more map.
class DialectPacks {
  static const Map<DialectId, Map<String, String>> _packs = {
    DialectId.egyptian: {
      'path.badge': 'اضغط هنا، مخصص ليك',
      'path.title': 'مساري',
      'path.allDone': '🎉 خلصت خطة النهاردة! برافو يا بطل',
    },
    DialectId.msaSimple: {
      'path.badge': 'اضغط هنا، مخصص لك',
      'path.title': 'مساري',
      'path.allDone': '🎉 أنهيت خطة اليوم! أحسنت يا بطل',
    },
    DialectId.gulf: <String, String>{},
  };

  static DialectId active = DialectId.egyptian;

  /// UI listens to this so a dialect change rebuilds the screens.
  static final ValueNotifier<DialectId> notifier =
      ValueNotifier<DialectId>(DialectId.egyptian);

  static void setActive(DialectId d) {
    active = d;
    notifier.value = d;
  }

  /// Reads assets/dialects/<dialect>.json (flat string map). A missing or
  /// broken file is skipped: that dialect then falls back to Egyptian.
  static Future<void> loadAssets(AssetBundle bundle) async {
    for (final d in DialectId.values) {
      try {
        final raw = await bundle.loadString('assets/dialects/${d.key}.json');
        final m = json.decode(raw) as Map<String, dynamic>;
        loaded[d] = {
          for (final e in m.entries)
            if (e.value is String && !e.key.startsWith('_'))
              e.key: e.value as String
        };
      } catch (_) {}
    }
  }

  static String t(String key, String fallback, {DialectId? dialect}) {
    final d = dialect ?? active;
    return _packs[d]?[key] ??
        _packs[DialectId.egyptian]?[key] ??
        fallback;
  }

  /// Loaded packs: dialect -> (Egyptian source text or key -> dialect text).
  static final Map<DialectId, Map<String, String>> loaded = {};

  static final RegExp _digits = RegExp(r'[0-9٠-٩]+');

  /// Translates visible text. Egyptian is the source language: its text is
  /// returned unchanged. Other dialects look the exact text up in their pack,
  /// then a number-template ("المرحلة {#} من {#}"), then fall back to the
  /// Egyptian text. Only text that is really in a pack changes.
  static String tr(String text, {DialectId? dialect}) {
    final d = dialect ?? active;
    if (d == DialectId.egyptian || text.isEmpty) return text;
    final pack = loaded[d];
    if (pack == null || pack.isEmpty) return text;
    final exact = pack[text];
    if (exact != null) return exact;
    if (_digits.hasMatch(text)) {
      final nums = _digits.allMatches(text).map((x) => x.group(0)!).toList();
      final tmpl = text.replaceAll(_digits, '{#}');
      final hit = pack[tmpl];
      if (hit != null) {
        var i = 0;
        return hit.replaceAllMapped(RegExp(r'\{#\}'),
            (_) => i < nums.length ? nums[i++] : '');
      }
    }
    return text;
  }

  static bool hasKey(DialectId d, String key) => _packs[d]?.containsKey(key) ?? false;
}
