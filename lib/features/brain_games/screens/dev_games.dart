import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:haneen_kids_vod/core/theme/kid_theme.dart';
import 'package:haneen_kids_vod/haneen_kids_exports.dart';
import 'extra_games.dart';

/// Original games for executive function and creativity.
/// They are practice and play. No claim that they raise intelligence.

Future<void> _win(AppStateManager s, String id, String title) =>
    s.recordBrainGameWin(gameId: id, gameTitle: title, earnedIqPoints: 10, earnedStars: 1);

Text _t(String s, {double size = 16, Color c = Colors.white, FontWeight w = FontWeight.w600}) =>
    Text(s, textAlign: TextAlign.center, style: TextStyle(color: c, fontSize: size, fontWeight: w));

/// Stop and go: tap on green, hold still on red. Practices impulse control.
class StopGoGame extends StatefulWidget {
  final AppStateManager appState;
  final ExtraReact onReact;
  const StopGoGame({super.key, required this.appState, required this.onReact});
  @override
  State<StopGoGame> createState() => _StopGoState();
}

class _StopGoState extends State<StopGoGame> {
  static const int rounds = 10;
  final Random _r = Random();
  int _round = 0;
  int _good = 0;
  bool _go = true;
  bool _tapped = false;
  bool _running = false;
  bool _done = false;
  Timer? _timer;
  String _note = '';

  void _start() {
    _round = 0;
    _good = 0;
    _done = false;
    _next();
  }

  void _next() {
    if (_round >= rounds) {
      _timer?.cancel();
      setState(() {
        _running = false;
        _done = true;
      });
      _win(widget.appState, 'stop_go', 'قف وامشِ');
      return;
    }
    setState(() {
      _running = true;
      _tapped = false;
      _go = _r.nextInt(100) < 60;
      _note = '';
    });
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 1500), _end);
  }

  void _end() {
    if (!mounted) return;
    final bool ok = _go ? _tapped : !_tapped;
    if (ok) _good++;
    widget.onReact(ok);
    setState(() => _note = ok ? 'أحسنت 👏' : (_go ? 'كنت محتاج تضغط' : 'استنى شوية المرة الجاية'));
    _round++;
    _timer = Timer(const Duration(milliseconds: 600), _next);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      _t('قف وامشِ 🚦', size: 18, w: FontWeight.w800),
      const SizedBox(height: 4),
      _t('أخضر: اضغط بسرعة. أحمر: استنى ومتضغطش.', c: Colors.white70, size: 13),
      const SizedBox(height: 12),
      if (!_running && !_done) KidButton(label: 'ابدأ', icon: Icons.play_arrow, color: KidTheme.info, onPressed: _start),
      if (_running) ...[
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(shape: BoxShape.circle, color: _go ? const Color(0xFF22C55E) : const Color(0xFFEF4444)),
          alignment: Alignment.center,
          child: Text(_go ? 'امشي' : 'قف', style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () => _tapped = true,
          child: Container(
            width: 220,
            height: 70,
            decoration: BoxDecoration(color: const Color(0xFF3B82F6), borderRadius: BorderRadius.circular(18)),
            alignment: Alignment.center,
            child: const Text('اضغط', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
          ),
        ),
        const SizedBox(height: 6),
        _t(_note, c: const Color(0xFFA7F3D0)),
        _t('${_round + 1 > rounds ? rounds : _round + 1} من $rounds', c: Colors.white54, size: 12),
      ],
      if (_done) ...[
        _t('خلصت! نجحت في $_good من $rounds 🌟', size: 18),
        const SizedBox(height: 6),
        _t('كل مرة بتتدرب أكتر على الانتظار والتركيز.', c: Colors.white70, size: 13),
        const SizedBox(height: 8),
        KidButton(label: 'تاني', icon: Icons.replay, color: KidTheme.info, onPressed: _start),
      ],
    ]);
  }
}

/// Rule switch: the rule changes between color and shape. Practices flexible thinking.
class RuleSwitchGame extends StatefulWidget {
  final AppStateManager appState;
  final ExtraReact onReact;
  const RuleSwitchGame({super.key, required this.appState, required this.onReact});
  @override
  State<RuleSwitchGame> createState() => _RuleSwitchState();
}

class _RuleSwitchState extends State<RuleSwitchGame> {
  static const int rounds = 8;
  static const List<Color> _colors = [Color(0xFFEF4444), Color(0xFF3B82F6), Color(0xFF22C55E), Color(0xFFF59E0B)];
  static const List<String> _colorNames = ['أحمر', 'أزرق', 'أخضر', 'أصفر'];
  static const List<IconData> _shapes = [Icons.circle, Icons.square, Icons.change_history, Icons.star];
  final Random _r = Random();
  int _round = 0;
  int _good = 0;
  bool _byColor = true;
  late int _tc, _ts; // target color / shape
  late List<List<int>> _opts; // [color, shape]
  late int _right;
  bool _done = false;
  String _note = '';

  @override
  void initState() {
    super.initState();
    _make();
  }

  void _make() {
    _byColor = (_round ~/ 2).isEven;
    _tc = _r.nextInt(4);
    _ts = _r.nextInt(4);
    final int oc = (_tc + 1 + _r.nextInt(3)) % 4;
    final int os = (_ts + 1 + _r.nextInt(3)) % 4;
    // option A matches color only, option B matches shape only
    final List<List<int>> o = [
      [_tc, os],
      [oc, _ts]
    ];
    final bool swap = _r.nextBool();
    _opts = swap ? o.reversed.toList() : o;
    _right = _opts.indexWhere((x) => _byColor ? x[0] == _tc : x[1] == _ts);
  }

  void _pick(int i) {
    final bool ok = i == _right;
    if (ok) _good++;
    widget.onReact(ok);
    setState(() => _note = ok ? 'تمام 👏' : 'قريب! خد بالك من القاعدة');
    Future<void>.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      _round++;
      if (_round >= rounds) {
        setState(() => _done = true);
        _win(widget.appState, 'rule_switch', 'غيّر القاعدة');
      } else {
        setState(() {
          _note = '';
          _make();
        });
      }
    });
  }

  Widget _card(int c, int s, {VoidCallback? onTap}) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(16)),
          child: Icon(_shapes[s], color: _colors[c], size: 56),
        ),
      );

  @override
  Widget build(BuildContext context) {
    if (_done) {
      return Column(mainAxisSize: MainAxisSize.min, children: [
        _t('خلصت! صح في $_good من $rounds 🌟', size: 18),
        const SizedBox(height: 8),
        KidButton(
            label: 'تاني',
            icon: Icons.replay,
            color: KidTheme.info,
            onPressed: () => setState(() {
                  _round = 0;
                  _good = 0;
                  _done = false;
                  _make();
                })),
      ]);
    }
    return Column(mainAxisSize: MainAxisSize.min, children: [
      _t('غيّر القاعدة 🔀', size: 18, w: FontWeight.w800),
      const SizedBox(height: 6),
      _t(_byColor ? 'القاعدة الآن: اختر نفس اللون (${_colorNames[_tc]})' : 'القاعدة الآن: اختر نفس الشكل',
          c: const Color(0xFFFCD34D)),
      const SizedBox(height: 10),
      _card(_tc, _ts),
      const SizedBox(height: 10),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        for (int i = 0; i < 2; i++) ...[
          _card(_opts[i][0], _opts[i][1], onTap: () => _pick(i)),
          const SizedBox(width: 14),
        ]
      ]),
      const SizedBox(height: 6),
      _t(_note, c: const Color(0xFFA7F3D0)),
      _t('${_round + 1} من $rounds', c: Colors.white54, size: 12),
    ]);
  }
}

/// Free drawing with an imagination prompt. Nothing is scored or saved.
class DrawImagineGame extends StatefulWidget {
  final AppStateManager appState;
  final ExtraReact onReact;
  const DrawImagineGame({super.key, required this.appState, required this.onReact});
  @override
  State<DrawImagineGame> createState() => _DrawImagineState();
}

class _Stroke {
  final Color color;
  final List<Offset> pts = [];
  _Stroke(this.color);
}

class _DrawImagineState extends State<DrawImagineGame> {
  static const List<String> _prompts = [
    'ارسم بيتًا غريبًا يعيش فيه حيوان',
    'ارسم سيارة تطير. إيه شكلها؟',
    'ارسم صديقًا جديدًا من الفضاء',
    'ارسم أطول برج تقدر تتخيله',
    'ارسم حديقة فيها حاجات مش موجودة',
    'ارسم طريقة تانية لعبور النهر',
  ];
  static const List<Color> _palette = [
    Color(0xFFEF4444), Color(0xFF3B82F6), Color(0xFF22C55E), Color(0xFFF59E0B), Color(0xFFA855F7), Colors.white,
  ];
  final List<_Stroke> _strokes = [];
  Color _color = const Color(0xFFEF4444);
  int _p = Random().nextInt(6);
  bool _rewarded = false;

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      _t('ارسم وتخيّل 🎨', size: 18, w: FontWeight.w800),
      const SizedBox(height: 4),
      _t(_prompts[_p], c: const Color(0xFFFCD34D)),
      const SizedBox(height: 8),
      Container(
        height: 240,
        width: double.infinity,
        decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white24)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: GestureDetector(
            onPanStart: (d) => setState(() => _strokes.add(_Stroke(_color)..pts.add(d.localPosition))),
            onPanUpdate: (d) => setState(() => _strokes.last.pts.add(d.localPosition)),
            child: CustomPaint(painter: _Painter(_strokes), size: Size.infinite),
          ),
        ),
      ),
      const SizedBox(height: 8),
      Wrap(spacing: 8, alignment: WrapAlignment.center, children: [
        for (final Color c in _palette)
          GestureDetector(
            onTap: () => setState(() => _color = c),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(color: c, shape: BoxShape.circle, border: Border.all(color: _color == c ? Colors.amber : Colors.white24, width: 3)),
            ),
          ),
      ]),
      const SizedBox(height: 8),
      Wrap(alignment: WrapAlignment.center, children: [
        TextButton(onPressed: () => setState(() { if (_strokes.isNotEmpty) _strokes.removeLast(); }), child: const Text('تراجع')),
        TextButton(onPressed: () => setState(_strokes.clear), child: const Text('امسح')),
        TextButton(onPressed: () => setState(() { _p = (_p + 1) % _prompts.length; }), child: const Text('فكرة جديدة')),
      ]),
      KidButton(
          label: 'خلصت رسمتي',
          icon: Icons.check,
          color: KidTheme.info,
          onPressed: () {
            widget.onReact(true);
            if (!_rewarded && _strokes.isNotEmpty) {
              _rewarded = true;
              _win(widget.appState, 'draw_imagine', 'ارسم وتخيّل');
            }
          }),
      _t('الرسمة مش بتتحفظ ولا بتتبعت لأي مكان.', c: Colors.white54, size: 12),
    ]);
  }
}

class _Painter extends CustomPainter {
  final List<_Stroke> strokes;
  _Painter(this.strokes);
  @override
  void paint(Canvas canvas, Size size) {
    for (final _Stroke s in strokes) {
      final Paint p = Paint()
        ..color = s.color
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      if (s.pts.length == 1) canvas.drawCircle(s.pts.first, 2.5, p..style = PaintingStyle.fill);
      for (int i = 1; i < s.pts.length; i++) {
        canvas.drawLine(s.pts[i - 1], s.pts[i], p);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _Painter old) => true;
}
