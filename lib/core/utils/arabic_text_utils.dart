import 'package:intl/intl.dart' as intl;

String normalizeArabicForSpeech(String input) {
  return ArabicTextUtils.normalizeArabicForComparison(input);
}

class ArabicTextUtils {
  static String normalizeArabicForComparison(String input) {
    return input
        .replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '')
        .replaceAll(RegExp(r'[أإآ]'), 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll('ى', 'ي')
        .replaceAll(RegExp(r'[^\u0621-\u064A0-9a-zA-Z\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// P2 Internationalization: Formats numbers according to active country/locale
  static String formatLocalizedNumber(num number, {String locale = 'ar'}) {
    try {
      return intl.NumberFormat.decimalPattern(locale).format(number);
    } catch (_) {
      return number.toString();
    }
  }

  /// P2 Internationalization: Formats dates according to active country/locale
  static String formatLocalizedDate(DateTime date, {String locale = 'ar'}) {
    try {
      return intl.DateFormat.yMMMMd(locale).format(date);
    } catch (_) {
      return '${date.year}-${date.month}-${date.day}';
    }
  }
}
