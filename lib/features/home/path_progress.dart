import 'package:shared_preferences/shared_preferences.dart';

/// "مساري" progress. A step counts as done ONLY when the child really finishes
/// the activity (story played to the end, lesson answered correctly, game won).
/// Opening a screen and going back never marks anything.
class PathProgress {
  /// Set once at start-up; returns the active child's id (or null).
  static String? Function()? activeChildIdProvider;

  static Future<void> recordForActive(String kind) async {
    final String? id = activeChildIdProvider?.call();
    if (id != null) await record(id, kind);
  }

  static const String story = 'story';
  static const String lesson = 'lesson';
  static const String game = 'game';

  /// Main-shell tab index of a step -> the kind of completion it needs.
  static String kindForTab(int tab) =>
      tab == 0 ? story : (tab == 1 ? lesson : game);

  static String _key(String childId, String kind, [DateTime? now]) {
    final DateTime n = now ?? DateTime.now();
    return 'path_count_${childId}_${n.year}${n.month}${n.day}_$kind';
  }

  /// Called by the real completion events.
  static Future<void> record(String childId, String kind,
      {DateTime? now}) async {
    final SharedPreferences p = await SharedPreferences.getInstance();
    final String k = _key(childId, kind, now);
    await p.setInt(k, (p.getInt(k) ?? 0) + 1);
  }

  static Future<Map<String, int>> countsToday(String childId,
      {DateTime? now}) async {
    final SharedPreferences p = await SharedPreferences.getInstance();
    return {
      for (final String k in const [story, lesson, game])
        k: p.getInt(_key(childId, k, now)) ?? 0,
    };
  }

  /// Which steps are done, given each step's tab in order. The n-th step that
  /// needs a kind is done when at least n completions of that kind happened.
  static List<bool> doneFlags(List<int> stepTabs, Map<String, int> counts) {
    final Map<String, int> seen = {};
    final List<bool> out = [];
    for (final int tab in stepTabs) {
      final String kind = kindForTab(tab);
      final int idx = seen[kind] ?? 0;
      seen[kind] = idx + 1;
      out.add((counts[kind] ?? 0) > idx);
    }
    return out;
  }
}
