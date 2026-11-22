import 'package:flutter_test/flutter_test.dart';
import 'package:haneen_kids_vod/haneen_kids_exports.dart';

/// Pinned Phase 4 tests: LessonProgressBridge bridges the Phase 2 attempt
/// ledger to AdaptiveLearningEngine recommendations (weak-concept detection,
/// remediation trigger, next lesson + brain game, gradual difficulty) with
/// no score mutation, no demotion, and AR/EN curricula intact.
ChildProfile _child({
  Map<String, List<LessonAttemptRecord>> ledger = const {},
  List<String> remediation = const [],
  int tier = 2,
}) {
  final ChildProfile child = ChildProfile(    id: 'child_p4',
    name: 'سارة',
    age: '3–4',
    dailyTimeLimit: 30,
    chosenAvatar: 'girl',
    currentCurriculumTier: tier,
    completedLessons: [],
    skillMasteryByLessonId: {},
    needsRemediationLessonIds: List<String>.from(remediation),
    lessonAttemptsByLessonId: Map<String, List<LessonAttemptRecord>>.from(ledger),
  );
  return child;
}

LessonAttemptRecord _rec(LessonAttemptOutcome outcome,
    {int hint = 0, int ms = 0}) {
  return LessonAttemptRecord(
    id: 'r_$ms',
    lessonId: 'l',
    outcome: outcome,
    timestampIso: DateTime.fromMillisecondsSinceEpoch(1735689600000 - ms)
        .toIso8601String(),
    hintLevelUsed: hint,
    answerRevealed: false,
  );
}

void main() {
  group('LessonProgressBridge weak-concept detection', () {
    test('repeatedMistake in latest 3 attempts flags a weak lesson', () {
      final records = [
        _rec(LessonAttemptOutcome.repeatedMistake, ms: 3),
        _rec(LessonAttemptOutcome.incorrect, ms: 2),
        _rec(LessonAttemptOutcome.incorrect, ms: 1),
      ];
      expect(LessonProgressBridge.isWeakLesson(records), isTrue);
    });

    test('2+ failures in latest 4 attempts flags a weak lesson', () {
      final records = [
        _rec(LessonAttemptOutcome.incorrect, ms: 4),
        _rec(LessonAttemptOutcome.independentCorrect, ms: 3),
        _rec(LessonAttemptOutcome.independentCorrect, ms: 2),
        _rec(LessonAttemptOutcome.incorrect, ms: 1),
      ];
      expect(LessonProgressBridge.isWeakLesson(records), isTrue);
    });

    test('success-only history and empty ledger are not weak', () {
      expect(LessonProgressBridge.isWeakLesson(const []), isFalse);
      expect(
        LessonProgressBridge.isWeakLesson([
          _rec(LessonAttemptOutcome.independentCorrect, ms: 3),
          _rec(LessonAttemptOutcome.correctAfterHint, ms: 2),
          _rec(LessonAttemptOutcome.independentCorrect, ms: 1),
        ]),
        isFalse,
      );
    });

    test('old failures beyond the latest 4 attempts are ignored', () {
      final records = [
        _rec(LessonAttemptOutcome.independentCorrect, ms: 5),
        _rec(LessonAttemptOutcome.independentCorrect, ms: 4),
        _rec(LessonAttemptOutcome.independentCorrect, ms: 3),
        _rec(LessonAttemptOutcome.independentCorrect, ms: 2),
        _rec(LessonAttemptOutcome.incorrect, ms: 1),
        _rec(LessonAttemptOutcome.incorrect, ms: 0),
      ];
      expect(LessonProgressBridge.isWeakLesson(records), isFalse);
    });
  });

  group('LessonProgressBridge remediation trigger', () {
    test('repeated mistakes trigger remediation for unflagged lessons only',
        () {
      final child = _child(
        ledger: {
          'les_arabic_alif': [
            _rec(LessonAttemptOutcome.repeatedMistake, ms: 1),
          ],
        },
        remediation: const ['already_flagged_lesson'],
      );
      final res = LessonProgressBridge.analyze(child: child);
      expect(res.weakLessonIds, contains('les_arabic_alif'));
      expect(res.remediationLessonIds, ['les_arabic_alif']);
      expect(res.triggeredRemediation, isTrue);
      // Pure: the profile is untouched.
      expect(child.needsRemediationLessonIds, ['already_flagged_lesson']);
      expect(child.skillMasteryByLessonId, isEmpty);
    });

    test('already-remediated weak lesson is not re-flagged', () {
      final child = _child(
        ledger: {
          'les_arabic_alif': [_rec(LessonAttemptOutcome.repeatedMistake)],
        },
        remediation: const ['les_arabic_alif'],
      );
      final res = LessonProgressBridge.analyze(child: child);
      expect(res.weakLessonIds, ['les_arabic_alif']);
      expect(res.remediationLessonIds, isEmpty);
      expect(res.triggeredRemediation, isFalse);
    });

    test('clean history yields no remediation and positive message', () {
      final child = _child(
        ledger: {
          'les_arabic_alif': [
            _rec(LessonAttemptOutcome.independentCorrect),
          ],
        },
      );
      final res = LessonProgressBridge.analyze(child: child);
      expect(res.triggeredRemediation, isFalse);
      expect(res.recommendationMessageAr, contains('أحسنت'));
    });
  });

  group('LessonProgressBridge recommendations', () {
    test('weak lesson is prioritized as the next lesson', () {
      final child = _child(
        ledger: {
          'les_arabic_alif': [_rec(LessonAttemptOutcome.repeatedMistake)],
        },
      );
      final res = LessonProgressBridge.analyze(child: child);
      expect(res.nextLesson.id, 'les_arabic_alif');
      expect(res.nextLessonMastery, LessonMasteryLevel.attempted);
      expect(res.recommendationMessageAr, contains('تدريباً إضافياً'));
    });

    test('strong child gets next unmastered lesson in tier', () {
      final child = _child(
        ledger: {
          'les_arabic_alif': [
            _rec(LessonAttemptOutcome.independentCorrect, ms: 3),
            _rec(LessonAttemptOutcome.independentCorrect, ms: 2),
            _rec(LessonAttemptOutcome.independentCorrect, ms: 1),
          ],
        },
      );
      child.skillMasteryByLessonId['les_arabic_alif'] = 100;
      final res = LessonProgressBridge.analyze(child: child);
      expect(res.nextLesson.id, isNot('les_arabic_alif'));
      expect(res.nextLesson.tierLevel, 2);
    });

    test('brain game recommendation is reused with gradual level', () {
      for (int gamesCompleted in [0, 10, 30]) {
        final child = _child(tier: 2);
        child.gamesCompletedCount = gamesCompleted;
        child.gameProgressByGameId['memory_match_lvl'] = gamesCompleted;
        child.gameProgressByGameId['pic_match'] = gamesCompleted;
        child.gameProgressByGameId['classify'] = gamesCompleted;
        child.gameProgressByGameId['pattern_logic'] = gamesCompleted;
        child.gameProgressByGameId['math_counting'] = gamesCompleted;
        final res = LessonProgressBridge.analyze(child: child);
        expect(res.gameRecommendation.recommendedGameId, isNotEmpty);
        final int level = res.gameRecommendation.recommendedGameLevel;
        expect(level, inInclusiveRange(1, 100));
        // Gradual: exactly one step above the stored progress for the
        // recommended game, never a jump.
        final int? progress =
            child.gameProgressByGameId[res.gameRecommendation.recommendedGameId];
        expect(level, (progress ?? 0) + 1);
      }
    });

    test('existing mastery scores and tier are never changed', () {
      final child = _child(
        ledger: {
          'les_arabic_alif': [_rec(LessonAttemptOutcome.repeatedMistake)],
        },
        tier: 3,
      );
      child.skillMasteryByLessonId['les_arabic_alif'] = 90;
      LessonProgressBridge.analyze(child: child);
      expect(child.skillMasteryByLessonId['les_arabic_alif'], 90);
      expect(child.currentCurriculumTier, 3);
    });
  });

  group('LessonProgressBridge AR/EN localization', () {
    test('works with both AR and EN curricula deterministically', () {
      for (final curriculum in [
        kHaneenAcademyCurriculum,
        kHaneenAcademyCurriculumEn,
      ]) {
        final child = _child(
          ledger: {
            curriculum.first.id: [
              _rec(LessonAttemptOutcome.repeatedMistake),
            ],
          },
        );
        final res = LessonProgressBridge.analyze(
          child: child,
          curriculum: curriculum,
        );
        expect(res.nextLesson.id, curriculum.first.id);
        expect(res.triggeredRemediation, isTrue);
      }
    });
  });
}
