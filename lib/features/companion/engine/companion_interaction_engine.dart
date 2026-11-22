import 'package:flutter/foundation.dart';

import 'companion_interaction_state.dart';
import 'companion_personality.dart';
import 'interaction_policy.dart';

/// Pure-Dart interaction engine shared by every companion surface.
///
/// Consumes typed [CompanionEvent]s and produces a [CompanionVisualState] the
/// surfaces map onto the existing avatar widget parameters. Holds no Flutter
/// widgets, no strings, no persistence, no speech — those remain at the
/// surfaces and existing services. Reaction priority and duplicate
/// suppression are deterministic:
///
///  * Events from a different surface immediately supersede pending state
///    (the newest activity wins, matching Khan-style focus).
///  * Re-emitting the same event kind + activity id within the debounce
///    window is ignored, preventing duplicate celebrations from rebuilds or
///    double taps.
///  * A new reaction always replaces the previous one — no stacking.
class CompanionInteractionEngine extends ChangeNotifier {
  CompanionInteractionEngine({
    CompanionInteractionPolicy policy = CompanionInteractionPolicy.defaultPolicy,
    CompanionPersonalityProfile? profile,
  })  : _policy = policy,
        _profile = profile ?? kCompanionPersonalityProfiles[CompanionGenderLike.boy]!;

  CompanionInteractionPolicy _policy;
  CompanionPersonalityProfile _profile;

  CompanionVisualState _state = CompanionVisualState.idle;

  /// Rolling outcome history for streak logic (true = correct).
  final List<bool> _recentOutcomes = [];

  /// Monotonic counter; surfaces use it exactly like the existing
  /// `reactionTick` parameter.
  int _tick = 0;

  /// Current emitting surface — events from a new surface take over.
  CompanionSurface? _activeSurface;

  /// Dedup signature of the last accepted event.
  String? _lastEventSignature;
  DateTime _lastEventAt = DateTime.fromMillisecondsSinceEpoch(0);

  /// Debounce window for duplicate events.
  static const Duration _duplicateWindow = Duration(milliseconds: 400);

  CompanionVisualState get state => _state;
  CompanionInteractionPolicy get policy => _policy;
  CompanionPersonalityProfile get profile => _profile;

  /// Current correct-answer streak within the policy window.
  int get currentStreak {
    int streak = 0;
    for (int i = _recentOutcomes.length - 1; i >= 0; i--) {
      if (!_recentOutcomes[i]) break;
      streak++;
    }
    return streak;
  }

  void setPolicy(CompanionInteractionPolicy policy) {
    _policy = policy;
  }

  void setProfile(CompanionPersonalityProfile profile) {
    _profile = profile;
  }

  /// Feeds one interaction event; notifies listeners only when the visual
  /// state actually changes.
  void dispatch(CompanionEvent event) {
    final String signature =
        '${event.kind.name}|${event.surface.name}|${event.activityId ?? ''}';

    // Surface takeover: a different surface becomes active and resets streaks
    // so progress in one game never leaks into another.
    final bool surfaceChanged = _activeSurface != event.surface;
    if (surfaceChanged) {
      _activeSurface = event.surface;
      _recentOutcomes.clear();
    }

    if (!surfaceChanged &&
        signature == _lastEventSignature &&
        DateTime.now().difference(_lastEventAt) < _duplicateWindow) {
      return; // duplicate tap / rebuild echo
    }
    _lastEventSignature = signature;
    _lastEventAt = DateTime.now();

    switch (event.kind) {
      case CompanionEventKind.activityShown:
        _applyState(
          reaction: CompanionReactionKind.none,
          isCelebrating: false,
          isWaving: false,
        );
        break;

      case CompanionEventKind.answerCorrect:
        _recordOutcome(true);
        final int streak = currentStreak;
        if (streak >= _policy.correctStreakForCelebration) {
          // Budgeted celebration; spending it resets the streak so the
          // companion does not celebrate back-to-back.
          _recentOutcomes.clear();
          _applyState(
            reaction: CompanionReactionKind.celebrate,
            isCelebrating: true,
            isWaving: false,
          );
        } else if (streak >= _policy.correctStreakForWave) {
          _applyState(
            reaction: CompanionReactionKind.gentleAcknowledge,
            isCelebrating: false,
            isWaving: true,
          );
        } else {
          _applyState(
            reaction: CompanionReactionKind.gentleAcknowledge,
            isCelebrating: false,
            isWaving: false,
          );
        }
        break;

      case CompanionEventKind.answerIncorrect:
        _recordOutcome(false);
        _applyState(
          reaction: CompanionReactionKind.encourageRetry,
          isCelebrating: false,
          isWaving: false,
        );
        break;

      case CompanionEventKind.tapGreeting:
        _applyState(
          reaction: CompanionReactionKind.gentleAcknowledge,
          isCelebrating: false,
          isWaving: true,
        );
        break;
    }
  }

  /// Dispatches and returns the resulting state in one call (convenience for
  /// surfaces that setState synchronously).
  CompanionVisualState dispatchAndRead(CompanionEvent event) {
    dispatch(event);
    return _state;
  }

  /// Returns the companion to idle without touching streak history.
  void clearReaction() {
    if (_state.reaction == CompanionReactionKind.none &&
        !_state.isCelebrating &&
        !_state.isWaving) {
      return;
    }
    _applyState(
      reaction: CompanionReactionKind.none,
      isCelebrating: false,
      isWaving: false,
    );
  }

  void _recordOutcome(bool correct) {
    _recentOutcomes.add(correct);
    if (_recentOutcomes.length > _policy.streakWindow) {
      _recentOutcomes.removeRange(
          0, _recentOutcomes.length - _policy.streakWindow);
    }
  }

  void _applyState({
    required CompanionReactionKind reaction,
    required bool isCelebrating,
    required bool isWaving,
  }) {
    _tick++;
    final CompanionVisualState next = CompanionVisualState(
      reaction: reaction,
      isCelebrating: isCelebrating,
      isWaving: isWaving,
      reactionTick: _tick,
    );
    if (next.reactionTick == _state.reactionTick) return;
    _state = next;
    notifyListeners();
  }
}
