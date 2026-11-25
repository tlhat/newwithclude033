import 'dart:convert';

/// Exercise data comes from JSON (assets/exercises/*.json), not code.
/// Types: choice, number, ordering, matching, categorize, plus widget ideas
/// from Khan Academy's Perseus (MIT): numberline, blank (fill-in-the-blank
/// dropdown), multi (multiple answers), grid_point (interactive graph point),
/// bars (plotter), and an optional `explain` text (explanation widget).
class Exercise {
  final String id;
  final String type;
  final String prompt;
  final List<String> hints;
  final String correctFeedback;
  final String wrongFeedback;
  final Map<String, dynamic> data;
  final String skill;
  final int level;
  final String explain;
  const Exercise({
    this.explain = '',
    this.skill = 'general',
    this.level = 1,
    required this.id,
    required this.type,
    required this.prompt,
    required this.hints,
    required this.correctFeedback,
    required this.wrongFeedback,
    required this.data,
  });

  factory Exercise.fromJson(Map<String, dynamic> j) => Exercise(
        id: j['id'].toString(),
        type: j['type'].toString(),
        prompt: j['prompt'].toString(),
        hints: ((j['hints'] as List?) ?? const []).map((e) => '$e').toList(),
        correctFeedback: (j['correct'] ?? 'برافو!').toString(),
        wrongFeedback: (j['wrong'] ?? 'جرّب تاني.').toString(),
        data: Map<String, dynamic>.from(j['data'] as Map),
        skill: (j['skill'] ?? 'general').toString(),
        level: ((j['level'] as num?) ?? 1).toInt(),
        explain: (j['explain'] ?? '').toString(),
      );

  static List<Exercise> parseList(String raw) {
    final List l = jsonDecode(raw) as List;
    return l
        .map((e) => Exercise.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }
}

/// A learner's answer. Shape depends on type:
/// choice: int index; number: num/String; ordering: List<String> in order;
/// matching: Map<String,String> left->right; categorize: Map<String,String> item->bin.
class ExerciseGrader {
  static bool grade(Exercise e, Object? answer) {
    try {
      switch (e.type) {
        case 'choice':
        case 'blank':
          return answer == (e.data['correct'] as num).toInt();
        case 'numberline':
          final num? v = answer is num ? answer : num.tryParse('$answer');
          return v != null && v == (e.data['answer'] as num);
        case 'multi':
          final Set<int> want =
              (e.data['correct'] as List).map((x) => (x as num).toInt()).toSet();
          final Set<int> got = (answer as Iterable).map((x) => (x as num).toInt()).toSet();
          return want.length == got.length && want.containsAll(got);
        case 'grid_point':
          final List w = e.data['answer'] as List;
          final List g = answer as List;
          return g.length == 2 && g[0] == (w[0] as num).toInt() && g[1] == (w[1] as num).toInt();
        case 'bars':
          final List t = e.data['target'] as List;
          final List g2 = answer as List;
          if (t.length != g2.length) return false;
          for (int i = 0; i < t.length; i++) {
            if ((t[i] as num).toInt() != (g2[i] as num).toInt()) return false;
          }
          return true;
        case 'number':
          final num? v = answer is num ? answer : num.tryParse('$answer'.trim());
          return v != null && v == (e.data['answer'] as num);
        case 'ordering':
          final List<String> want =
              (e.data['order'] as List).map((x) => '$x').toList();
          final List<String> got = (answer as List).map((x) => '$x').toList();
          if (want.length != got.length) return false;
          for (int i = 0; i < want.length; i++) {
            if (want[i] != got[i]) return false;
          }
          return true;
        case 'matching':
          final Map want = e.data['pairs'] as Map;
          final Map got = answer as Map;
          if (want.length != got.length) return false;
          return want.entries.every((p) => got['${p.key}'] == '${p.value}');
        case 'categorize':
          final Map want = e.data['items'] as Map;
          final Map got = answer as Map;
          if (want.length != got.length) return false;
          return want.entries.every((p) => got['${p.key}'] == '${p.value}');
      }
    } catch (_) {}
    return false;
  }

  /// Hint for the n-th wrong attempt (0-based); the last hint repeats.
  static String? hintFor(Exercise e, int wrongAttempts) {
    if (e.hints.isEmpty) return null;
    return e.hints[wrongAttempts.clamp(0, e.hints.length - 1)];
  }
}


/// Step-level grading: which parts of the answer were right or wrong.
class StepResult {
  final int total;
  final List<String> wrongSteps;
  const StepResult(this.total, this.wrongSteps);
  int get right => total - wrongSteps.length;
  bool get allRight => wrongSteps.isEmpty;
}

extension StepGrading on ExerciseGrader {
  static StepResult steps(Exercise e, Object? answer) {
    try {
      switch (e.type) {
        case 'ordering':
          final List want = e.data['order'] as List;
          final List got = answer as List;
          final List<String> bad = [];
          for (int i = 0; i < want.length; i++) {
            if (i >= got.length || '${got[i]}' != '${want[i]}') bad.add('${want[i]}');
          }
          return StepResult(want.length, bad);
        case 'bars':
          final List t = e.data['target'] as List;
          final List labels = (e.data['labels'] as List?) ?? const [];
          final List g = answer as List;
          final List<String> bad = [
            for (int i = 0; i < t.length; i++)
              if (i >= g.length || (g[i] as num).toInt() != (t[i] as num).toInt())
                i < labels.length ? '${labels[i]}' : '$i'
          ];
          return StepResult(t.length, bad);
        case 'matching':
        case 'categorize':
          final Map want = (e.type == 'matching' ? e.data['pairs'] : e.data['items']) as Map;
          final Map got = answer as Map;
          final List<String> bad = [
            for (final en in want.entries)
              if (got['${en.key}'] != '${en.value}') '${en.key}'
          ];
          return StepResult(want.length, bad);
      }
    } catch (_) {}
    final bool ok = ExerciseGrader.grade(e, answer);
    return StepResult(1, ok ? const [] : const ['answer']);
  }
}

/// Local mastery + adaptive difficulty + mistake review. Pure logic, the
/// caller stores [toJson] on the phone.
class ExerciseProgress {
  final Map<String, Map<String, int>> skills; // skill -> level/streak/right/total
  final Map<String, Map<String, dynamic>> review; // exId -> step/due
  ExerciseProgress([Map<String, Map<String, int>>? s, Map<String, Map<String, dynamic>>? r])
      : skills = s ?? {},
        review = r ?? {};

  static const List<int> _days = [1, 3, 7];

  int levelOf(String skill) => skills[skill]?['level'] ?? 1;
  int percentOf(String skill) {
    final Map<String, int>? m = skills[skill];
    if (m == null || (m['total'] ?? 0) == 0) return 0;
    return ((m['right']! * 100) / m['total']!).round();
  }

  /// Mastered: at least 5 tries, 80% right, and at level 3.
  bool mastered(String skill) =>
      (skills[skill]?['total'] ?? 0) >= 5 && percentOf(skill) >= 80 && levelOf(skill) >= 3;

  void record(Exercise e, bool correct, DateTime now) {
    final Map<String, int> m = skills.putIfAbsent(
        e.skill, () => {'level': 1, 'streak': 0, 'right': 0, 'total': 0});
    m['total'] = m['total']! + 1;
    if (correct) {
      m['right'] = m['right']! + 1;
      m['miss'] = 0;
      m['streak'] = m['streak']! + 1;
      if (m['streak']! >= 3 && m['level']! < 3) {
        m['level'] = m['level']! + 1;
        m['streak'] = 0;
      }
    } else {
      // Gentle adaptivity: the level only drops after two misses in a row,
      // and a single miss never lowers it.
      m['streak'] = 0;
      m['miss'] = (m['miss'] ?? 0) + 1;
      if (m['miss']! >= 2) {
        if (m['level']! > 1) m['level'] = m['level']! - 1;
        m['miss'] = 0;
      }
    }
    final Map<String, dynamic>? r = review[e.id];
    int step = correct ? (r == null ? -1 : (r['step'] as int)) + 1 : 0;
    if (correct && r == null) {
      return; // right first time: no review needed
    }
    if (step >= _days.length) {
      review.remove(e.id);
    } else {
      review[e.id] = {
        'step': step,
        'due': now.add(Duration(days: _days[step])).toIso8601String()
      };
    }
  }

  /// Next exercise: a due review first, otherwise the least-mastered skill at
  /// its current level, avoiding the one just played.
  Exercise next(List<Exercise> bank, DateTime now, {String? lastId}) {
    for (final en in review.entries) {
      final DateTime? due = DateTime.tryParse('${en.value['due']}');
      if (due != null && !due.isAfter(now)) {
        for (final Exercise e in bank) {
          if (e.id == en.key && e.id != lastId) return e;
        }
      }
    }
    final List<String> skillNames = bank.map((e) => e.skill).toSet().toList()
      ..sort((a, b) => percentOf(a).compareTo(percentOf(b)));
    for (final String sk in skillNames) {
      final int lv = levelOf(sk);
      final List<Exercise> pool = bank
          .where((e) => e.skill == sk && e.id != lastId)
          .toList()
        ..sort((a, b) => (a.level - lv).abs().compareTo((b.level - lv).abs()));
      if (pool.isNotEmpty) return pool.first;
    }
    return bank.first;
  }

  Map<String, dynamic> toJson() => {'skills': skills, 'review': review};

  static ExerciseProgress fromJson(Map<String, dynamic> j) {
    final Map<String, Map<String, int>> s = {};
    ((j['skills'] as Map?) ?? {}).forEach((k, v) {
      s['$k'] = Map<String, int>.from((v as Map).map((a, b) => MapEntry('$a', (b as num).toInt())));
    });
    final Map<String, Map<String, dynamic>> r = {};
    ((j['review'] as Map?) ?? {}).forEach((k, v) {
      r['$k'] = Map<String, dynamic>.from(v as Map);
    });
    return ExerciseProgress(s, r);
  }
}
