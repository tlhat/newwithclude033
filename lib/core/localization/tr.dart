import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

/// UI text lookup. Screens keep the Arabic text in code; when the interface
/// language is English, the same text is looked up in assets/i18n/en.json.
/// A missing entry falls back to the Arabic text, never to an empty string.
class Tr {
  Tr._();
  static String lang = 'ar';
  static Map<String, String> en = <String, String>{};

  static bool get isEn => lang == 'en';
  static TextDirection get dir => isEn ? TextDirection.ltr : TextDirection.rtl;

  static Future<void> load() async {
    try {
      final String raw = await rootBundle.loadString('assets/i18n/en.json');
      final Map<String, dynamic> m = jsonDecode(raw) as Map<String, dynamic>;
      en = m.map((k, v) => MapEntry(k, v.toString()));
    } catch (_) {}
  }
}

/// [ar] may contain {0}, {1} placeholders filled from [args].
String tr(String ar, [List<Object?> args = const []]) {
  String s = Tr.isEn ? (Tr.en[ar] ?? ar) : ar;
  for (int i = 0; i < args.length; i++) {
    s = s.replaceAll('{$i}', '${args[i]}');
  }
  return s;
}
