import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haneen_kids_vod/haneen_kids_exports.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('star reward card appears, then disappears', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final app = AppStateManager(prefs);
    await tester.pumpWidget(MaterialApp(
      home: StarRewardHost(appState: app, child: const Scaffold(body: Text('home'))),
    ));
    expect(find.textContaining('+2'), findsNothing);

    app.announceStarReward(2, 'أحسنت يا بطل');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('⭐ +2'), findsOneWidget);
    expect(find.text('أحسنت يا بطل'), findsOneWidget);
    // Touches still reach the screen below.
    expect(find.text('home').hitTestable(), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    expect(find.text('⭐ +2'), findsNothing);

    app.announceStarReward(0, 'x');
    await tester.pump();
    expect(find.textContaining('+0'), findsNothing);
  });
}
