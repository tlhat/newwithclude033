import 'package:flutter/material.dart';
import 'package:haneen_kids_vod/core/localization/tr.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:haneen_kids_vod/haneen_kids_exports.dart';
import 'level_check_screen.dart';

class PathStep {
  final String id;
  final String emoji;
  final String title;
  final String hint;

  /// Tab index in the main shell: 0 stories, 1 academy, 2 games.
  final int tab;
  PathStep(this.id, this.emoji, this.title, this.hint, this.tab);
}

/// "مساري": a short daily plan chosen from the child's age.
class MyPathPlan {
  static int ageOf(String age) {
    final String digits = age.replaceAllMapped(
        RegExp(r'[٠-٩]'), (m) => (m[0]!.codeUnitAt(0) - 0x0660).toString());
    return int.tryParse(RegExp(r'\d+').firstMatch(digits)?.group(0) ?? '') ?? 5;
  }

  static String groupName(int age) =>
      age <= 4 ? tr('من ٣ إلى ٤ سنين') : (age <= 6 ? tr('من ٥ إلى ٦ سنين') : tr('٧ سنين وأكتر'));

  static List<PathStep> stepsFor(int age) {
    if (age <= 4) {
      return [
        PathStep('s1', '📖', 'قصة قصيرة', 'اسمع قصة وشوف الرسومات', 0),
        PathStep('a1', '🔤', 'حروف وأصوات', 'اتعلم حرف جديد مع حنين', 1),
        PathStep('g1', '🧩', 'لعبة صور وأصوات', 'طابق الصورة بالصوت', 2),
        PathStep('a2', '🌈', 'ألوان وأشكال', 'سمّي الألوان والأشكال', 1),
        PathStep('s2', '🌙', 'قصة هادئة', 'ختام لطيف لليوم', 0),
      ];
    }
    if (age <= 6) {
      return [
        PathStep('a1', '🔤', 'درس الحروف', 'حرف جديد وكلمات بيه', 1),
        PathStep('g1', '🔢', 'لعبة الأرقام', 'عدّ وجمّع', 2),
        PathStep('s1', '📖', 'قصة', 'اقرا واسمع واتعلم', 0),
        PathStep('g2', '🧠', 'لعبة ذاكرة', 'فكّر وتذكّر', 2),
        PathStep('a2', '🗣️', 'نطق واضح', 'قول الكلمة بصوت واضح', 1),
      ];
    }
    return [
      PathStep('a1', '📚', 'درس اليوم', 'كلمات وجمل أطول', 1),
      PathStep('g1', '🧠', tr('تحدّي ذكاء'), tr('نمط وتصنيف ومختلف'), 2),
      PathStep('g2', '🔢', tr('رياضيات'), tr('مسائل أسرع شوية'), 2),
      PathStep('s1', '📖', tr('قصة وأسئلة'), tr('اقرا وجاوب'), 0),
      PathStep('g3', '🎨', tr('مرسم الآداب'), tr('ارسم وتعلّم أدب جديد'), 2),
    ];
  }

  static String _key(String childId) {
    final DateTime n = DateTime.now();
    return 'path_done_${childId}_${n.year}${n.month}${n.day}';
  }

  static Future<Set<String>> doneToday(String childId) async {
    final SharedPreferences p = await SharedPreferences.getInstance();
    return (p.getStringList(_key(childId)) ?? const <String>[]).toSet();
  }

  static Future<void> markDone(String childId, String stepId) async {
    final SharedPreferences p = await SharedPreferences.getInstance();
    final Set<String> s = (p.getStringList(_key(childId)) ?? <String>[]).toSet()
      ..add(stepId);
    await p.setStringList(_key(childId), s.toList());
  }
}

class MyPathScreen extends StatefulWidget {
  final AppStateManager appState;
  final void Function(int tab) onGoToTab;
  const MyPathScreen(
      {super.key, required this.appState, required this.onGoToTab});

  @override
  State<MyPathScreen> createState() => _MyPathScreenState();
}

class _MyPathScreenState extends State<MyPathScreen> {
  Set<String> _done = <String>{};

  String get _childId => widget.appState.currentAccount!.activeChild.id;

  @override
  void initState() {
    super.initState();
    _load();
    HintVoiceService.instance.play('hint_my_path', oncePerSession: true);
    if (!widget.appState.levelCheckDone) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => LevelCheckScreen(appState: widget.appState)));
      });
    }
  }

  Future<void> _load() async {
    final Set<String> d = await MyPathPlan.doneToday(_childId);
    if (mounted) setState(() => _done = d);
  }

  @override
  Widget build(BuildContext context) {
    final child = widget.appState.currentAccount!.activeChild;
    final int age = MyPathPlan.ageOf(child.age);
    final List<PathStep> steps = MyPathPlan.stepsFor(age);
    final int doneCount = steps.where((s) => _done.contains(s.id + s.tab.toString())).length;
    return Directionality(
      textDirection: Tr.dir,
      child: Scaffold(
        appBar: AppBar(title: Text(tr('مساري 🧭'))),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(tr('خطة النهاردة يا {0} ({1})', [child.name, MyPathPlan.groupName(age)]),
                style:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            LinearProgressIndicator(
                value: steps.isEmpty ? 0 : doneCount / steps.length,
                minHeight: 10,
                borderRadius: BorderRadius.circular(8)),
            const SizedBox(height: 4),
            Text(tr('{0} من {1}', [doneCount, steps.length])),
            const SizedBox(height: 12),
            for (final s in steps)
              Card(
                child: ListTile(
                  leading: Text(s.emoji, style: const TextStyle(fontSize: 28)),
                  title: Text(s.title,
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text(s.hint),
                  trailing: _done.contains(s.id + s.tab.toString())
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : const Icon(Icons.play_circle_fill_rounded),
                  onTap: () async {
                    await MyPathPlan.markDone(_childId, s.id + s.tab.toString());
                    if (!mounted) return;
                    Navigator.of(context).pop();
                    widget.onGoToTab(s.tab);
                  },
                ),
              ),
            if (doneCount >= steps.length)
              Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text(tr('🎉 خلصت خطة النهاردة! برافو يا بطل'),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              ),
          ],
        ),
      ),
    );
  }
}
