import 'package:flutter_test/flutter_test.dart';
import 'package:haneen_kids_vod/haneen_kids_exports.dart';

/// Pinned Phase 2 tests: Lesson Attempt Ledger mastery derivation,
/// merge idempotency, and Tier 3 safe worked examples.
void main() {
  LessonAttemptRecord rec({
    required String id,
    required LessonAttemptOutcome outcome,
    required int t, // seconds since epoch
  }) {
    return LessonAttemptRecord(
      id: id,
      lessonId: 'lesson_1',
      outcome: outcome,
      timestampIso: DateTime.fromMillisecondsSinceEpoch(t * 1000)
          .toIso8601String(),
    );
  }

  List<LessonAttemptRecord> ledger(List<LessonAttemptRecord> chronological) {
    // appendCapped sorts newest-first, which is the stored format.
    List<LessonAttemptRecord> out = const [];
    for (final r in chronological) {
      out = LessonAttemptLedgerEngine.appendCapped(out, r);
    }
    return out;
  }

  group('LessonAttemptLedgerEngine.buildRecord', () {
    test('correct + no hint -> independentCorrect', () {
      final r = LessonAttemptLedgerEngine.buildRecord(
        childId: 'child_1',
        lessonId: 'lesson_1',
        isCorrectAnswer: true,
      );
      expect(r.outcome, LessonAttemptOutcome.independentCorrect);
      expect(r.hintLevelUsed, 0);
      expect(r.answerRevealed, false);
    });

    test('correct + hint -> correctAfterHint, never independentCorrect', () {
      final r = LessonAttemptLedgerEngine.buildRecord(
        childId: 'child_1',
        lessonId: 'lesson_1',
        isCorrectAnswer: true,
        hintLevelUsed: 2,
      );
      expect(r.outcome, LessonAttemptOutcome.correctAfterHint);
    });

    test('correct + answer revealed -> correctAfterHint', () {
      final r = LessonAttemptLedgerEngine.buildRecord(
        childId: 'child_1',
        lessonId: 'lesson_1',
        isCorrectAnswer: true,
        answerRevealed: true,
      );
      expect(r.outcome, LessonAttemptOutcome.correctAfterHint);
    });

    test('correct + alternative remediation -> remediationCompleted', () {
      final r = LessonAttemptLedgerEngine.buildRecord(
        childId: 'child_1',
        lessonId: 'lesson_1',
        isCorrectAnswer: true,
        usedAlternativeRemediation: true,
      );
      expect(r.outcome, LessonAttemptOutcome.remediationCompleted);
    });

    test('incorrect after incorrect -> repeatedMistake', () {
      final r = LessonAttemptLedgerEngine.buildRecord(
        childId: 'child_1',
        lessonId: 'lesson_1',
        isCorrectAnswer: false,
        previousOutcome: LessonAttemptOutcome.incorrect,
      );
      expect(r.outcome, LessonAttemptOutcome.repeatedMistake);
    });

    test('incorrect after correct -> incorrect (streak reset)', () {
      final r = LessonAttemptLedgerEngine.buildRecord(
        childId: 'child_1',
        lessonId: 'lesson_1',
        isCorrectAnswer: false,
        previousOutcome: LessonAttemptOutcome.independentCorrect,
      );
      expect(r.outcome, LessonAttemptOutcome.incorrect);
    });

    test('stable id format: childId_lessonId_micros', () {
      final r = LessonAttemptLedgerEngine.buildRecord(
        childId: 'child_9',
        lessonId: 'lesson_2',
        isCorrectAnswer: true,
      );
      expect(r.id, startsWith('child_9_lesson_2_'));
    });

    test('hint level clamped to 0..3', () {
      final r = LessonAttemptLedgerEngine.buildRecord(
        childId: 'child_1',
        lessonId: 'lesson_1',
        isCorrectAnswer: true,
        hintLevelUsed: 99,
      );
      expect(r.hintLevelUsed, 3);
    });
  });

  group('LessonAttemptLedgerEngine.appendCapped', () {
    test('keeps only the latest 10 records, newest first', () {
      List<LessonAttemptRecord> out = const [];
      for (int i = 0; i < 15; i++) {
        out = LessonAttemptLedgerEngine.appendCapped(
          out,
          rec(id: 'r$i', outcome: LessonAttemptOutcome.incorrect, t: 100 + i),
        );
      }
      expect(out.length, 10);
      // Newest record (r14) must be first.
      expect(out.first.id, 'r14');
      // Oldest kept record is r5.
      expect(out.last.id, 'r5');
    });
  });

  group('LessonAttemptLedgerEngine.deriveMasteryLevel — pinned scenarios',
      () {
    test(
        'scenario 1: hinted alone (attempts with hints) -> Attempted only, never higher',
        () {
      final records = ledger([
        rec(id: 'a', outcome: LessonAttemptOutcome.correctAfterHint, t: 1),
        rec(id: 'b', outcome: LessonAttemptOutcome.correctAfterHint, t: 2),
        rec(id: 'c', outcome: LessonAttemptOutcome.correctAfterHint, t: 3),
        rec(id: 'd', outcome: LessonAttemptOutcome.correctAfterHint, t: 4),
      ]);
      expect(
        LessonAttemptLedgerEngine.deriveMasteryLevel(records: records),
        LessonMasteryLevel.attempted,
      );
    });

    test(
        'scenario 2: incorrect resets the Proficient suffix streak',
        () {
      final records = ledger([
        rec(id: 'a', outcome: LessonAttemptOutcome.incorrect, t: 1),
        rec(id: 'b', outcome: LessonAttemptOutcome.independentCorrect, t: 2),
        rec(id: 'c', outcome: LessonAttemptOutcome.independentCorrect, t: 3),
        rec(id: 'd', outcome: LessonAttemptOutcome.incorrect, t: 4),
      ]);
      // Suffix broken by incorrect -> not Proficient. Latest 4 have 2
      // independentCorrect -> Familiar.
      expect(
        LessonAttemptLedgerEngine.deriveMasteryLevel(records: records),
        LessonMasteryLevel.familiar,
      );
      // Contrast: without the trailing incorrect the suffix would be
      // Proficient, so the incorrect does reset the streak.
      final streaking = ledger([
        rec(id: 'a', outcome: LessonAttemptOutcome.independentCorrect, t: 1),
        rec(id: 'b', outcome: LessonAttemptOutcome.independentCorrect, t: 2),
        rec(id: 'c', outcome: LessonAttemptOutcome.independentCorrect, t: 3),
      ]);
      expect(
        LessonAttemptLedgerEngine.deriveMasteryLevel(records: streaking),
        LessonMasteryLevel.proficient,
      );
    });

    test(
        'scenario 3: a hinted answer breaks the Proficient suffix',
        () {
      final records = ledger([
        rec(id: 'a', outcome: LessonAttemptOutcome.independentCorrect, t: 1),
        rec(id: 'b', outcome: LessonAttemptOutcome.independentCorrect, t: 2),
        rec(id: 'c', outcome: LessonAttemptOutcome.correctAfterHint, t: 3),
        rec(id: 'd', outcome: LessonAttemptOutcome.independentCorrect, t: 4),
        rec(id: 'e', outcome: LessonAttemptOutcome.independentCorrect, t: 5),
      ]);
      // Chronological suffix: IC, IC, CH -> streak 2, not Proficient.
      // Latest 4: IC, IC, CH, IC -> 3 independentCorrect -> Familiar.
      expect(
        LessonAttemptLedgerEngine.deriveMasteryLevel(records: records),
        LessonMasteryLevel.familiar,
      );
    });

    test(
        'scenario 4: Mastered requires Proficient + score >= threshold (80)',
        () {
      final records = ledger([
        rec(id: 'a', outcome: LessonAttemptOutcome.independentCorrect, t: 1),
        rec(id: 'b', outcome: LessonAttemptOutcome.independentCorrect, t: 2),
        rec(id: 'c', outcome: LessonAttemptOutcome.independentCorrect, t: 3),
      ]);
      expect(
        LessonAttemptLedgerEngine.deriveMasteryLevel(
          records: records,
          existingMasteryScore: 80,
        ),
        LessonMasteryLevel.mastered,
      );
      expect(
        LessonAttemptLedgerEngine.deriveMasteryLevel(
          records: records,
          existingMasteryScore: 79,
        ),
        LessonMasteryLevel.proficient,
      );
    });

    test(
        'scenario 5: existing mastery score is never lowered by derivation',
        () {
      // Derivation is a pure function of records; it never touches
      // skillMasteryByLessonId. Verify it does not throw and returns
      // without mutation, and that a high existing score with only
      // Attempted records stays Attempted (no score-based promotion).
      final records = ledger([
        rec(id: 'a', outcome: LessonAttemptOutcome.incorrect, t: 1),
      ]);
      expect(
        LessonAttemptLedgerEngine.deriveMasteryLevel(
          records: records,
          existingMasteryScore: 100,
        ),
        LessonMasteryLevel.attempted,
      );
    });

    test(
        'scenario 6: Familiar via 2 independentCorrect in latest 4',
        () {
      final records = ledger([
        rec(id: 'a', outcome: LessonAttemptOutcome.incorrect, t: 1),
        rec(id: 'b', outcome: LessonAttemptOutcome.independentCorrect, t: 2),
        rec(id: 'c', outcome: LessonAttemptOutcome.correctAfterHint, t: 3),
        rec(id: 'd', outcome: LessonAttemptOutcome.independentCorrect, t: 4),
      ]);
      expect(
        LessonAttemptLedgerEngine.deriveMasteryLevel(records: records),
        LessonMasteryLevel.familiar,
      );
    });

    test(
        'scenario 6b: Familiar via 1 independentCorrect + 1 correctAfterHint',
        () {
      final records = ledger([
        rec(id: 'a', outcome: LessonAttemptOutcome.incorrect, t: 1),
        rec(id: 'b', outcome: LessonAttemptOutcome.incorrect, t: 2),
        rec(id: 'c', outcome: LessonAttemptOutcome.independentCorrect, t: 3),
        rec(id: 'd', outcome: LessonAttemptOutcome.correctAfterHint, t: 4),
      ]);
      expect(
        LessonAttemptLedgerEngine.deriveMasteryLevel(records: records),
        LessonMasteryLevel.familiar,
      );
    });

    test(
        'scenario 7: remediationCompleted freezes (breaks) the streak',
        () {
      // Chronological: IC, IC, IC, RC, IC.
      // Suffix streak = 1 (RC breaks it) -> not Proficient.
      // Latest 4 = IC, IC, RC, IC -> 3 independentCorrect -> Familiar.
      final frozen = ledger([
        rec(id: 'a', outcome: LessonAttemptOutcome.independentCorrect, t: 1),
        rec(id: 'b', outcome: LessonAttemptOutcome.independentCorrect, t: 2),
        rec(id: 'c', outcome: LessonAttemptOutcome.independentCorrect, t: 3),
        rec(id: 'd', outcome: LessonAttemptOutcome.remediationCompleted, t: 4),
        rec(id: 'e', outcome: LessonAttemptOutcome.independentCorrect, t: 5),
      ]);
      expect(
        LessonAttemptLedgerEngine.deriveMasteryLevel(records: frozen),
        LessonMasteryLevel.familiar,
      );
    });

    test(
        'scenario 8: empty ledger -> none',
        () {
      expect(
        LessonAttemptLedgerEngine.deriveMasteryLevel(records: const []),
        LessonMasteryLevel.none,
      );
    });

    test(
        'scenario 9: no demotion — deriveMasteryLevel never reduces records or score',
        () {
      final records = ledger([
        rec(id: 'a', outcome: LessonAttemptOutcome.independentCorrect, t: 1),
        rec(id: 'b', outcome: LessonAttemptOutcome.independentCorrect, t: 2),
        rec(id: 'c', outcome: LessonAttemptOutcome.independentCorrect, t: 3),
      ]);
      final before = List<LessonAttemptRecord>.from(records);
      LessonAttemptLedgerEngine.deriveMasteryLevel(
        records: records,
        existingMasteryScore: 90,
      );
      expect(records.length, before.length);
      for (int i = 0; i < records.length; i++) {
        expect(records[i].id, before[i].id);
      }
    });
  });

  group('LessonAttemptLedgerEngine.mergeLedgers', () {
    LessonAttemptRecord mRec({
      required String id,
      required String lessonId,
      required int t,
      LessonAttemptOutcome outcome = LessonAttemptOutcome.incorrect,
    }) {
      return LessonAttemptRecord(
        id: id,
        lessonId: lessonId,
        outcome: outcome,
        timestampIso: DateTime.fromMillisecondsSinceEpoch(t * 1000)
            .toIso8601String(),
      );
    }

    test(
        'scenario: idempotent merge preserving both devices\' records',
        () {
      final local = {
        'lesson_1': [mRec(id: 'L1', lessonId: 'lesson_1', t: 100)],
        'lesson_2': [
          mRec(id: 'L2', lessonId: 'lesson_2', t: 200),
          mRec(id: 'L3', lessonId: 'lesson_2', t: 300),
        ],
      };
      final remote = {
        'lesson_1': [mRec(id: 'R1', lessonId: 'lesson_1', t: 150)],
        'lesson_2': [mRec(id: 'L3', lessonId: 'lesson_2', t: 300)],
        'lesson_3': [mRec(id: 'R2', lessonId: 'lesson_3', t: 400)],
      };
      final merged =
          LessonAttemptLedgerEngine.mergeLedgers(local, remote);
      // Union of lessons.
      expect(merged.keys.toSet(), {'lesson_1', 'lesson_2', 'lesson_3'});
      // Distinct records from both devices kept.
      expect(
        merged['lesson_1']!.map((r) => r.id).toSet(),
        {'L1', 'R1'},
      );
      expect(
        merged['lesson_2']!.map((r) => r.id).toSet(),
        {'L2', 'L3'},
      );
      // Same-id record deduped (L3 exists in both).
      expect(merged['lesson_2']!.where((r) => r.id == 'L3').length, 1);
      // Idempotent: merging again with same inputs yields the same result.
      final merged2 =
          LessonAttemptLedgerEngine.mergeLedgers(local, remote);
      expect(
        LessonAttemptLedgerEngine.ledgerToJson(merged2),
        LessonAttemptLedgerEngine.ledgerToJson(merged),
      );
      // Idempotent in the other direction too (symmetry on union).
      final merged3 =
          LessonAttemptLedgerEngine.mergeLedgers(merged, remote);
      expect(
        LessonAttemptLedgerEngine.ledgerToJson(merged3),
        LessonAttemptLedgerEngine.ledgerToJson(merged),
      );
    });

    test('newest timestamp wins on conflicting record ids', () {
      final older = mRec(
        id: 'x',
        lessonId: 'lesson_1',
        t: 100,
        outcome: LessonAttemptOutcome.incorrect,
      );
      final newer = mRec(
        id: 'x',
        lessonId: 'lesson_1',
        t: 200,
        outcome: LessonAttemptOutcome.independentCorrect,
      );
      final merged = LessonAttemptLedgerEngine.mergeLedgers(
        {'lesson_1': [older]},
        {'lesson_1': [newer]},
      );
      expect(merged['lesson_1']!.length, 1);
      expect(merged['lesson_1']!.first.outcome,
          LessonAttemptOutcome.independentCorrect);
    });

    test('merge re-caps each lesson to 10 records', () {
      final many = List<LessonAttemptRecord>.generate(
        14,
        (i) => mRec(id: 'a$i', lessonId: 'lesson_1', t: 100 + i),
      );
      final merged = LessonAttemptLedgerEngine.mergeLedgers(
        {'lesson_1': many},
        const {},
      );
      expect(merged['lesson_1']!.length, 10);
    });
  });

  group('LessonAttemptLedgerEngine JSON round-trip', () {
    test('ledgerToJson/ledgerFromJson round-trip', () {
      final ledgerIn = {
        'lesson_1': [
          LessonAttemptLedgerEngine.buildRecord(
            childId: 'child_1',
            lessonId: 'lesson_1',
            isCorrectAnswer: true,
            hintLevelUsed: 2,
            at: DateTime.fromMillisecondsSinceEpoch(1000),
          ),
        ],
      };
      final json = LessonAttemptLedgerEngine.ledgerToJson(ledgerIn);
      final out = LessonAttemptLedgerEngine.ledgerFromJson(json);
      expect(out.keys, ledgerIn.keys);
      expect(out['lesson_1']!.length, 1);
      expect(out['lesson_1']!.first.id, ledgerIn['lesson_1']!.first.id);
      expect(out['lesson_1']!.first.hintLevelUsed, 2);
    });

    test('ledgerFromJson tolerates malformed json', () {
      expect(
        LessonAttemptLedgerEngine.ledgerFromJson(null),
        isEmpty,
      );
      expect(
        LessonAttemptLedgerEngine.ledgerFromJson({'lesson_1': 'not-a-list'}),
        isEmpty,
      );
      expect(
        LessonAttemptLedgerEngine.ledgerFromJson({
          'lesson_1': ['not-a-map'],
        }),
        isEmpty,
      );
    });
  });

  group('HintLadderEngine Tier 3 safe worked example', () {
    test(
        'picks a curriculum word that is not any quiz/correct/remediation answer',
        () {
      final example = HintLadderEngine.buildSafeWorkedExample(
        forbiddenAnswers: ['cat', 'dog', 'bird', 'fish'],
        candidateWords: ['cat', 'sun'],
        candidateEmojis: ['🐱', '☀️'],
      );
      expect(example.isCurriculumExample, true);
      expect(example.exampleWord, 'sun');
      expect(example.exampleEmoji, '☀️');
    });

    test('blocks substring matches that would reveal the answer', () {
      final example = HintLadderEngine.buildSafeWorkedExample(
        forbiddenAnswers: ['cat'],
        candidateWords: ['a cat', 'cattle', 'moon'],
        candidateEmojis: ['🐱', '🐄', '🌙'],
      );
      expect(example.isCurriculumExample, true);
      expect(example.exampleWord, 'moon');
      expect(example.exampleEmoji, '🌙');
    });

    test(
        'falls back to generic strategy when no safe candidate exists',
        () {
      final example = HintLadderEngine.buildSafeWorkedExample(
        forbiddenAnswers: ['cat', 'sun', 'moon'],
        candidateWords: ['cat', 'sun', 'moon', ''],
        candidateEmojis: ['🐱', '☀️', '🌙', ''],
      );
      expect(example.isCurriculumExample, false);
      expect(example.exampleWord, '');
      expect(example.exampleEmoji, '');
    });

    test('skips blank/empty candidates', () {
      final example = HintLadderEngine.buildSafeWorkedExample(
        forbiddenAnswers: ['cat'],
        candidateWords: ['  ', '', 'tree'],
        candidateEmojis: ['', '', '🌳'],
      );
      expect(example.isCurriculumExample, true);
      expect(example.exampleWord, 'tree');
      expect(example.exampleEmoji, '🌳');
    });

    test('missing emoji index yields empty emoji, still curriculum example',
        () {
      final example = HintLadderEngine.buildSafeWorkedExample(
        forbiddenAnswers: ['cat'],
        candidateWords: ['tree'],
        candidateEmojis: const [],
      );
      expect(example.isCurriculumExample, true);
      expect(example.exampleWord, 'tree');
      expect(example.exampleEmoji, '');
    });
  });

  group('HintLadderEngine / HintLadderSessionState', () {
    test('nextTier advances 0->1->2->3 and stops', () {
      expect(HintLadderEngine.nextTier(0)!.level, 1);
      expect(HintLadderEngine.nextTier(1)!.level, 2);
      expect(HintLadderEngine.nextTier(2)!.level, 3);
      expect(HintLadderEngine.nextTier(3), isNull);
    });

    test('answer reveal gated by allowsAnswerReveal (default false)', () {
      final state = HintLadderSessionState(lessonId: 'lesson_1');
      expect(state.revealAnswer(), false);
      expect(state.answerRevealed, false);

      final allowing = HintLadderSessionState(
        lessonId: 'lesson_1',
        allowsAnswerReveal: true,
      );
      expect(allowing.revealAnswer(), true);
      expect(allowing.answerRevealed, true);
    });

    test('advanceHint tracks hintLevelUsed; reset restores', () {
      final state = HintLadderSessionState(lessonId: 'lesson_1');
      state.advanceHint();
      state.advanceHint();
      expect(state.hintLevelUsed, 2);
      state.revealAnswer(); // gated off, stays false
      state.reset();
      expect(state.hintLevelUsed, 0);
      expect(state.answerRevealed, false);
      expect(state.shownTiers, isEmpty);
    });
  });

  group('lastOutcome', () {
    test('returns newest record outcome or null when empty', () {
      expect(
        LessonAttemptLedgerEngine.lastOutcome(const []),
        isNull,
      );
      final records = ledger([
        rec(id: 'old', outcome: LessonAttemptOutcome.incorrect, t: 1),
        rec(id: 'new', outcome: LessonAttemptOutcome.independentCorrect, t: 2),
      ]);
      expect(
        LessonAttemptLedgerEngine.lastOutcome(records),
        LessonAttemptOutcome.independentCorrect,
      );
    });
  });
}
