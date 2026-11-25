import 'dart:math';
import 'package:haneen_kids_vod/core/services/local_audio_library.dart';
import 'package:haneen_kids_vod/features/exercises/exercise_models.dart';
import 'package:haneen_kids_vod/features/exercises/game_catalog.dart';
import 'package:haneen_kids_vod/haneen_kids_exports.dart';

/// Spoken guidance for games, stories and creative features.
///
/// Every line has a stable id and exact Arabic text (tools/guide_manifest.json,
/// built by tools/gen_guide_manifest.py). The clip lives at
/// assets/audio/haneen/guide/<id>.mp3 and is found by the same text key as the
/// other bundled clips. The text is always shown on screen too. If a clip is
/// missing nothing is played and no network call is made.
class GuideVoice {
  GuideVoice._();
  static final GuideVoice instance = GuideVoice._();

  final Set<String> _played = <String>{};
  final Set<String> missing = <String>{};
  final Random _r = Random();

  /// Short natural lines after a right or wrong answer (ids gv_right_N, gv_wrong_N).
  static const List<String> rightLines = [
    'برافو عليك! إجابة صح.',
    'ممتاز! إنت شاطر جداً.',
    'أحسنت! كمّل كده.',
    'إيه الحلاوة دي! صح تمام.',
    'يا سلام! إنت بتفهم بسرعة.',
    'صح! أنا فخورة بيك.',
    'عظيم! خدت نجمة.',
    'تمام التمام! يلا اللي بعده.',
  ];
  static const List<String> wrongLines = [
    'مش مشكلة، جرّب تاني.',
    'قريب! فكّر شوية وجرّب كمان مرة.',
    'ولا يهمك، الغلط بيعلّمنا. حاول تاني.',
    'بالراحة، بص كويس وجرّب تاني.',
    'تقريباً! إنت تقدر.',
    'مش دي، بس إنت قريب. جرّب تاني.',
  ];

  /// What each widget game says when it opens (id = game id).
  static const Map<String, String> widgetIntro = {
    'letter_catcher': 'يلا نصطاد الحروف! بص على الحرف المطلوب، ودوس عليه قبل ما ينزل.',
    'clock_set': 'يلا نظبط الساعة! حرّك العقارب لحد ما الساعة تبقى على الوقت المكتوب.',
    'shadow_match': 'مين صاحب الظل؟ بص على الظل الأسود، واختار الصورة اللي تشبهه.',
    'slide_puzzle': 'بازل الأرقام! حرّك القطع لحد ما تترتب من واحد لتمانية.',
    'maze': 'المتاهة! ودّي حنين للنجمة. حرّك صباعك في الطريق وخلّي بالك من الحيطان.',
    'stop_go': 'قف وامشِ! لما تشوف الأخضر دوس بسرعة، ولما تشوف الأحمر استنى ولا تدوس.',
    'rule_switch': 'غيّر القاعدة! مرة نختار باللون ومرة بالشكل. اسمع القاعدة وبص كويس.',
    'draw_imagine': 'ارسم وتخيّل! ارسم اللي في خيالك بصباعك، وأنا هستنى أشوفه.',
    'daily_challenge': 'تحدي اليوم! خمس أسئلة صغيرة، جاوب عليهم واحد واحد.',
    'haneen_house': 'ده بيت حنين! اختار حاجة بنجومك وزيّن بيتنا.',
    'haneen_pet': 'ده الكتكوت بتاعنا! اهتم بيه وهو هيكبر كل يوم.',
    'sticker_album': 'ألبوم الملصقات! هنا كل الملصقات والجوائز اللي جمعتها.',
    'certificate': 'دي شهادة التقدير بتاعتك! إنت تعبت وتستاهل.',
    'bedtime': 'يلا نسمع حدوتة هادية قبل النوم. غمّض عينيك واسمع.',
    'dad_voice': 'صوت بابا بيحكي! سجّل حدوتة بصوتك، وتقدر تسمعها أي وقت.',
    'screen_free': 'وضع بدون شاشة! ماما أو بابا يسمعوا معاك، وإنت تجاوب بصوتك.',
    'plant_care': 'اعتني بالنبتة! اسقيها وحطها في الشمس عشان تكبر.',
  };

  static const String bedtimeStart = 'اسمع الحدوتة وإنت مرتاح، وأنا هحكيها لك.';

  Future<void> play(String id, String text, {bool oncePerSession = false}) async {
    final String t = spokenText(text);
    if (t.isEmpty) return;
    if (oncePerSession && !_played.add(id)) return;
    try {
      final String? clip = await LocalAudioLibrary.resolveToFile('haneen', t);
      if (clip == null) {
        missing.add(id);
        return;
      }
      await CalmVoiceService.instance
          .speakWithPersona(text: t, personaId: 'haneen');
    } catch (_) {}
  }

  Future<void> right() {
    final int i = _r.nextInt(rightLines.length);
    return play('gv_right_${i + 1}', rightLines[i]);
  }

  Future<void> wrong() {
    final int i = _r.nextInt(wrongLines.length);
    return play('gv_wrong_${i + 1}', wrongLines[i]);
  }

  Future<void> widgetStart(String gameId) {
    final String? t = widgetIntro[gameId];
    return t == null ? Future<void>.value() : play('gi_$gameId', t, oncePerSession: false);
  }

  /// Intro for a JSON-engine game card: id gi_ex_<skill>.
  Future<void> exerciseGameStart(String skill) {
    for (final ExerciseGameDef g in kExerciseGames) {
      if (g.skill == skill) {
        return play('gi_ex_$skill', exerciseIntroText(g));
      }
    }
    return Future<void>.value();
  }

  static String exerciseIntroText(ExerciseGameDef g) => 'يلا نلعب ${g.title}. ${g.hint.replaceAll(RegExp(r'[؟?!.]+$'), '')}.';

  // ---- exercise lines: stable ids from the exercise id
  Future<void> prompt(Exercise e) => play('ex_${e.id}_q', e.prompt);

  Future<void> hint(Exercise e, String h) {
    final int i = e.hints.indexOf(h);
    return play('ex_${e.id}_h${i < 0 ? 0 : i}', h);
  }

  Future<void> correct(Exercise e) async {
    await play('ex_${e.id}_ok', e.correctFeedback);
    if (e.explain.isNotEmpty) await play('ex_${e.id}_why', e.explain);
  }

  Future<void> incorrect(Exercise e, String? h) async {
    await play('ex_${e.id}_no', e.wrongFeedback);
    if (h != null && h.isNotEmpty) await hint(e, h);
  }
}

/// Text as it is recorded: emoji and symbols removed, spaces collapsed.
/// tools/gen_guide_manifest.py applies the same rule.
String spokenText(String text) => text
    .replaceAll(RegExp("[^\u0600-\u06FFA-Za-z0-9\\s.,\u060C\u061F?!:;()'\\-]"), '')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

/// Oral quiz speech: the question, with options only when they are plain words.
String oralSpeech(Exercise e) {
  String q = e.prompt;
  if (e.type == 'blank') q = '$q ${e.data['sentence']}';
  final List<String> opts = (e.data['options'] as List?)?.map((x) => '$x').toList() ?? [];
  final RegExp plain = RegExp(r'^[\u0600-\u06FF0-9 ]+$');
  if (opts.isNotEmpty &&
      (e.type == 'choice' || e.type == 'blank') &&
      opts.every(plain.hasMatch)) {
    q = '$q الاختيارات: ${opts.join('، ')}.';
  }
  return q;
}
