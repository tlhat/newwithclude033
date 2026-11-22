import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'package:haneen_kids_vod/haneen_kids_exports.dart';

/// Speech phase reported by [SpeechCoordinator].
enum CompanionSpeechPhase {
  /// No speech activity.
  idle,

  /// Audio playback is (assumed to be) in progress.
  speaking,

  /// Audio failed or is unavailable; text-only fallback is being shown.
  textFallback,
}

/// Immutable snapshot of the coordinator state consumed by the avatar mouth.
@immutable
class CompanionSpeechSnapshot {
  final CompanionSpeechPhase phase;

  /// Estimated playback progress in `0.0 .. 1.0` while [phase] is
  /// [CompanionSpeechPhase.speaking]. Approximate only: derived from the
  /// estimated speech duration (word count heuristic), clamped to the actual
  /// completion signal from the voice service. Never used for true lip-sync.
  final double playbackProgress;

  /// Mouth openness in `0.0 .. 1.0` for approximate mouth animation.
  /// Always `0.0` when not speaking (idle / fallback / muted).
  final double mouthOpen;

  const CompanionSpeechSnapshot({
    this.phase = CompanionSpeechPhase.idle,
    this.playbackProgress = 0.0,
    this.mouthOpen = 0.0,
  });

  static const CompanionSpeechSnapshot idle = CompanionSpeechSnapshot();

  bool get isSpeaking => phase == CompanionSpeechPhase.speaking;

  @override
  bool operator ==(Object other) =>
      other is CompanionSpeechSnapshot &&
      other.phase == phase &&
      other.playbackProgress == playbackProgress &&
      other.mouthOpen == mouthOpen;

  @override
  int get hashCode =>
      Object.hash(phase, playbackProgress, mouthOpen);
}

/// Drives the companion's speech lifecycle on top of [CalmVoiceService].
///
/// Responsibilities (Phase 3 scope only):
/// - Guarantees no overlapping companion speech: a new [speak] cancels the
///   previous request via the voice service's own sequential stop semantics.
/// - Speech tokens + activity scope IDs reject stale callbacks.
/// - Respects mute / parental sound controls before starting audio.
/// - Approximate mouth animation driver: animates only while audio plays,
///   correlated to estimated playback progress; the mouth closes immediately
///   on completion, stop, or cancellation.
/// - Falls back to a text-only state when the voice synthesis fails.
///
/// This coordinator does NOT own or alter the CalmVoiceService playback
/// queue, caching, personas, or story narration; it only calls the same
/// public APIs screens already use (`speakCalmly`, `stopSpeaking`).
class SpeechCoordinator extends ChangeNotifier {
  /// Default voice driver: delegates to the shared CalmVoiceService.
  static Future<void> _defaultVoiceDriver(String text) async {
    await CalmVoiceService.instance.speakCalmly(
      text,
      allowSpeechForRepeatGame: true,
    );
  }

  /// Default clock: wall-clock milliseconds.
  static int _defaultClock() => DateTime.now().millisecondsSinceEpoch;

  final Future<void> Function(String text) _voiceDriver;
  final int Function() _clockMillis;
  final bool Function() _isMuted;
  final bool Function() _isVoiceAvailable;
  final bool _ownsDefaultVoiceDriver;

  int _nextToken = 0;
  int _activeToken = 0;
  String? _activeScopeId;
  Timer? _progressTimer;

  CompanionSpeechSnapshot _snapshot = CompanionSpeechSnapshot.idle;

  /// Fallback text shown while [CompanionSpeechPhase.textFallback].
  String fallbackText = '';

  SpeechCoordinator({
    Future<void> Function(String text)? voiceDriver,
    int Function()? clockMillis,
    bool Function()? mutePolicy,
    bool Function()? voiceAvailability,
  })  : _voiceDriver = voiceDriver ?? _defaultVoiceDriver,
        _ownsDefaultVoiceDriver = voiceDriver == null,
        _clockMillis = clockMillis ?? _defaultClock,
        _isMuted = mutePolicy ??
            (() => CalmVoiceService.instance.isAssistantMuted ||
                !CalmVoiceService.instance.isSoundAndVoiceEnabled),
        _isVoiceAvailable = voiceAvailability ?? (() => true);

  /// Current snapshot for the avatar mouth animation.
  CompanionSpeechSnapshot get snapshot => _snapshot;

  /// Whether a companion speech request is currently active.
  bool get isSpeaking => _snapshot.isSpeaking;

  /// The scope ID of the active speech request, if any.
  String? get activeScopeId => _activeScopeId;

  /// True when the last completed request failed audio and fell back to text.
  bool get isShowingTextFallback =>
      _snapshot.phase == CompanionSpeechPhase.textFallback;

  /// Speaks [text] on behalf of the activity identified by [scopeId]
  /// (e.g. `lesson:<lessonId>`).
  ///
  /// - If mute / parental sound controls forbid audio, no audio starts, the
  ///   mouth never animates, and no stale state is published.
  /// - Any previous companion speech request is cancelled (stale callbacks
  ///   are rejected via its token) before this one starts.
  Future<void> speak(String scopeId, String text) async {
    final String clean = text.trim();
    if (clean.isEmpty) return;

    // Cancel previous request first (no overlap).
    await cancel();

    if (_isMuted()) {
      _publish(CompanionSpeechSnapshot.idle);
      return;
    }

    final int token = ++_nextToken;
    _activeToken = token;
    _activeScopeId = scopeId;

    // Entering speaking immediately: mouth may animate from now on.
    final int startedAt = _clockMillis();
    final Duration estimated = _estimateSpeechDuration(clean);
    // Publish the speaking state immediately so consumers see the phase
    // without waiting for the first progress tick.
    _publish(const CompanionSpeechSnapshot(
      phase: CompanionSpeechPhase.speaking,
    ));
    _scheduleNextAdvance(token, scopeId, startedAt, estimated);

    Object? failure;
    try {
      await _voiceDriver(clean);
    } catch (error) {
      failure = error;
    }

    // Stale guard: another request or a scope change superseded this one.
    if (token != _activeToken || scopeId != _activeScopeId) return;

    if (failure != null || !_isVoiceAvailable()) {
      // Audio failed: silent text fallback.
      fallbackText = clean;
      _publish(const CompanionSpeechSnapshot(
        phase: CompanionSpeechPhase.textFallback,
      ));
      return;
    }

    _completeSpeaking();
  }

  /// Polls the approximate playback progress while awaiting the voice
  /// driver, so the mouth correlates to (estimated) playback time. Uses a
  /// ~60fps timer; tests drive time forward with a fake clock.
  void _scheduleNextAdvance(
    int token,
    String scopeId,
    int startedAt,
    Duration estimated,
  ) {
    _progressTimer = Timer(const Duration(milliseconds: 16), () {
      if (token != _activeToken || scopeId != _activeScopeId) return;
      final int now = _clockMillis();
      final double progress =
          (now - startedAt) / estimated.inMilliseconds;
      if (progress >= 1.0) {
        // Estimated duration exhausted: hold near-complete until the driver
        // completes (the service's safety bound may exceed our estimate).
        if (_snapshot.isSpeaking) {
          _publish(CompanionSpeechSnapshot(
            phase: CompanionSpeechPhase.speaking,
            playbackProgress: 0.99,
            mouthOpen: 0.0,
          ));
        }
        return;
      }
      if (_snapshot.isSpeaking) {
        _publish(CompanionSpeechSnapshot(
          phase: CompanionSpeechPhase.speaking,
          playbackProgress: progress.clamp(0.0, 0.99),
          mouthOpen: _mouthOpennessForElapsed(
              now - startedAt, progress.clamp(0.0, 1.0)),
        ));
      }
      _scheduleNextAdvance(token, scopeId, startedAt, estimated);
    });
  }

  /// Completes the active speech: progress reaches 1.0 and the mouth closes
  /// immediately.
  void _completeSpeaking() {
    _progressTimer?.cancel();
    _activeToken = 0;
    _activeScopeId = null;
    _publish(const CompanionSpeechSnapshot(
      phase: CompanionSpeechPhase.idle,
      playbackProgress: 1.0,
      mouthOpen: 0.0,
    ));
  }

  /// Cancels any active companion speech (scope change, activity exit,
  /// parental gate). Stale callbacks from the cancelled request are rejected
  /// by their token. The mouth closes immediately.
  Future<void> cancel() async {
    if (_activeToken != 0) {
      _progressTimer?.cancel();
      _activeToken = 0;
      _activeScopeId = null;
      _publish(CompanionSpeechSnapshot.idle);
      // Only interrupt the shared voice service when we actually owned an
      // active request AND the default driver (which owns service playback)
      // is in use; injected test drivers manage their own audio.
      if (_ownsDefaultVoiceDriver) {
        await CalmVoiceService.instance.stopSpeaking();
      }
    }
    fallbackText = '';
  }

  /// Notifies that the activity scope changed (e.g. a new lesson opened).
  /// Cancels any speech whose scope no longer matches.
  Future<void> onScopeChanged(String newScopeId) async {
    if (_activeScopeId != null && _activeScopeId != newScopeId) {
      await cancel();
    }
  }

  void _publish(CompanionSpeechSnapshot snapshot) {
    if (_snapshot == snapshot) return;
    _snapshot = snapshot;
    notifyListeners();
  }

  /// Word-count heuristic mirroring CalmVoiceService's safety-bound estimate.
  static Duration _estimateSpeechDuration(String text) {
    final int words =
        math.max(1, text.trim().split(RegExp(r'\s+')).length);
    return Duration(milliseconds: math.max(1200, words * 420));
  }

  /// Approximate jaw oscillation: a smooth sine driven by elapsed time,
  /// slightly damped near the very start and end of the utterance so the
  /// mouth eases closed instead of snapping mid-cycle.
  static double _mouthOpennessForElapsed(int elapsedMs, double progress) {
    if (progress <= 0.0 || progress >= 1.0) return 0.0;
    final double rampIn = (elapsedMs / 120.0).clamp(0.0, 1.0);
    final double rampOut = ((1.0 - progress) / 0.08).clamp(0.0, 1.0);
    final double wave =
        0.5 + 0.5 * math.sin(2 * math.pi * elapsedMs / 260.0);
    return (wave * rampIn * rampOut).clamp(0.0, 1.0);
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _activeToken = 0;
    _activeScopeId = null;
    super.dispose();
  }
}

/// Exposes internal heuristics for pinning tests without exposing them on
/// the public coordinator API.
class SpeechCoordinatorTestHooks {
  /// See [SpeechCoordinator._estimateSpeechDuration].
  static Duration estimateSpeechDuration(String text) =>
      SpeechCoordinator._estimateSpeechDuration(text);
}
