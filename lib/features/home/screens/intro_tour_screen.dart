import 'package:flutter/material.dart' hide Text;
import 'package:haneen_kids_vod/core/regional/dialect_text.dart';
import 'package:haneen_kids_vod/core/safe_mode.dart';
import 'package:haneen_kids_vod/core/services/guide_voice.dart';
import 'package:haneen_kids_vod/core/services/local_audio_library.dart';
import 'package:haneen_kids_vod/haneen_kids_exports.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// First-launch intro, shown once before the Google sign-in gate.
/// The boy and the girl welcome the family and explain the app in four short
/// voiced lines (bundled clips; if a clip is missing the text still shows and
/// nothing is played). Arabic only. A skip button is always visible.
class IntroTourScreen extends StatefulWidget {
  final AppStateManager appState;
  final VoidCallback onDone;
  const IntroTourScreen({super.key, required this.appState, required this.onDone});

  static const String seenKey = 'intro_tour_seen_v1';

  @override
  State<IntroTourScreen> createState() => _IntroTourScreenState();
}

class _IntroLine {
  final String persona;
  final String avatar;
  final String text;
  const _IntroLine(this.persona, this.avatar, this.text);
}

class _IntroTourScreenState extends State<IntroTourScreen> {
  static const List<_IntroLine> _lines = [
    _IntroLine('haneen', 'assets/avatars/girl_front.png',
        'أهلاً بيكم في حنين كيدز! أنا حنين، وده صاحبي البطل.'),
    _IntroLine('cheerful_friend', 'assets/avatars/boy_front.png',
        'أهلاً يا أبطال! هنا هتلعبوا وتتعلموا حاجات حلوة أوي: قصص وألعاب وأكاديمية.'),
    _IntroLine('haneen', 'assets/avatars/girl_front.png',
        'بابا أو ماما هيدخلوا بحساب جوجل عشان نحفظ تقدمكم ونجوائزكم على أي موبايل.'),
    _IntroLine('cheerful_friend', 'assets/avatars/boy_front.png',
        'يلا بينا نبدأ المغامرة!'),
  ];

  int _i = 0;

  @override
  void initState() {
    super.initState();
    SafeMode.risk();
    WidgetsBinding.instance.addPostFrameCallback((_) => _speak());
  }

  Future<void> _speak() async {
    final _IntroLine line = _lines[_i];
    final String t = spokenText(line.text);
    if (t.isEmpty) return;
    try {
      final String? clip = await LocalAudioLibrary.resolveToFile(line.persona, t);
      if (clip == null || !mounted) return;
      await CalmVoiceService.instance
          .speakWithPersona(text: t, personaId: line.persona);
    } catch (_) {}
  }

  Future<void> _finish() async {
    CalmVoiceService.instance.stopAllAudioImmediatelyForParentalGate();
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      await p.setBool(IntroTourScreen.seenKey, true);
    } catch (_) {}
    widget.onDone();
  }

  void _next() {
    if (_i >= _lines.length - 1) {
      _finish();
      return;
    }
    CalmVoiceService.instance.stopAllAudioImmediatelyForParentalGate();
    setState(() => _i++);
    WidgetsBinding.instance.addPostFrameCallback((_) => _speak());
  }

  @override
  Widget build(BuildContext context) {
    final _IntroLine line = _lines[_i];
    final bool last = _i == _lines.length - 1;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF5CB6F5), Color(0xFFCDEBFF)],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: AlignmentDirectional.topStart,
                  child: TextButton(
                    onPressed: _finish,
                    child: const Text('تخطّي',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF3A2A22))),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 280),
                          child: Image.asset(
                            line.avatar,
                            key: ValueKey<String>(line.avatar),
                            height:
                                (MediaQuery.of(context).size.height * 0.34)
                                    .clamp(180.0, 300.0),
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 18),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 280),
                          child: Container(
                            key: ValueKey<int>(_i),
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 18),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF7E8),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: const [
                                BoxShadow(
                                    color: Color(0x22000000),
                                    blurRadius: 12,
                                    offset: Offset(0, 5))
                              ],
                            ),
                            child: Text(
                              line.text,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 19,
                                  height: 1.7,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF3A2A22)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _lines.length,
                    (int d) => Container(
                      width: d == _i ? 22 : 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: d == _i
                            ? const Color(0xFF3A2A22)
                            : const Color(0x663A2A22),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Padding(
                  padding: EdgeInsets.fromLTRB(22, 0, 22,
                      18 + MediaQuery.of(context).padding.bottom),
                  child: SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3A2A22),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: _next,
                      child: Text(last ? 'يلا نبدأ' : 'التالي',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w900)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
