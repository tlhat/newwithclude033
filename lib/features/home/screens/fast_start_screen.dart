import 'package:flutter/material.dart' hide Text;
import 'package:haneen_kids_vod/core/regional/dialect_text.dart';
import 'package:haneen_kids_vod/core/services/guide_voice.dart';
import 'package:haneen_kids_vod/features/exercises/exercise_screen.dart';
import 'package:haneen_kids_vod/haneen_kids_exports.dart';

/// Shown once, right after the parent's one-time setup (PIN only).
///   1. Haneen says hello by voice and offers a first game.
///   2. A first simple picture game (no reading needed).
///   3. Big-button questions: boy or girl, age, and an optional name.
/// Nothing here asks for money, an account or a form.
class FastStartScreen extends StatefulWidget {
  final AppStateManager appState;
  const FastStartScreen({super.key, required this.appState});

  @override
  State<FastStartScreen> createState() => _FastStartScreenState();
}

class _FastStartScreenState extends State<FastStartScreen> {
  /// 0 = greeting, 1 = first game, 2 = light questions.
  int _stage = 0;
  int _answers = 0;
  String _gender = 'boy';
  String _age = '3–4 سنوات';
  bool _saving = false;
  final TextEditingController _name = TextEditingController();

  static const String _greet = 'أهلاً يا بطل! مستعد نكتشف شيئاً جديداً معاً؟';
  static const String _qGender = 'إنت ولد ولا بنت؟';
  static const String _qAge = 'عندك كام سنة؟';
  static const String _qName = 'اسمك إيه؟';

  static const List<List<String>> _ages = [
    ['2–3 سنوات', '٢ – ٣', '🧸'],
    ['3–4 سنوات', '٣ – ٤', '🎈'],
    ['4–5 سنوات', '٤ – ٥', '🚀'],
    ['5–6 سنوات', '٥ – ٦', '🎒'],
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      GuideVoice.instance.play('comp_greet_2', _greet);
    });
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _toQuestions() {
    CalmVoiceService.instance.stopAllAudioImmediatelyForParentalGate();
    setState(() => _stage = 2);
    GuideVoice.instance.play('fs_gender', _qGender);
  }

  Future<void> _finish() async {
    if (_saving) return;
    setState(() => _saving = true);
    await widget.appState.finishChildIntro(
      name: _name.text.trim().isEmpty ? null : _name.text.trim(),
      age: _age,
      gender: _gender,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF1E1B4B),
        body: SafeArea(
          child: switch (_stage) {
            0 => _greeting(),
            1 => _game(),
            _ => _questions(),
          },
        ),
      ),
    );
  }

  Widget _bigButton(String label, VoidCallback onTap, {Color? color}) {
    return SizedBox(
      width: double.infinity,
      height: 68,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? const Color(0xFF14B8A6),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
        onPressed: onTap,
        child: Text(label,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
      ),
    );
  }

  Widget _greeting() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Flexible(
                    child: Image.asset('assets/avatars/girl_front.png',
                        cacheHeight: 700)),
                Flexible(
                    child: Image.asset('assets/avatars/boy_front.png',
                        cacheHeight: 700)),
              ],
            ),
          ),
          const Text(_greet,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
          const SizedBox(height: 18),
          _bigButton('يلا نلعب 🎮', () {
            CalmVoiceService.instance.stopAllAudioImmediatelyForParentalGate();
            setState(() => _stage = 1);
          }),
        ],
      ),
    );
  }

  Widget _game() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _toQuestions,
                child: const Text('كمّل ←',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFDE68A))),
              ),
            ],
          ),
        ),
        Expanded(
          child: ExerciseGame(
            key: const ValueKey<String>('fast_start_game'),
            appState: widget.appState,
            skill: 'odd_one',
            title: 'مين المختلف',
            onReact: (bool correct) {
              _answers++;
              // After three answers move on to the light questions.
              if (_answers >= 3 && mounted && _stage == 1) {
                Future.delayed(const Duration(milliseconds: 1500), () {
                  if (mounted && _stage == 1) _toQuestions();
                });
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _choice(String emoji, String label, bool selected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 96,
          margin: const EdgeInsets.symmetric(horizontal: 5),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF14B8A6) : const Color(0xFF312E81),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
                color: selected ? Colors.white : Colors.white24, width: 3),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 34)),
              Text(label,
                  style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _questions() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(_qGender,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
          const SizedBox(height: 10),
          Row(children: [
            _choice('👦', 'ولد', _gender == 'boy',
                () => setState(() => _gender = 'boy')),
            _choice('👧', 'بنت', _gender == 'girl',
                () => setState(() => _gender = 'girl')),
          ]),
          const SizedBox(height: 22),
          GestureDetector(
            onTap: () => GuideVoice.instance.play('fs_age', _qAge),
            child: const Text(_qAge,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.white)),
          ),
          const SizedBox(height: 10),
          Row(children: [
            for (final List<String> a in _ages)
              _choice(a[2], a[1], _age == a[0], () => setState(() => _age = a[0])),
          ]),
          const SizedBox(height: 22),
          GestureDetector(
            onTap: () => GuideVoice.instance.play('fs_name', _qName),
            child: const Text('$_qName (لو حابب)',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.white)),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _name,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, color: Color(0xFF1E2A4A)),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              hintText: 'الاسم',
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 22),
          _bigButton(_saving ? '...' : 'تمام ✅', _finish),
          TextButton(
            onPressed: _saving ? null : _finish,
            child: const Text('بعدين',
                style: TextStyle(fontSize: 16, color: Colors.white70)),
          ),
        ],
      ),
    );
  }
}
