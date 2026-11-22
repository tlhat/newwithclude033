import 'dart:async';

// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haneen_kids_vod/haneen_kids_exports.dart';

/// Pinned Phase 3 tests: SpeechCoordinator lifecycle (no overlap, stale /
/// scope cancellation, mute gate, text fallback) and approximate mouth
/// animation gating in the avatar widget.
void main() {
  // The fake clock: tests advance it manually so the coordinator never
  // depends on real wall time.
  int fakeNow = 1000000;

  (SpeechCoordinator, List<String>) makeCoordinator({
    Future<void> Function(String text)? driver,
    bool Function()? mutePolicy,
    bool Function()? voiceAvailability,
  }) {
    final List<String> spoken = <String>[];
    final SpeechCoordinator coordinator = SpeechCoordinator(
      voiceDriver: driver ?? (text) async => spoken.add(text),
      clockMillis: () => fakeNow,
      mutePolicy: mutePolicy ?? () => false,
      voiceAvailability: voiceAvailability ?? () => true,
    );
    return (coordinator, spoken);
  }

  void elapseMs(int ms) {
    fakeNow += ms;
  }

  group('SpeechCoordinator.speak', () {
    test('speaks via the injected driver and returns to idle', () async {
      final (coordinator, spoken) = makeCoordinator();
      await coordinator.speak('lesson:1', 'مرحبا بكم في الدرس');
      expect(spoken, ['مرحبا بكم في الدرس']);
      expect(coordinator.snapshot.phase, CompanionSpeechPhase.idle);
      expect(coordinator.snapshot.mouthOpen, 0.0);
      coordinator.dispose();
    });

    test('empty text is ignored entirely', () async {
      final (coordinator, spoken) = makeCoordinator();
      await coordinator.speak('lesson:1', '   ');
      expect(spoken, isEmpty);
      expect(coordinator.snapshot.phase, CompanionSpeechPhase.idle);
      coordinator.dispose();
    });

    test('English text lifecycle works the same', () async {
      final (coordinator, spoken) = makeCoordinator();
      await coordinator.speak('lesson:2', 'Great job, keep going!');
      expect(spoken, ['Great job, keep going!']);
      expect(coordinator.snapshot.phase, CompanionSpeechPhase.idle);
      coordinator.dispose();
    });

    test('driver failure falls back to text, mouth stays closed', () async {
      final (coordinator, _) = makeCoordinator(
        driver: (text) async => throw Exception('synthesis failed'),
      );
      await coordinator.speak('lesson:1', 'أعد المحاولة');
      expect(coordinator.snapshot.phase, CompanionSpeechPhase.textFallback);
      expect(coordinator.snapshot.mouthOpen, 0.0);
      expect(coordinator.fallbackText, 'أعد المحاولة');
      coordinator.dispose();
    });

    test('voice unavailable also triggers text fallback', () async {
      final (coordinator, _) = makeCoordinator(voiceAvailability: () => false);
      await coordinator.speak('lesson:1', 'hello');
      expect(coordinator.snapshot.phase, CompanionSpeechPhase.textFallback);
      coordinator.dispose();
    });

    test('mute prevents any audio and any mouth movement', () async {
      final (coordinator, spoken) =
          makeCoordinator(mutePolicy: () => true);
      await coordinator.speak('lesson:1', 'مرحبا');
      expect(spoken, isEmpty);
      expect(coordinator.snapshot.phase, CompanionSpeechPhase.idle);
      expect(coordinator.snapshot.mouthOpen, 0.0);
      coordinator.dispose();
    });
  });

  group('SpeechCoordinator cancellation', () {
    test('new speak cancels previous (no overlap), stale completion ignored',
        () async {
      final List<String> completed = <String>[];
      final Completer<void> firstGate = Completer<void>();

      final SpeechCoordinator coordinator = SpeechCoordinator(
        voiceDriver: (text) async {
          if (text == 'first') {
            await firstGate.future;
          }
          completed.add(text);
        },
        clockMillis: () => fakeNow,
        mutePolicy: () => false,
      );

      final Future<void> first = coordinator.speak('lesson:1', 'first');
      // While the first is still pending, a second request arrives.
      final Future<void> second = coordinator.speak('lesson:1', 'second');
      await second;

      // The first is superseded: its token is invalidated, and when it
      // finally resolves it must NOT publish a completion snapshot.
      firstGate.complete();
      await first;
      await Future<void>.delayed(Duration.zero);

      expect(coordinator.snapshot.phase, CompanionSpeechPhase.idle);
      // Only the second request's lifecycle was honored.
      expect(completed, contains('second'));
      // The scope ID tracks the (only) live request.
      expect(coordinator.activeScopeId, isNull);
      coordinator.dispose();
    });

    test('scope change cancels active speech and closes the mouth',
        () async {
      final Completer<void> gate = Completer<void>();
      final SpeechCoordinator coordinator = SpeechCoordinator(
        voiceDriver: (_) => gate.future,
        clockMillis: () => fakeNow,
        mutePolicy: () => false,
      );

      final Future<void> speaking = coordinator.speak('lesson:1', ' نص ');
           // Give the speak() internals a tick to register the request.
      await Future<void>.delayed(Duration.zero);
      await coordinator.onScopeChanged('lesson:2');

      expect(coordinator.snapshot.phase, CompanionSpeechPhase.idle);
      expect(coordinator.snapshot.mouthOpen, 0.0);

      gate.complete();
      await speaking;
      await Future<void>.delayed(Duration.zero);
      // Stale completion after cancellation must not revive speech.
      expect(coordinator.snapshot.phase, CompanionSpeechPhase.idle);
      coordinator.dispose();
    });

    test('cancel() while pending closes the mouth immediately', () async {
      final Completer<void> gate = Completer<void>();
      final SpeechCoordinator coordinator = SpeechCoordinator(
        voiceDriver: (_) => gate.future,
        clockMillis: () => fakeNow,
        mutePolicy: () => false,
      );

      final Future<void> speaking = coordinator.speak('lesson:1', 'text');
      await Future<void>.delayed(Duration.zero);
      await coordinator.cancel();

      expect(coordinator.snapshot.phase, CompanionSpeechPhase.idle);
      expect(coordinator.snapshot.mouthOpen, 0.0);

      gate.complete();
      await speaking;
      await Future<void>.delayed(Duration.zero);
      expect(coordinator.snapshot.phase, CompanionSpeechPhase.idle);
      coordinator.dispose();
    });

    test('same-scope notification does not cancel speech', () async {
      final Completer<void> gate = Completer<void>();
      final SpeechCoordinator coordinator = SpeechCoordinator(
        voiceDriver: (_) => gate.future,
        clockMillis: () => fakeNow,
        mutePolicy: () => false,
      );

      final Future<void> speaking = coordinator.speak('lesson:1', 'text');
      await Future<void>.delayed(Duration.zero);
      await coordinator.onScopeChanged('lesson:1');
      expect(coordinator.snapshot.phase, CompanionSpeechPhase.speaking);

      gate.complete();
      await speaking;
      expect(coordinator.snapshot.phase, CompanionSpeechPhase.idle);
      coordinator.dispose();
    });
  });

  group('SpeechCoordinator approximate progress', () {
    test('mouth animates only while speaking, closes at completion',
        () async {
      // Gate the driver so speech stays active while the progress timer ticks;
      // the fake clock supplies the elapsed time.
      final Completer<void> gate = Completer<void>();
      final SpeechCoordinator coordinator = SpeechCoordinator(
        voiceDriver: (_) => gate.future,
        clockMillis: () => fakeNow,
        mutePolicy: () => false,
      );
      final List<CompanionSpeechSnapshot> history =
          <CompanionSpeechSnapshot>[];
      coordinator.addListener(
          () => history.add(coordinator.snapshot));

      final Future<void> speaking =
          coordinator.speak('lesson:1', 'one two three four five');
      await Future<void>.delayed(const Duration(milliseconds: 120));
      elapseMs(300);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(coordinator.snapshot.phase, CompanionSpeechPhase.speaking);
      expect(
        history.any((s) => s.isSpeaking && s.mouthOpen > 0.0),
        isTrue,
        reason: 'mouth should open while audio is playing',
      );

      gate.complete();
      await speaking;
      expect(coordinator.snapshot.phase, CompanionSpeechPhase.idle);
      expect(coordinator.snapshot.mouthOpen, 0.0);
      expect(
        history.any((s) =>
            !s.isSpeaking && s.mouthOpen > 0.0),
        isFalse,
        reason: 'mouth must never be open when not speaking',
      );
      coordinator.dispose();
    });

    test('estimated duration is word-count based and bounded', () {
      // Static heuristic sanity: a one-word utterance never estimates below
      // the floor, and long text estimates longer than short text.
      final Duration short =
          SpeechCoordinatorTestHooks.estimateSpeechDuration('hi');
      final Duration long = SpeechCoordinatorTestHooks
          .estimateSpeechDuration('a '.padRight(60, 'a '));
      expect(short.inMilliseconds, greaterThanOrEqualTo(1200));
      expect(long.inMilliseconds, greaterThan(short.inMilliseconds));
    });
  });

  group('HaneenCompanionAvatarWidget mouth animation', () {
    Widget wrap(Widget child) => MaterialApp(
          home: Scaffold(body: Center(child: child)),
        );

    testWidgets('mouth overlay hidden when not speaking', (tester) async {
      final (coordinator, _) = makeCoordinator();
      await tester.pumpWidget(wrap(HaneenCompanionAvatarWidget(
        avatar: AvatarCustomizationModel(),
        size: 200,
        speechCoordinator: coordinator,
      )));

      // No mouth overlay key present while idle.
      expect(find.byKey(const ValueKey('companion_mouth_overlay')),
          findsNothing);
      coordinator.dispose();
    });

    testWidgets('mouth overlay visible while speaking, closes on completion',
        (tester) async {
      final Completer<void> gate = Completer<void>();
      final SpeechCoordinator coordinator = SpeechCoordinator(
        voiceDriver: (_) => gate.future,
        clockMillis: () => fakeNow,
        mutePolicy: () => false,
      );

      await tester.pumpWidget(wrap(HaneenCompanionAvatarWidget(
        avatar: AvatarCustomizationModel(),
        size: 200,
        speechCoordinator: coordinator,
      )));

      final Future<void> speaking = coordinator.speak('lesson:1', 'text');
      await tester.pump();
      elapseMs(300);
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byKey(const ValueKey('companion_mouth_overlay')),
          findsOneWidget);

      gate.complete();
      await speaking;
      await tester.pump();
      expect(find.byKey(const ValueKey('companion_mouth_overlay')),
          findsNothing);
      coordinator.dispose();
    });

    testWidgets('mouthAnimationEnabled=false suppresses the overlay',
        (tester) async {
      final Completer<void> gate = Completer<void>();
      final SpeechCoordinator coordinator = SpeechCoordinator(
        voiceDriver: (_) => gate.future,
        clockMillis: () => fakeNow,
        mutePolicy: () => false,
      );

      await tester.pumpWidget(wrap(HaneenCompanionAvatarWidget(
        avatar: AvatarCustomizationModel(),
        size: 200,
        speechCoordinator: coordinator,
        mouthAnimationEnabled: false,
      )));

      coordinator.speak('lesson:1', 'text');
      await tester.pump();
      elapseMs(300);
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byKey(const ValueKey('companion_mouth_overlay')),
          findsNothing);

      gate.complete();
      coordinator.dispose();
    });

    testWidgets('all four sprites honor the mouth overlay anchor', (tester) async {
      final Completer<void> gate = Completer<void>();
      final SpeechCoordinator coordinator = SpeechCoordinator(
        voiceDriver: (_) => gate.future,
        clockMillis: () => fakeNow,
        mutePolicy: () => false,
      );

      const List<(CompanionGender, CompanionViewAngle)> combos = [
        (CompanionGender.boy, CompanionViewAngle.front),
        (CompanionGender.boy, CompanionViewAngle.threeQuarter),
        (CompanionGender.girl, CompanionViewAngle.front),
        (CompanionGender.girl, CompanionViewAngle.threeQuarter),
      ];

      for (final (gender, angle) in combos) {
        await tester.pumpWidget(wrap(HaneenCompanionAvatarWidget(
          avatar: AvatarCustomizationModel(gender: gender),
          size: 200,
          viewAngle: angle,
          speechCoordinator: coordinator,
        )));

        coordinator.speak('lesson:1', 'text');
        await tester.pump();
        elapseMs(300);
        await tester.pump(const Duration(milliseconds: 100));

        expect(
          find.byKey(const ValueKey('companion_mouth_overlay')),
          findsOneWidget,
          reason: 'mouth overlay must render for $gender $angle',
        );
        await coordinator.cancel();
        await tester.pump();
        expect(find.byKey(const ValueKey('companion_mouth_overlay')),
            findsNothing);
      }
      gate.complete();
      coordinator.dispose();
    });
  });
}
