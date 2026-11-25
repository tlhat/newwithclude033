import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:haneen_kids_vod/haneen_kids_exports.dart';
import 'package:haneen_kids_vod/features/exercises/exercise_models.dart';
import 'package:haneen_kids_vod/features/exercises/exercise_screen.dart';
import 'package:haneen_kids_vod/features/exercises/game_catalog.dart';
import 'package:haneen_kids_vod/features/exercises/skill_mastery_card.dart';
import 'package:haneen_kids_vod/features/brain_games/screens/extra_games.dart';
import 'dev_core.dart';

const Color _card = Color(0xFF1E293B);

Map<String, String> _skillTitles() => {
      ...SkillMasteryCard.skillNames,
      for (final ExerciseGameDef g in kExerciseGames) g.skill: g.title,
      for (final WidgetGameDef g in kWidgetGames) g.id: g.title,
    };

String _childId(AppStateManager s) => s.currentAccount?.activeChild.id ?? '';
String _childAge(AppStateManager s) => s.currentAccount?.activeChild.age ?? '';

/// Wraps the games area. 18 to 36 months: off until a parent turns on
/// co-use. Counts minutes spent here against the parent-set daily cap.
class DevGate extends StatefulWidget {
  final AppStateManager appState;
  final Widget child;
  final bool active;
  const DevGate({super.key, required this.appState, required this.child, this.active = true});
  @override
  State<DevGate> createState() => _DevGateState();
}

class _DevGateState extends State<DevGate> {
  DevData? _d;
  String _id = '';
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _reload();
    _t = Timer.periodic(const Duration(seconds: 60), (_) => _tick());
  }

  Future<void> _reload() async {
    _id = _childId(widget.appState);
    final DevData d = await DevStore.load(_id);
    if (mounted) setState(() => _d = d);
  }

  Future<void> _tick() async {
    final DevData? d = _d;
    if (d == null || !widget.active || !mounted) return;
    final AgeBand b = d.bandFor(_childAge(widget.appState));
    if (gateState(b, d.coUse, d.capFor(b), d.usedByDay[dayKey(DateTime.now())] ?? 0) != GateState.ok) return;
    final String k = dayKey(DateTime.now());
    d.usedByDay[k] = (d.usedByDay[k] ?? 0) + 1;
    await DevStore.save(_id, d);
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(covariant DevGate old) {
    super.didUpdateWidget(old);
    if (_id != _childId(widget.appState) || (!old.active && widget.active)) _reload();
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  Widget _msg(String title, String body, String activity) => Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: const Color(0xFF0F172A),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text('🌙', style: TextStyle(fontSize: 56)),
                const SizedBox(height: 12),
                Text(title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                Text(body, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 15)),
                if (activity.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text('نشاط حقيقي دلوقتي: $activity',
                      textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFA7F3D0), fontSize: 15)),
                ],
              ]),
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final DevData? d = _d;
    if (d == null) return widget.child;
    final AgeBand b = d.bandFor(_childAge(widget.appState));
    final int used = d.usedByDay[dayKey(DateTime.now())] ?? 0;
    final GateState g = gateState(b, d.coUse, d.capFor(b), used);
    final String act = realWorldFor(b, SkillArea.motor, DateTime.now());
    if (g == GateState.offByDefault) {
      return _msg('الألعاب مقفولة للفئة دي',
          'الفئة (${b.label}): الأفضل لعب حقيقي وكلام مع الأهل. الوالد يقدر يفتحها للاستخدام المشترك من بوابة الوالدين.', act);
    }
    if (g == GateState.timeUp) {
      return _msg('خلص وقت الألعاب النهارده', 'الوقت اللي حدده الوالد خلص. نكمل بكرة بإذن الله.', act);
    }
    if (b == AgeBand.m18to36) {
      return Column(children: [
        Container(
          width: double.infinity,
          color: const Color(0xFF14532D),
          padding: const EdgeInsets.all(6),
          child: const Directionality(
              textDirection: TextDirection.rtl,
              child: Text('استخدام مشترك: العب مع طفلك وكلّمه عن اللي بيشوفه',
                  textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 12))),
        ),
        Expanded(child: widget.child),
      ]);
    }
    return widget.child;
  }
}

/// Independent check: 3 questions not seen before in this skill.
class TransferCheckScreen extends StatefulWidget {
  final AppStateManager appState;
  final String skill;
  final String title;
  const TransferCheckScreen({super.key, required this.appState, required this.skill, required this.title});
  @override
  State<TransferCheckScreen> createState() => _TransferCheckScreenState();
}

class _TransferCheckScreenState extends State<TransferCheckScreen> {
  List<Exercise> _items = [];
  int _i = 0;
  int _right = 0;
  bool _loaded = false;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final String raw = await rootBundle.loadString('assets/exercises/exercises_v1.json');
    final DevData d = await DevStore.load(_childId(widget.appState));
    final List<Exercise> bank = Exercise.parseList(raw).where((e) => e.skill == widget.skill).toList();
    if (mounted) {
      setState(() {
        _items = pickTransfer<Exercise>(bank, (e) => e.id, d.seen, 3);
        _loaded = true;
      });
    }
  }

  Future<void> _finish() async {
    final bool pass = _right * 3 >= _items.length * 2;
    final DevData d = await DevStore.load(_childId(widget.appState));
    d.logTransfer(widget.skill, pass, DateTime.now());
    await DevStore.save(_childId(widget.appState), d);
    if (mounted) setState(() => _done = true);
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (!_loaded) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_items.isEmpty) {
      body = const Center(child: Text('مفيش أسئلة كفاية للفحص'));
    } else if (_done) {
      final bool pass = _right * 3 >= _items.length * 2;
      body = Center(
          child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                  pass
                      ? 'ممتاز! جاوب على أسئلة جديدة بنفسه 🌟'
                      : 'محتاجين نتدرب شوية كمان، وهنجرب تاني بعد كام يوم 🌱',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700))));
    } else {
      body = SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(children: [
          Text('سؤال ${_i + 1} من ${_items.length}', style: const TextStyle(fontWeight: FontWeight.w700)),
          ExerciseGame(
            key: ValueKey('tc_$_i'),
            appState: widget.appState,
            onReact: (_) {},
            fixed: _items[_i],
            title: widget.title,
            onFirstTry: (e, ok) {
              if (ok) _right++;
            },
            onSolved: () {
              if (_i + 1 >= _items.length) {
                _finish();
              } else {
                setState(() => _i++);
              }
            },
          ),
        ]),
      );
    }
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(appBar: AppBar(title: Text('فحص مستقل: ${widget.title}')), body: body),
    );
  }
}

/// Parent view: development report, screen time, real-world activities, notes.
class DevelopmentCard extends StatefulWidget {
  final AppStateManager appState;
  const DevelopmentCard({super.key, required this.appState});
  @override
  State<DevelopmentCard> createState() => _DevelopmentCardState();
}

class _DevelopmentCardState extends State<DevelopmentCard> {
  DevData? _d;
  ExerciseProgress _p = ExerciseProgress();
  final TextEditingController _note = TextEditingController();
  SkillArea _noteArea = SkillArea.language;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final String id = _childId(widget.appState);
    final DevData d = await DevStore.load(id);
    ExerciseProgress p = ExerciseProgress();
    try {
      final SharedPreferences sp = await SharedPreferences.getInstance();
      final String? raw = sp.getString('ex_progress_$id');
      if (raw != null) p = ExerciseProgress.fromJson(Map<String, dynamic>.from(jsonDecode(raw) as Map));
    } catch (_) {}
    if (mounted) {
      setState(() {
        _d = d;
        _p = p;
      });
    }
  }

  Future<void> _save() async {
    await DevStore.save(_childId(widget.appState), _d!);
    if (mounted) setState(() {});
  }

  int _due() {
    int n = 0;
    final DateTime now = DateTime.now();
    for (final v in _p.review.values) {
      final DateTime? t = DateTime.tryParse('${v['due']}');
      if (t != null && !t.isAfter(now)) n++;
    }
    return n;
  }

  Widget _title(String t) => Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 6),
      child: Text(t, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)));

  Widget _small(String t, {Color c = Colors.white60}) =>
      Text(t, style: TextStyle(color: c, fontSize: 12));

  @override
  Widget build(BuildContext context) {
    final DevData? d = _d;
    final String name = widget.appState.currentAccount?.activeChild.name ?? '';
    final Map<String, String> titles = _skillTitles();
    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: _card, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white12)),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Material(
          type: MaterialType.transparency,
          child: d == null
              ? const LinearProgressIndicator()
              : Column(crossAxisAlignment: CrossAxisAlignment.start, children: _content(d, name, titles)),
        ),
      ),
    );
  }

  List<Widget> _content(DevData d, String name, Map<String, String> titles) {
    final AgeBand band = d.bandFor(_childAge(widget.appState));
    final DateTime now = DateTime.now();
    final int used = d.usedByDay[dayKey(now)] ?? 0;
    final int cap = d.capFor(band);
    final List<Widget> w = [
      const Text('🌱 تقرير النمو والتدريب',
          style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold, color: Colors.white)),
      const SizedBox(height: 4),
      _small('تدريب $name داخل التطبيق فقط. محفوظ على هذا الهاتف ولا يتقارن بأطفال آخرين.'),
      const SizedBox(height: 4),
      _small(kNoDiagnosisLine, c: const Color(0xFFFCD34D)),
      _title('الفئة العمرية'),
      Wrap(spacing: 8, children: [
        for (final AgeBand b in AgeBand.values)
          ChoiceChip(
            label: Text(b.label),
            selected: band == b,
            onSelected: (_) {
              d.bandOverride = b;
              _save();
            },
          ),
      ]),
      _small('اختيار الفئة وتوزيع الأنشطة عليها قرار تصميم غير مُثبت علميًا (غير مُثبت).'),
      _title('وقت الشاشة (يحدده الوالد)'),
    ];
    if (band == AgeBand.m18to36) {
      w.addAll([
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('تشغيل الألعاب للاستخدام المشترك مع الوالد', style: TextStyle(color: Colors.white)),
          subtitle: _small('مقفولة افتراضيًا. منظمة الصحة العالمية لا توصي بوقت شاشة جالس لعمر السنة.'),
          value: d.coUse,
          onChanged: (v) {
            d.coUse = v;
            _save();
          },
        ),
      ]);
    }
    w.add(Row(children: [
      Expanded(
          child: Text(cap == 0 ? 'الحد اليومي: بدون حد من التطبيق' : 'الحد اليومي: $cap دقيقة',
              style: const TextStyle(color: Colors.white))),
      IconButton(
          onPressed: () {
            d.capOverride = (cap - 5).clamp(0, 240);
            _save();
          },
          icon: const Icon(Icons.remove_circle_outline, color: Colors.white70)),
      IconButton(
          onPressed: () {
            d.capOverride = (cap + 5).clamp(0, 240);
            _save();
          },
          icon: const Icon(Icons.add_circle_outline, color: Colors.white70)),
    ]));
    w.add(_small('استُخدم اليوم في الألعاب: $used دقيقة. الأرقام الافتراضية (٢٠ و٦٠) اختيار متحفظ مبني على إرشادات WHO وAAP، '
        'ولا يوجد رقم علمي لعمر ٦ إلى ١٢ (غير مُثبت). تجنّب الشاشات وقت الأكل وقبل النوم بساعة.'));

    // Summary: strengths, improving, needs practice, over time
    final List<String> strong = [], improving = [], needs = [];
    for (final String k in d.days.keys) {
      final SkillState st = d.stateOf(k);
      final List<int> tr = d.trend(k);
      final String t = titles[k] ?? k;
      if (st.stage == Stage.confident || st.stage == Stage.solid) {
        strong.add(t);
      } else if (tr.length >= 2 && tr.last > tr.first) {
        improving.add(t);
      } else if (st.attempts >= 5) {
        needs.add(t);
      }
    }
    w.add(_title('ملخص التقدم'));
    w.add(_small('نقاط القوة: ${strong.isEmpty ? 'لسه بدري' : strong.join('، ')}', c: const Color(0xFFA7F3D0)));
    w.add(_small('بتتحسن: ${improving.isEmpty ? '-' : improving.join('، ')}', c: const Color(0xFFFCD34D)));
    w.add(_small('تحتاج تدريبًا: ${needs.isEmpty ? '-' : needs.join('، ')}', c: Colors.white70));
    w.add(_small('الثقة في التقدير تزيد بتكرار الأداء على أيام مختلفة. إجابات يوم واحد لا تكفي.'));

    // Skill map
    w.add(_title('خريطة المهارات'));
    w.add(_small('مهارات مناسبة لفئة ${band.label} (توزيع تصميمي غير مُثبت): '
        '${titles.keys.where((k) => bandsOf(k).contains(band)).map((k) => titles[k]).take(14).join('، ')}...'));
    for (final SkillArea a in SkillArea.values) {
      final EvidenceBadge ev = kAreaEvidence[a]!;
      final List<String> skills = d.days.keys.where((s) => areaOf(s) == a).toList()..sort();
      w.add(Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(a.label, style: const TextStyle(color: Color(0xFF5EEAD4), fontWeight: FontWeight.bold)),
      ));
      w.add(_small('${ev.strengthLabel}${ev.sources.isEmpty ? '' : ' • المصادر: ${ev.sources.join('، ')}'}'));
      w.add(_small('حدّ الدليل: ${ev.limit}'));
      if (ev.strength == EvidenceStrength.unverified) {
        w.add(_small('تُعرض كلعب وليس كتدريب مهارة.', c: const Color(0xFFFCD34D)));
      }
      if (skills.isEmpty) {
        w.add(_small(a == SkillArea.motor ? 'لا يُقاس بعد داخل التطبيق.' : 'لم يبدأ بعد.'));
      }
      for (final String s in skills) {
        final SkillState st = d.stateOf(s);
        final String t = titles[s] ?? s;
        final ActivityMeta m = metaFor(s, t, level: _p.levelOf(s));
        final bool ageOk = m.bands.contains(band);
        w.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                  child: Text('${st.stage.label}  $t',
                      style: const TextStyle(color: Colors.white, fontSize: 14))),
              Text('${st.confidenceLabel} • ${st.attempts} إجابة • ${st.goodDays} يوم جيد',
                  style: const TextStyle(color: Colors.white54, fontSize: 11)),
            ]),
            _small('${m.goal} • ${m.hints}'),
            _small('${m.assessment}'),
            _small('محاولات إضافية بعد تلميح: ${d.extraTries(s)} • الثبات عبر الأيام (٪ صح): ${d.trend(s).isEmpty ? '-' : d.trend(s).join(' ← ')}'),
            if (!ageOk) _small('مناسب أكثر لفئة عمرية أخرى (تصميم غير مُثبت).'),
            if (st.stage == Stage.confident)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () async {
                    await Navigator.of(context).push(MaterialPageRoute<void>(
                        builder: (_) => TransferCheckScreen(appState: widget.appState, skill: s, title: t)));
                    _load();
                  },
                  child: const Text('ابدأ فحصًا مستقلًا (٣ أسئلة جديدة)'),
                ),
              ),
          ]),
        ));
      }
    }
    w.add(const SizedBox(height: 6));
    w.add(_small('مراجعات مستحقة اليوم: ${_due()}', c: const Color(0xFFA7F3D0)));
    w.add(_small('واثق = ٧٠٪ صح فأكثر في يومين مختلفين. راسخ = واثق + فحص مستقل ناجح + يوم جيد بعد ٣ أيام أو أكثر. '
        'هذه الحدود قرار تصميم (غير مُثبت) مبني على فكرة التكرار المتباعد (S8, S9).'));

    // Real-world activities
    w.add(_title('أنشطة حقيقية هذا الأسبوع'));
    final String wk = weekKey(now);
    for (final SkillArea a in SkillArea.values) {
      final String key = '$wk|${a.name}';
      w.add(CheckboxListTile(
        contentPadding: EdgeInsets.zero,
        controlAffinity: ListTileControlAffinity.leading,
        value: d.actDone[key] ?? false,
        onChanged: (v) {
          d.actDone[key] = v ?? false;
          _save();
        },
        title: Text(realWorldFor(band, a, now), style: const TextStyle(color: Colors.white, fontSize: 13.5)),
        subtitle: _small(a.label),
      ));
    }

    // Notes
    w.add(_title('ملاحظات الوالد'));
    w.add(Wrap(spacing: 6, children: [
      for (final SkillArea a in SkillArea.values)
        ChoiceChip(label: Text(a.label, style: const TextStyle(fontSize: 11)), selected: _noteArea == a, onSelected: (_) => setState(() => _noteArea = a)),
    ]));
    w.add(TextField(
      controller: _note,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: 'اكتب ما لاحظته (مثلًا قال كلمة جديدة)',
        hintStyle: const TextStyle(color: Colors.white38),
        suffixIcon: IconButton(
          icon: const Icon(Icons.add_comment, color: Color(0xFF5EEAD4)),
          onPressed: () {
            final String t = _note.text.trim();
            if (t.isEmpty) return;
            d.notes.insert(0, {'d': dayKey(now), 'area': _noteArea.label, 't': t});
            if (d.notes.length > 100) d.notes.removeLast();
            _note.clear();
            _save();
          },
        ),
      ),
    ));
    for (final Map<String, String> n in d.notes.take(8)) {
      w.add(Padding(
          padding: const EdgeInsets.only(top: 4),
          child: _small('${n['d']} • ${n['area']}: ${n['t']}', c: Colors.white70)));
    }
    w.add(const SizedBox(height: 10));
    w.add(_small('المصادر والحدود الكاملة في docs/EVIDENCE.md. لا تُعرض أي نسب مقارنة أو "عمر عقلي" أو ذكاء.'));
    return w;
  }
}
