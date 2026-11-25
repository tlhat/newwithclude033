import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:haneen_kids_vod/haneen_kids_exports.dart';
import 'package:haneen_kids_vod/core/theme/kid_theme.dart';
import 'exercise_models.dart';
import 'game_catalog.dart';
import 'package:haneen_kids_vod/features/development/dev_core.dart';

/// Plays the JSON exercises one after another. Rendering lives here, grading
/// lives in ExerciseGrader.
class ExerciseGame extends StatefulWidget {
  final AppStateManager appState;
  final void Function(bool correct) onReact;
  /// Optional: play only one skill (used by the single-widget games).
  final String? skill;
  final String title;
  /// Play exactly this question, then call [onSolved] (daily challenge).
  final Exercise? fixed;
  final VoidCallback? onSolved;
  /// Called once per question with whether the first try was right.
  final void Function(Exercise e, bool firstTry)? onFirstTry;
  const ExerciseGame(
      {super.key,
      required this.appState,
      required this.onReact,
      this.skill,
      this.fixed,
      this.onSolved,
      this.onFirstTry,
      this.title = 'تمارين متنوعة'});
  @override
  State<ExerciseGame> createState() => _ExerciseGameState();
}

class _ExerciseGameState extends State<ExerciseGame> {
  List<Exercise> _list = [];
  Exercise? _cur;
  ExerciseProgress _prog = ExerciseProgress();
  late SharedPreferences _sp;
  String get _key => 'ex_progress_${widget.appState.currentAccount?.activeChild.id}';
  int _wrong = 0;
  String? _msg;
  bool _msgGood = false;
  // answer state
  int? _choice;
  final TextEditingController _num = TextEditingController();
  final List<String> _order = [];
  final Map<String, String> _pairs = {};
  String? _leftSel;
  final Map<String, String> _bins = {};
  double _line = 0;
  bool _lineTouched = false;
  final Set<int> _multi = {};
  int? _gx, _gy;
  List<int> _barVals = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _num.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final String raw =
          await rootBundle.loadString('assets/exercises/exercises_v1.json');
      final List<Exercise> all = widget.fixed != null
          ? <Exercise>[widget.fixed!]
          : Exercise.parseList(raw);
      final List<Exercise> l = widget.fixed != null
          ? all
          : widget.skill == null
          ? all.where((x) => !kExerciseGameSkills.contains(x.skill)).toList()
          : all.where((x) => x.skill == widget.skill).toList();
      _sp = await SharedPreferences.getInstance();
      try {
        _prog = ExerciseProgress.fromJson(
            jsonDecode(_sp.getString(_key) ?? '{}') as Map<String, dynamic>);
      } catch (_) {}
      if (mounted) {
        setState(() {
          _list = l;
          _cur = _prog.next(l, DateTime.now());
        });
      }
    } catch (_) {}
  }

  void _resetAnswer() {
    _choice = null;
    _num.clear();
    _order.clear();
    _pairs.clear();
    _leftSel = null;
    _bins.clear();
    _lineTouched = false;
    _multi.clear();
    _gx = null;
    _gy = null;
    _barVals = [];
  }

  Object? _answer(Exercise e) {
    switch (e.type) {
      case 'choice':
      case 'blank':
        return _choice;
      case 'numberline':
        return _lineTouched ? _line.round() : null;
      case 'multi':
        return _multi.toList();
      case 'grid_point':
        return (_gx == null || _gy == null) ? <int>[] : <int>[_gx!, _gy!];
      case 'bars':
        return _barVals;
      case 'number':
        return _num.text;
      case 'ordering':
        return _order;
      case 'matching':
        return _pairs;
      default:
        return _bins;
    }
  }

  Future<void> _check(Exercise e) async {
    final StepResult st = StepGrading.steps(e, _answer(e));
    final bool ok = ExerciseGrader.grade(e, _answer(e));
    if (_wrong == 0) {
      _prog.record(e, ok, DateTime.now());
      DevStore.logAttempt(widget.appState.currentAccount?.activeChild.id ?? '', e.skill, e.id, ok);
      widget.onFirstTry?.call(e, ok);
      _sp.setString(_key, jsonEncode(_prog.toJson()));
    }
    widget.onReact(ok);
    if (ok) {
      setState(() {
        _msg = e.explain.isEmpty ? e.correctFeedback : '${e.correctFeedback}\n${e.explain}';
        _msgGood = true;
      });
      HintVoiceService.instance.play('hint_great');
      await widget.appState.recordBrainGameWin(
          gameId: 'exercise_${e.id}',
          gameTitle: widget.title,
          earnedIqPoints: 10,
          earnedStars: 1);
      await Future<void>.delayed(Duration(milliseconds: e.explain.isEmpty ? 900 : 2600));
      if (!mounted) return;
      if (widget.onSolved != null) {
        widget.onSolved!();
        return;
      }
      setState(() {
        _cur = _prog.next(_list, DateTime.now(), lastId: e.id);
        _wrong = 0;
        _msg = null;
        _resetAnswer();
      });
    } else {
      final String? h = ExerciseGrader.hintFor(e, _wrong);
      setState(() {
        final String part = st.total > 1
            ? '\n${st.right} من ${st.total} صح'
            : '';
        _msg = (h == null ? e.wrongFeedback : '${e.wrongFeedback}\n💡 $h') + part;
        _msgGood = false;
        _wrong++;
      });
      HintVoiceService.instance.play('hint_try_again');
    }
  }

  Widget _tile(String t, {bool sel = false, VoidCallback? onTap, Color? c}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(
            minWidth: KidTheme.minTouch, minHeight: KidTheme.minTouch),
        padding: const EdgeInsets.symmetric(
            horizontal: KidTheme.s4, vertical: KidTheme.s3),
        decoration: BoxDecoration(
          color: c ?? (sel ? KidTheme.info : KidTheme.surfaceHigh),
          borderRadius: BorderRadius.circular(KidTheme.rMedium),
          border: Border.all(color: sel ? Colors.white : Colors.white24, width: 2),
        ),
        child: Text(t,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
      ),
    );
  }

  Widget _body(Exercise e) {
    switch (e.type) {
      case 'choice':
        final List opts = e.data['options'] as List;
        return Wrap(spacing: 10, runSpacing: 10, alignment: WrapAlignment.center, children: [
          for (int k = 0; k < opts.length; k++)
            _tile('${opts[k]}', sel: _choice == k, onTap: () => setState(() => _choice = k)),
        ]);
      case 'blank':
        final List bo = e.data['options'] as List;
        final String sent = '${e.data['sentence']}';
        final String fill = _choice == null ? '＿＿＿' : '${bo[_choice!]}';
        return Column(children: [
          Text(sent.replaceAll('___', fill),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
          const SizedBox(height: KidTheme.s3),
          Wrap(spacing: 10, runSpacing: 10, alignment: WrapAlignment.center, children: [
            for (int k = 0; k < bo.length; k++)
              _tile('${bo[k]}', sel: _choice == k, onTap: () => setState(() => _choice = k)),
          ]),
        ]);
      case 'multi':
        final List mo = e.data['options'] as List;
        return Wrap(spacing: 10, runSpacing: 10, alignment: WrapAlignment.center, children: [
          for (int k = 0; k < mo.length; k++)
            _tile('${_multi.contains(k) ? '✅ ' : ''}${mo[k]}',
                sel: _multi.contains(k),
                onTap: () => setState(() {
                      if (!_multi.add(k)) _multi.remove(k);
                    })),
        ]);
      case 'numberline':
        final int lo = (e.data['min'] as num).toInt();
        final int hi = (e.data['max'] as num).toInt();
        if (!_lineTouched && _line < lo) _line = lo.toDouble();
        return Column(children: [
          Text(_lineTouched ? '${_line.round()}' : '؟',
              style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w900)),
          Slider(
            min: lo.toDouble(),
            max: hi.toDouble(),
            divisions: hi - lo,
            value: _line.clamp(lo.toDouble(), hi.toDouble()),
            onChanged: (v) => setState(() {
              _line = v;
              _lineTouched = true;
            }),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              for (int i = lo; i <= hi; i++)
                Text('$i', style: const TextStyle(color: Colors.white70, fontSize: 16)),
            ]),
          ),
        ]);
      case 'grid_point':
        final int n = (e.data['size'] as num).toInt();
        return Column(mainAxisSize: MainAxisSize.min, children: [
          for (int y = n; y >= 1; y--)
            Row(mainAxisSize: MainAxisSize.min, children: [
              SizedBox(width: 22, child: Text('$y', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70))),
              for (int x = 1; x <= n; x++)
                GestureDetector(
                  onTap: () => setState(() {
                    _gx = x;
                    _gy = y;
                  }),
                  child: Container(
                    width: 46,
                    height: 46,
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: (_gx == x && _gy == y) ? KidTheme.accent : KidTheme.surfaceHigh,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: (_gx == x && _gy == y) ? const Icon(Icons.star, color: Colors.white) : null,
                  ),
                ),
            ]),
          Row(mainAxisSize: MainAxisSize.min, children: [
            const SizedBox(width: 22),
            for (int x = 1; x <= n; x++)
              SizedBox(width: 50, child: Text('$x', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70))),
          ]),
        ]);
      case 'bars':
        final List labels = e.data['labels'] as List;
        final int mx = (e.data['max'] as num).toInt();
        if (_barVals.length != labels.length) _barVals = List<int>.filled(labels.length, 0);
        return Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, crossAxisAlignment: CrossAxisAlignment.end, children: [
          for (int i = 0; i < labels.length; i++)
            GestureDetector(
              onTap: () => setState(() => _barVals[i] = (_barVals[i] + 1) % (mx + 1)),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text('${_barVals[i]}', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                Container(
                  width: 52,
                  height: 22.0 * mx + 6,
                  alignment: Alignment.bottomCenter,
                  decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(8)),
                  child: Container(
                    width: 52,
                    height: 22.0 * _barVals[i],
                    decoration: BoxDecoration(color: KidTheme.primary, borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 4),
                Text('${labels[i]}', style: const TextStyle(color: Colors.white, fontSize: 24)),
              ]),
            ),
        ]);
      case 'number':
        return SizedBox(
          width: 140,
          child: TextField(
            controller: _num,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 32),
            decoration: const InputDecoration(
                filled: true, fillColor: KidTheme.surfaceHigh, border: OutlineInputBorder()),
          ),
        );
      case 'ordering':
        final List items = e.data['items'] as List;
        return Column(children: [
          Wrap(spacing: 8, children: [
            for (final x in _order) _tile('$x', sel: true),
          ]),
          const SizedBox(height: KidTheme.s3),
          Wrap(spacing: 10, runSpacing: 10, children: [
            for (final x in items)
              if (!_order.contains('$x'))
                _tile('$x', onTap: () => setState(() => _order.add('$x'))),
          ]),
          TextButton(
              onPressed: () => setState(_order.clear),
              child: const Text('من الأول')),
        ]);
      case 'matching':
        final List left = e.data['left'] as List;
        final List right = e.data['right'] as List;
        return Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          Column(children: [
            for (final l in left)
              Padding(
                padding: const EdgeInsets.all(5),
                child: _tile('$l',
                    sel: _leftSel == '$l',
                    c: _pairs.containsKey('$l') ? KidTheme.primary : null,
                    onTap: () => setState(() {
                          _pairs.remove('$l');
                          _leftSel = '$l';
                        })),
              ),
          ]),
          Column(children: [
            for (final r in right)
              Padding(
                padding: const EdgeInsets.all(5),
                child: _tile('$r',
                    c: _pairs.containsValue('$r') ? KidTheme.primary : null,
                    onTap: () => setState(() {
                          if (_leftSel != null && !_pairs.containsValue('$r')) {
                            _pairs[_leftSel!] = '$r';
                            _leftSel = null;
                          }
                        })),
              ),
          ]),
        ]);
      default:
        final Map items = e.data['items'] as Map;
        final List bins = e.data['bins'] as List;
        return Column(children: [
          Wrap(spacing: 12, children: [
            for (final k in items.keys)
              if (!_bins.containsKey('$k'))
                Draggable<String>(
                  data: '$k',
                  feedback: Material(
                      color: Colors.transparent,
                      child: Text('$k', style: const TextStyle(fontSize: 54))),
                  childWhenDragging: Opacity(opacity: .25, child: Text('$k', style: const TextStyle(fontSize: 54))),
                  child: Text('$k', style: const TextStyle(fontSize: 54)),
                ),
          ]),
          const SizedBox(height: KidTheme.s3),
          Row(children: [
            for (final b in bins)
              Expanded(
                child: DragTarget<String>(
                  onAcceptWithDetails: (d) => setState(() => _bins[d.data] = '$b'),
                  builder: (ctx, c, r) => Container(
                    height: 120,
                    margin: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                        color: c.isNotEmpty ? Colors.white24 : KidTheme.surfaceHigh,
                        borderRadius: BorderRadius.circular(KidTheme.rMedium),
                        border: Border.all(color: Colors.white38, width: 2)),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text('$b', style: KidTheme.title),
                      Wrap(children: [
                        for (final en in _bins.entries)
                          if (en.value == '$b') Text(en.key, style: const TextStyle(fontSize: 30)),
                      ]),
                    ]),
                  ),
                ),
              ),
          ]),
        ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_list.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    final Exercise e = _cur ?? _list.first;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Text(e.prompt, textAlign: TextAlign.center, style: KidTheme.title),
      const SizedBox(height: KidTheme.s4),
      _body(e),
      const SizedBox(height: KidTheme.s4),
      if (_msg != null)
        Padding(
          padding: const EdgeInsets.only(bottom: KidTheme.s3),
          child: Text(_msg!,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: _msgGood ? KidTheme.primary : KidTheme.accent,
                  fontSize: KidTheme.fBody,
                  fontWeight: FontWeight.w800)),
        ),
      KidButton(label: 'تأكيد', icon: Icons.check, onPressed: () => _check(e)),
    ]);
  }
}
