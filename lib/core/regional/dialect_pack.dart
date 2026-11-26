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

  static String t(String key, String fallback, {DialectId? dialect}) {
    final d = dialect ?? active;
    return _packs[d]?[key] ??
        _packs[DialectId.egyptian]?[key] ??
        fallback;
  }

  static bool hasKey(DialectId d, String key) => _packs[d]?.containsKey(key) ?? false;
}
