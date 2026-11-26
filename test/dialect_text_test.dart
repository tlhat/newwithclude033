import 'dart:io';
import 'package:flutter/material.dart' hide Text;
import 'package:flutter_test/flutter_test.dart';
import 'package:haneen_kids_vod/core/regional/country_config.dart';
import 'package:haneen_kids_vod/core/regional/dialect_pack.dart';
import 'package:haneen_kids_vod/core/regional/dialect_text.dart';

Widget _host(Widget w) => Directionality(
    textDirection: TextDirection.rtl,
    child: ValueListenableBuilder<DialectId>(
        valueListenable: DialectPacks.notifier,
        builder: (_, d, __) => DialectScope(dialect: d, child: w)));

void main() {
  tearDown(() {
    DialectPacks.loaded.clear();
    DialectPacks.setActive(DialectId.egyptian);
  });

  testWidgets('Egyptian shows the code text unchanged', (t) async {
    DialectPacks.loaded[DialectId.msaSimple] = {'اضغط هنا، مخصص ليك': 'X'};
    await t.pumpWidget(_host(const Text('اضغط هنا، مخصص ليك')));
    expect(find.text('اضغط هنا، مخصص ليك'), findsOneWidget);
  });

  testWidgets('another dialect overrides, missing keys fall back',
      (t) async {
    DialectPacks.loaded[DialectId.msaSimple] = {'اضغط هنا، مخصص ليك': 'اضغط هنا، مخصص لك'};
    await t.pumpWidget(_host(const Column(children: [
      Text('اضغط هنا، مخصص ليك'),
      Text('نص ما له ترجمة'),
    ])));
    DialectPacks.setActive(DialectId.msaSimple);
    await t.pump();
    expect(find.text('اضغط هنا، مخصص لك'), findsOneWidget);
    expect(find.text('نص ما له ترجمة'), findsOneWidget);
  });

  test('number templates keep the digits', () {
    DialectPacks.loaded[DialectId.gulf] = {'مرحلة {#} من {#}': 'المرحلة {#} من {#}'};
    expect(DialectPacks.tr('مرحلة 2 من 5', dialect: DialectId.gulf),
        'المرحلة 2 من 5');
  });

  test('no UI file uses the material Text with Arabic literals', () {
    final bad = <String>[];
    for (final e in Directory('lib').listSync(recursive: true)) {
      if (e is! File || !e.path.endsWith('.dart')) continue;
      if (e.path.contains('core/regional/')) continue;
      final s = e.readAsStringSync();
      final usesText = RegExp(r'\bText\(|\bText\.rich\(').hasMatch(s);
      final materialText = s.contains("flutter/material.dart';") ||
          s.contains("flutter/widgets.dart';");
      if (usesText && materialText) bad.add(e.path);
    }
    expect(bad, isEmpty);
  });
}
