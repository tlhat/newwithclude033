import 'dart:async';
import 'dart:math' as math;

// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:haneen_kids_vod/features/companion/engine/speech_coordinator.dart';
import 'package:haneen_kids_vod/features/companion/models/avatar_customization_model.dart';
import 'package:haneen_kids_vod/features/companion/widgets/haneen_companion_avatar_widget.dart';
import 'package:rive/rive.dart';

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
  static void clearFileCacheForTesting() =>
      _HaneenRiveAvatarWidgetState._fileCache.clear();

  @override
  State<HaneenRiveAvatarWidget> createState() => _HaneenRiveAvatarWidgetState();
}

class _HaneenRiveAvatarWidgetState extends State<HaneenRiveAvatarWidget> {
  static final Map<String, Future<RiveFile?>> _fileCache =
      <String, Future<RiveFile?>>{};

  StateMachineController? _controller;
  Artboard? _artboard;
  SMIBool? _isSpeakingInput;
  SMINumber? _lookXInput;
  SMINumber? _lookYInput;
  SMITrigger? _blinkTriggerInput;
  SMINumber? _mouthOpenInput;
  SMINumber? _emotionIdInput;
  SMITrigger? _waveTriggerInput;
  SMITrigger? _celebrateTriggerInput;

  Timer? _blinkTimer;
  Timer? _gazeTimer;
  double _gazeX = 0;
  double _gazeY = 0;
  bool _waveFired = false;
  bool _celebrateFired = false;
  bool _lastSpeaking = false;
  int _lastEmotion = -1;

  String _riveAssetPath() {
    final String gender =
        widget.avatar.gender == CompanionGender.boy ? 'boy' : 'girl';
    return 'assets/avatars/${gender}_${widget.viewAngle.assetSuffix}.riv';
  }

  @override
  void initState() {
    super.initState();
    _loadRiveFile();
    widget.speechCoordinator?.addListener(_onSpeechChanged);
    _lastSpeaking =
        widget.speechCoordinator?.snapshot.isSpeaking ?? false;
  }

  @override
  void didUpdateWidget(covariant HaneenRiveAvatarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.speechCoordinator != widget.speechCoordinator) {
      oldWidget.speechCoordinator?.removeListener(_onSpeechChanged);
      widget.speechCoordinator?.addListener(_onSpeechChanged);
    }
    if (oldWidget.avatar.gender != widget.avatar.gender ||
        oldWidget.viewAngle != widget.viewAngle) {
      _disposeController();
      _loadRiveFile();
    } else if (oldWidget.expressionOverride != widget.expressionOverride ||
        oldWidget.isWaving != widget.isWaving ||
        oldWidget.isCelebrating != widget.isCelebrating) {
      _syncAllInputs();
    }
  }

  Future<void> _loadRiveFile() async {
    if (!widget.riveEnabled) {
      return;
    }
    final String path = _riveAssetPath();
    final Future<RiveFile?> load = _fileCache.putIfAbsent(
      path,
      () => RiveFile.asset(path).then<RiveFile?>((f) => f).catchError(
            (_) => null,
          ),
    );
    final RiveFile? file = await load;
    if (!mounted || file == null) {
      return;
    }
    if (file.artboards.isEmpty) {
      return;
    }
    _attachController(file.mainArtboard);
  }

  void _attachController(Artboard artboard) {
    final StateMachineController? controller =
        StateMachineController.fromArtboard(
      artboard,
      'companion_state_machine',
    );
    if (controller == null) {
      // Unrigged / wrong state-machine name: stay on the PNG fallback.
      return;
    }
    _controller = controller;
    _artboard = artboard;
    _isSpeakingInput = controller.getBoolInput(HaneenRiveInputs.isSpeaking);
    _lookXInput = controller.getNumberInput(HaneenRiveInputs.lookX);
    _lookYInput = controller.getNumberInput(HaneenRiveInputs.lookY);
    _blinkTriggerInput =
        controller.getTriggerInput(HaneenRiveInputs.blinkTrigger);
    _mouthOpenInput =
        controller.getNumberInput(HaneenRiveInputs.mouthOpen);
    // visemeId is intentionally NOT wired: no phoneme source exists.
    _emotionIdInput =
        controller.getNumberInput(HaneenRiveInputs.emotionId);
    _waveTriggerInput =
        controller.getTriggerInput(HaneenRiveInputs.waveTrigger);
    _celebrateTriggerInput =
        controller.getTriggerInput(HaneenRiveInputs.celebrateTrigger);
    artboard.addController(controller);

    _startBlinkTimer();
    _startGazeTimer();
    if (mounted) {
      setState(() {});
    }
    _syncAllInputs();
  }

  void _startBlinkTimer() {
    _blinkTimer?.cancel();
    _blinkTimer = Timer(_randomBlinkDelay(), _fireBlink);
  }

  Duration _randomBlinkDelay() {
    // Layer 2: randomized 2-6 s cadence so blinks are non-robotic.
    return Duration(milliseconds: 2000 + math.Random().nextInt(4000));
  }

  void _fireBlink() {
    _blinkTriggerInput?.fire();
    if (mounted) {
      _startBlinkTimer();
    }
  }

  void _startGazeTimer() {
    // Layer 1: gentle idle gaze drift within -1..1, eased toward the target.
    _gazeTimer?.cancel();
    _gazeTimer = Timer.periodic(const Duration(milliseconds: 900), (_) {
      final math.Random rng = math.Random();
      _gazeX = (rng.nextDouble() * 2 - 1) * 0.35;
      _gazeY = (rng.nextDouble() * 2 - 1) * 0.2;
      _lookXInput?.value = _gazeX;
      _lookYInput?.value = _gazeY;
    });
  }

  void _onSpeechChanged() {
    if (!mounted) {
      return;
    }
    _syncSpeechInputs();
  }

  void _syncSpeechInputs() {
    final CompanionSpeechSnapshot snapshot =
        widget.speechCoordinator?.snapshot ?? CompanionSpeechSnapshot.idle;
    final bool speaking =
        snapshot.isSpeaking && widget.mouthAnimationEnabled;
    if (speaking != _lastSpeaking) {
      _isSpeakingInput?.value = speaking;
      _lastSpeaking = speaking;
    }
    _mouthOpenInput?.value =
        speaking ? snapshot.mouthOpen.clamp(0.0, 1.0) : 0.0;
  }

  int _emotionIndex() {
    final CompanionFaceExpression? expression = widget.expressionOverride;
    if (expression == null) {
      return 0; // happy — the companion's default face.
    }
    final int idx = CompanionFaceExpression.values.indexOf(expression);
    return idx < 0 ? 0 : idx;
  }

  void _syncAllInputs() {
    _syncSpeechInputs();
    final int emotion = _emotionIndex();
    if (emotion != _lastEmotion) {
      _emotionIdInput?.value = emotion.toDouble();
      _lastEmotion = emotion;
    }
    _lookXInput?.value = _gazeX;
    _lookYInput?.value = _gazeY;
    // Fire wave/celebrate triggers on rising transitions only.
    if (widget.isWaving && !_waveFired) {
      _waveTriggerInput?.fire();
      _waveFired = true;
    } else if (!widget.isWaving) {
      _waveFired = false;
    }
    if (widget.isCelebrating && !_celebrateFired) {
      _celebrateTriggerInput?.fire();
      _celebrateFired = true;
    } else if (!widget.isCelebrating) {
      _celebrateFired = false;
    }
  }

  @override
  void dispose() {
    // Explicit dispose discipline: never leak a StateMachineController.
    _blinkTimer?.cancel();
    _gazeTimer?.cancel();
    widget.speechCoordinator?.removeListener(_onSpeechChanged);
    _disposeController();
    super.dispose();
  }

  void _disposeController() {
    _controller?.dispose();
    _controller = null;
    _artboard = null;
    _isSpeakingInput = null;
    _lookXInput = null;
    _lookYInput = null;
    _blinkTriggerInput = null;
    _mouthOpenInput = null;
    _emotionIdInput = null;
    _waveTriggerInput = null;
    _celebrateTriggerInput = null;
    _waveFired = false;
    _celebrateFired = false;
    _blinkTimer?.cancel();
    _gazeTimer?.cancel();
  }

  Widget _buildFallback() {
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

  @override
  Widget build(BuildContext context) {
    final Artboard? artboard = _artboard;
    if (!widget.riveEnabled || artboard == null) {
      return _buildFallback();
    }
    return RepaintBoundary(
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: Rive(artboard: artboard),
      ),
    );
  }
}
