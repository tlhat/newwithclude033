import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:haneen_kids_vod/haneen_kids_exports.dart';
import 'package:haneen_kids_vod/core/theme/kid_theme.dart';
import 'exercise_models.dart';

/// Plays the JSON exercises one after another. Rendering lives here, grading
/// lives in ExerciseGrader.
class ExerciseGame extends StatefulWidget {
  final AppStateManager appState;
  final void Function(bool correct) onReact;
  const ExerciseGame({super.key, required this.appState, required this.onReact});
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
      final List<Exercise> l = Exercise.parseList(raw);
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
  }

  Object? _answer(Exercise e) {
    switch (e.type) {
      case 'choice':
        return _choice;
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
      _sp.setString(_key, jsonEncode(_prog.toJson()));
    }
    widget.onReact(ok);
    if (ok) {
      setState(() {
        _msg = e.correctFeedback;
        _msgGood = true;
      });
      HintVoiceService.instance.play('hint_great');
      await widget.appState.recordBrainGameWin(
          gameId: 'exercise_${e.id}',
          gameTitle: 'تمارين متنوعة',
          earnedIqPoints: 10,
          earnedStars: 1);
      await Future<void>.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;
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
