import 'dart:async';
import 'dart:math' as math;

// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:haneen_kids_vod/features/companion/engine/speech_coordinator.dart';
import 'package:haneen_kids_vod/features/companion/models/avatar_customization_model.dart';
import 'package:haneen_kids_vod/features/companion/widgets/haneen_companion_avatar_widget.dart';

/// Rig input contract for the Haneen Kids Rive mascots.
///
/// Animators must expose exactly these inputs on the artboard's default
/// state machine. Flutter drives them; the rig consumes them.
///
/// | Input          | Type       | Range / semantics                                   |
/// |----------------|------------|------------------------------------------------------|
/// | isSpeaking     | SMIBool    | true while TTS audio plays (Layer 4 gate)            |
/// | lookX, lookY   | SMINumber  | -1.0 .. 1.0 gaze target with parallax (Layer 1)      |
/// | blinkTrigger   | SMITrigger | fire to blink; randomized 2-6 s cadence (Layer 2)    |
/// | mouthOpen      | SMINumber  | 0.0 .. 1.0 approximate mouth openness (fallback)    |
/// | visemeId       | SMINumber  | 0..12 viseme index, 0.03-0.05 s mix — UNWIRED       |
/// | emotionId      | SMINumber  | 0..N enum of CompanionFaceExpression (Layer 4)      |
/// | waveTrigger    | SMITrigger | fire on wave start (backward compat, Phase 3)       |
/// | celebrateTrigger | SMITrigger | fire on celebration start (backward compat)       |
///
/// Layer 0 (breathing / posture) lives inside the rig's idle state machine.
///
/// `visemeId` is documented as BLOCKED: SpeechCoordinator exposes no phoneme
/// data (no RMS, no timestamps, no viseme events), so no code path sets it.
/// It is declared here only so animator rigs and the Flutter harness agree
/// on the full contract once real phoneme data exists upstream.
class HaneenRiveInputs {
  static const String isSpeaking = 'isSpeaking';
  static const String lookX = 'lookX';
  static const String lookY = 'lookY';
  static const String blinkTrigger = 'blinkTrigger';
  static const String mouthOpen = 'mouthOpen';
  static const String visemeId = 'visemeId';
  static const String emotionId = 'emotionId';
  static const String waveTrigger = 'waveTrigger';
  static const String celebrateTrigger = 'celebrateTrigger';

  /// Ordered mapping used by [emotionId]. Rigs must implement the same order.
  static const List<String> emotionOrder = [
    'happy',
    'excited',
    'calm',
    'shy',
    'thinking',
  ];

  const HaneenRiveInputs._();
}

/// Renders the companion from a rigged Rive asset (`.riv`) when one exists,
/// and falls back to the existing PNG-based [HaneenCompanionAvatarWidget]
/// otherwise. The PNG path is the DEFAULT and always safe: today there are
/// no `.riv` assets in the repo, so this widget renders the exact same tree
/// callers had before the Rive upgrade.
///
/// Lifecycle guarantees:
/// - `RiveFile`s are pre-cached once per asset path (static cache) so no
///   `build` ever awaits disk/network.
/// - Every [StateMachineController] is [StateMachineController.dispose]d in
///   [State.dispose]; controllers are created once per successful load, not
///   per build.
/// - A [RepaintBoundary] wraps ONLY the Rive canvas (full-canvas repaint
///   isolation); the PNG fallback keeps its original paint structure.
///
/// State pattern: no new state-management library. Inputs follow the
/// existing ChangeNotifier/listener pattern used by [SpeechCoordinator].
class HaneenRiveAvatarWidget extends StatefulWidget {
  /// All props accepted by [HaneenCompanionAvatarWidget] are forwarded
  /// verbatim to the PNG fallback.
  final AvatarCustomizationModel avatar;
  final CompanionDisplayMode mode;
  final double size;
  final bool animateBreathing;
  final bool showSpeechBubble;
  final String? speechText;
  final VoidCallback? onTap;
  final bool isWaving;
  final bool isCelebrating;
  final CompanionFaceExpression? expressionOverride;
  final bool speakOnTap;
  final CompanionViewAngle viewAngle;
  final bool showBackgroundScene;

  /// Speech coordinator whose snapshot drives `isSpeaking` and `mouthOpen`.
  final SpeechCoordinator? speechCoordinator;

  /// Kill-switch for the approximate mouth input (mirrors the PNG widget).
  final bool mouthAnimationEnabled;

  /// Kill-switch for the whole Rive path. When false (or when no `.riv`
  /// exists / it fails to load / it has no usable state machine), the widget
  /// renders the PNG fallback.
  final bool riveEnabled;

  const HaneenRiveAvatarWidget({
    super.key,
    required this.avatar,
    this.mode = CompanionDisplayMode.fullBody,
    this.size = 200,
    this.animateBreathing = true,
    this.showSpeechBubble = false,
    this.speechText,
    this.onTap,
    this.isWaving = false,
    this.isCelebrating = false,
    this.expressionOverride,
    this.speakOnTap = false,
    this.viewAngle = CompanionViewAngle.front,
    this.showBackgroundScene = true,
    this.speechCoordinator,
    this.mouthAnimationEnabled = true,
    this.riveEnabled = true,
  });

  /// Tests can reset the file cache to avoid leaking cached failed loads.
  @visibleForTesting
  static void clearFileCacheForTesting() {}

  @override
  State<HaneenRiveAvatarWidget> createState() => _HaneenRiveAvatarWidgetState();
}

class _HaneenRiveAvatarWidgetState extends State<HaneenRiveAvatarWidget> {
  // The Rive runtime was removed: it shipped a native library that is not
  // 16 KB page-size aligned (Google Play requirement), and no .riv asset
  // exists in the app. The companion always uses the drawn avatar below.
  @override
  Widget build(BuildContext context) {
    return HaneenCompanionAvatarWidget(
      avatar: widget.avatar,
      mode: widget.mode,
      size: widget.size,
      animateBreathing: widget.animateBreathing,
      showSpeechBubble: widget.showSpeechBubble,
      speechText: widget.speechText,
      onTap: widget.onTap,
      isWaving: widget.isWaving,
      isCelebrating: widget.isCelebrating,
      expressionOverride: widget.expressionOverride,
      speakOnTap: widget.speakOnTap,
      viewAngle: widget.viewAngle,
      showBackgroundScene: widget.showBackgroundScene,
      speechCoordinator: widget.speechCoordinator,
      mouthAnimationEnabled: widget.mouthAnimationEnabled,
    );
  }
}
