import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:haneen_kids_vod/haneen_kids_exports.dart';
import 'package:haneen_kids_vod/features/development/dev_cards.dart';

class _FakeState extends Fake implements AppStateManager {
  @override
  ParentAccount? currentAccount;
  @override
  bool isDailyLimitReached = false;
}

Widget _wrap(Widget w) => MaterialApp(home: Scaffold(body: SingleChildScrollView(child: w)));

void main() {
  testWidgets('12-36 months band is not locked', (t) async {
    SharedPreferences.setMockInitialValues({'dev_state_': '{"band":0}'});
    await t.pumpWidget(MaterialApp(
        home: DevGate(appState: _FakeState(), child: const Text('GAMES'))));
    await t.pump(const Duration(milliseconds: 200));
    expect(find.text('GAMES'), findsOneWidget);
    expect(find.textContaining('مقفولة'), findsNothing);
  });
  testWidgets('co-use on shows the games with a banner', (t) async {
    SharedPreferences.setMockInitialValues({'dev_state_': '{"band":0,"coUse":true}'});
    await t.pumpWidget(MaterialApp(
        home: DevGate(appState: _FakeState(), child: const Text('GAMES'))));
    await t.pump(const Duration(milliseconds: 200));
    expect(find.text('GAMES'), findsOneWidget);
    expect(find.textContaining('استخدام مشترك'), findsOneWidget);
  });
  testWidgets('time up screen when cap reached', (t) async {
    SharedPreferences.setMockInitialValues({'dev_state_': '{"band":1}'});
    await t.pumpWidget(MaterialApp(
        home: DevGate(appState: _FakeState()..isDailyLimitReached = true, child: const Text('GAMES'))));
    await t.pump(const Duration(milliseconds: 200));
    expect(find.text('GAMES'), findsNothing);
    expect(find.textContaining('خلص وقت'), findsOneWidget);
  });
  testWidgets('development card renders report, no IQ wording', (t) async {
    SharedPreferences.setMockInitialValues({});
    tester(t);
    await t.pumpWidget(_wrap(DevelopmentCard(appState: _FakeState())));
    await t.pump(const Duration(milliseconds: 300));
    expect(t.takeException(), isNull);
    expect(find.textContaining('لا يشخّص'), findsOneWidget);
    expect(find.textContaining('IQ'), findsNothing);
  });
}

void tester(WidgetTester t) {
  t.view.physicalSize = const Size(400, 3000);
  t.view.devicePixelRatio = 1.0;
}
