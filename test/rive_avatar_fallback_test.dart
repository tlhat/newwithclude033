// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haneen_kids_vod/features/companion/models/avatar_customization_model.dart';
import 'package:haneen_kids_vod/features/companion/widgets/haneen_companion_avatar_widget.dart';
import 'package:haneen_kids_vod/features/companion/widgets/haneen_rive_avatar_widget.dart';

void main() {
  testWidgets('Rive avatar falls back to PNG widget when no .riv asset',
      (WidgetTester tester) async {
    HaneenRiveAvatarWidget.clearFileCacheForTesting();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: HaneenRiveAvatarWidget(
              avatar: AvatarCustomizationModel(
                gender: CompanionGender.girl,
              ),
              size: 120,
              isWaving: true,
              expressionOverride: CompanionFaceExpression.excited,
            ),
          ),
        ),
      ),
    );
    // Asset load fails (no .riv exists) -> stays on fallback forever.
    // Fixed pumps instead of pumpAndSettle: the PNG fallback animates
    // continuously (breathing), so the frame scheduler never settles.
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(HaneenCompanionAvatarWidget), findsOneWidget);
    expect(find.byType(HaneenRiveAvatarWidget), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Rive avatar uses PNG fallback when riveEnabled is false',
      (WidgetTester tester) async {
    HaneenRiveAvatarWidget.clearFileCacheForTesting();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: HaneenRiveAvatarWidget(
              avatar: AvatarCustomizationModel(
                gender: CompanionGender.boy,
              ),
              riveEnabled: false,
            ),
          ),
        ),
      ),
    );
    // Fixed pumps: PNG fallback animates continuously, never settles.
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(HaneenCompanionAvatarWidget), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Rive avatar disposes cleanly', (WidgetTester tester) async {
    HaneenRiveAvatarWidget.clearFileCacheForTesting();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: HaneenRiveAvatarWidget(
              avatar: AvatarCustomizationModel(
                gender: CompanionGender.girl,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
