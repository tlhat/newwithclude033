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

  group('HaneenLayeredAvatarWidget - Four Character Variants', () {
    testWidgets('renders Boy Front layered character with all core body parts',
        (WidgetTester tester) async {
      await tester.pumpWidget(wrap(
        HaneenLayeredAvatarWidget(
          avatar: AvatarCustomizationModel(
            gender: CompanionGender.boy,
            hairStyle: 'cap',
            outfit: 'casual',
          ),
          viewAngle: CompanionViewAngle.front,
          size: 200,
        ),
      ));
      await tester.pump();

      expect(find.byType(HaneenLayeredAvatarWidget), findsOneWidget);
      expect(find.byKey(const ValueKey('layered_avatar_rig')), findsOneWidget);
      expect(find.byKey(const ValueKey('layer_body')), findsOneWidget);
      expect(find.byKey(const ValueKey('layer_head')), findsOneWidget);
      expect(find.byKey(const ValueKey('layer_leg_left')), findsOneWidget);
      expect(find.byKey(const ValueKey('layer_leg_right')), findsOneWidget);
      expect(find.byKey(const ValueKey('layer_arm_left')), findsOneWidget);
      expect(find.byKey(const ValueKey('layer_arm_right')), findsOneWidget);
      expect(find.byKey(const ValueKey('layer_outfit')), findsOneWidget);
      expect(find.byKey(const ValueKey('layer_hair')), findsOneWidget);
      expect(find.byKey(const ValueKey('layer_eyebrows')), findsOneWidget);
    });

    testWidgets('renders Boy 3D Angle layered character with all core body parts',
        (WidgetTester tester) async {
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
      await tester.pump();

      expect(find.byType(HaneenLayeredAvatarWidget), findsOneWidget);
      expect(find.byKey(const ValueKey('layer_body')), findsOneWidget);
      expect(find.byKey(const ValueKey('layer_head')), findsOneWidget);
    });

    testWidgets('renders Girl Front layered character with ponytail and casual outfit',
        (WidgetTester tester) async {
      await tester.pumpWidget(wrap(
        HaneenLayeredAvatarWidget(
          avatar: AvatarCustomizationModel(
            gender: CompanionGender.girl,
            hairStyle: 'ponytail',
            outfit: 'casual',
          ),
          viewAngle: CompanionViewAngle.front,
          size: 200,
        ),
      ));
      await tester.pump();

      expect(find.byType(HaneenLayeredAvatarWidget), findsOneWidget);
      expect(find.byKey(const ValueKey('layer_hair')), findsOneWidget);
      expect(find.byKey(const ValueKey('layer_outfit')), findsOneWidget);
    });

    testWidgets('renders Girl 3D Angle layered character with braids and fancy outfit',
        (WidgetTester tester) async {
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
      await tester.pump();

      expect(find.byType(HaneenLayeredAvatarWidget), findsOneWidget);
      expect(find.byKey(const ValueKey('layer_hair')), findsOneWidget);
      expect(find.byKey(const ValueKey('layer_outfit')), findsOneWidget);
    });
  });

  group('HaneenLayeredAvatarWidget - Customization Options', () {
    testWidgets('renders accessories when equipped (wings, glasses, crown)',
        (WidgetTester tester) async {
      // 1. Wings
      await tester.pumpWidget(wrap(
        HaneenLayeredAvatarWidget(
          avatar: AvatarCustomizationModel(
            gender: CompanionGender.boy,
            accessory: 'wings',
          ),
          size: 200,
        ),
      ));
      await tester.pump();
      expect(find.byKey(const ValueKey('layer_acc_wings')), findsOneWidget);

      // 2. Glasses
      await tester.pumpWidget(wrap(
        HaneenLayeredAvatarWidget(
          avatar: AvatarCustomizationModel(
            gender: CompanionGender.girl,
            accessory: 'glasses',
          ),
          size: 200,
        ),
      ));
      await tester.pump();
      expect(find.byKey(const ValueKey('layer_acc_glasses')), findsOneWidget);

      // 3. Crown
      await tester.pumpWidget(wrap(
        HaneenLayeredAvatarWidget(
          avatar: AvatarCustomizationModel(
            gender: CompanionGender.girl,
            accessory: 'crown',
          ),
          size: 200,
        ),
      ));
      await tester.pump();
      expect(find.byKey(const ValueKey('layer_acc_crown')), findsOneWidget);
    });

    testWidgets('renders all eyebrow emotions based on expressionOverride',
        (WidgetTester tester) async {
      const expressions = [
        CompanionFaceExpression.happy,
        CompanionFaceExpression.excited,
        CompanionFaceExpression.calm,
        CompanionFaceExpression.shy,
        CompanionFaceExpression.thinking,
      ];

      for (final expr in expressions) {
        await tester.pumpWidget(wrap(
          HaneenLayeredAvatarWidget(
            avatar: AvatarCustomizationModel(gender: CompanionGender.girl),
            expressionOverride: expr,
            size: 200,
          ),
        ));
        await tester.pump();
        expect(find.byKey(const ValueKey('layer_eyebrows')), findsOneWidget);
      }
    });

    testWidgets('renders all boy hairstyles (curly, spiky, cap)',
        (WidgetTester tester) async {
      for (final hair in ['curly', 'spiky', 'cap']) {
        await tester.pumpWidget(wrap(
          HaneenLayeredAvatarWidget(
            avatar: AvatarCustomizationModel(
              gender: CompanionGender.boy,
              hairStyle: hair,
            ),
            size: 200,
          ),
        ));
        await tester.pump();
        expect(find.byKey(const ValueKey('layer_hair')), findsOneWidget);
      }
    });

    testWidgets('renders all girl hairstyles (ponytail, braids, bow, crown)',
        (WidgetTester tester) async {
      for (final hair in ['ponytail', 'braids', 'bow', 'crown']) {
        await tester.pumpWidget(wrap(
          HaneenLayeredAvatarWidget(
            avatar: AvatarCustomizationModel(
              gender: CompanionGender.girl,
              hairStyle: hair,
            ),
            size: 200,
          ),
        ));
        await tester.pump();
        expect(find.byKey(const ValueKey('layer_hair')), findsOneWidget);
      }
    });

    testWidgets('renders all outfits (casual, sporty, explorer, fancy)',
        (WidgetTester tester) async {
      for (final outfit in ['casual', 'sporty', 'explorer', 'fancy']) {
        await tester.pumpWidget(wrap(
          HaneenLayeredAvatarWidget(
            avatar: AvatarCustomizationModel(outfit: outfit),
            size: 200,
          ),
        ));
        await tester.pump();
        expect(find.byKey(const ValueKey('layer_outfit')), findsOneWidget);
      }
    });
  });

  group('HaneenLayeredAvatarWidget - Facial Animations & Speech', () {
    testWidgets('switches between neutral and open mouth based on speech coordinator',
        (WidgetTester tester) async {
      int fakeClock = 1000;
      final Completer<void> gate = Completer<void>();
      final SpeechCoordinator coordinator = SpeechCoordinator(
        voiceDriver: (_) => gate.future,
        clockMillis: () => fakeClock,
        mutePolicy: () => false,
      );

      await tester.pumpWidget(wrap(
        HaneenLayeredAvatarWidget(
          avatar: AvatarCustomizationModel(),
          size: 200,
          speechCoordinator: coordinator,
        ),
      ));
      await tester.pump();

      // Idle: mouth neutral
      expect(find.byKey(const ValueKey('layer_mouth_neutral')), findsOneWidget);
      expect(find.byKey(const ValueKey('companion_mouth_overlay')), findsNothing);

      // Start speech and advance clock so mouth opens
      coordinator.speak('lesson:1', 'أهلا يا صديقي');
      await tester.pump();
      fakeClock += 300;
      await tester.pump(const Duration(milliseconds: 100));

      // Speaking: mouth open
      expect(find.byKey(const ValueKey('companion_mouth_overlay')), findsOneWidget);

      // Cancel: mouth closes
      await coordinator.cancel();
      await tester.pump();
      expect(find.byKey(const ValueKey('companion_mouth_overlay')), findsNothing);
      expect(find.byKey(const ValueKey('layer_mouth_neutral')), findsOneWidget);

      gate.complete();
      coordinator.dispose();
    });

    testWidgets('debugForceMouthOpen forces open mouth',
        (WidgetTester tester) async {
      await tester.pumpWidget(wrap(
        HaneenLayeredAvatarWidget(
          avatar: AvatarCustomizationModel(),
          size: 200,
          debugForceMouthOpen: true,
        ),
      ));
      await tester.pump();

      expect(find.byKey(const ValueKey('companion_mouth_overlay')), findsOneWidget);
    });

    testWidgets('muted coordinator suppresses mouth opening',
        (WidgetTester tester) async {
      final SpeechCoordinator mutedCoordinator = SpeechCoordinator(
        voiceDriver: (_) async {},
        clockMillis: () => 1000,
        mutePolicy: () => true,
      );

      await tester.pumpWidget(wrap(
        HaneenLayeredAvatarWidget(
          avatar: AvatarCustomizationModel(),
          size: 200,
          speechCoordinator: mutedCoordinator,
        ),
      ));
      await tester.pump();

      mutedCoordinator.speak('lesson:1', 'مرحبا');
      await tester.pump();
      expect(find.byKey(const ValueKey('companion_mouth_overlay')), findsNothing);
      expect(find.byKey(const ValueKey('layer_mouth_neutral')), findsOneWidget);

      mutedCoordinator.dispose();
    });
  });

  group('HaneenLayeredAvatarWidget - Lifecycle & Fallback', () {
    testWidgets('disposes all animation controllers and timers cleanly',
        (WidgetTester tester) async {
      await tester.pumpWidget(wrap(
        HaneenLayeredAvatarWidget(
          avatar: AvatarCustomizationModel(),
          size: 200,
          isWaving: true,
        ),
      ));
      await tester.pump(const Duration(milliseconds: 100));

      // Unmount widget
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets('respects fallbackToFlatSprite flag',
        (WidgetTester tester) async {
      await tester.pumpWidget(wrap(
        HaneenLayeredAvatarWidget(
          avatar: AvatarCustomizationModel(gender: CompanionGender.boy),
          viewAngle: CompanionViewAngle.front,
          size: 200,
          fallbackToFlatSprite: true,
        ),
      ));
      await tester.pump();

      // Rig stack is bypassed, single flat image rendered
      expect(find.byKey(const ValueKey('layered_avatar_rig')), findsNothing);
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('respects disableAnimations MediaQuery preference',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: Scaffold(
              body: Center(
                child: HaneenLayeredAvatarWidget(
                  avatar: AvatarCustomizationModel(),
                  size: 200,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byKey(const ValueKey('layered_avatar_rig')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
