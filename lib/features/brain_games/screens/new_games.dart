import 'dart:math';
import 'package:haneen_kids_vod/core/localization/tr.dart';
import 'package:flutter/material.dart';
import 'package:haneen_kids_vod/haneen_kids_exports.dart';

typedef GameReact = void Function(bool correct);

List<String> _kLetters = [
  'ا', 'ب', 'ت', 'ث', 'ج', 'ح', 'خ', 'د', 'ذ', 'ر', 'ز', 'س', 'ش', 'ص',
  tr('ض'), tr('ط'), tr('ظ'), tr('ع'), tr('غ'), tr('ف'), tr('ق'), tr('ك'), tr('ل'), tr('م'), tr('ن'), tr('هـ'), tr('و'), tr('ي')
];

Future<void> _win(AppStateManager s, String id, String title) =>
    s.recordBrainGameWin(
        gameId: id, gameTitle: title, earnedIqPoints: 10, earnedStars: 1);

class _Stroke {
  final List<Offset> pts = [];
  final Color color;
  final double width;
  _Stroke(this.color, this.width);
}

class _StrokesPainter extends CustomPainter {
  final List<_Stroke> strokes;
  _StrokesPainter(this.strokes);
  @override
  void paint(Canvas canvas, Size size) {
    for (final _Stroke s in strokes) {
      final Paint p = Paint()
        ..color = s.color
        ..strokeWidth = s.width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      if (s.pts.length == 1) {
        canvas.drawCircle(s.pts.first, s.width / 2, p..style = PaintingStyle.fill);
        continue;
      }
      final Path path = Path()..moveTo(s.pts.first.dx, s.pts.first.dy);
      for (int i = 1; i < s.pts.length; i++) {
        final Offset a = s.pts[i - 1], b = s.pts[i];
        path.quadraticBezierTo(
            a.dx, a.dy, (a.dx + b.dx) / 2, (a.dy + b.dy) / 2);
      }
      canvas.drawPath(path, p);
    }
  }

  @override
  bool shouldRepaint(covariant _StrokesPainter old) => true;
}

// ---------------------------------------------------------------- tracing
class TraceLetterGame extends StatefulWidget {
  final AppStateManager appState;
  final GameReact onReact;
  const TraceLetterGame(
      {super.key, required this.appState, required this.onReact});
  @override
  State<TraceLetterGame> createState() => _TraceLetterGameState();
}

class _TraceLetterGameState extends State<TraceLetterGame> {
  int _i = 0;
  final List<_Stroke> _strokes = [];
  final Set<int> _cells = {};
  static const double _box = 280;

  @override
  void initState() {
    super.initState();
    HintVoiceService.instance.play('hint_trace_letter', oncePerSession: true);
  }

  void _mark(Offset p) {
    final int cx = (p.dx / (_box / 5)).floor().clamp(0, 4);
    final int cy = (p.dy / (_box / 5)).floor().clamp(0, 4);
    _cells.add(cy * 5 + cx);
  }

  Future<void> _done() async {
    if (_cells.length < 7) {
      HintVoiceService.instance.play('hint_try_again');
      widget.onReact(false);
      return;
    }
    widget.onReact(true);
    HintVoiceService.instance.play('hint_great');
    await _win(widget.appState, 'trace_letter_$_i', tr('تتبّع الحروف'));
    setState(() {
      _i = (_i + 1) % _kLetters.length;
      _strokes.clear();
      _cells.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Text(tr('✏️ امشي بصباعك على الحرف'),
          style: TextStyle(
              color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
      const SizedBox(height: 10),
      Container(
        width: _box,
        height: _box,
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(22)),
        child: GestureDetector(
          onPanStart: (d) => setState(() {
            _strokes.add(_Stroke(const Color(0xFF10B981), 16)
              ..pts.add(d.localPosition));
            _mark(d.localPosition);
          }),
          onPanUpdate: (d) => setState(() {
            _strokes.last.pts.add(d.localPosition);
            _mark(d.localPosition);
          }),
          child: Stack(alignment: Alignment.center, children: [
            Text(_kLetters[_i],
                style: TextStyle(
                    fontSize: 200,
                    fontWeight: FontWeight.w900,
                    color: Colors.grey.withOpacity(0.35))),
            CustomPaint(
                size: const Size(_box, _box),
                painter: _StrokesPainter(_strokes)),
          ]),
        ),
      ),
      const SizedBox(height: 12),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        OutlinedButton.icon(
            onPressed: () => setState(() {
                  _strokes.clear();
                  _cells.clear();
                }),
            icon: const Icon(Icons.refresh),
            label: Text(tr('من الأول'))),
        const SizedBox(width: 12),
        ElevatedButton.icon(
            onPressed: _done,
            icon: const Icon(Icons.check),
            label: Text(tr('خلصت'))),
      ]),
    ]);
  }
}

// --------------------------------------------------------------- counting
class CountPicsGame extends StatefulWidget {
  final AppStateManager appState;
  final GameReact onReact;
  const CountPicsGame(
      {super.key, required this.appState, required this.onReact});
  @override
  State<CountPicsGame> createState() => _CountPicsGameState();
}

class _CountPicsGameState extends State<CountPicsGame> {
  static const List<String> _pics = ['🍎', '⭐', '🐟', '🎈', '🐥', '🚗', '🌸'];
  final Random _r = Random();
  int _round = 0;
  late String _pic;
  late int _a, _b;
  late bool _add;
  late List<int> _options;

  @override
  void initState() {
    super.initState();
    _next();
    HintVoiceService.instance.play('hint_count_pics', oncePerSession: true);
  }

  int get _answer => _add ? _a + _b : _a;

  void _next() {
    _pic = _pics[_r.nextInt(_pics.length)];
    _add = _round >= 3 && _round % 2 == 1;
    _a = 1 + _r.nextInt(_add ? 5 : 9);
    _b = _add ? 1 + _r.nextInt(5) : 0;
    final Set<int> o = {_answer};
    while (o.length < 3) {
      final int v = max(1, _answer + _r.nextInt(5) - 2);
      o.add(v);
    }
    _options = o.toList()..shuffle(_r);
  }

  Future<void> _pick(int v) async {
    if (v == _answer) {
      widget.onReact(true);
      HintVoiceService.instance.play('hint_great');
      await _win(widget.appState, 'count_pics', tr('عدّ وجمّع بالصور'));
      setState(() {
        _round++;
        _next();
      });
    } else {
      widget.onReact(false);
      HintVoiceService.instance.play('hint_try_again');
    }
  }

  Widget _group(int n) => Wrap(
      alignment: WrapAlignment.center,
      children: [for (int i = 0; i < n; i++) Text(_pic, style: const TextStyle(fontSize: 34))]);

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Text(_add ? tr('➕ كام الإجمالي؟') : tr('🔢 عُد الصور'),
          style: const TextStyle(
              color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
      const SizedBox(height: 12),
      if (_add)
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Flexible(child: _group(_a)),
          const Padding(
              padding: EdgeInsets.all(8),
              child: Text('+',
                  style: TextStyle(color: Colors.white, fontSize: 30))),
          Flexible(child: _group(_b)),
        ])
      else
        _group(_a),
      const SizedBox(height: 18),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        for (final int v in _options)
          Padding(
            padding: const EdgeInsets.all(6),
            child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    minimumSize: Size(72, 72),
                    textStyle: TextStyle(
                        fontSize: 28, fontWeight: FontWeight.w900)),
                onPressed: () => _pick(v),
                child: Text('$v')),
          ),
      ]),
    ]);
  }
}

// ------------------------------------------------------------ shape sorting
class ShapeSortGame extends StatefulWidget {
  final AppStateManager appState;
  final GameReact onReact;
  ShapeSortGame(
      {super.key, required this.appState, required this.onReact});
  @override
  State<ShapeSortGame> createState() => _ShapeSortGameState();
}

class _SItem {
  final String glyph;
  final Color color;
  final String shapeName;
  final String colorName;
  _SItem(this.glyph, this.color, this.shapeName, this.colorName);
}

class _ShapeSortGameState extends State<ShapeSortGame> {
  static Color red = Color(0xFFEF4444), blue = Color(0xFF3B82F6);
  static List<_SItem> _all = [
    _SItem('●', red, tr('دايرة'), tr('أحمر')),
    _SItem('■', red, tr('مربع'), tr('أحمر')),
    _SItem('▲', red, tr('مثلث'), tr('أحمر')),
    _SItem('●', blue, tr('دايرة'), tr('أزرق')),
    _SItem('■', blue, tr('مربع'), tr('أزرق')),
    _SItem('▲', blue, tr('مثلث'), tr('أزرق')),
  ];
  final Random _r = Random();
  bool _byColor = true;
  late List<_SItem> _items;
  late List<String> _bins;
  int _placed = 0;

  @override
  void initState() {
    super.initState();
    _newRound();
    HintVoiceService.instance.play('hint_sort_shapes', oncePerSession: true);
  }

  void _newRound() {
    _placed = 0;
    if (_byColor) {
      _bins = [tr('أحمر'), tr('أزرق')];
    } else {
      _bins = ([tr('دايرة'), tr('مربع'), tr('مثلث')]..shuffle(_r)).take(2).toList();
    }
    final List<_SItem> pool = _byColor
        ? _all
        : _all.where((e) => _bins.contains(e.shapeName)).toList();
    _items = (List<_SItem>.of(pool)..shuffle(_r)).take(4).toList();
  }

  String _keyOf(_SItem i) => _byColor ? i.colorName : i.shapeName;

  Future<void> _drop(_SItem item, String bin) async {
    if (_keyOf(item) == bin) {
      widget.onReact(true);
      setState(() {
        _items.remove(item);
        _placed++;
      });
      if (_items.isEmpty) {
        HintVoiceService.instance.play('hint_great');
        await _win(widget.appState, 'shape_sort', tr('رتّب الأشكال والألوان'));
        setState(() {
          _byColor = !_byColor;
          _newRound();
        });
      }
    } else {
      widget.onReact(false);
      HintVoiceService.instance.play('hint_try_again');
    }
  }

  Widget _chip(_SItem i, {double op = 1}) => Opacity(
      opacity: op,
      child: Text(i.glyph, style: TextStyle(fontSize: 54, color: i.color)));

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Text(_byColor ? tr('🎨 رتّب حسب اللون') : tr('🔷 رتّب حسب الشكل'),
          style: const TextStyle(
              color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
      const SizedBox(height: 10),
      Wrap(spacing: 14, children: [
        for (final _SItem i in _items)
          Draggable<_SItem>(
            data: i,
            feedback: Material(color: Colors.transparent, child: _chip(i)),
            childWhenDragging: _chip(i, op: 0.25),
            child: _chip(i),
          ),
      ]),
      const SizedBox(height: 14),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        for (final String b in _bins)
          Expanded(
            child: DragTarget<_SItem>(
              onAcceptWithDetails: (d) => _drop(d.data, b),
              builder: (ctx, cand, rej) => Container(
                height: 110,
                margin: const EdgeInsets.all(8),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    color: cand.isNotEmpty
                        ? Colors.white24
                        : const Color(0xFF334155),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white38, width: 2)),
                child: Text(b,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800)),
              ),
            ),
          ),
      ]),
    ]);
  }
}

// ------------------------------------------------------- draw your imagination
class ImagineDrawGame extends StatefulWidget {
  final AppStateManager appState;
  final GameReact onReact;
  const ImagineDrawGame(
      {super.key, required this.appState, required this.onReact});
  @override
  State<ImagineDrawGame> createState() => _ImagineDrawGameState();
}

class _ImagineDrawGameState extends State<ImagineDrawGame> {
  static const List<Color> _palette = [
    Color(0xFF111827), Color(0xFFEF4444), Color(0xFFF59E0B), Color(0xFF10B981),
    Color(0xFF3B82F6), Color(0xFF8B5CF6), Color(0xFFEC4899),
  ];
  static const List<String> _asks = ['hint_draw_ask_1', 'hint_draw_ask_2'];
  final List<_Stroke> _strokes = [];
  Color _color = _palette[1];
  int _ask = 0;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    HintVoiceService.instance.play('hint_draw_imagine', oncePerSession: true);
  }

  Future<void> _finish() async {
    if (_strokes.length < 3) {
      HintVoiceService.instance.play('hint_draw_start');
      return;
    }
    setState(() => _finished = true);
    widget.onReact(true);
    HintVoiceService.instance.play('hint_draw_done');
    await _win(widget.appState, 'imagine_draw', tr('ارسم خيالك'));
  }

  void _again() {
    setState(() {
      _strokes.clear();
      _finished = false;
      _ask = (_ask + 1) % _asks.length;
    });
    HintVoiceService.instance.play(_asks[_ask]);
  }

  @override
  Widget build(BuildContext context) {
    final String q = HintVoiceService.lines[_asks[_ask]]!;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Text('🖍️ $q',
          textAlign: TextAlign.center,
          style: const TextStyle(
              color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
      const SizedBox(height: 8),
      Container(
        height: 300,
        width: double.infinity,
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(22)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: GestureDetector(
            onPanStart: _finished
                ? null
                : (d) => setState(() =>
                    _strokes.add(_Stroke(_color, 9)..pts.add(d.localPosition))),
            onPanUpdate: _finished
                ? null
                : (d) => setState(() => _strokes.last.pts.add(d.localPosition)),
            child: CustomPaint(
                size: Size.infinite, painter: _StrokesPainter(_strokes)),
          ),
        ),
      ),
      const SizedBox(height: 8),
      Wrap(spacing: 8, children: [
        for (final Color c in _palette)
          GestureDetector(
            onTap: () => setState(() => _color = c),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                  color: c,
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: _color == c ? Colors.white : Colors.transparent,
                      width: 3)),
            ),
          ),
      ]),
      const SizedBox(height: 8),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        OutlinedButton(
            onPressed: _strokes.isEmpty || _finished
                ? null
                : () => setState(() => _strokes.removeLast()),
            child: Text(tr('تراجع'))),
        const SizedBox(width: 10),
        _finished
            ? ElevatedButton(onPressed: _again, child: Text(tr('رسمة جديدة')))
            : ElevatedButton(onPressed: _finish, child: Text(tr('خلصت'))),
      ]),
    ]);
  }
}
