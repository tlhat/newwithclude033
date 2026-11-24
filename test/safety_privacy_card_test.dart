import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haneen_kids_vod/haneen_kids_exports.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('privacy policy screen lists the main sections', (tester) async {
    tester.view.physicalSize = const Size(800, 6000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: PrivacyPolicyScreen()));
    expect(find.text('سياسة الخصوصية'), findsOneWidget);
    expect(find.text('ما لا نفعله'), findsOneWidget);
    // Every section has a title and text.
    for (final s in PrivacyPolicyScreen.sections) {
      expect(s.length, 2);
      expect(s[1].trim().isNotEmpty, true);
    }
  });

  testWidgets('card without a logged in account shows only the button',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final app = AppStateManager(await SharedPreferences.getInstance());
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: SafetyPrivacyCard(appState: app)),
    ));
    expect(find.textContaining('123456'), findsNothing);
    expect(find.text('سياسة الخصوصية وحماية بيانات الأطفال'), findsOneWidget);
    await tester.tap(find.text('سياسة الخصوصية وحماية بيانات الأطفال'));
    await tester.pumpAndSettle();
    expect(find.text('سياسة الخصوصية'), findsOneWidget);
  });
}
