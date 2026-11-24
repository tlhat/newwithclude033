import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haneen_kids_vod/app/app_theme.dart';
import 'package:haneen_kids_vod/shared/widgets/bouncy_tap.dart';
import 'package:haneen_kids_vod/shared/widgets/confetti_burst.dart';

void main() {
  testWidgets('BouncyTap shrinks while pressed and keeps child tap working',
      (t) async {
    int taps = 0;
    await t.pumpWidget(MaterialApp(
      home: Center(
        child: BouncyTap(
          child:
              ElevatedButton(onPressed: () => taps++, child: const Text('go')),
        ),
      ),
    ));
    final g = await t.startGesture(t.getCenter(find.text('go')));
    await t.pump(const Duration(milliseconds: 200));
    expect(t.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 0.95);
    await g.up();
    await t.pump(const Duration(milliseconds: 600));
    expect(t.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 1.0);
    expect(taps, 1);
  });

  testWidgets('ConfettiBurst shows then removes itself', (t) async {
    await t.pumpWidget(MaterialApp(
      home: Builder(
        builder: (c) => ElevatedButton(
          onPressed: () => ConfettiBurst.show(c),
          child: const Text('go'),
        ),
      ),
    ));
    await t.tap(find.text('go'));
    await t.pump(const Duration(milliseconds: 700));
    expect(find.byType(ConfettiBurst), findsOneWidget);
    await t.pump(const Duration(seconds: 3));
    expect(find.byType(ConfettiBurst), findsNothing);
  });

  testWidgets('theme uses soft page transitions', (t) async {
    final theme = AppTheme.buildTheme(highContrast: false);
    expect(theme.pageTransitionsTheme.builders[TargetPlatform.android],
        isA<SoftPageTransitionsBuilder>());
    await t.pumpWidget(MaterialApp(
      theme: theme,
      home: Builder(
        builder: (c) => ElevatedButton(
          onPressed: () => Navigator.push(
              c, MaterialPageRoute(builder: (_) => const Text('page2'))),
          child: const Text('go'),
        ),
      ),
    ));
    await t.tap(find.text('go'));
    await t.pumpAndSettle();
    expect(find.text('page2'), findsOneWidget);
  });
}
