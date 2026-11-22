import 'package:flutter/foundation.dart';

/// Tunable interaction behavior. Values are constants in Phase 1 so the
/// existing visual identity is unchanged; per-child configuration can come
/// later without touching the engine.
@immutable
class CompanionInteractionPolicy {
  /// Answers between full celebrations. Phase 1 keeps a modest streak so the
  /// companion stays calm instead of celebrating every correct answer.
  final int correctStreakForCelebration;

  /// A wrong answer after a correct streak still merits one calm wave.
  final int correctStreakForWave;

  /// Events remembered for streak computation.
  final int streakWindow;

  const CompanionInteractionPolicy({
    this.correctStreakForCelebration = 3,
    this.correctStreakForWave = 2,
    this.streakWindow = 8,
  });

  static const CompanionInteractionPolicy defaultPolicy =
      CompanionInteractionPolicy();
}
