import 'package:flutter/material.dart';
import 'package:haneen_kids_vod/core/regional/dialect_pack.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:haneen_kids_vod/haneen_kids_exports.dart';
import 'level_check_screen.dart';
import 'package:haneen_kids_vod/features/home/path_progress.dart';
import 'package:haneen_kids_vod/features/home/path_target.dart';

class PathStep {
  final String id;
  final String emoji;
  final String title;
  final String hint;

  /// Tab index in the main shell: 0 stories, 1 academy, 2 games.
  final int tab;
  final String? trackId;
  final int? gameIndex;
  PathStep(this.id, this.emoji, this.title, this.hint, this.tab,
      {this.trackId, this.gameIndex});
  PathTarget get target =>
      PathTarget(tab, trackId: trackId, gameIndex: gameIndex);
}

/// "مساري": a short daily plan chosen from the child's age.
class MyPathPlan {
  static int ageOf(String age) {
    final String digits = age.replaceAllMapped(
        RegExp(r'[٠-٩]'), (m) => (m[0]!.codeUnitAt(0) - 0x0660).toString());
    return int.tryParse(RegExp(r'\d+').firstMatch(digits)?.group(0) ?? '') ?? 5;
  }

  static String groupName(int age) =>
      age <= 4 ? 'من ٣ إلى ٤ سنين' : (age <= 6 ? 'من ٥ إلى ٦ سنين' : '٧ سنين وأكتر');

  static List<PathStep> stepsFor(int age) {
    if (age <= 4) {
      return [
        PathStep('s1', '📖', 'قصة قصيرة', 'اسمع قصة وشوف الرسومات', 0),
        PathStep('a1', '🔤', 'حروف وأصوات', 'اتعلم حرف جديد مع حنين', 1, trackId: 'arabic_letters'),
        PathStep('g1', '🧩', 'لعبة صور وأصوات', 'طابق الصورة بالصوت', 2, gameIndex: 8),
        PathStep('a2', '🌈', 'ألوان وأشكال', 'سمّي الألوان والأشكال', 1, trackId: 'colors_shapes'),
        PathStep('s2', '🌙', 'قصة هادئة', 'ختام لطيف لليوم', 0),
      ];
    }
    if (age <= 6) {
      return [
        PathStep('a1', '🔤', 'درس الحروف', 'حرف جديد وكلمات بيه', 1, trackId: 'arabic_letters'),
        PathStep('g1', '🔢', 'لعبة الأرقام', 'عدّ وجمّع', 2, gameIndex: 4),
        PathStep('s1', '📖', 'قصة', 'اقرا واسمع واتعلم', 0),
        PathStep('g2', '🧠', 'لعبة ذاكرة', 'فكّر وتذكّر', 2, gameIndex: 3),
        PathStep('a2', '🗣️', 'نطق واضح', 'قول الكلمة بصوت واضح', 1, trackId: 'communication'),
      ];
    }
    return [
      PathStep('a1', '📚', 'درس اليوم', 'كلمات وجمل أطول', 1, trackId: 'vocabulary'),
      PathStep('g1', '🧠', 'تحدّي ذكاء', 'نمط وتصنيف ومختلف', 2, gameIndex: 2),
      PathStep('g2', '🔢', 'رياضيات', 'مسائل أسرع شوية', 2, gameIndex: 4),
      PathStep('s1', '📖', 'قصة وأسئلة', 'اقرا وجاوب', 0),
      PathStep('g3', '🎨', 'مرسم الآداب', 'ارسم وتعلّم أدب جديد', 2, gameIndex: 0),
    ];
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
  List<bool> _flags = const <bool>[];

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
    final int age = MyPathPlan.ageOf(widget.appState.currentAccount!.activeChild.age);
    final counts = await PathProgress.countsToday(_childId);
    final flags = PathProgress.doneFlags(
        MyPathPlan.stepsFor(age).map((s) => s.tab).toList(), counts);
    if (mounted) setState(() => _flags = flags);
  }

  @override
  Widget build(BuildContext context) {
    final child = widget.appState.currentAccount!.activeChild;
    final int age = MyPathPlan.ageOf(child.age);
    final List<PathStep> steps = MyPathPlan.stepsFor(age);
    final List<bool> flags = _flags.length == steps.length ? _flags : List<bool>.filled(steps.length, false);
    final int doneCount = flags.where((d) => d).length;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: Text('مساري 🧭')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('خطة النهاردة يا ${child.name} (${MyPathPlan.groupName(age)})',
                style:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            LinearProgressIndicator(
                value: steps.isEmpty ? 0 : doneCount / steps.length,
                minHeight: 10,
                borderRadius: BorderRadius.circular(8)),
            const SizedBox(height: 4),
            Text('${doneCount} من ${steps.length}'),
            const SizedBox(height: 12),
            for (int si = 0; si < steps.length; si++)
              Card(
                child: ListTile(
                  leading: Text(steps[si].emoji, style: const TextStyle(fontSize: 28)),
                  title: Text(steps[si].title,
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text(steps[si].hint),
                  trailing: flags[si]
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : const Icon(Icons.play_circle_fill_rounded),
                  onTap: () async {
                    // Only go there. It is marked done when really finished.
                    if (!mounted) return;
                    Navigator.of(context).pop();
                    PathTarget.pending.value = steps[si].target;
                    widget.onGoToTab(steps[si].tab);
                  },
                ),
              ),
            if (doneCount >= steps.length)
              Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text(DialectPacks.t('path.allDone', '🎉 خلصت خطة النهاردة! برافو يا بطل'),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              ),
          ],
        ),
      ),
    );
  }
}
