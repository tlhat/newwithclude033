import 'calm_voice_service.dart';

/// Plays a short spoken introduction the first time the child enters each
/// section in a session. Texts are fixed so each one can be a pre-recorded
/// clip: assets/audio/haneen/section_intro/intro_<key>.mp3
class SectionIntroService {
  SectionIntroService._();
  static final SectionIntroService instance = SectionIntroService._();

  static const Map<String, String> kIntroTexts = {
    'stories':
        'أهلاً بيك في قصص حنين! هنا هتسمع حكايات حلوة، وكل حكاية بتعلمك حاجة جديدة. اختار القصة اللي عجبتك وأنا هحكيهالك.',
    'academy':
        'ده مكان التعلم! فيه دروس عن الحروف والكلمات والأرقام. اتعلم، وجاوب، وهتكسب نجوم.',
    'games':
        'أهلاً بيك في واحة الذكاء! ألعاب حلوة بتخلي مخك أذكى: ذاكرة وحساب وألغاز. العب وكسب نجوم.',
    'achievements':
        'هنا كل نجومك وإنجازاتك! شوف إنت وصلت لفين، وإيه الجوايز اللي كسبتها.',
    'account':
        'ده حسابك! تقدر تغير شكل شخصيتك، وتشوف معلوماتك.',
    'etiquette': 'مرسم الآداب! اتعلم الأخلاق الحلوة وإنت بترسم وتلوّن.',
    'oddone': 'قوة الملاحظة! دور على الشكل المختلف وسط الأشكال.',
    'pattern': 'الألغاز والمنطق! كمّل النمط واكتشف إيه اللي جاي بعد كده.',
    'memory':
        'لعبة الذاكرة! افتكر مكان الصور المتشابهة. ركز كويس وافتح كروتين زي بعض.',
    'math': 'الحساب والجمع! عدّ الأشكال واختار الرقم الصح.',
    'letters': 'الحروف والكلمات! اتعلم الحروف العربي ونطقها.',
    'picmatch': 'مطابقة الصور والكلمات! اختار الصورة اللي تناسب الكلمة.',
    'classify': 'التصنيف الذكي! حط كل حاجة في مجموعتها الصح.',
    'sounds': 'أصوات الحيوانات! اسمع الصوت وخمّن صاحبه.',
    'sequence': 'الترتيب والتسلسل! رتّب الخطوات بالترتيب الصح.',
  };

  /// Order of the bottom navigation tabs.
  static const List<String> kTabKeys = [
    'stories',
    'academy',
    'games',
    'achievements',
    'account',
  ];

  /// Order of the games in the games hub (same as _buildActiveBrainGameCard).
  static const List<String> kGameKeys = [
    'etiquette',
    'oddone',
    'pattern',
    'memory',
    'math',
    'letters',
    'picmatch',
    'classify',
    'sounds',
    'sequence',
  ];

  final Set<String> _played = <String>{};

  bool hasPlayed(String key) => _played.contains(key);

  int _generation = 0;

  /// Speaks the section intro EVERY time the section is opened (so it is
  /// consistent), after stopping any other audio at once. If the child taps
  /// another section quickly, the older intro never starts.
  Future<void> playOnce(String key) async {
    final String? text = kIntroTexts[key];
    if (text == null) return;
    _played.add(key);
    final int gen = ++_generation;
    final voice = CalmVoiceService.instance;
    await voice.stopSpeaking(); // keep the calm background music running
    if (gen != _generation) return;
    await voice.speakCalmly(
      text,
      rate: 0.38,
      allowSpeechForRepeatGame: true,
      overridePersonaId: 'haneen',
      respectContextualPersonas: false,
    );
  }

  Future<void> playForTab(int index) {
    if (index < 0 || index >= kTabKeys.length) return Future.value();
    return playOnce(kTabKeys[index]);
  }

  Future<void> playForGame(int index) {
    if (index < 0 || index >= kGameKeys.length) return Future.value();
    return playOnce(kGameKeys[index]);
  }
}
