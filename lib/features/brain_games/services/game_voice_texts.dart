/// The exact lines the game speaker buttons speak.
///
/// They must stay identical to the texts in tools/audio_manifest.json, because
/// the offline clip lookup is keyed by the exact text. A different wording
/// means no clip is found and the button is silent without internet.
/// test/audio_buttons_coverage_test.dart checks every level.
class GameVoiceTexts {
  /// English word shown in brackets for each picture-word pool entry.
  static const List<String> pictureWordEnglish = [
    'Apple', 'Lion', 'Plane', 'Butterfly', 'Book',
    'Sun', 'Fish', 'Train', 'Bee', 'Tree',
  ];

  static String pictureWord(int levelNumber, String word, String hint) {
    final String en =
        pictureWordEnglish[(levelNumber - 1) % pictureWordEnglish.length];
    return 'يا بطل حنين، اختر الصورة المطابقة لكلمة $word ($en). $hint';
  }

  static String sound(String soundText, String question) =>
      'استمع مع حنين. $soundText. $question';

  static String riddle(String title, String riddleTip) =>
      '$title. $riddleTip';
}
