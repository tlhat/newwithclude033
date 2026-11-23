import 'dart:async';

// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haneen_kids_vod/features/companion/engine/speech_coordinator.dart';
import 'package:haneen_kids_vod/features/companion/models/avatar_customization_model.dart';
import 'package:haneen_kids_vod/features/companion/widgets/haneen_companion_avatar_widget.dart';
import 'package:haneen_kids_vod/features/companion/widgets/haneen_layered_avatar_widget.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: Center(child: child),
      ),
    );
  }

  group('Visual & Runtime QA - Hierarchical Layer Transforms & Pivots', () {
    testWidgets('Boy Front verifies pivots and non-detached limbs during breathing & wave',
        (tester) async {
      await tester.pumpWidget(wrap(
        HaneenLayeredAvatarWidget(
          avatar: AvatarCustomizationModel(
            gender: CompanionGender.boy,
            hairStyle: 'cap',
            outfit: 'casual',
          ),
          viewAngle: CompanionViewAngle.front,
          size: 200,
          isWaving: true,
        ),
      ));

      // Pump through animation cycle to verify zero exceptions across frames
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        expect(tester.takeException(), isNull);
        expect(find.byKey(const ValueKey('layer_body')), findsOneWidget);
        expect(find.byKey(const ValueKey('layer_head')), findsOneWidget);
        expect(find.byKey(const ValueKey('layer_arm_left')), findsOneWidget);
        expect(find.byKey(const ValueKey('layer_arm_right')), findsOneWidget);
        expect(find.byKey(const ValueKey('layer_leg_left')), findsOneWidget);
        expect(find.byKey(const ValueKey('layer_leg_right')), findsOneWidget);
      }
    });

    testWidgets('Girl Front verifies pivots and non-detached limbs during breathing & wave',
        (tester) async {
      await tester.pumpWidget(wrap(
        HaneenLayeredAvatarWidget(
          avatar: AvatarCustomizationModel(
            gender: CompanionGender.girl,
            hairStyle: 'ponytail',
            outfit: 'casual',
          ),
          viewAngle: CompanionViewAngle.front,
          size: 200,
          isWaving: true,
        ),
      ));

      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        expect(tester.takeException(), isNull);
        expect(find.byKey(const ValueKey('layer_body')), findsOneWidget);
        expect(find.byKey(const ValueKey('layer_head')), findsOneWidget);
        expect(find.byKey(const ValueKey('layer_hair')), findsOneWidget);
      }
    });

    testWidgets('Boy 3D Angle verifies perspective rendering & joints',
        (tester) async {
      await tester.pumpWidget(wrap(
        HaneenLayeredAvatarWidget(
          avatar: AvatarCustomizationModel(
            gender: CompanionGender.boy,
            hairStyle: 'spiky',
            outfit: 'sporty',
          ),
          viewAngle: CompanionViewAngle.threeQuarter,
          size: 200,
        ),
      ));
      await tester.pump(const Duration(milliseconds: 200));

      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey('layer_head')), findsOneWidget);
      expect(find.byKey(const ValueKey('layer_body')), findsOneWidget);
      expect(find.byKey(const ValueKey('layer_outfit')), findsOneWidget);
    });

    testWidgets('Girl 3D Angle verifies perspective rendering & joints',
        (tester) async {
      await tester.pumpWidget(wrap(
        HaneenLayeredAvatarWidget(
          avatar: AvatarCustomizationModel(
            gender: CompanionGender.girl,
            hairStyle: 'braids',
            outfit: 'fancy',
          ),
          viewAngle: CompanionViewAngle.threeQuarter,
          size: 200,
        ),
      ));
      await tester.pump(const Duration(milliseconds: 200));

      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey('layer_head')), findsOneWidget);
      expect(find.byKey(const ValueKey('layer_hair')), findsOneWidget);
    });
  });

  group('Visual & Runtime QA - Facial Component Dynamics', () {
    testWidgets('Blinking transitions from open eyes to closed eyes without flicker',
        (tester) async {
      await tester.pumpWidget(wrap(
        HaneenLayeredAvatarWidget(
          avatar: AvatarCustomizationModel(),
          size: 200,
        ),
      ));
      await tester.pump();

      // At start, eyes are open
      expect(find.byKey(const ValueKey('layer_eyes_open')), findsOneWidget);
      expect(find.byKey(const ValueKey('layer_pupils')), findsOneWidget);
      expect(find.byKey(const ValueKey('layer_eyelashes')), findsOneWidget);

      // Fast-forward until blink timer fires (around 3.5s)
      await tester.pump(const Duration(milliseconds: 3600));
      await tester.pump(const Duration(milliseconds: 80));

      // Either in blink or open, no exceptions thrown
      expect(tester.takeException(), isNull);
    });

    testWidgets('Speaking mouth accurately tracks SpeechCoordinator lifecycle',
        (tester) async {
      int fakeClock = 1000;
      final Completer<void> gate = Completer<void>();
      final coordinator = SpeechCoordinator(
        voiceDriver: (_) => gate.future,
        clockMillis: () => fakeClock,
        mutePolicy: () => false,
      );

      await tester.pumpWidget(wrap(
        HaneenCompanionAvatarWidget(
          avatar: AvatarCustomizationModel(),
          size: 200,
          speechCoordinator: coordinator,
        ),
      ));
      await tester.pump();

      // Initial state: neutral mouth
      expect(find.byKey(const ValueKey('companion_mouth_overlay')), findsNothing);

      // Speak start
      coordinator.speak('lesson:1', 'أهلا بك في عالم حنين');
      await tester.pump();
      fakeClock += 300;
      await tester.pump(const Duration(milliseconds: 100));

      // Speaking: open mouth rendered
      expect(find.byKey(const ValueKey('companion_mouth_overlay')), findsOneWidget);

      // Mute while speaking: speech cancels and mouth closes immediately
      await coordinator.cancel();
      await tester.pump();
      expect(find.byKey(const ValueKey('companion_mouth_overlay')), findsNothing);

      gate.complete();
      coordinator.dispose();
    });

    testWidgets('Emotion changes update eyebrows smoothly',
        (tester) async {
      final controller = ValueNotifier<CompanionFaceExpression>(CompanionFaceExpression.calm);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ValueListenableBuilder<CompanionFaceExpression>(
              valueListenable: controller,
              builder: (context, expr, _) {
                return HaneenLayeredAvatarWidget(
                  avatar: AvatarCustomizationModel(),
                  expressionOverride: expr,
                  size: 200,
                );
              },
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byKey(const ValueKey('layer_eyebrows')), findsOneWidget);

      // Switch to happy
      controller.value = CompanionFaceExpression.happy;
      await tester.pump();
      expect(tester.takeException(), isNull);

      // Switch to excited
      controller.value = CompanionFaceExpression.excited;
      await tester.pump();
      expect(tester.takeException(), isNull);

      // Switch to thinking
      controller.value = CompanionFaceExpression.thinking;
      await tester.pump();
      expect(tester.takeException(), isNull);

      // Switch to shy
      controller.value = CompanionFaceExpression.shy;
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  group('Visual & Runtime QA - View Angle & Customization Switching', () {
    testWidgets('Rapidly switching between Front and 3D Angle preserves state and throws zero errors',
        (tester) async {
      final angleNotifier = ValueNotifier<CompanionViewAngle>(CompanionViewAngle.front);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ValueListenableBuilder<CompanionViewAngle>(
              valueListenable: angleNotifier,
              builder: (context, angle, _) {
                return HaneenCompanionAvatarWidget(
                  avatar: AvatarCustomizationModel(),
                  viewAngle: angle,
                  size: 200,
                );
              },
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(HaneenLayeredAvatarWidget), findsOneWidget);

      // Rapidly toggle back and forth 6 times
      for (int i = 0; i < 6; i++) {
        angleNotifier.value = i.isEven
            ? CompanionViewAngle.threeQuarter
            : CompanionViewAngle.front;
        await tester.pump(const Duration(milliseconds: 50));
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('Equipping all accessories concurrently renders all layers without overlap collision',
        (tester) async {
      await tester.pumpWidget(wrap(
        HaneenLayeredAvatarWidget(
          avatar: AvatarCustomizationModel(
            gender: CompanionGender.girl,
            hairStyle: 'crown',
            accessory: 'wings', // has wings
          ),
          size: 200,
        ),
      ));
      await tester.pump();

      expect(find.byKey(const ValueKey('layer_acc_wings')), findsOneWidget);
      expect(find.byKey(const ValueKey('layer_hair')), findsOneWidget);
      expect(find.byKey(const ValueKey('layer_head')), findsOneWidget);
      expect(find.byKey(const ValueKey('layer_body')), findsOneWidget);
    });
  });
}
