import 'package:flutter/foundation.dart';

/// Which surface emitted an interaction event.
enum CompanionSurface { academy, brainGames, home, studio }

/// What the child just did. Deliberately coarse in Phase 1 — hint tiers,
/// attempt outcomes and mastery transitions arrive in later phases and will
/// extend, not replace, this list.
enum CompanionEventKind {
  activityShown,
  answerCorrect,
  answerIncorrect,
  tapGreeting,
}

/// A single typed interaction event forwarded from a UI surface.
@immutable
class CompanionEvent {
  final CompanionEventKind kind;
  final CompanionSurface surface;
  final String? activityId;

  const CompanionEvent({
    required this.kind,
    required this.surface,
    this.activityId,
  });
}

/// Deterministic reaction chosen by the engine. Surfaces map this onto the
/// existing avatar widget parameters and localized strings — the engine never
/// owns UI text.
enum CompanionReactionKind {
  none,
  gentleAcknowledge, // correct answer, no celebration budget spent
  celebrate, // budgeted celebration (streak/first-correct-after-miss)
  encourageRetry, // wrong answer — calm, non-punitive
}

/// Everything a surface needs to render the companion this frame. Pure data:
/// no Flutter widgets, no strings — localization stays at the surface.
@immutable
class CompanionVisualState {
  final CompanionReactionKind reaction;
  final bool isCelebrating;
  final bool isWaving;
  final int reactionTick;

  static const CompanionVisualState idle = CompanionVisualState._(
    reaction: CompanionReactionKind.none,
    isCelebrating: false,
    isWaving: false,
    reactionTick: 0,
  );

  const CompanionVisualState._({
    required this.reaction,
    required this.isCelebrating,
    required this.isWaving,
    required this.reactionTick,
  });

  const CompanionVisualState({
    required this.reaction,
    required this.isCelebrating,
    required this.isWaving,
    required this.reactionTick,
  });

  CompanionVisualState copyWith({
    CompanionReactionKind? reaction,
    bool? isCelebrating,
    bool? isWaving,
    int? reactionTick,
  }) =>
      CompanionVisualState(
        reaction: reaction ?? this.reaction,
        isCelebrating: isCelebrating ?? this.isCelebrating,
        isWaving: isWaving ?? this.isWaving,
        reactionTick: reactionTick ?? this.reactionTick,
      );

  @override
  bool operator ==(Object other) =>
      other is CompanionVisualState &&
      other.reaction == reaction &&
      other.isCelebrating == isCelebrating &&
      other.isWaving == isWaving &&
      other.reactionTick == reactionTick;

  @override
  int get hashCode =>
      Object.hash(reaction, isCelebrating, isWaving, reactionTick);
}
