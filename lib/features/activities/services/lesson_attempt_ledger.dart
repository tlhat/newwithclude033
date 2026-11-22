/// Outcome of a single lesson attempt recorded in the ledger.
enum LessonAttemptOutcome {
  independentCorrect,
  correctAfterHint,
  incorrect,
  repeatedMistake,
  remediationCompleted,
}

/// Derived mastery level (Khan Academy style). Levels are ordered and
/// derived ONLY from the attempt ledger; they are fully separate from
/// `skillMasteryByLessonId` scores which are never modified by this engine.
enum LessonMasteryLevel {
  none,
  attempted,
  familiar,
  proficient,
  mastered,
}

const int kLessonAttemptLedgerMaxRecords = 10;

/// One attempt record in the per-lesson attempt ledger (latest 10 kept).
class LessonAttemptRecord {
  final String id;
  final String lessonId;
  final LessonAttemptOutcome outcome;
  final String timestampIso;
  final int hintLevelUsed;
  final bool answerRevealed;

  const LessonAttemptRecord({
    required this.id,
    required this.lessonId,
    required this.outcome,
    required this.timestampIso,
    this.hintLevelUsed = 0,
    this.answerRevealed = false,
  });

  LessonAttemptRecord copyWith({LessonAttemptOutcome? outcome}) =>
      LessonAttemptRecord(
        id: id,
        lessonId: lessonId,
        outcome: outcome ?? this.outcome,
        timestampIso: timestampIso,
        hintLevelUsed: hintLevelUsed,
        answerRevealed: answerRevealed,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'lessonId': lessonId,
        'outcome': outcome.name,
        'timestampIso': timestampIso,
        'hintLevelUsed': hintLevelUsed,
        'answerRevealed': answerRevealed,
      };

  factory LessonAttemptRecord.fromJson(Map<String, dynamic> json) {
    return LessonAttemptRecord(
      id: (json['id'] ?? '').toString(),
      lessonId: (json['lessonId'] ?? '').toString(),
      outcome: _outcomeFromName(json['outcome']?.toString()),
      timestampIso: (json['timestampIso'] ?? '').toString(),
      hintLevelUsed:
          int.tryParse(json['hintLevelUsed']?.toString() ?? '0') ?? 0,
      answerRevealed: json['answerRevealed']?.toString() == 'true',
    );
  }

  static LessonAttemptOutcome _outcomeFromName(String? name) {
    for (final o in LessonAttemptOutcome.values) {
      if (o.name == name) return o;
    }
    return LessonAttemptOutcome.incorrect;
  }
}

/// Pure, offline, deterministic engine for the lesson attempt ledger and
/// derived mastery levels. No I/O, no mutation of `skillMasteryByLessonId`.
class LessonAttemptLedgerEngine {
  /// Builds one record and classifies its outcome deterministically:
  /// - correct + alternative remediation used  -> remediationCompleted
  /// - correct + no hint + no answer reveal    -> independentCorrect
  /// - correct + hint used or answer revealed  -> correctAfterHint
  ///   (a correct answer after a hint is NEVER an independentCorrect)
  /// - incorrect after a previous incorrect/repeatedMistake -> repeatedMistake
  /// - incorrect otherwise                     -> incorrect
  static LessonAttemptRecord buildRecord({
    required String childId,
    required String lessonId,
    required bool isCorrectAnswer,
    bool usedAlternativeRemediation = false,
    int hintLevelUsed = 0,
    bool answerRevealed = false,
    LessonAttemptOutcome? previousOutcome,
    DateTime? at,
  }) {
    final DateTime now = at ?? DateTime.now();
    final LessonAttemptOutcome outcome;
    if (isCorrectAnswer) {
      if (usedAlternativeRemediation) {
        outcome = LessonAttemptOutcome.remediationCompleted;
      } else if (hintLevelUsed > 0 || answerRevealed) {
        outcome = LessonAttemptOutcome.correctAfterHint;
      } else {
        outcome = LessonAttemptOutcome.independentCorrect;
      }
    } else {
      if (previousOutcome == LessonAttemptOutcome.incorrect ||
          previousOutcome == LessonAttemptOutcome.repeatedMistake) {
        outcome = LessonAttemptOutcome.repeatedMistake;
      } else {
        outcome = LessonAttemptOutcome.incorrect;
      }
    }
    return LessonAttemptRecord(
      id: '${childId}_$lessonId${_nowIsoKey(now)}',
      lessonId: lessonId,
      outcome: outcome,
      timestampIso: now.toIso8601String(),
      hintLevelUsed: hintLevelUsed.clamp(0, 3),
      answerRevealed: answerRevealed,
    );
  }

  static String _nowIsoKey(DateTime now) =>
      '_${now.microsecondsSinceEpoch}';

  /// Appends a record to the per-lesson list, keeping the latest 10
  /// (sorted newest-first). Records are never silently discarded otherwise.
  static List<LessonAttemptRecord> appendCapped(
    List<LessonAttemptRecord> existing,
    LessonAttemptRecord record,
  ) {
    final List<LessonAttemptRecord> next = [...existing, record]
      ..sort((a, b) => b.timestampIso.compareTo(a.timestampIso));
    return next.take(kLessonAttemptLedgerMaxRecords).toList();
  }

  /// Derives the mastery level from the ledger records (newest first).
  ///
  /// - Attempted: at least 1 attempt.
  /// - Familiar: >=2 independentCorrect in the latest 4 attempts, OR
  ///   1 independentCorrect + 1 correctAfterHint in the latest 4.
  /// - Proficient: 3 consecutive independentCorrect at the END of the
  ///   attempt history (contiguous suffix). incorrect/repeatedMistake reset
  ///   the streak; correctAfterHint/remediationCompleted freeze it (break
  ///   the contiguous suffix without extending it); a hinted answer never
  ///   counts toward the streak.
  /// - Mastered: Proficient + existing mastery score >= required score
  ///   (lesson.requiredMasteryScore, default 80). Never demotes or modifies
  ///   existing scores.
  static LessonMasteryLevel deriveMasteryLevel({
    required List<LessonAttemptRecord> records,
    int existingMasteryScore = 0,
    int requiredMasteryScore = 80,
  }) {
    if (records.isEmpty) return LessonMasteryLevel.none;
    final level = _deriveIgnoringScore(records);
    if (level == LessonMasteryLevel.proficient &&
        existingMasteryScore >= requiredMasteryScore) {
      return LessonMasteryLevel.mastered;
    }
    return level;
  }

  static LessonMasteryLevel _deriveIgnoringScore(
      List<LessonAttemptRecord> records) {
    // Records are stored newest-first; evaluate chronologically from the end.
    final List<LessonAttemptRecord> chronological =
        records.reversed.toList();
    if (chronological.isEmpty) return LessonMasteryLevel.none;

    // Familiar: latest 4 attempts window.
    final List<LessonAttemptRecord> latest4 =
        chronological.length <= 4 ? chronological : chronological.sublist(chronological.length - 4);
    int independentCorrect = 0;
    int correctAfterHint = 0;
    for (final r in latest4) {
      if (r.outcome == LessonAttemptOutcome.independentCorrect) {
        independentCorrect++;
      } else if (r.outcome == LessonAttemptOutcome.correctAfterHint) {
        correctAfterHint++;
      }
    }
    final bool familiar = independentCorrect >= 2 ||
        (independentCorrect >= 1 && correctAfterHint >= 1);

    // Proficient: contiguous suffix of 3 independentCorrect.
    int streak = 0;
    for (int i = chronological.length - 1; i >= 0; i--) {
      if (chronological[i].outcome == LessonAttemptOutcome.independentCorrect) {
        streak++;
        if (streak >= 3) break;
      } else {
        break;
      }
    }
    final bool proficient = streak >= 3;
    if (proficient) return LessonMasteryLevel.proficient;
    if (familiar) return LessonMasteryLevel.familiar;
    return LessonMasteryLevel.attempted;
  }

  /// Union-by-record-id merge of two ledgers. Newest timestamp wins on
  /// conflicting record IDs; both devices' distinct records are kept;
  /// each lesson list is re-capped to 10 (newest first). Idempotent.
  static Map<String, List<LessonAttemptRecord>> mergeLedgers(
    Map<String, List<LessonAttemptRecord>> local,
    Map<String, List<LessonAttemptRecord>> remote,
  ) {
    final Map<String, List<LessonAttemptRecord>> merged = {};
    for (final lessonId in {...local.keys, ...remote.keys}) {
      final localRecords = local[lessonId] ?? const <LessonAttemptRecord>[];
      final remoteRecords = remote[lessonId] ?? const <LessonAttemptRecord>[];
      final Map<String, LessonAttemptRecord> byId = {};
      for (final r in localRecords) {
        byId[r.id] = r;
      }
      for (final r in remoteRecords) {
        final existing = byId[r.id];
        // Same id: identical event; newest timestamp wins (ties keep local).
        if (existing == null ||
            r.timestampIso.compareTo(existing.timestampIso) > 0) {
          byId[r.id] = r;
        }
      }
      merged[lessonId] = byId.values.toList()
        ..sort((a, b) => b.timestampIso.compareTo(a.timestampIso));
      merged[lessonId] = merged[lessonId]!
          .take(kLessonAttemptLedgerMaxRecords)
          .toList();
    }
    return merged;
  }

  /// JSON (de)serialization for local-first persistence in the profile.
  static Map<String, dynamic> ledgerToJson(
      Map<String, List<LessonAttemptRecord>> ledger) {
    final Map<String, dynamic> out = {};
    ledger.forEach((lessonId, records) {
      out[lessonId] = records.map((r) => r.toJson()).toList();
    });
    return out;
  }

  static Map<String, List<LessonAttemptRecord>> ledgerFromJson(dynamic json) {
    final Map<String, List<LessonAttemptRecord>> out = {};
    if (json is Map) {
      json.forEach((k, v) {
        if (v is List) {
          final parsed = v
              .whereType<Map>()
              .map((m) =>
                  LessonAttemptRecord.fromJson(Map<String, dynamic>.from(m)))
              .toList();
          // Drop lessons whose records are entirely malformed, so a
          // corrupted entry never lingers as an empty ledger key.
          if (parsed.isNotEmpty) out[k.toString()] = parsed;
        }
      });
    }
    return out;
  }

  /// Convenience: the outcome of the most recent record (or null).
  static LessonAttemptOutcome? lastOutcome(List<LessonAttemptRecord> records) {
    if (records.isEmpty) return null;
    final sorted = [...records]..sort((a, b) => b.timestampIso.compareTo(a.timestampIso));
    return sorted.first.outcome;
  }
}
