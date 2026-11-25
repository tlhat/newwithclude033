import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:haneen_kids_vod/core/theme/kid_theme.dart';
import 'package:haneen_kids_vod/features/exercises/exercise_models.dart';
import 'package:haneen_kids_vod/features/exercises/exercise_screen.dart';
import 'package:haneen_kids_vod/haneen_kids_exports.dart';
import 'dad_voice.dart';

/// "عالم حنين": house, stickers, pet, certificate, bedtime story, screen-free
/// quiz. Everything is stored on this phone only (SharedPreferences).

Text _h(String t) => Text(t,
    textAlign: TextAlign.center,
    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800));

String arNum(int n) {
  const String ar = '٠١٢٣٤٥٦٧٨٩';
  return n.toString().split('').map((c) => c == '-' ? '-' : ar[int.parse(c)]).join();
}

String dayKey(DateTime d) =>
    '${d.year}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';

// ------------------------------------------------------------ pure rules
class HouseItem {
  final String id, emoji, name;
  final int cost;
  const HouseItem(this.id, this.emoji, this.name, this.cost);
}

const List<HouseItem> kHouseItems = [
  HouseItem('balloon', '🎈', 'بالون', 1),
  HouseItem('plant', '🪴', 'نبتة', 2),
  HouseItem('frame', '🖼️', 'لوحة', 2),
  HouseItem('lamp', '🛋️', 'كنبة', 3),
  HouseItem('teddy', '🧸', 'دبدوب', 3),
  HouseItem('books', '📚', 'مكتبة', 3),
  HouseItem('fish', '🐠', 'حوض سمك', 4),
  HouseItem('bed', '🛏️', 'سرير', 4),
  HouseItem('rainbow', '🌈', 'قوس قزح', 5),
  HouseItem('trophy', '🏆', 'كأس', 6),
];

class HouseLogic {
  /// Stars the child can still spend.
  static int available(int starsEarned, Iterable<String> owned) {
    int spent = 0;
    for (final String id in owned) {
      final List<HouseItem> f = kHouseItems.where((x) => x.id == id).toList();
      if (f.isNotEmpty) spent += f.first.cost;
    }
    return max(0, starsEarned - spent);
  }

  static bool canBuy(int starsEarned, Set<String> owned, HouseItem it) =>
      !owned.contains(it.id) && available(starsEarned, owned) >= it.cost;
}

class PetLogic {
  static const List<String> icons = ['🥚', '🐣', '🐥', '🐔'];
  static const List<String> names = ['بيضة', 'كتكوت صغير', 'كتكوت', 'فرخة كبيرة'];
  static int stage(int stars) => stars < 5 ? 0 : stars < 15 ? 1 : stars < 40 ? 2 : 3;
  static bool hungry(DateTime? lastFed, DateTime now) =>
      lastFed == null || now.difference(lastFed).inHours >= 8;
}

class StickerDef {
  final String emoji, name, rule;
  final bool Function(StickerStats) test;
  const StickerDef(this.emoji, this.name, this.rule, this.test);
}

class StickerStats {
  final int stars, games, mastered, dailyDone, houseItems, petStage;
  const StickerStats(
      {this.stars = 0, this.games = 0, this.mastered = 0, this.dailyDone = 0, this.houseItems = 0, this.petStage = 0});
}

final List<StickerDef> kStickers = [
  StickerDef('⭐', 'أول نجمة', 'اجمع نجمة', (s) => s.stars >= 1),
  StickerDef('🌟', 'عشر نجوم', 'اجمع ١٠ نجوم', (s) => s.stars >= 10),
  StickerDef('💫', 'خمسين نجمة', 'اجمع ٥٠ نجمة', (s) => s.stars >= 50),
  StickerDef('🌠', 'مئة نجمة', 'اجمع ١٠٠ نجمة', (s) => s.stars >= 100),
  StickerDef('🎮', 'لاعب صغير', 'أنهِ لعبة', (s) => s.games >= 1),
  StickerDef('🕹️', 'لاعب ماهر', 'أنهِ ١٠ ألعاب', (s) => s.games >= 10),
  StickerDef('🏅', 'بطل الألعاب', 'أنهِ ٥٠ لعبة', (s) => s.games >= 50),
  StickerDef('🧠', 'عقل ذكي', 'أتقن مهارة', (s) => s.mastered >= 1),
  StickerDef('🎓', 'خريج صغير', 'أتقن ٣ مهارات', (s) => s.mastered >= 3),
  StickerDef('📅', 'تحدي اليوم', 'أنهِ تحدي اليوم', (s) => s.dailyDone >= 1),
  StickerDef('🔥', 'مواظب', 'أنهِ ٣ تحديات يومية', (s) => s.dailyDone >= 3),
  StickerDef('🏠', 'صاحب بيت', 'اشترِ قطعة لبيت حنين', (s) => s.houseItems >= 1),
  StickerDef('🛋️', 'بيت جميل', 'اشترِ ٥ قطع للبيت', (s) => s.houseItems >= 5),
  StickerDef('🐣', 'رعاية الكتكوت', 'خلّي الكتكوت يفقس', (s) => s.petStage >= 1),
  StickerDef('🐔', 'فرخة كبيرة', 'كبّر الكتكوت للآخر', (s) => s.petStage >= 3),
];

/// Same 5 questions for the whole day (seeded by the date).
List<Exercise> dailyPick(List<Exercise> bank, String day, {int n = 5}) {
  final Random r = Random(int.parse(day));
  final List<String> skills = bank.map((e) => e.skill).toSet().toList()..sort();
  skills.shuffle(r);
  final List<Exercise> out = [];
  for (final String s in skills) {
    final List<Exercise> pool = bank.where((e) => e.skill == s && e.type != 'bars').toList();
    if (pool.isEmpty) continue;
    out.add(pool[r.nextInt(pool.length)]);
    if (out.length == n) break;
  }
  return out;
}

// ---------------------------------------------------------- local storage
class WorldStore {
  static Future<SharedPreferences> get _p => SharedPreferences.getInstance();
  static String _k(AppStateManager a, String n) =>
      'world_${n}_${a.currentAccount?.activeChild.id}';
  static Future<Set<String>> house(AppStateManager a) async =>
      ((await _p).getStringList(_k(a, 'house')) ?? <String>[]).toSet();
  static Future<void> saveHouse(AppStateManager a, Set<String> s) async =>
      (await _p).setStringList(_k(a, 'house'), s.toList());
  static Future<DateTime?> lastFed(AppStateManager a) async =>
      DateTime.tryParse((await _p).getString(_k(a, 'fed')) ?? '');
  static Future<void> feed(AppStateManager a, DateTime t) async =>
      (await _p).setString(_k(a, 'fed'), t.toIso8601String());
  static Future<List<String>> dailyDays(AppStateManager a) async =>
      (await _p).getStringList(_k(a, 'daily')) ?? <String>[];
  static Future<void> addDaily(AppStateManager a, String day) async {
    final List<String> l = await dailyDays(a);
    if (!l.contains(day)) {
      l.add(day);
      (await _p).setStringList(_k(a, 'daily'), l);
    }
  }

  static Future<int> masteredCount(AppStateManager a) async {
    try {
      final String? raw = (await _p).getString('ex_progress_${a.currentAccount?.activeChild.id}');
      if (raw == null) return 0;
      final ExerciseProgress p = ExerciseProgress.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      return p.skills.keys.where(p.mastered).length;
    } catch (_) {
      return 0;
    }
  }

  static Future<StickerStats> stats(AppStateManager a) async {
    final ChildProfile? c = a.currentAccount?.activeChild;
    if (c == null) return const StickerStats();
    return StickerStats(
      stars: c.starsEarned,
      games: c.gamesCompletedCount,
      mastered: await masteredCount(a),
      dailyDone: (await dailyDays(a)).length,
      houseItems: (await house(a)).length,
      petStage: PetLogic.stage(c.starsEarned),
    );
  }
}

Widget buildWorldGame(String id, AppStateManager s) {
  switch (id) {
    case 'haneen_house':
      return HaneenHouseCard(appState: s);
    case 'sticker_album':
      return StickerAlbumCard(appState: s);
    case 'haneen_pet':
      return HaneenPetCard(appState: s);
    case 'certificate':
      return CertificateCard(appState: s);
    case 'dad_voice':
      return DadVoiceCard(appState: s);
    case 'bedtime':
      return BedtimeLauncherCard(appState: s);
    case 'daily_challenge':
      return DailyChallengeCard(appState: s);
    default:
      return ScreenFreeQuizCard(appState: s);
  }
}

// -------------------------------------------------------------------- house
class HaneenHouseCard extends StatefulWidget {
  final AppStateManager appState;
  const HaneenHouseCard({super.key, required this.appState});
  @override
  State<HaneenHouseCard> createState() => _HouseState();
}

class _HouseState extends State<HaneenHouseCard> {
  Set<String> _owned = {};
  String? _msg;
  int get _stars => widget.appState.currentAccount?.activeChild.starsEarned ?? 0;

  @override
  void initState() {
    super.initState();
    WorldStore.house(widget.appState).then((v) {
      if (mounted) setState(() => _owned = v);
    });
  }

  Future<void> _buy(HouseItem it) async {
    if (!HouseLogic.canBuy(_stars, _owned, it)) {
      setState(() => _msg = 'محتاج نجوم أكتر. العب وكسب نجوم! ⭐');
      return;
    }
    setState(() {
      _owned = {..._owned, it.id};
      _msg = 'حطيت ${it.name} في البيت! ${it.emoji}';
    });
    await WorldStore.saveHouse(widget.appState, _owned);
  }

  @override
  Widget build(BuildContext context) {
    final int avail = HouseLogic.available(_stars, _owned);
    return Column(mainAxisSize: MainAxisSize.min, children: [
      _h('بيت حنين 🏠   نجومك المتاحة: ${arNum(avail)} ⭐'),
      const SizedBox(height: 8),
      Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 110),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
            color: const Color(0xFF7C5E3C), borderRadius: BorderRadius.circular(KidTheme.rMedium)),
        child: _owned.isEmpty
            ? const Center(child: Text('البيت فاضي. اشترِ حاجات بنجومك!', style: TextStyle(color: Colors.white70)))
            : Wrap(spacing: 10, runSpacing: 6, alignment: WrapAlignment.center, children: [
                for (final HouseItem it in kHouseItems)
                  if (_owned.contains(it.id)) Text(it.emoji, style: const TextStyle(fontSize: 44)),
              ]),
      ),
      const SizedBox(height: 8),
      Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center, children: [
        for (final HouseItem it in kHouseItems)
          if (!_owned.contains(it.id))
            GestureDetector(
              onTap: () => _buy(it),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                    color: avail >= it.cost ? KidTheme.primary : KidTheme.surfaceHigh,
                    borderRadius: BorderRadius.circular(KidTheme.rSmall)),
                child: Text('${it.emoji} ${arNum(it.cost)}⭐',
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
              ),
            ),
      ]),
      if (_msg != null)
        Padding(padding: const EdgeInsets.only(top: 8), child: Text(_msg!, style: const TextStyle(color: Colors.white70))),
    ]);
  }
}

// ------------------------------------------------------------------ stickers
class StickerAlbumCard extends StatefulWidget {
  final AppStateManager appState;
  const StickerAlbumCard({super.key, required this.appState});
  @override
  State<StickerAlbumCard> createState() => _StickerState();
}

class _StickerState extends State<StickerAlbumCard> {
  StickerStats _s = const StickerStats();
  @override
  void initState() {
    super.initState();
    WorldStore.stats(widget.appState).then((v) {
      if (mounted) setState(() => _s = v);
    });
  }

  @override
  Widget build(BuildContext context) {
    final int got = kStickers.where((x) => x.test(_s)).length;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      _h('ألبوم الملصقات 🏅   ${arNum(got)} من ${arNum(kStickers.length)}'),
      const SizedBox(height: 8),
      Wrap(spacing: 10, runSpacing: 10, alignment: WrapAlignment.center, children: [
        for (final StickerDef d in kStickers)
          Container(
            width: 96,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: d.test(_s) ? const Color(0xFFFFF7E6) : KidTheme.surfaceHigh,
                borderRadius: BorderRadius.circular(KidTheme.rMedium)),
            child: Column(children: [
              Text(d.test(_s) ? d.emoji : '🔒', style: const TextStyle(fontSize: 34)),
              Text(d.test(_s) ? d.name : d.rule,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: d.test(_s) ? Colors.black87 : Colors.white70,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700)),
            ]),
          ),
      ]),
    ]);
  }
}

// ----------------------------------------------------------------------- pet
class HaneenPetCard extends StatefulWidget {
  final AppStateManager appState;
  const HaneenPetCard({super.key, required this.appState});
  @override
  State<HaneenPetCard> createState() => _PetState();
}

class _PetState extends State<HaneenPetCard> {
  DateTime? _fed;
  String? _msg;
  @override
  void initState() {
    super.initState();
    WorldStore.lastFed(widget.appState).then((v) {
      if (mounted) setState(() => _fed = v);
    });
  }

  Future<void> _feed() async {
    final DateTime now = DateTime.now();
    final bool was = PetLogic.hungry(_fed, now);
    setState(() {
      _fed = now;
      _msg = was ? 'نعمة! شبع وفرحان 😋' : 'لسه شبعان، شكراً يا بطل 😊';
    });
    await WorldStore.feed(widget.appState, now);
  }

  @override
  Widget build(BuildContext context) {
    final int stars = widget.appState.currentAccount?.activeChild.starsEarned ?? 0;
    final int st = PetLogic.stage(stars);
    final bool hungry = PetLogic.hungry(_fed, DateTime.now());
    final int next = st == 0 ? 5 : st == 1 ? 15 : st == 2 ? 40 : 0;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      _h('كتكوت حنين: ${PetLogic.names[st]}'),
      Text(PetLogic.icons[st], style: TextStyle(fontSize: 70.0 + st * 16)),
      Text(hungry ? 'جعان 🥺' : 'مبسوط 😊', style: const TextStyle(color: Colors.white, fontSize: 18)),
      const SizedBox(height: 6),
      KidButton(label: 'أكّله 🌾', color: KidTheme.accent, onPressed: _feed),
      if (_msg != null) Padding(padding: const EdgeInsets.only(top: 6), child: Text(_msg!, style: const TextStyle(color: Colors.white70))),
      const SizedBox(height: 6),
      Text(next == 0 ? 'كبر للآخر! 🎉' : 'يكبر لما تجمع ${arNum(next)} نجمة (معاك ${arNum(stars)})',
          style: const TextStyle(color: Colors.white54, fontSize: 12)),
    ]);
  }
}

// --------------------------------------------------------------- certificate
class CertificateCard extends StatefulWidget {
  final AppStateManager appState;
  const CertificateCard({super.key, required this.appState});
  @override
  State<CertificateCard> createState() => _CertState();
}

class _CertState extends State<CertificateCard> {
  StickerStats _s = const StickerStats();
  @override
  void initState() {
    super.initState();
    WorldStore.stats(widget.appState).then((v) {
      if (mounted) setState(() => _s = v);
    });
  }

  @override
  Widget build(BuildContext context) {
    final ChildProfile? c = widget.appState.currentAccount?.activeChild;
    final DateTime n = DateTime.now();
    final bool earned = _s.stars >= 1 || _s.games >= 1;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E6),
        borderRadius: BorderRadius.circular(KidTheme.rMedium),
        border: Border.all(color: const Color(0xFFD4A017), width: 5),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('🏆 شهادة تقدير 🏆',
            style: TextStyle(color: Color(0xFF8A6100), fontSize: 24, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Text(earned ? 'تُمنح هذه الشهادة للبطل' : 'العب واجمع نجوم عشان تاخد شهادتك',
            style: const TextStyle(color: Colors.black87, fontSize: 15)),
        if (earned) ...[
          Text(c?.name ?? '',
              style: const TextStyle(color: Colors.black, fontSize: 30, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text('جمع ${arNum(_s.stars)} نجمة، وأنهى ${arNum(_s.games)} لعبة،\nوأتقن ${arNum(_s.mastered)} مهارة',
              textAlign: TextAlign.center, style: const TextStyle(color: Colors.black87, fontSize: 16)),
          const SizedBox(height: 6),
          Text('${arNum(n.day)}/${arNum(n.month)}/${arNum(n.year)}',
              style: const TextStyle(color: Colors.black54, fontSize: 14)),
          const Text('للعرض داخل التطبيق فقط', style: TextStyle(color: Colors.black38, fontSize: 11)),
        ],
      ]),
    );
  }
}

// ------------------------------------------------------------ bedtime story
const List<List<String>> kBedtimeStories = [
  [
    'في غابة هادية، كان فيه أرنوب صغير اسمه نور.',
    'في آخر النهار، قال نور: الشمس بتنام، وأنا كمان هنام.',
    'مشى نور على أطراف صوابعه، ومرّ على صاحبه الدب وقال له: تصبح على خير.',
    'والعصافير سكتت، والنجوم طلعت واحدة واحدة.',
    'دخل نور بيته الدافي، وحط راسه على الوسادة الناعمة.',
    'أخد نفس طويل، وغمّض عينيه، ونام. تصبح على خير.',
  ],
  [
    'كان فيه قمر صغير بيحب يحرس الأطفال بالليل.',
    'كل ما طفل ينام، القمر يبعتله شعاع نور ناعم.',
    'الشعاع بيقول: نام مطمّن، أنا هنا.',
    'والأحلام الجميلة بتيجي على ضهر السحاب.',
    'وفي الصبح، الشمس بتيجي وتقول: صباح الخير. تصبح على خير.',
  ],
  [
    'السلحفاة بطيئة بس بتوصل دايماً.',
    'في ليلة، قالت السلحفاة: هروح أنام في بيتي الصغير.',
    'مشيت خطوة خطوة، وكل خطوة بتقول: هدوء، هدوء.',
    'وصلت بيتها، وسحبت راسها جوه الصدفة الدافية.',
    'وسمعت صوت الريح الخفيف، وناميت. تصبح على خير.',
  ],
];

class BedtimeLauncherCard extends StatelessWidget {
  final AppStateManager appState;
  const BedtimeLauncherCard({super.key, required this.appState});
  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      _h('حدوتة قبل النوم 🌙'),
      const SizedBox(height: 4),
      const Text('الإضاءة بتخفت مع الحدوتة لحد ما تنام', style: TextStyle(color: Colors.white70)),
      const SizedBox(height: 10),
      for (int i = 0; i < kBedtimeStories.length; i++)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: KidButton(
              label: 'حدوتة ${arNum(i + 1)}',
              icon: Icons.nightlight_round,
              color: KidTheme.info,
              onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => BedtimeStoryScreen(story: kBedtimeStories[i])))),
        ),
    ]);
  }
}

class BedtimeStoryScreen extends StatefulWidget {
  final List<String> story;
  const BedtimeStoryScreen({super.key, required this.story});
  @override
  State<BedtimeStoryScreen> createState() => _BedtimeState();
}

class _BedtimeState extends State<BedtimeStoryScreen> {
  int _i = 0;

  int get _storyNo => kBedtimeStories.indexWhere((s) => identical(s, widget.story) || s.join() == widget.story.join());

  void _say() => GuideVoice.instance.play('bed_${_storyNo + 1}_${_i + 1}', widget.story[_i]);

  @override
  void initState() {
    super.initState();
    GuideVoice.instance.play('bed_start', GuideVoice.bedtimeStart).then((_) {
      if (mounted) _say();
    });
  }
  @override
  Widget build(BuildContext context) {
    final double dim = (_i / max(1, widget.story.length - 1)).clamp(0.0, 1.0);
    final bool last = _i == widget.story.length - 1;
    // Background goes from a calm blue to near black; text softens too.
    final Color bg = Color.lerp(const Color(0xFF1E3A8A), const Color(0xFF020617), dim)!;
    final Color fg = Color.lerp(Colors.white, const Color(0xFF94A3B8), dim)!;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bg,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, foregroundColor: fg),
        body: AnimatedContainer(
          duration: const Duration(milliseconds: 900),
          color: bg,
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(last ? '🌙' : '✨', style: const TextStyle(fontSize: 60)),
            const SizedBox(height: 18),
            Text(widget.story[_i],
                textAlign: TextAlign.center,
                style: TextStyle(color: fg, fontSize: 24, height: 1.8, fontWeight: FontWeight.w700)),
            const SizedBox(height: 30),
            if (!last)
              KidButton(
                  label: 'كمّل',
                  color: Colors.white24,
                  onPressed: () {
                    setState(() => _i++);
                    _say();
                  })
            else
              Text('تصبح على خير 💤', style: TextStyle(color: fg, fontSize: 22)),
          ]),
        ),
      ),
    );
  }
}

// ----------------------------------------------------------- daily challenge
class DailyChallengeCard extends StatefulWidget {
  final AppStateManager appState;
  const DailyChallengeCard({super.key, required this.appState});
  @override
  State<DailyChallengeCard> createState() => _DailyState();
}

class _DailyState extends State<DailyChallengeCard> {
  List<Exercise> _q = [];
  int _i = 0;
  bool _done = false;
  bool _started = false;
  final String _day = dayKey(DateTime.now());

  @override
  void initState() {
    super.initState();
    () async {
      final String raw = await rootBundle.loadString('assets/exercises/exercises_v1.json');
      final List<Exercise> q = dailyPick(Exercise.parseList(raw), _day);
      final bool d = (await WorldStore.dailyDays(widget.appState)).contains(_day);
      if (mounted) {
        setState(() {
          _q = q;
          _done = d;
        });
      }
    }();
  }

  Future<void> _finish() async {
    await WorldStore.addDaily(widget.appState, _day);
    await widget.appState.recordBrainGameWin(
        gameId: 'daily_challenge_day$_day', gameTitle: 'تحدي اليوم', earnedIqPoints: 20, earnedStars: 3);
    if (mounted) setState(() => _done = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_q.isEmpty) return const Center(child: CircularProgressIndicator());
    if (_done) {
      return Column(mainAxisSize: MainAxisSize.min, children: [
        _h('تحدي اليوم 📅'),
        const SizedBox(height: 10),
        const Text('🎉', style: TextStyle(fontSize: 60)),
        const Text('خلصت تحدي النهاردة! ارجع بكرة لتحدي جديد.',
            textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 17)),
      ]);
    }
    if (!_started) {
      return Column(mainAxisSize: MainAxisSize.min, children: [
        _h('تحدي اليوم 📅'),
        const SizedBox(height: 8),
        Text('${arNum(_q.length)} أسئلة قصيرة، وتاخد ٣ نجوم لما تخلصهم!',
            textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 10),
        KidButton(label: 'ابدأ', icon: Icons.play_arrow, onPressed: () => setState(() => _started = true)),
      ]);
    }
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Text('سؤال ${arNum(_i + 1)} من ${arNum(_q.length)}', style: const TextStyle(color: Colors.white54)),
      const SizedBox(height: 6),
      ExerciseGame(
          key: ValueKey<int>(_i),
          appState: widget.appState,
          onReact: (_) {},
          fixed: _q[_i],
          onSolved: () {
            if (_i + 1 >= _q.length) {
              _finish();
            } else {
              setState(() => _i++);
            }
          }),
    ]);
  }
}

// ----------------------------------------------------------- screen-free quiz
class ScreenFreeQuizCard extends StatefulWidget {
  final AppStateManager appState;
  const ScreenFreeQuizCard({super.key, required this.appState});
  @override
  State<ScreenFreeQuizCard> createState() => _ScreenFreeState();
}

class _ScreenFreeState extends State<ScreenFreeQuizCard> {
  List<Exercise> _bank = [];
  int _i = 0;
  int _right = 0;
  bool _show = false;
  final Random _r = Random();

  @override
  void initState() {
    super.initState();
    rootBundle.loadString('assets/exercises/exercises_v1.json').then((raw) {
      final List<Exercise> all = Exercise.parseList(raw)
          .where((e) => spokenAnswer(e) != null)
          .toList()
        ..shuffle(_r);
      if (mounted) {
        setState(() => _bank = all);
        _sayQ();
      }
    });
  }

  void _sayQ() {
    if (_bank.isEmpty) return;
    final Exercise e = _bank[_i];
    GuideVoice.instance.play('oral_${e.id}_q', oralSpeech(e));
  }

  void _sayA() {
    final Exercise e = _bank[_i];
    GuideVoice.instance.play('oral_${e.id}_a', 'الإجابة هي ${spokenAnswer(e)}.');
  }

  Future<void> _mark(bool ok) async {
    if (ok) {
      _right++;
      await widget.appState.recordBrainGameWin(
          gameId: 'oral_${_bank[_i].id}', gameTitle: 'سؤال شفهي', earnedIqPoints: 5, earnedStars: 1);
    }
    setState(() {
      _i = (_i + 1) % _bank.length;
      _show = false;
    });
    _sayQ();
  }

  @override
  Widget build(BuildContext context) {
    if (_bank.isEmpty) return const Center(child: CircularProgressIndicator());
    final Exercise e = _bank[_i];
    return Column(mainAxisSize: MainAxisSize.min, children: [
      _h('وضع بدون شاشة 🗣️ (الأب أو الأم يقرأ السؤال)'),
      const SizedBox(height: 8),
      const Text('اقرأ السؤال بصوت عالي، والطفل يجاوب بصوته، وبعدين اضغط صح أو غلط.',
          textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontSize: 12)),
      const SizedBox(height: 10),
      Text(spokenQuestion(e),
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white, fontSize: 26, height: 1.6, fontWeight: FontWeight.w800)),
      const SizedBox(height: 10),
      if (_show)
        Text('الإجابة: ${spokenAnswer(e)}',
            style: const TextStyle(color: Color(0xFFA7F3D0), fontSize: 22, fontWeight: FontWeight.w800))
      else
        KidButton(label: 'أظهر الإجابة', color: KidTheme.surfaceHigh, onPressed: () {
          setState(() => _show = true);
          _sayA();
        }),
      const SizedBox(height: 10),
      Wrap(spacing: 12, children: [
        KidButton(label: 'صح ✅', onPressed: () => _mark(true)),
        KidButton(label: 'غلط ❌', color: KidTheme.danger, onPressed: () => _mark(false)),
      ]),
      const SizedBox(height: 6),
      Text('الصح: ${arNum(_right)}', style: const TextStyle(color: Colors.white70)),
    ]);
  }
}

/// Text read aloud for a question (options are spoken as "أ، ب، ج").
String spokenQuestion(Exercise e) {
  final List<String> opts = (e.data['options'] as List?)?.map((x) => '$x').toList() ?? [];
  String q = e.prompt;
  if (e.type == 'blank') q = '$q\n${e.data['sentence']}';
  if (opts.isNotEmpty && (e.type == 'choice' || e.type == 'blank')) {
    q = '$q\nالاختيارات: ${opts.join(' ، ')}';
  }
  return q;
}

/// Answer text for spoken types; null when the type needs the screen.
String? spokenAnswer(Exercise e) {
  try {
    if (e.type == 'choice' || e.type == 'blank') {
      return '${(e.data['options'] as List)[(e.data['correct'] as num).toInt()]}';
    }
    if (e.type == 'number') return '${e.data['answer']}';
  } catch (_) {}
  return null;
}
