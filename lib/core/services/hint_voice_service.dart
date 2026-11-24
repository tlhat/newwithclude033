import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:haneen_kids_vod/haneen_kids_exports.dart';

/// Plays short recorded hint lines (assets/audio/haneen/hints). The lines come
/// from tools/audio_manifest.json (feature "hints"). If a clip is missing the
/// normal speech pipeline is used, and if that fails nothing happens.
class HintVoiceService {
  HintVoiceService._();
  static final HintVoiceService instance = HintVoiceService._();

  static const Map<String, String> lines = {
    'hint_games_pick': 'اختار لعبة من اللي قدامك وأنا هلعب معاك!',
    'hint_stories_pick': 'دوس على الحكاية اللي عجباك، وأنا هحكيهالك.',
    'hint_academy_pick': 'يلا نتعلم حاجة جديدة النهاردة. دوس على الدرس.',
    'hint_my_path': 'دي خطتك النهاردة. دوس على أول خطوة ونبدأ!',
    'hint_draw_start': 'حط صباعك على الشكل وارسم معايا بالراحة.',
    'hint_draw_imagine': 'ارسم اللي في خيالك. أنا فضولية أشوفه!',
    'hint_draw_ask_1': 'إنت بتحب ترسم إيه النهاردة؟ حيوان ولا عربية؟',
    'hint_draw_ask_2': 'إيه اللون اللي نفسك تستخدمه في رسمتك؟',
    'hint_draw_done': 'إيه الرسمة الجميلة دي! برافو عليك.',
    'hint_trace_letter': 'امشي بصباعك على الحرف من النقطة الخضرا.',
    'hint_count_pics': 'عُد معايا الصور، واحد، اتنين، تلاتة.',
    'hint_sort_shapes': 'شد الشكل وحطه في مكانه الصح.',
    'hint_try_again': 'مش مشكلة، جرّب تاني. أنا واثقة إنك تقدر!',
    'hint_great': 'برافو! إنت شاطر جداً.',
    'hint_eye_break': 'يلا نريّح عينينا شوية. بص بعيد عن الشاشة وعُد لخمسة.',
    'hint_streak': 'إنت جيت النهاردة كمان! خدت نجمة زيادة.',
  };

  final Set<String> _playedThisSession = <String>{};

  /// Speaks the hint. [oncePerSession] avoids nagging on repeat visits.
  Future<void> play(String id, {bool oncePerSession = false}) async {
    final String? text = lines[id];
    if (text == null) return;
    if (oncePerSession && !_playedThisSession.add(id)) return;
    try {
      await CalmVoiceService.instance
          .speakWithPersona(text: text, personaId: 'haneen');
    } catch (_) {}
  }
}
