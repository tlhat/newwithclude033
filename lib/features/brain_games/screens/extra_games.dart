import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:haneen_kids_vod/core/theme/kid_theme.dart';
import 'package:haneen_kids_vod/haneen_kids_exports.dart';
import 'world_games.dart';
import 'dev_games.dart';
import 'package:haneen_kids_vod/features/development/dev_core.dart';

typedef ExtraReact = void Function(bool correct);

/// Hub cards for games that are real widgets (not JSON questions).
class WidgetGameDef {
  final String id;
  final String title;
  final String icon;
  final String hint;
  final int color;
  const WidgetGameDef(this.id, this.title, this.icon, this.hint, this.color);
}

const List<WidgetGameDef> kWidgetGames = [
  WidgetGameDef('letter_catcher', 'صائد الحروف', '🎣', 'امسك الحرف المطلوب قبل ما ينزل', 0xFF14B8A6),
  WidgetGameDef('clock_set', 'اضبط عقارب الساعة', '🕒', 'حرّك العقارب على الوقت', 0xFFF59E0B),
  WidgetGameDef('shadow_match', 'ظل الصورة', '🌑', 'اعرف صاحب الظل', 0xFF6366F1),
  WidgetGameDef('slide_puzzle', 'بازل الأرقام', '🧩', 'رتّب القطع من ١ لـ ٨', 0xFFEC4899),
  WidgetGameDef('maze', 'المتاهة', '🌀', 'وصّل حنين للنجمة', 0xFF22C55E),
  WidgetGameDef('stop_go', 'قف وامشِ', '🚦', 'أخضر اضغط وأحمر استنى', 0xFF22C55E),
  WidgetGameDef('rule_switch', 'غيّر القاعدة', '🔀', 'مرة باللون ومرة بالشكل', 0xFF6366F1),
  WidgetGameDef('draw_imagine', 'ارسم وتخيّل', '🎨', 'ارسم فكرة من خيالك', 0xFFEC4899),
  WidgetGameDef('daily_challenge', 'تحدي اليوم', '📅', '٥ أسئلة قصيرة كل يوم', 0xFFEF4444),
  WidgetGameDef('haneen_house', 'بيت حنين', '🏠', 'زيّن البيت بنجومك', 0xFF7C5E3C),
  WidgetGameDef('haneen_pet', 'كتكوت حنين', '🐣', 'اعتني بالكتكوت وهو يكبر', 0xFFF59E0B),
  WidgetGameDef('sticker_album', 'ألبوم الملصقات', '🏅', 'اجمع الملصقات والجوائز', 0xFFA855F7),
  WidgetGameDef('certificate', 'شهادة التقدير', '🏆', 'شهادتك داخل التطبيق', 0xFFD4A017),
  WidgetGameDef('bedtime', 'حدوتة قبل النوم', '🌙', 'الإضاءة بتخفت مع الحدوتة', 0xFF1E3A8A),
  WidgetGameDef('dad_voice', 'صوت بابا بيحكي', '🎙️', 'سجّل حدوتة بصوتك', 0xFF0EA5E9),
  WidgetGameDef('screen_free', 'وضع بدون شاشة', '🗣️', 'أسئلة شفهية مع الأب أو الأم', 0xFF10B981),
  WidgetGameDef('plant_care', 'اعتني بالنبتة', '🌱', 'اسقِها وعرّضها للشمس لتكبر', 0xFF84CC16),
];

/// Plays the spoken intro of a widget game once when it opens.
class _GameIntro extends StatefulWidget {
  final String id;
  final Widget child;
  const _GameIntro({super.key, required this.id, required this.child});
  @override
  State<_GameIntro> createState() => _GameIntroState();
}

class _GameIntroState extends State<_GameIntro> {
  @override
  void initState() {
    super.initState();
    GuideVoice.instance.widgetStart(widget.id);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

Widget buildWidgetGame(String id, AppStateManager s, ExtraReact rawReact) {
  return _GameIntro(
      key: ValueKey<String>('intro_$id'),
      id: id,
      child: _buildWidgetGameInner(id, s, rawReact));
}

Widget _buildWidgetGameInner(String id, AppStateManager s, ExtraReact rawReact) {
  // Every widget game reports each answer to the local developmental log.
  void react(bool ok) {
    DevStore.logAttempt(s.currentAccount?.activeChild.id ?? '', id, id, ok);
    rawReact(ok);
    if (ok) {
      GuideVoice.instance.right();
    } else {
      GuideVoice.instance.wrong();
    }
  }

  switch (id) {
    case 'stop_go':
      return StopGoGame(appState: s, onReact: react);
    case 'rule_switch':
      return RuleSwitchGame(appState: s, onReact: react);
    case 'draw_imagine':
      return DrawImagineGame(appState: s, onReact: react);
    case 'letter_catcher':
      return LetterCatcherGame(appState: s, onReact: react);
    case 'clock_set':
      return ClockSetGame(appState: s, onReact: react);
    case 'shadow_match':
      return ShadowMatchGame(appState: s, onReact: react);
    case 'slide_puzzle':
      return SlidePuzzleGame(appState: s, onReact: react);
    case 'maze':
      return MazeGame(appState: s, onReact: react);
    case 'plant_care':
      return PlantCareGame(appState: s, onReact: react);
    default:
      return buildWorldGame(id, s);
  }
}

Future<void> _win(AppStateManager s, String id, String title) =>
    s.recordBrainGameWin(
        gameId: id, gameTitle: title, earnedIqPoints: 10, earnedStars: 1);

Text _head(String t) => Text(t,
    textAlign: TextAlign.center,
    style: const TextStyle(
        color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800));

// ------------------------------------------------------------ letter catcher
class LetterCatcherGame extends StatefulWidget {
  final AppStateManager appState;
  final ExtraReact onReact;
  const LetterCatcherGame({super.key, required this.appState, required this.onReact});
  @override
  State<LetterCatcherGame> createState() => _LetterCatcherState();
}

class _LetterCatcherState extends State<LetterCatcherGame>
    with SingleTickerProviderStateMixin {
  static const List<String> _l = ['ا', 'ب', 'ت', 'ج', 'د', 'ر', 'س', 'ش', 'م', 'ن', 'ه', 'و'];
  final Random _r = Random();
  late AnimationController _c;
  late String _target;
  late List<String> _falling;
  int _score = 0;
  bool _locked = false;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 7))
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) _round();
      });
    _round();
  }

  void _round() {
    final List<String> p = List<String>.of(_l)..shuffle(_r);
    _falling = p.take(4).toList();
    _target = _falling[_r.nextInt(4)];
    _locked = false;
    _c.forward(from: 0);
    if (mounted) setState(() {});
  }

  Future<void> _tap(String l) async {
    if (_locked) return;
    if (l == _target) {
      _locked = true;
      _c.stop();
      widget.onReact(true);
      _score++;
      await _win(widget.appState, 'letter_catcher', 'صائد الحروف');
      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (mounted) _round();
    } else {
      widget.onReact(false);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      _head('امسك حرف ($_target)   ⭐ $_score'),
      const SizedBox(height: 8),
      SizedBox(
        height: 260,
        child: LayoutBuilder(builder: (ctx, bc) {
          return AnimatedBuilder(
              animation: _c,
              builder: (ctx, _) {
                return Stack(children: [
                  for (int i = 0; i < _falling.length; i++)
                    Positioned(
                      left: (bc.maxWidth - 64) * (i + 0.5) / _falling.length - 10,
                      top: (_c.value * (260 - 64) * (0.7 + 0.1 * i)).clamp(0, 196),
                      child: GestureDetector(
                        onTap: () => _tap(_falling[i]),
                        child: Container(
                          width: 64,
                          height: 64,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                              color: KidTheme.info,
                              borderRadius: BorderRadius.circular(32)),
                          child: Text(_falling[i],
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 34,
                                  fontWeight: FontWeight.w900)),
                        ),
                      ),
                    ),
                ]);
              });
        }),
      ),
    ]);
  }
}

// --------------------------------------------------------------------- clock
/// Pure helper: hands angles in radians from 12 o'clock.
class ClockMath {
  static double hourAngle(int h, int m) => ((h % 12) + m / 60) * 2 * pi / 12;
  static double minuteAngle(int m) => m * 2 * pi / 60;
  static String label(int h, int m) {
    const String ar = '٠١٢٣٤٥٦٧٨٩';
    String t(int n) => n.toString().split('').map((c) => ar[int.parse(c)]).join();
    return '${t(h)}:${m.toString().padLeft(2, '0').split('').map((c) => ar[int.parse(c)]).join()}';
  }
}

class _ClockPainter extends CustomPainter {
  final int h, m;
  _ClockPainter(this.h, this.m);
  @override
  void paint(Canvas canvas, Size size) {
    final Offset c = size.center(Offset.zero);
    final double rad = size.width / 2 - 4;
    canvas.drawCircle(c, rad, Paint()..color = Colors.white);
    canvas.drawCircle(c, rad, Paint()
      ..color = KidTheme.info
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6);
    for (int i = 1; i <= 12; i++) {
      final double a = i * pi / 6;
      final TextPainter tp = TextPainter(
          text: TextSpan(
              text: '$i',
              style: const TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.w800)),
          textDirection: TextDirection.ltr)
        ..layout();
      final Offset p = c + Offset(sin(a), -cos(a)) * (rad - 22);
      tp.paint(canvas, p - Offset(tp.width / 2, tp.height / 2));
    }
    void hand(double a, double len, double w, Color col) {
      canvas.drawLine(c, c + Offset(sin(a), -cos(a)) * len,
          Paint()
            ..color = col
            ..strokeWidth = w
            ..strokeCap = StrokeCap.round);
    }
    hand(ClockMath.hourAngle(h, m), rad * 0.45, 8, Colors.black87);
    hand(ClockMath.minuteAngle(m), rad * 0.7, 5, KidTheme.danger);
    canvas.drawCircle(c, 6, Paint()..color = Colors.black87);
  }

  @override
  bool shouldRepaint(covariant _ClockPainter o) => o.h != h || o.m != m;
}

class ClockSetGame extends StatefulWidget {
  final AppStateManager appState;
  final ExtraReact onReact;
  const ClockSetGame({super.key, required this.appState, required this.onReact});
  @override
  State<ClockSetGame> createState() => _ClockSetState();
}

class _ClockSetState extends State<ClockSetGame> {
  final Random _r = Random();
  int _round = 0;
  late int _th, _tm;
  int _h = 12, _m = 0;
  String? _msg;

  @override
  void initState() {
    super.initState();
    _next();
  }

  void _next() {
    _th = 1 + _r.nextInt(12);
    _tm = _round < 3 ? 0 : (_round < 6 ? 30 : [0, 15, 30, 45][_r.nextInt(4)]);
    _h = 12;
    _m = 0;
    _msg = null;
  }

  Future<void> _check() async {
    if (_h == _th && _m == _tm) {
      widget.onReact(true);
      setState(() => _msg = 'برافو! 🎉');
      await _win(widget.appState, 'clock_set', 'اضبط عقارب الساعة');
      await Future<void>.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;
      setState(() {
        _round++;
        _next();
      });
    } else {
      widget.onReact(false);
      setState(() => _msg = 'قريب! الساعة الصغيرة للساعات والكبيرة للدقايق.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      _head('اضبط الساعة على ${ClockMath.label(_th, _tm)}'),
      const SizedBox(height: 8),
      SizedBox(width: 190, height: 190, child: CustomPaint(painter: _ClockPainter(_h, _m))),
      const SizedBox(height: 8),
      Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center, children: [
        KidButton(label: 'ساعة −', color: KidTheme.surfaceHigh, onPressed: () => setState(() => _h = _h == 1 ? 12 : _h - 1)),
        KidButton(label: 'ساعة +', color: KidTheme.surfaceHigh, onPressed: () => setState(() => _h = _h == 12 ? 1 : _h + 1)),
        KidButton(label: 'دقيقة −', color: KidTheme.surfaceHigh, onPressed: () => setState(() => _m = (_m + 45) % 60)),
        KidButton(label: 'دقيقة +', color: KidTheme.surfaceHigh, onPressed: () => setState(() => _m = (_m + 15) % 60)),
      ]),
      const SizedBox(height: 8),
      if (_msg != null) Text(_msg!, style: const TextStyle(color: Colors.white, fontSize: 16)),
      KidButton(label: 'تأكيد', icon: Icons.check, onPressed: _check),
    ]);
  }
}

// -------------------------------------------------------------------- shadow
class ShadowMatchGame extends StatefulWidget {
  final AppStateManager appState;
  final ExtraReact onReact;
  const ShadowMatchGame({super.key, required this.appState, required this.onReact});
  @override
  State<ShadowMatchGame> createState() => _ShadowState();
}

class _ShadowState extends State<ShadowMatchGame> {
  static const List<String> _all = ['🐘', '🐱', '🐟', '🦋', '🚗', '🏠', '🌳', '⭐', '🐢', '✈️', '🍎', '🦒'];
  final Random _r = Random();
  late String _ans;
  late List<String> _opts;

  @override
  void initState() {
    super.initState();
    _next();
  }

  void _next() {
    final List<String> p = List<String>.of(_all)..shuffle(_r);
    _opts = p.take(3).toList();
    _ans = _opts[_r.nextInt(3)];
  }

  Future<void> _pick(String e) async {
    if (e == _ans) {
      widget.onReact(true);
      await _win(widget.appState, 'shadow_match', 'ظل الصورة');
      setState(_next);
    } else {
      widget.onReact(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      _head('ده ظل مين؟'),
      const SizedBox(height: 10),
      ColorFiltered(
        colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn),
        child: Text(_ans, style: const TextStyle(fontSize: 110)),
      ),
      const SizedBox(height: 10),
      Wrap(spacing: 14, children: [
        for (final String e in _opts)
          GestureDetector(
            onTap: () => _pick(e),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: KidTheme.surfaceHigh,
                  borderRadius: BorderRadius.circular(KidTheme.rMedium)),
              child: Text(e, style: const TextStyle(fontSize: 48)),
            ),
          ),
      ]),
    ]);
  }
}

// ------------------------------------------------------------- slide puzzle
class SlidePuzzle {
  /// 3x3 board, 0 is the blank. Always solvable: starts solved, then moves.
  static List<int> shuffled(Random r, {int moves = 40}) {
    final List<int> b = [1, 2, 3, 4, 5, 6, 7, 8, 0];
    int blank = 8;
    int last = -1;
    for (int i = 0; i < moves; i++) {
      final List<int> n = neighbors(blank)..remove(last);
      final int t = n[r.nextInt(n.length)];
      b[blank] = b[t];
      b[t] = 0;
      last = blank;
      blank = t;
    }
    return b;
  }

  static List<int> neighbors(int i) {
    final int x = i % 3, y = i ~/ 3;
    return [
      if (x > 0) i - 1,
      if (x < 2) i + 1,
      if (y > 0) i - 3,
      if (y < 2) i + 3,
    ];
  }

  static bool solved(List<int> b) {
    for (int i = 0; i < 8; i++) {
      if (b[i] != i + 1) return false;
    }
    return b[8] == 0;
  }
}

class SlidePuzzleGame extends StatefulWidget {
  final AppStateManager appState;
  final ExtraReact onReact;
  const SlidePuzzleGame({super.key, required this.appState, required this.onReact});
  @override
  State<SlidePuzzleGame> createState() => _SlidePuzzleState();
}

class _SlidePuzzleState extends State<SlidePuzzleGame> {
  final Random _r = Random();
  late List<int> _b;
  int _moves = 0;

  @override
  void initState() {
    super.initState();
    _newGame(10);
  }

  void _newGame(int m) {
    _b = SlidePuzzle.shuffled(_r, moves: m);
    if (SlidePuzzle.solved(_b)) _b = SlidePuzzle.shuffled(_r, moves: m + 6);
    _moves = 0;
  }

  Future<void> _tap(int i) async {
    final int blank = _b.indexOf(0);
    if (!SlidePuzzle.neighbors(blank).contains(i)) return;
    setState(() {
      _b[blank] = _b[i];
      _b[i] = 0;
      _moves++;
    });
    if (SlidePuzzle.solved(_b)) {
      widget.onReact(true);
      await _win(widget.appState, 'slide_puzzle', 'بازل الأرقام');
      await Future<void>.delayed(const Duration(milliseconds: 700));
      if (mounted) setState(() => _newGame(10 + 6 * min(3, _moves ~/ 8)));
    }
  }

  @override
  Widget build(BuildContext context) {
    const List<String> ar = ['', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨'];
    return Column(mainAxisSize: MainAxisSize.min, children: [
      _head('رتّب الأرقام من ١ لـ ٨ والخانة الفاضية في الآخر'),
      const SizedBox(height: 10),
      SizedBox(
        width: 228,
        child: Wrap(spacing: 6, runSpacing: 6, children: [
          for (int i = 0; i < 9; i++)
            GestureDetector(
              onTap: () => _tap(i),
              child: Container(
                width: 70,
                height: 70,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    color: _b[i] == 0 ? Colors.white10 : KidTheme.info,
                    borderRadius: BorderRadius.circular(KidTheme.rSmall)),
                child: Text(ar[_b[i]],
                    style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
              ),
            ),
        ]),
      ),
      const SizedBox(height: 8),
      Text('عدد الحركات: $_moves', style: const TextStyle(color: Colors.white70)),
      TextButton(onPressed: () => setState(() => _newGame(10)), child: const Text('من الأول')),
    ]);
  }
}

// ---------------------------------------------------------------------- maze
class MazeData {
  /// '#' wall, '.' path, 'S' start, 'E' end.
  static const List<List<String>> levels = [
    ['S..#.', '.#.#.', '.#...', '.####', '....E'],
    ['S.#...', '..#.#.', '#...#.', '..###.', '.#...E', '.....#'],
    ['S#....#', '.#.##.#', '.#..#..', '.##.#.#', '.#..#.#', '...##..', '#.....E'],
  ];

  static bool solvable(List<String> g) {
    final int h = g.length, w = g[0].length;
    int sy = 0, sx = 0;
    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        if (g[y][x] == 'S') {
          sy = y;
          sx = x;
        }
      }
    }
    final Set<int> seen = {sy * w + sx};
    final List<int> q = [sy * w + sx];
    while (q.isNotEmpty) {
      final int c = q.removeLast();
      final int y = c ~/ w, x = c % w;
      if (g[y][x] == 'E') return true;
      for (final List<int> d in [[0, 1], [1, 0], [0, -1], [-1, 0]]) {
        final int ny = y + d[0], nx = x + d[1];
        if (ny < 0 || nx < 0 || ny >= h || nx >= w) continue;
        if (g[ny][nx] == '#' || !seen.add(ny * w + nx)) continue;
        q.add(ny * w + nx);
      }
    }
    return false;
  }
}

class MazeGame extends StatefulWidget {
  final AppStateManager appState;
  final ExtraReact onReact;
  const MazeGame({super.key, required this.appState, required this.onReact});
  @override
  State<MazeGame> createState() => _MazeState();
}

class _MazeState extends State<MazeGame> {
  int _lv = 0;
  late int _y, _x;

  List<String> get _g => MazeData.levels[_lv % MazeData.levels.length];

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    for (int y = 0; y < _g.length; y++) {
      for (int x = 0; x < _g[0].length; x++) {
        if (_g[y][x] == 'S') {
          _y = y;
          _x = x;
        }
      }
    }
  }

  Future<void> _move(int dy, int dx) async {
    final int ny = _y + dy, nx = _x + dx;
    if (ny < 0 || nx < 0 || ny >= _g.length || nx >= _g[0].length) return;
    if (_g[ny][nx] == '#') {
      widget.onReact(false);
      return;
    }
    setState(() {
      _y = ny;
      _x = nx;
    });
    if (_g[ny][nx] == 'E') {
      widget.onReact(true);
      await _win(widget.appState, 'maze', 'المتاهة');
      await Future<void>.delayed(const Duration(milliseconds: 600));
      if (mounted) {
        setState(() {
          _lv++;
          _reset();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<String> g = _g;
    const double cell = 40;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      _head('وصّل حنين 🧒 للنجمة ⭐ (مرحلة ${_lv + 1})'),
      const SizedBox(height: 8),
      Directionality(
        textDirection: TextDirection.ltr,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          for (int y = 0; y < g.length; y++)
            Row(mainAxisSize: MainAxisSize.min, children: [
              for (int x = 0; x < g[0].length; x++)
                Container(
                  width: cell,
                  height: cell,
                  alignment: Alignment.center,
                  color: g[y][x] == '#' ? KidTheme.surfaceHigh : Colors.white12,
                  child: Text(
                      (y == _y && x == _x) ? '🧒' : (g[y][x] == 'E' ? '⭐' : ''),
                      style: const TextStyle(fontSize: 26)),
                ),
            ]),
        ]),
      ),
      const SizedBox(height: 8),
      Directionality(
        textDirection: TextDirection.ltr,
        child: Column(children: [
          IconButton(iconSize: 40, onPressed: () => _move(-1, 0), icon: const Icon(Icons.keyboard_arrow_up, color: Colors.white)),
          Row(mainAxisSize: MainAxisSize.min, children: [
            IconButton(iconSize: 40, onPressed: () => _move(0, -1), icon: const Icon(Icons.keyboard_arrow_left, color: Colors.white)),
            const SizedBox(width: 30),
            IconButton(iconSize: 40, onPressed: () => _move(0, 1), icon: const Icon(Icons.keyboard_arrow_right, color: Colors.white)),
          ]),
          IconButton(iconSize: 40, onPressed: () => _move(1, 0), icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white)),
        ]),
      ),
    ]);
  }
}

// --------------------------------------------------------------------- plant
/// Pure growth rule: stage 0..4 from care counts. Water and sun both needed.
class PlantGrowth {
  static int stage(int water, int sun) => min(4, min(water, sun) ~/ 2);
  static const List<String> icons = ['🌰', '🌱', '🌿', '🪴', '🌻'];
  static const List<String> names = ['بذرة', 'نبتة صغيرة', 'نبتة تكبر', 'نبتة كبيرة', 'زهرة عباد الشمس'];
}

class PlantCareGame extends StatefulWidget {
  final AppStateManager appState;
  final ExtraReact onReact;
  const PlantCareGame({super.key, required this.appState, required this.onReact});
  @override
  State<PlantCareGame> createState() => _PlantState();
}

class _PlantState extends State<PlantCareGame> {
  int _water = 0, _sun = 0;
  SharedPreferences? _sp;
  String get _k => 'plant_${widget.appState.currentAccount?.activeChild.id}';

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) {
      _sp = p;
      final List<String> v = (p.getString(_k) ?? '0,0').split(',');
      if (mounted) {
        setState(() {
          _water = int.tryParse(v[0]) ?? 0;
          _sun = int.tryParse(v.length > 1 ? v[1] : '0') ?? 0;
        });
      }
    });
  }

  Future<void> _care(bool water) async {
    final int before = PlantGrowth.stage(_water, _sun);
    setState(() => water ? _water++ : _sun++);
    _sp?.setString(_k, '$_water,$_sun');
    final int after = PlantGrowth.stage(_water, _sun);
    widget.onReact(true);
    if (after > before) {
      await _win(widget.appState, 'plant_care_$after', 'اعتني بالنبتة');
    }
  }

  @override
  Widget build(BuildContext context) {
    final int st = PlantGrowth.stage(_water, _sun);
    return Column(mainAxisSize: MainAxisSize.min, children: [
      _head('اعتني بنبتتك: ${PlantGrowth.names[st]}'),
      Text(PlantGrowth.icons[st], style: TextStyle(fontSize: 60.0 + st * 18)),
      Text('💧 $_water   ☀️ $_sun', style: const TextStyle(color: Colors.white, fontSize: 20)),
      const SizedBox(height: 8),
      Wrap(spacing: 12, children: [
        KidButton(label: 'اسقِها 💧', color: KidTheme.info, onPressed: () => _care(true)),
        KidButton(label: 'شمس ☀️', color: KidTheme.accent, onPressed: () => _care(false)),
      ]),
      const SizedBox(height: 6),
      const Text('كل مرتين سقي وشمس تكبر درجة', style: TextStyle(color: Colors.white54, fontSize: 12)),
    ]);
  }
}
