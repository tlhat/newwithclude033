import 'package:flutter_test/flutter_test.dart';
import 'package:haneen_kids_vod/haneen_kids_exports.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Phase 5 wiring integration tests: greeting presentation + duplicate
/// prevention, child switching isolation, logout memory clearing, memory
/// restoration, and real parental-lock behavior — without touching
/// widget_test.dart or requiring real device audio.
ChildProfile _child({required String id, required String name}) {
  return ChildProfile(
    id: id,
    name: name,
    age: '3–4',
    dailyTimeLimit: 30,
    chosenAvatar: 'girl',
    gender: 'girl',
    completedLessons: [],
    skillMasteryByLessonId: {},
    needsRemediationLessonIds: [],
    lessonAttemptsByLessonId: {},
  );
}

ParentAccount _account(ChildProfile child) {
  return ParentAccount(
    emailOrPhone: 'parent_p5@test.local',
    fullName: 'والد حنين',
    pinHash: 'x',
    children: [child],
    activeChildId: child.id,
    voiceAssistantEnabled: true,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('greeting presentation & duplicate prevention', () {
    test('presentCompanionGreetingOnce returns greeting once, then null',
        () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final manager = AppStateManager(prefs);
      final child = _child(id: 'w1', name: 'سارة');
      manager.currentAccount = _account(child);

      final g1 = manager.presentCompanionGreetingOnce();
      expect(g1, isNotNull);
      // Simulated rebuild / navigation / repeated lifecycle event:
      expect(manager.presentCompanionGreetingOnce(), isNull);
      expect(manager.presentCompanionGreetingOnce(), isNull);

      // lastGreetingId persisted only after successful presentation.
      await Future<void>.delayed(Duration.zero);
      final snap = CompanionMemoryEngine.loadFrom(prefs, 'w1');
      expect(snap, isNotNull);
      expect(snap!.lastGreetingId, g1!.id);
    });

    test('muted voice assistant blocks speech but text stays safe', () {
      // covered by the dedicated test below
    });

    test('parental lock blocks speech but text stays safe', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final manager = AppStateManager(prefs);
      manager.currentAccount = _account(_child(id: 'w2', name: 'ليان'));
      manager.isParentalControlActive = true;
      final g = manager.buildCompanionGreetingForActiveChild();
      expect(g, isNotNull);
      expect(g!.speakAllowed, isFalse);
      // Still safe to present text-only:
      final presented = manager.presentCompanionGreetingOnce();
      expect(presented, isNotNull);
      expect(manager.currentAssistantBannerMessage, presented!.text);
    });

    test('muted voice assistant blocks speech but text displays', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final manager = AppStateManager(prefs);
      manager.currentAccount = _account(_child(id: 'w3', name: 'نور'));
      CalmVoiceService.instance.isAssistantMuted = true;
      addTearDown(
          () => CalmVoiceService.instance.isAssistantMuted = false);
      final g = manager.buildCompanionGreetingForActiveChild();
      expect(g!.speakAllowed, isFalse);
      final presented = manager.presentCompanionGreetingOnce();
      expect(presented, isNotNull);
      expect(manager.currentAssistantBannerMessage, contains('نور'));
    });
  });

  group('child switching & logout isolation', () {
    test('switching children re-allows greeting and keeps per-child memory',
        () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final manager = AppStateManager(prefs);
      final childA = _child(id: 'sa', name: 'سارة');
      final childB = _child(id: 'sb', name: 'محمد');
      final account = _account(childA);
      account.children.add(childB);
      manager.currentAccount = account;

      final gA = manager.presentCompanionGreetingOnce();
      expect(gA, isNotNull);
      expect(manager.presentCompanionGreetingOnce(), isNull); // dup guard

      await manager.switchActiveChild('sb');
      // New child gets a fresh greeting from its own (fresh) memory:
      final gB = manager.presentCompanionGreetingOnce();
      expect(gB, isNotNull);
      expect(gB, isNotNull);
      // Memories stored under separate keys:
      expect(CompanionMemoryEngine.loadFrom(prefs, 'sa'), isNotNull);
      expect(CompanionMemoryEngine.loadFrom(prefs, 'sb'), isNotNull);
      expect(CompanionMemoryEngine.keyFor('sa'),
          isNot(equals(CompanionMemoryEngine.keyFor('sb'))));
    });

    test('logout clears presentation guard; no greeting without account',
        () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final manager = AppStateManager(prefs);
      manager.currentAccount = _account(_child(id: 'lo', name: 'سارة'));
      expect(manager.presentCompanionGreetingOnce(), isNotNull);

      await manager.logout();
      // No active account => no greeting, no crash:
      expect(manager.presentCompanionGreetingOnce(), isNull);
      expect(manager.currentAccount, isNull);
      // Memory itself remains on disk (per-child, restorable), only the
      // active session context is cleared:
      expect(CompanionMemoryEngine.loadFrom(prefs, 'lo'), isNotNull);
    });

    test('openChildProfilesScreen resets greeting guard', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final manager = AppStateManager(prefs);
      manager.currentAccount = _account(_child(id: 'pr', name: 'سارة'));
      expect(manager.presentCompanionGreetingOnce(), isNotNull);
      await manager.openChildProfilesScreen();
      expect(manager.hasSelectedChildInSession, isFalse);
      // After re-selection a new greeting is allowed (not duplicate-blocked):
      await manager.selectChildAndEnterFeed('pr');
      expect(manager.presentCompanionGreetingOnce(), isNotNull);
    });
  });

  group('memory restoration & valid session navigation', () {
    test('restored snapshot feeds greeting; completed lesson never suggested',
        () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      // Persist memory claiming an "unfinished" lesson the child already
      // completed — must NOT be suggested (no false resume):
      final stale = CompanionMemorySnapshot(
        childId: 'rs',
        childName: 'سارة',
        preferredCompanion: 'girl',
        lastCompletedActivityId: 'les_arabic_alif',
        unfinishedLessonId: 'les_arabic_ba',
        unfinishedSessionStartedAtIso: DateTime.now().toIso8601String(),
      );
      await CompanionMemoryEngine.saveTo(prefs, stale);

      final manager = AppStateManager(prefs);
      final child = _child(id: 'rs', name: 'سارة');
      child.completedLessons.add('les_arabic_ba'); // already completed
      manager.currentAccount = _account(child);

      final suggested = manager.suggestNextActivityForActiveChild();
      expect(suggested, isNotNull);
      expect(suggested, isNot(equals('les_arabic_ba')));

      final g = manager.buildCompanionGreetingForActiveChild();
      expect(g, isNotNull);
      expect(g!.text, contains('سارة'));
    });

    test('setLastActiveAcademyLesson syncs memory snapshot', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final manager = AppStateManager(prefs);
      manager.currentAccount = _account(_child(id: 'sl', name: 'سارة'));
      await manager.setLastActiveAcademyLesson('les_arabic_ba');
      final snap = CompanionMemoryEngine.loadFrom(prefs, 'sl');
      expect(snap, isNotNull);
      expect(snap!.unfinishedLessonId, 'les_arabic_ba');
    });

    test('stale session (older than 7 days) is not suggested', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await CompanionMemoryEngine.saveTo(
        prefs,
        CompanionMemorySnapshot(
          childId: 'st',
          childName: 'سارة',
          preferredCompanion: 'girl',
          unfinishedLessonId: 'les_arabic_ba',
          unfinishedSessionStartedAtIso: DateTime.now()
              .subtract(const Duration(days: 9))
              .toIso8601String(),
        ),
      );
      final manager = AppStateManager(prefs);
      final child = _child(id: 'st', name: 'سارة');
      manager.currentAccount = _account(child);
      expect(manager.suggestNextActivityForActiveChild(),
          isNot(equals('les_arabic_ba')));
    });
  });
}
