import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Developmental-support layer. Pure logic plus local storage on this phone.
/// It describes practice in the app only. It never diagnoses, never gives an
/// IQ or "brain age", and never compares children. See docs/EVIDENCE.md.

enum AgeBand { m12to36, y3to5, y6to8, y9to12 }

extension AgeBandX on AgeBand {
  String get label {
    switch (this) {
      case AgeBand.m12to36:
        return '١٢ شهرًا – ٣ سنوات';
      case AgeBand.y3to5:
        return '٣ – ٥ سنوات';
      case AgeBand.y6to8:
        return '٦ – ٨ سنوات';
      case AgeBand.y9to12:
        return '٩ – ١٢ سنة';
    }
  }

  /// The daily limit is OFF by default for every band (0 = no cap).
  /// A parent may set one; the app never blocks a game on its own.
  int get defaultCapMinutes {
    switch (this) {
      default:
        return 0;
    }
  }
}

AgeBand bandFromAgeString(String age) {
  final Iterable<RegExpMatch> m = RegExp(r'\d+').allMatches(age);
  if (m.isEmpty) return AgeBand.y3to5;
  final int first = int.parse(m.first.group(0)!);
  if (first <= 2) return AgeBand.m12to36;
  if (first <= 5) return AgeBand.y3to5;
  if (first <= 8) return AgeBand.y6to8;
  return AgeBand.y9to12;
}

enum SkillArea { cognition, language, social, executive, independence, creative, motor }

extension SkillAreaX on SkillArea {
  String get label {
    switch (this) {
      case SkillArea.cognition:
        return 'التفكير والإدراك';
      case SkillArea.language:
        return 'اللغة والتواصل';
      case SkillArea.social:
        return 'المهارات الاجتماعية والانفعالية';
      case SkillArea.executive:
        return 'الوظائف التنفيذية (انتباه ومرونة وضبط اندفاع)';
      case SkillArea.independence:
        return 'الاستقلالية (روتين وتعليمات وقرارات)';
      case SkillArea.creative:
        return 'الإبداع والخيال';
      case SkillArea.motor:
        return 'المهارات الحركية';
    }
  }
}

enum EvidenceStrength { strong, moderate, weak, unverified }

class EvidenceBadge {
  final List<String> sources;
  final EvidenceStrength strength;
  final String limit;
  const EvidenceBadge(this.sources, this.strength, this.limit);

  String get strengthLabel {
    switch (strength) {
      case EvidenceStrength.strong:
        return 'دليل قوي';
      case EvidenceStrength.moderate:
        return 'دليل متوسط';
      case EvidenceStrength.weak:
        return 'دليل ضعيف';
      case EvidenceStrength.unverified:
        return 'تصميم داخلي غير مُثبت علميًا (لعب)';
    }
  }
}

/// One badge per area, from docs/EVIDENCE.md section 2.
const Map<SkillArea, EvidenceBadge> kAreaEvidence = {
  SkillArea.cognition: EvidenceBadge(['S9', 'S10'], EvidenceStrength.moderate,
      'التحسن في التمرين لا يعني بالضرورة تحسنًا في التفكير العام (S6, S7).'),
  SkillArea.language: EvidenceBadge(['S11', 'S3'], EvidenceStrength.moderate,
      'أثر القراءة الحوارية مع الأهل مثبت، لا دراسة عربية في ما فُحص، والتطبيق لا يعلّم الكلام لوحده.'),
  SkillArea.social: EvidenceBadge(['S12'], EvidenceStrength.strong,
      'الدليل من برامج مدرسية يقودها معلمون، وانتقال أثر التطبيق للسلوك غير مثبت.'),
  SkillArea.executive: EvidenceBadge(['S4', 'S5'], EvidenceStrength.moderate,
      'التدرج والتكرار مفيدان، لكن "تدريب الدماغ" لا يرفع الذكاء العام (S6, S7).'),
  SkillArea.independence: EvidenceBadge(['S4'], EvidenceStrength.weak,
      'الروتين اليومي في التطبيق تدريب على الفهم فقط، والاستقلالية الحقيقية تُبنى في البيت (تصميم غير مُثبت).'),
  SkillArea.creative: EvidenceBadge([], EvidenceStrength.unverified,
      'لم نفتح دراسة عن أنشطة الإبداع الرقمية. تُعرض كلعب حر.'),
  SkillArea.motor: EvidenceBadge([], EvidenceStrength.unverified,
      'لم نفتح دراسة عن الحركة باللمس. الحركة الحقيقية (لعب خارجي) أهم (S2).'),
};

const Map<String, SkillArea> _areas = {
  // language
  'letters': SkillArea.language, 'missing_letter': SkillArea.language,
  'build_word': SkillArea.language, 'same_start': SkillArea.language,
  'same_end': SkillArea.language, 'pic_word': SkillArea.language,
  'scrambled': SkillArea.language, 'harakat': SkillArea.language,
  'rhyme': SkillArea.language, 'first_letter': SkillArea.language,
  'vocabulary': SkillArea.language, 'fill_blank': SkillArea.language,
  'animal_sounds': SkillArea.language, 'story_order': SkillArea.language,
  // social
  'right_wrong': SkillArea.social, 'emotions': SkillArea.social,
  'emotions_choice': SkillArea.social, 'please_thanks': SkillArea.social,
  'sharing': SkillArea.social, 'road_safety': SkillArea.social,
  // executive (routines and planning)
  'daily_routine': SkillArea.independence, 'day_routine': SkillArea.independence,
  'tidy_room': SkillArea.independence, 'teeth': SkillArea.independence,
  'wash_hands': SkillArea.independence, 'plant_care': SkillArea.independence,
  // widget games
  'stop_go': SkillArea.executive, 'rule_switch': SkillArea.executive,
  'slide_puzzle': SkillArea.executive, 'letter_catcher': SkillArea.language,
  'maze': SkillArea.motor, 'draw_imagine': SkillArea.creative,
};

SkillArea areaOf(String skill) => _areas[skill] ?? SkillArea.cognition;

const Set<String> _early = {
  'animals', 'animal_sounds', 'colors', 'shapes', 'vocabulary', 'body_parts',
  'classify', 'emotions', 'odd_one', 'animal_home', 'fruit_veg', 'pic_word',
};
const Set<String> _advanced = {
  'addition', 'subtraction', 'money', 'build_word', 'scrambled', 'harakat',
  'fill_blank', 'bar_chart', 'grid_points', 'multi_select', 'number_line',
  'even_odd', 'length', 'story_order', 'hidden_shapes', 'mirror', 'size_order',
  'rhyme', 'subtract_apples', 'add_pics', 'before_after', 'missing_number',
};

/// Band assignment is a design choice (UNVERIFIED), shown as such.
List<AgeBand> bandsOf(String skill) {
  if (_early.contains(skill)) return [AgeBand.m12to36, AgeBand.y3to5];
  if (_advanced.contains(skill)) return [AgeBand.y6to8, AgeBand.y9to12];
  return [AgeBand.y3to5, AgeBand.y6to8, AgeBand.y9to12];
}

/// Activity metadata shown to the parent.
class ActivityMeta {
  final String skill;
  final SkillArea area;
  final List<AgeBand> bands;
  final String goal;
  final String assessment;
  final String hints;
  final EvidenceBadge evidence;
  const ActivityMeta(this.skill, this.area, this.bands, this.goal,
      this.assessment, this.hints, this.evidence);
}

ActivityMeta metaFor(String skill, String title, {int level = 1}) {
  final SkillArea a = areaOf(skill);
  return ActivityMeta(
    skill,
    a,
    bandsOf(skill),
    'هدف: تدريب «$title» (المستوى $level من ٣)',
    'التقييم: نسبة الإجابات الصحيحة من أول محاولة، على أيام مختلفة',
    'التلميحات: تزيد مع كل خطأ، ولا تخصم شيئًا',
    kAreaEvidence[a]!,
  );
}

enum Stage { fresh, learning, confident, solid }

extension StageX on Stage {
  String get label {
    switch (this) {
      case Stage.fresh:
        return '🌱 جديدة';
      case Stage.learning:
        return '🌿 يتعلّم';
      case Stage.confident:
        return '⭐ واثق';
      case Stage.solid:
        return '🏆 راسخ';
    }
  }
}

class SkillState {
  final Stage stage;
  final int confidence; // 0 low, 1 medium, 2 high
  final int attempts;
  final int goodDays;
  const SkillState(this.stage, this.confidence, this.attempts, this.goodDays);
  String get confidenceLabel => const ['ثقة منخفضة', 'ثقة متوسطة', 'ثقة عالية'][confidence];
}

String dayKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Stages are design choices (UNVERIFIED), inspired by spaced practice (S8, S9):
/// fresh < 5 answers; confident = 70% or more right on 2 separate days
/// (3 answers or more each day); solid = confident, plus a passed independent
/// check, plus a good day at least 3 days after the first good day.
SkillState computeState(Map<String, List<int>> days, List<Map<String, dynamic>> transfer) {
  int attempts = 0;
  final List<String> good = [];
  days.forEach((d, v) {
    attempts += v[1];
    if (v[1] >= 3 && v[0] * 100 >= v[1] * 70) good.add(d);
  });
  good.sort();
  Stage st;
  if (attempts < 5) {
    st = Stage.fresh;
  } else if (good.length >= 2) {
    st = Stage.confident;
    final DateTime a = DateTime.parse(good.first);
    final DateTime b = DateTime.parse(good.last);
    final bool spaced = b.difference(a).inDays >= 3;
    final bool passed = transfer.any((t) =>
        t['pass'] == true && '${t['d']}'.compareTo(good.first) >= 0);
    if (spaced && passed) st = Stage.solid;
  } else {
    st = Stage.learning;
  }
  int conf = 0;
  if (attempts >= 15 && good.length >= 3) {
    conf = 2;
  } else if (attempts >= 8 && good.length >= 2) {
    conf = 1;
  }
  return SkillState(st, conf, attempts, good.length);
}

/// Picks [n] items for an independent check: items not answered before first.
List<T> pickTransfer<T>(List<T> bank, String Function(T) idOf, Set<String> seen, int n) {
  final List<T> fresh = bank.where((e) => !seen.contains(idOf(e))).toList();
  final List<T> rest = bank.where((e) => seen.contains(idOf(e))).toList();
  return [...fresh, ...rest].take(n).toList();
}

enum GateState { ok, offByDefault, timeUp }

/// No game is locked by age band or co-use. Only an optional parent-set
/// minutes cap (default off) can end play for the day.
GateState gateState(AgeBand band, bool coUse, int capMinutes, int usedToday) {
  if (capMinutes > 0 && usedToday >= capMinutes) return GateState.timeUp;
  return GateState.ok;
}

/// Real-world activities per band and area (docs/EVIDENCE.md section 3).
const Map<AgeBand, Map<SkillArea, List<String>>> kRealWorld = {
  AgeBand.m12to36: {
    SkillArea.language: ['سمّوا الأشياء في البيت وقولوا اسم كل شيء', 'اقرأوا كتاب صور واسألوه: ما هذا؟'],
    SkillArea.cognition: ['فرزوا الغسيل أو الملاعق أو الألعاب مع بعض'],
    SkillArea.social: ['سمّوا المشاعر خلال اليوم: شكلك فرحان'],
    SkillArea.executive: ['ألعاب الدور وأغاني قف وامش'],
    SkillArea.independence: ['نفّذوا تعليمة من خطوتين: هات الكورة وحطها هنا'],
    SkillArea.creative: ['العبوا بالكوبايات والصناديق وتخيلوا إنها بيت'],
    SkillArea.motor: ['تركيب المكعبات والخربشة والجري والتسلق'],
  },
  AgeBand.y3to5: {
    SkillArea.language: ['قراءة حوارية: اسأل، استمع، ووسّع كلامه'],
    SkillArea.cognition: ['عدّوا درجات السلم وابحثوا عن أنماط في الشارع'],
    SkillArea.social: ['تحدثوا عن موقف حصل فعلًا: ماذا كنت ستفعل؟'],
    SkillArea.executive: ['لعبة سيمون يقول، وروتين ترتيب الألعاب'],
    SkillArea.independence: ['اتركه يختار ملابسه ويرتب شنطته بنفسه'],
    SkillArea.creative: ['ارسموا مع بعض واحكوا حكاية الرسمة'],
    SkillArea.motor: ['رسم وصلصال ولعب بالكرة'],
  },
  AgeBand.y6to8: {
    SkillArea.language: ['اقرأوا معًا ثم يحكي هو القصة بصوته'],
    SkillArea.cognition: ['تسوّق بالفلوس وقياسات الطبخ'],
    SkillArea.social: ['حديث عائلي عن حل خلاف'],
    SkillArea.executive: ['خطّط لمهمة نهاية الأسبوع وقائمة روتين'],
    SkillArea.independence: ['اتركه يخطط ترتيب واجبه ويتخذ قرارًا بسيطًا'],
    SkillArea.creative: ['ابنوا شيئًا من علب فاضية وفكروا في أكتر من حل'],
    SkillArea.motor: ['رياضة ورسم وكتابة باليد'],
  },
  AgeBand.y9to12: {
    SkillArea.language: ['حديث عن كتاب وكتابة فقرة قصيرة'],
    SkillArea.cognition: ['ميزانية رحلة وألغاز عائلية'],
    SkillArea.social: ['حديث عن المشاعر والأصدقاء'],
    SkillArea.executive: ['مخطط للواجبات وهدف أسبوعي يراجعه معك'],
    SkillArea.independence: ['مهمة مسؤولية أسبوعية يديرها بنفسه'],
    SkillArea.creative: ['مشروع صغير: اختراع أو قصة أو مجسم من مواد البيت'],
    SkillArea.motor: ['رياضة وأشغال يدوية ولعب خارجي'],
  },
};

String realWorldFor(AgeBand b, SkillArea a, DateTime now) {
  final List<String> l = kRealWorld[b]![a]!;
  final int week = now.difference(DateTime(2026, 1, 1)).inDays ~/ 7;
  return l[week % l.length];
}

String weekKey(DateTime now) => 'w${now.difference(DateTime(2026, 1, 1)).inDays ~/ 7}';

/// Short, non-blocking parent note. Sources S1 and S2 in docs/EVIDENCE.md.
const String kWhoNote =
    'معلومة للوالد (WHO، المصدر S1 وS2): منظمة الصحة العالمية لا توصي بوقت شاشة جالس لعمر السنة، '
    'وبحد أقصى ساعة لعمر ٢ إلى ٤ سنوات، والأقل أفضل. هذا مجرد إرشاد ولا يمنع التطبيق أي لعبة.';

const String kNoDiagnosisLine =
    'هذا التطبيق للتدريب واللعب فقط، ولا يشخّص ولا يقيس ذكاء. إذا كنت قلقًا على نمو طفلك، تحدث مع طبيب أو أخصائي.';

/// All developmental data for one child. Stored on this phone only.
class DevData {
  AgeBand? bandOverride;
  bool coUse = false; // kept for old saves; no longer gates anything
  int capOverride = -1; // -1 = band default
  final Map<String, Map<String, List<int>>> days = {}; // skill -> date -> [right,total]
  final Map<String, List<Map<String, dynamic>>> transfer = {}; // skill -> [{d,pass}]
  final Set<String> seen = {};
  final Map<String, int> usedByDay = {}; // minutes in games per day
  final Map<String, bool> actDone = {}; // "week|area" -> done
  final List<Map<String, String>> notes = []; // {d, area, t}

  AgeBand bandFor(String ageString) => bandOverride ?? bandFromAgeString(ageString);
  int capFor(AgeBand b) => capOverride >= 0 ? capOverride : b.defaultCapMinutes;

  void logAttempt(String skill, String exId, bool ok, DateTime now) {
    final Map<String, List<int>> d = days.putIfAbsent(skill, () => {});
    final List<int> v = d.putIfAbsent(dayKey(now), () => [0, 0, 0]);
    while (v.length < 3) {
      v.add(0);
    }
    v[1]++;
    if (ok) v[0]++;
    seen.add(exId);
  }

  /// A wrong try after the first one (the child kept trying with hints).
  void logExtraTry(String skill, DateTime now) {
    final Map<String, List<int>> d = days.putIfAbsent(skill, () => {});
    final List<int> v = d.putIfAbsent(dayKey(now), () => [0, 0, 0]);
    while (v.length < 3) {
      v.add(0);
    }
    v[2]++;
  }

  /// Accuracy per day, oldest first, last [n] days with answers.
  List<int> trend(String skill, {int n = 5}) {
    final List<String> ks = (days[skill] ?? {}).keys.toList()..sort();
    return ks.reversed.take(n).toList().reversed.map((k) {
      final List<int> v = days[skill]![k]!;
      return v[1] == 0 ? 0 : (v[0] * 100 / v[1]).round();
    }).toList();
  }

  int extraTries(String skill) =>
      (days[skill] ?? {}).values.fold(0, (a, v) => a + (v.length > 2 ? v[2] : 0));

  void logTransfer(String skill, bool pass, DateTime now) {
    transfer.putIfAbsent(skill, () => []).add({'d': dayKey(now), 'pass': pass});
  }

  SkillState stateOf(String skill) =>
      computeState(days[skill] ?? {}, transfer[skill] ?? []);

  Map<String, dynamic> toJson() => {
        'band': bandOverride?.index,
        'coUse': coUse,
        'cap': capOverride,
        'days': days,
        'transfer': transfer,
        'seen': seen.toList(),
        'used': usedByDay,
        'act': actDone,
        'notes': notes,
      };

  static DevData fromJson(Map<String, dynamic> j) {
    final DevData d = DevData();
    if (j['band'] is int) d.bandOverride = AgeBand.values[(j['band'] as int).clamp(0, 3)];
    d.coUse = j['coUse'] == true;
    d.capOverride = (j['cap'] as num?)?.toInt() ?? -1;
    ((j['days'] as Map?) ?? {}).forEach((k, v) {
      final Map<String, List<int>> m = {};
      (v as Map).forEach((a, b) => m['$a'] = (b as List).map((x) => (x as num).toInt()).toList());
      d.days['$k'] = m;
    });
    ((j['transfer'] as Map?) ?? {}).forEach((k, v) {
      d.transfer['$k'] = (v as List).map((x) => Map<String, dynamic>.from(x as Map)).toList();
    });
    d.seen.addAll(((j['seen'] as List?) ?? []).map((x) => '$x'));
    ((j['used'] as Map?) ?? {}).forEach((k, v) => d.usedByDay['$k'] = (v as num).toInt());
    ((j['act'] as Map?) ?? {}).forEach((k, v) => d.actDone['$k'] = v == true);
    for (final x in ((j['notes'] as List?) ?? [])) {
      d.notes.add(Map<String, String>.from((x as Map).map((a, b) => MapEntry('$a', '$b'))));
    }
    return d;
  }
}

class DevStore {
  static String _key(String childId) => 'dev_state_$childId';

  static Future<DevData> load(String childId) async {
    final SharedPreferences sp = await SharedPreferences.getInstance();
    try {
      return DevData.fromJson(jsonDecode(sp.getString(_key(childId)) ?? '{}') as Map<String, dynamic>);
    } catch (_) {
      return DevData();
    }
  }

  static Future<void> save(String childId, DevData d) async {
    final SharedPreferences sp = await SharedPreferences.getInstance();
    await sp.setString(_key(childId), jsonEncode(d.toJson()));
  }

  static Future<void> logExtra(String childId, String skill) async {
    if (childId.isEmpty) return;
    try {
      final DevData d = await load(childId);
      d.logExtraTry(skill, DateTime.now());
      await save(childId, d);
    } catch (_) {}
  }

  static Future<void> logAttempt(String childId, String skill, String exId, bool ok) async {
    if (childId.isEmpty) return;
    try {
      final DevData d = await load(childId);
      d.logAttempt(skill, exId, ok, DateTime.now());
      await save(childId, d);
    } catch (_) {}
  }
}
