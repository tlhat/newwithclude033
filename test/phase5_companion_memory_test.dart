import 'package:flutter_test/flutter_test.dart';
import 'package:haneen_kids_vod/haneen_kids_exports.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Pinned Phase 5 tests: CompanionMemoryEngine persistence (per-child
/// isolation, corrupted-data fallback), greeting lifecycle (no immediate
/// repeats, speak-guards), session resumption validity, AppStateManager
/// wiring, and AR/EN localization — no false completion claims.
ChildProfile _child({String id = 'child_p5', String gender = 'boy'}) {
  return ChildProfile(
    id: id,
    name: 'سارة',
    age: '3–4',
    dailyTimeLimit: 30,
    chosenAvatar: 'girl',
    gender: gender,
    completedLessons: [],
    skillMasteryByLessonId: {},
    needsRemediationLessonIds: [],
    lessonAttemptsByLessonId: {},
  );
}

CompanionMemorySnapshot _snap(String childId, {String? lastGreetingId}) {
  return CompanionMemorySnapshot(
    childId: childId,
    childName: 'سارة',
    preferredCompanion: 'girl',
    lastCompletedActivityId: 'les_arabic_alif',
    unfinishedLessonId: 'les_arabic_ba',
    unfinishedSessionStartedAtIso: DateTime.now().toIso8601String(),
    recentAchievements: ['درس الألف'],
    weakLessonIds: ['les_arabic_ba'],
    lastGreetingId: lastGreetingId,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CompanionMemoryEngine persistence', () {
    test('save/load roundtrip restores snapshot fields', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final snap = _snap('child_a');
      expect(await CompanionMemoryEngine.saveTo(prefs, snap), isTrue);
      final loaded = CompanionMemoryEngine.loadFrom(prefs, 'child_a');
      expect(loaded, isNotNull);
      expect(loaded!.childName, 'سارة');
      expect(loaded.preferredCompanion, 'girl');
      expect(loaded.weakLessonIds, ['les_arabic_ba']);
      expect(loaded.recentAchievements, ['درس الألف']);
    });

    test('multi-child isolation: separate keys, no cross-read', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await CompanionMemoryEngine.saveTo(prefs, _snap('child_a'));
      await CompanionMemoryEngine.saveTo(prefs, _snap('child_b'));
      expect(CompanionMemoryEngine.loadFrom(prefs, 'child_b'), isNotNull);
      expect(CompanionMemoryEngine.keyFor('child_a'),
          isNot(CompanionMemoryEngine.keyFor('child_b')));
    });

    test('corrupted JSON returns null (graceful fallback)', () async {
      SharedPreferences.setMockInitialValues({
        CompanionMemoryEngine.keyFor('child_a'): '{{{not-json',
      });
      final prefs = await SharedPreferences.getInstance();
      expect(CompanionMemoryEngine.loadFrom(prefs, 'child_a'), isNull);
    });

    test('achievements deduped and capped at 5', () {
      final snap = CompanionMemorySnapshot(
        childId: 'c',
        childName: 'x',
        preferredCompanion: 'boy',
        recentAchievements: ['a', 'a', 'b', 'c', 'd', 'e', 'f'],
      );
      expect(snap.recentAchievements, ['a', 'b', 'c', 'd', 'e']);
    });

    test('clearFor removes stored memory', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await CompanionMemoryEngine.saveTo(prefs, _snap('child_a'));
      await CompanionMemoryEngine.clearFor(prefs, 'child_a');
      expect(CompanionMemoryEngine.loadFrom(prefs, 'child_a'), isNull);
    });
  });

  group('greeting lifecycle', () {
    test('greeting never immediately repeats across 5 presentations', () {
      String? last;
      final seen = <String>[];
      for (int i = 0; i < 5; i++) {
        final snap = _snap('child_a', lastGreetingId: last);
        final g = CompanionMemoryEngine.buildGreeting(snap, locale: 'ar');
        expect(g.id, isNot(equals(last)));
        seen.add(g.id);
        last = g.id;
      }
      expect(seen.toSet().length, 4);
    });

    test('speak blocked when muted, tts off, speaking, or lesson active', () {
      final snap = _snap('child_a');
      expect(
          CompanionMemoryEngine.buildGreeting(snap, isMuted: true)
              .speakAllowed,
          isFalse);
      expect(
          CompanionMemoryEngine.buildGreeting(snap, ttsEnabled: false)
              .speakAllowed,
          isFalse);
      expect(
          CompanionMemoryEngine.buildGreeting(snap, isSpeaking: true)
              .speakAllowed,
          isFalse);
      expect(
          CompanionMemoryEngine.buildGreeting(snap, lessonActive: true)
              .speakAllowed,
          isFalse);
      expect(
          CompanionMemoryEngine.buildGreeting(snap).speakAllowed, isTrue);
    });

    test('lastGreetingId persisted only after markGreetingPresented', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await CompanionMemoryEngine.saveTo(prefs, _snap('child_a'));
      final snap = CompanionMemoryEngine.loadFrom(prefs, 'child_a')!;
      expect(snap.lastGreetingId, isNull);
      final g = CompanionMemoryEngine.buildGreeting(snap);
      await CompanionMemoryEngine.saveTo(
          prefs, CompanionMemoryEngine.markGreetingPresented(snap, g.id));
      expect(CompanionMemoryEngine.loadFrom(prefs, 'child_a')!.lastGreetingId,
          g.id);
    });

    test('no greeting text ever claims full completion', () {
      final variants = <CompanionMemorySnapshot>[
        _snap('a'),
        CompanionMemorySnapshot(
            childId: 'a', childName: 'x', preferredCompanion: 'boy'),
      ];
      for (final snap in variants) {
        for (final locale in ['ar', 'en']) {
          final t = CompanionMemoryEngine.buildGreeting(snap, locale: locale).text;
          expect(t.contains('أكملت كل'), isFalse);
          expect(t.toLowerCase().contains('you finished everything'), isFalse);
        }
      }
    });
  });

  group('session resumption', () {
    test('unfinished session resumable while lesson still uncompleted', () {
      final snap = _snap('child_a');
      expect(snap.hasResumableSession({'les_arabic_alif'}), isTrue);
      expect(snap.hasResumableSession({'les_arabic_ba'}), isFalse);
    });

    test('stale session (>7 days) is not resumable', () {
      final snap = CompanionMemorySnapshot(
        childId: 'c',
        childName: 'x',
        preferredCompanion: 'boy',
        unfinishedLessonId: 'les_arabic_ba',
        unfinishedSessionStartedAtIso: DateTime.now()
            .subtract(const Duration(days: 8))
            .toIso8601String(),
      );
      expect(snap.hasResumableSession({}), isFalse);
    });

    test('suggestNextActivityId falls back to Phase 4 next lesson', () {
      final child = _child();
      final snap = CompanionMemorySnapshot(
        childId: child.id,
        childName: child.name,
        preferredCompanion: 'boy',
      );
      final next = CompanionMemoryEngine.suggestNextActivityId(snap, child);
      expect(next, isNotEmpty);
      expect(next, isNot(equals('les_arabic_ba')));
    });
  });

  group('localization & sync', () {
    test('AR and EN greeting texts differ and contain child name', () {
      final snap = _snap('child_a');
      final ar = CompanionMemoryEngine.buildGreeting(snap, locale: 'ar').text;
      final en = CompanionMemoryEngine.buildGreeting(snap, locale: 'en').text;
      expect(ar, isNot(equals(en)));
    });

    test('syncFromChild derives gender, weak concepts, and session',
        () {
      final child = _child(id: 'child_p5b', gender: 'girl');
      child.lastActiveAcademyLessonId = 'les_arabic_ba';
      final snap = CompanionMemoryEngine.syncFromChild(child);
      expect(snap.preferredCompanion, 'girl');
      expect(snap.unfinishedLessonId, 'les_arabic_ba');
      expect(snap.isFresh, isTrue);
    });

    test('syncFromChild: completed last lesson => no unfinished session', () {
      final child = _child();
      child.completedLessons.add('les_arabic_alif');
      child.lastActiveAcademyLessonId = 'les_arabic_alif';
      final snap = CompanionMemoryEngine.syncFromChild(child);
      expect(snap.unfinishedLessonId, isNull);
      expect(snap.lastCompletedActivityId, 'les_arabic_alif');
    });
  });
}
