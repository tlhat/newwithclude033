import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:haneen_kids_vod/app/app_theme.dart';
import 'package:haneen_kids_vod/core/services/calm_voice_service.dart';
import 'package:haneen_kids_vod/features/companion/engine/speech_coordinator.dart';
import 'package:haneen_kids_vod/features/companion/models/avatar_customization_model.dart';
import 'package:haneen_kids_vod/features/companion/widgets/haneen_layered_avatar_widget.dart';

/// Approximate mouth anchor calibration for the four companion sprites.
///
/// These are relative positions within the sprite box (0..1) where the mouth
/// sits, tuned per gender + view angle. Approximate mouth animation only —
/// the overlay merely darkens/opens a small ellipse at this anchor while the
/// companion speaks; it is not viseme/lip-sync.
class CompanionMouthAnchor {
  final double dx;
  final double dy;
  final double widthFactor;
  final double closedHeightFactor;
  final double openHeightFactor;

  const CompanionMouthAnchor({
    required this.dx,
    required this.dy,
    this.widthFactor = 0.075,
    this.closedHeightFactor = 0.012,
    this.openHeightFactor = 0.045,
  });

  static const CompanionMouthAnchor boyFront =
      CompanionMouthAnchor(dx: 0.50, dy: 0.205);
  static const CompanionMouthAnchor boyThreeQuarter =
      CompanionMouthAnchor(dx: 0.47, dy: 0.207);
  static const CompanionMouthAnchor girlFront =
      CompanionMouthAnchor(dx: 0.50, dy: 0.208);
  static const CompanionMouthAnchor girlThreeQuarter =
      CompanionMouthAnchor(dx: 0.47, dy: 0.210);

  static CompanionMouthAnchor forSprite({
    required CompanionGender gender,
    required CompanionViewAngle angle,
  }) {
    final bool front = angle == CompanionViewAngle.front;
    if (gender == CompanionGender.boy) {
      return front ? boyFront : boyThreeQuarter;
    }
    return front ? girlFront : girlThreeQuarter;
  }
}

enum CompanionDisplayMode {
  fullBody,
  bust,
}

enum CompanionViewAngle {
  front,
  threeQuarter;

  String get assetSuffix =>
      this == CompanionViewAngle.front ? 'front' : '3d_angle';
}

/// Interactive 3D-sprite companion avatar for Haneen Kids.
///
/// Renders the boy/girl sprite extracted from the character turnaround sheet
/// on top of a themed 3D scene (playroom / garden / space) with a realistic
/// ground shadow, breathing + float motion, greeting tilt, a happy jump with
/// floating stars, and equippable accessory overlays.
class HaneenCompanionAvatarWidget extends StatefulWidget {
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

  /// Optional speech coordinator driving approximate mouth animation.
  /// When provided (and [mouthAnimationEnabled] is true), the mouth overlay
  /// animates while the coordinator reports speech playback, and closes
  /// immediately when speech ends, stops, or is cancelled.
  final SpeechCoordinator? speechCoordinator;

  /// Kill-switch for approximate mouth animation (e.g. when animations are
  /// disabled platform-wide). Defaults to true.
  final bool mouthAnimationEnabled;

  /// Ignores the coordinator and forces the mouth open/closed. Used by tests.
  final bool debugForceMouthOpen;

  /// When true (the default), renders the authentic 110-part layered 2D rig.
  /// When false, falls back to the original single-sprite rendering.
  final bool useLayeredRig;

  const HaneenCompanionAvatarWidget({
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
    this.debugForceMouthOpen = false,
    this.useLayeredRig = true,
  });

  /// Asset path of the 3D sprite for this avatar's gender and view angle.
  String spriteAsset() {
    final String gender = avatar.gender == CompanionGender.boy ? 'boy' : 'girl';
    return 'assets/avatars/${gender}_${viewAngle.assetSuffix}.png';
  }

  @override
  State<HaneenCompanionAvatarWidget> createState() =>
      HaneenCompanionAvatarWidgetState();
}

class HaneenCompanionAvatarWidgetState
    extends State<HaneenCompanionAvatarWidget> with TickerProviderStateMixin {
  late AnimationController _breathingController;
  late Animation<double> _breathingAnim;

  late AnimationController _blinkController;
  late Animation<double> _blinkAnim;

  late AnimationController _waveController;
  late Animation<double> _waveAnim;

  late AnimationController _jumpController;
  late Animation<double> _jumpAnim;

  Timer? _blinkTimer;
  Timer? _reactionTimer;
  bool _manualWaving = false;
  bool _manualCelebrating = false;
  CompanionFaceExpression? _reactionExpression;

  // Approximate mouth animation state (Phase 3).
  CompanionSpeechSnapshot _speechSnapshot = CompanionSpeechSnapshot.idle;

  @override
  void initState() {
    super.initState();

    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );
    _breathingAnim = Tween<double>(begin: -4.0, end: 4.0).animate(
      CurvedAnimation(parent: _breathingController, curve: Curves.easeInOut),
    );

    if (widget.animateBreathing) {
      _breathingController.repeat(reverse: true);
    }

    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _blinkAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _blinkController, curve: Curves.easeInOut),
    );

    _startBlinkTimer();

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _waveAnim = Tween<double>(begin: -0.05, end: 0.08).animate(
      CurvedAnimation(parent: _waveController, curve: Curves.easeInOut),
    );

    _jumpController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _jumpAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _jumpController, curve: Curves.easeOutBack),
    );

    if (widget.avatar.pose == CompanionPose.waving || widget.isWaving) {
      _waveController.repeat(reverse: true);
    }

    if (widget.avatar.pose == CompanionPose.celebrating ||
        widget.isCelebrating) {
      _jumpController.repeat(reverse: true);
    }

    widget.speechCoordinator?.addListener(_onSpeechSnapshotChanged);
  }

  @override
  void didUpdateWidget(covariant HaneenCompanionAvatarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.speechCoordinator != widget.speechCoordinator) {
      oldWidget.speechCoordinator?.removeListener(_onSpeechSnapshotChanged);
      widget.speechCoordinator?.addListener(_onSpeechSnapshotChanged);
      _onSpeechSnapshotChanged();
    }
    if (widget.animateBreathing != oldWidget.animateBreathing) {
      if (widget.animateBreathing) {
        _breathingController.repeat(reverse: true);
      } else {
        _breathingController.stop();
        _breathingController.value = 0.0;
      }
    }

    final bool shouldWave = widget.avatar.pose == CompanionPose.waving ||
        widget.isWaving ||
        _manualWaving;
    if (shouldWave && !_waveController.isAnimating) {
      _waveController.repeat(reverse: true);
    } else if (!shouldWave && _waveController.isAnimating) {
      _waveController.stop();
      _waveController.value = 0.0;
    }

    final bool shouldCelebrate =
        widget.avatar.pose == CompanionPose.celebrating ||
            widget.isCelebrating ||
            _manualCelebrating;
    if (shouldCelebrate && !_jumpController.isAnimating) {
      _jumpController.repeat(reverse: true);
    } else if (!shouldCelebrate && _jumpController.isAnimating) {
      _jumpController.stop();
      _jumpController.value = 0.0;
    }
  }

  void _startBlinkTimer() {
    _blinkTimer?.cancel();
    _blinkTimer = Timer.periodic(const Duration(milliseconds: 3800), (_) {
      if (mounted && _blinkController.isDismissed) {
        _blinkController.forward().then((_) {
          if (mounted) _blinkController.reverse();
        });
      }
    });
  }

  void _onSpeechSnapshotChanged() {
    final CompanionSpeechSnapshot next =
        widget.speechCoordinator?.snapshot ?? CompanionSpeechSnapshot.idle;
    if (next == _speechSnapshot) return;
    // Ignore mouth-open values when mouth animation is disabled: only keep
    // the phase so listeners still see lifecycle, but never animate.
    setState(() => _speechSnapshot = next);
  }

  /// Effective mouth openness for the approximate mouth overlay. Zero
  /// whenever the animation is disabled, muted-driven idle, or not speaking.
  double get _effectiveMouthOpen {
    if (widget.debugForceMouthOpen) return 1.0;
    if (!widget.mouthAnimationEnabled) return 0.0;
    if (!_speechSnapshot.isSpeaking) return 0.0;
    return _speechSnapshot.mouthOpen.clamp(0.0, 1.0);
  }

  /// Triggers a friendly greeting tilt + wave animation
  void triggerWave() {
    if (!mounted) return;
    setState(() => _manualWaving = true);
    _waveController.repeat(reverse: true);
    Future.delayed(const Duration(milliseconds: 1600), () {
      if (mounted &&
          widget.avatar.pose != CompanionPose.waving &&
          !widget.isWaving) {
        setState(() => _manualWaving = false);
        _waveController.stop();
        _waveController.value = 0.0;
      }
    });
  }

  /// Triggers an energetic celebratory jump with 3D stars
  void triggerCelebration() {
    if (!mounted) return;
    setState(() => _manualCelebrating = true);
    _jumpController.repeat(reverse: true);
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted &&
          widget.avatar.pose != CompanionPose.celebrating &&
          !widget.isCelebrating) {
        setState(() => _manualCelebrating = false);
        _jumpController.stop();
        _jumpController.value = 0.0;
      }
    });
  }

  /// Playful reaction triggered on tap
  void triggerReaction({
    CompanionFaceExpression expression = CompanionFaceExpression.excited,
  }) {
    if (!mounted) return;
    _reactionTimer?.cancel();
    setState(() => _reactionExpression = expression);
    triggerWave();
    _reactionTimer = Timer(const Duration(milliseconds: 2400), () {
      if (mounted) setState(() => _reactionExpression = null);
    });
  }

  /// Gentle thinking hint after a mistake
  void triggerHint() {
    if (!mounted) return;
    _reactionTimer?.cancel();
    setState(() => _reactionExpression = CompanionFaceExpression.thinking);
    _reactionTimer = Timer(const Duration(milliseconds: 3200), () {
      if (mounted) setState(() => _reactionExpression = null);
    });
  }

  /// Happy burst after a correct answer
  void triggerCelebrateReaction() {
    if (!mounted) return;
    _reactionTimer?.cancel();
    setState(() => _reactionExpression = CompanionFaceExpression.excited);
    triggerCelebration();
    _reactionTimer = Timer(const Duration(milliseconds: 2200), () {
      if (mounted) setState(() => _reactionExpression = null);
    });
  }

  @override
  void dispose() {
    widget.speechCoordinator?.removeListener(_onSpeechSnapshotChanged);
    _reactionTimer?.cancel();
    _blinkTimer?.cancel();
    _breathingController.dispose();
    _blinkController.dispose();
    _waveController.dispose();
    _jumpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return Semantics(
      label: widget.avatar.gender == CompanionGender.boy
          ? 'شخصية الصديق البطل'
          : 'شخصية الصديقة البطلة',
      button: widget.onTap != null,
      child: GestureDetector(
        onTap: () {
          widget.onTap?.call();
          triggerReaction();
          final String? say = widget.speechText?.trim();
          if (widget.speakOnTap && say != null && say.isNotEmpty) {
            CalmVoiceService.instance.speakCalmly(
              say,
              allowSpeechForRepeatGame: true,
            );
          }
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (widget.showSpeechBubble &&
                widget.speechText != null &&
                widget.speechText!.trim().isNotEmpty) ...[
              _buildSpeechBubble(context),
              const SizedBox(height: 6),
            ],
            AnimatedBuilder(
              animation: Listenable.merge([
                _breathingAnim,
                _blinkAnim,
                _waveAnim,
                _jumpAnim,
              ]),
              builder: (context, _) {
                final bool celebrating =
                    widget.avatar.pose == CompanionPose.celebrating ||
                        widget.isCelebrating ||
                        _manualCelebrating;

                // jump arc: 0 = grounded, 1 = apex
                final double jumpT =
                    disableAnimations ? 0.0 : _jumpAnim.value.clamp(0.0, 1.0);
                final double jumpLift = celebrating ? -jumpT * 0.14 : 0.0;

                // gentle breathing float + greeting tilt
                final double floatDy =
                    disableAnimations ? 0.0 : _breathingAnim.value;
                final double tiltAngle = disableAnimations
                    ? 0.0
                    : (_waveAnim.value * 0.5 +
                        (celebrating ? jumpT * 0.06 : 0.0));

                return _buildScene(
                  context,
                  jumpLift: jumpLift,
                  jumpT: jumpT,
                  floatDy: floatDy,
                  tiltAngle: tiltAngle,
                  celebrating: celebrating,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// The 3D stage: themed background, ground shadow, sprite and accessories.
  Widget _buildScene(
    BuildContext context, {
    required double jumpLift,
    required double jumpT,
    required double floatDy,
    required double tiltAngle,
    required bool celebrating,
  }) {
    final double size = widget.size;
    final bool isBust = widget.mode == CompanionDisplayMode.bust;
    final bool waving = widget.avatar.pose == CompanionPose.waving ||
        widget.isWaving ||
        _manualWaving;

    final Widget characterBody = widget.useLayeredRig
        ? HaneenLayeredAvatarWidget(
            avatar: widget.avatar,
            viewAngle: widget.viewAngle,
            size: size,
            animateBreathing: widget.animateBreathing,
            isWaving: waving,
            isCelebrating: celebrating,
            expressionOverride:
                widget.expressionOverride ?? _reactionExpression,
            speechCoordinator: widget.speechCoordinator,
            mouthAnimationEnabled: widget.mouthAnimationEnabled,
            debugForceMouthOpen: widget.debugForceMouthOpen,
          )
        : _buildSprite(size, isBust: isBust);

    final Widget character = Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: [
        // Explorer wings sit behind the sprite (legacy path only; layered rig has native wings)
        if (!widget.useLayeredRig &&
            widget.avatar.accessory == 'wings' &&
            !isBust)
          Positioned(
            bottom: size * 0.42,
            child: Opacity(
              opacity: 0.9,
              child: Text(
                '🪽',
                style: TextStyle(fontSize: size * 0.34),
              ),
            ),
          ),
        characterBody,
        // Approximate mouth animation overlay (legacy path only; layered rig has articulated mouth)
        if (!widget.useLayeredRig && _effectiveMouthOpen > 0.001)
          _buildMouthOverlay(size, isBust: isBust),
        // smart glasses over the face (legacy path only; layered rig has native glasses)
        if (!widget.useLayeredRig && widget.avatar.accessory == 'glasses')
          Positioned(
            top: isBust ? size * 0.16 : size * 0.20,
            child: Text(
              '🕶️',
              style: TextStyle(fontSize: size * 0.16),
            ),
          ),
        // golden crown above the head (legacy path only; layered rig has native crown)
        if (!widget.useLayeredRig && widget.avatar.accessory == 'crown')
          Positioned(
            top: isBust ? size * 0.015 : size * 0.03,
            child: const Text('👑', style: TextStyle(fontSize: 18)),
          ),
        // 3D celebration stars burst around the character
        if (celebrating) ..._buildCelebrationStars(size, jumpT),
      ],
    );

    return SizedBox(
      width: size,
      height: size + 10,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          // Themed 3D scene backdrop
          if (widget.showBackgroundScene && !isBust)
            Positioned.fill(
              child: _buildSceneBackdrop(context, size),
            ),
          // Realistic ground shadow that tracks the jump motion
          if (!isBust)
            Positioned(
              bottom: size * 0.015,
              child: Transform.scale(
                // Shadow shrinks/fades as the character floats up (floatDy is -4..4).
                scale: (1.0 - jumpT * 0.35) * (1.0 + floatDy * 0.012),
                child: Opacity(
                  opacity: 0.35 * (1.0 - jumpT * 0.55) * (1.0 + floatDy * 0.02),
                  child: Container(
                    width: size * 0.62,
                    height: size * 0.085,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(100),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          blurRadius: size * 0.06,
                          spreadRadius: size * 0.02,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          // The character floats above its shadow
          Positioned(
            bottom: size * 0.05,
            child: Transform.translate(
              offset: Offset(0, floatDy + jumpLift * size),
              child: Transform.rotate(
                angle: tiltAngle + floatDy * 0.0035,
                alignment: Alignment.bottomCenter,
                // Soft squash and stretch synced to the breathing float.
                child: Transform.scale(
                  alignment: Alignment.bottomCenter,
                  scaleX: 1.0 - floatDy * 0.004,
                  scaleY: 1.0 + floatDy * 0.006,
                  child: SizedBox(
                    width: size,
                    height: size * 0.94,
                    child: isBust ? _buildBustClip(character) : character,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Approximate mouth overlay: a small dark ellipse at the calibrated
  /// mouth anchor whose height scales with the current openness. This is a
  /// stylized "talking" cue correlated to playback progress — explicitly NOT
  /// waveform/viseme lip-sync.
  Widget _buildMouthOverlay(double size, {required bool isBust}) {
    final CompanionMouthAnchor anchor = CompanionMouthAnchor.forSprite(
      gender: widget.avatar.gender,
      angle: widget.viewAngle,
    );
    final double open = _effectiveMouthOpen;
    final double heightFactor = anchor.closedHeightFactor +
        (anchor.openHeightFactor - anchor.closedHeightFactor) * open;
    return IgnorePointer(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: SizedBox(
          width: size,
          height: size * 0.94,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: size * anchor.dx - (size * anchor.widthFactor) / 2,
                top: size * anchor.dy - (size * heightFactor) / 2,
                child: Container(
                  key: const ValueKey('companion_mouth_overlay'),
                  width: size * anchor.widthFactor,
                  height: size * heightFactor,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B2314).withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(size * 0.05),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBustClip(Widget character) {
    return ClipOval(
      child: OverflowBox(
        maxWidth: double.infinity,
        maxHeight: double.infinity,
        alignment: Alignment.bottomCenter,
        child: Transform.translate(
          offset: Offset(0, -widget.size * 0.06),
          child: Transform.scale(
            scale: 1.25,
            child: SizedBox(
              width: widget.size,
              height: widget.size * 0.94,
              child: character,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSprite(double size, {required bool isBust}) {
    final Color? outfitTint = _outfitTint();

    Widget sprite = Image.asset(
      widget.spriteAsset(),
      fit: BoxFit.contain,
      gaplessPlayback: true,
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
    );

    if (outfitTint != null) {
      // tint only the outfit region (upper half of the sprite)
      sprite = Stack(
        alignment: Alignment.bottomCenter,
        children: [
          sprite,
          Positioned.fill(
            child: IgnorePointer(
              child: Align(
                alignment: Alignment.topCenter,
                child: FractionallySizedBox(
                  heightFactor: 0.55,
                  child: Container(color: outfitTint.withOpacity(0.28)),
                ),
              ),
            ),
          ),
        ],
      );
    }
    return sprite;
  }

  Color? _outfitTint() {
    switch (widget.avatar.outfit) {
      case 'sporty':
        return AppDesignTokens.secondaryGreen;
      case 'explorer':
        return AppDesignTokens.rewardGold;
      case 'fancy':
        return AppDesignTokens.gentlePink;
      case 'casual':
      default:
        return null;
    }
  }

  /// Themed gradient scene behind the character: playroom / garden / space.
  Widget _buildSceneBackdrop(BuildContext context, double size) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    List<Color> colors;
    List<_SceneDot> dots;

    switch (widget.avatar.background) {
      case 'garden':
        colors = const [
          Color(0xFFBBF7D0),
          Color(0xFF86EFAC),
          Color(0xFF4ADE80),
        ];
        dots = [
          _SceneDot(const Offset(-0.45, -0.35), 6.0,
              Colors.pinkAccent.withOpacity(0.7)),
          _SceneDot(
              const Offset(0.42, -0.42), 7.0, Colors.amber.withOpacity(0.8)),
          _SceneDot(const Offset(-0.38, 0.30), 5.0,
              Colors.pinkAccent.withOpacity(0.5)),
        ];
        break;
      case 'space':
        colors = const [
          Color(0xFF1E1B4B),
          Color(0xFF312E81),
          Color(0xFF4C1D95),
        ];
        dots = [
          _SceneDot(const Offset(-0.42, -0.38), 3.0, Colors.white70),
          _SceneDot(const Offset(0.36, -0.30), 2.4, Colors.white70),
          _SceneDot(const Offset(0.48, 0.18), 3.2, Colors.white60),
          _SceneDot(const Offset(-0.30, 0.28), 2.0, Colors.white54),
          _SceneDot(const Offset(0.05, -0.48), 2.6, Colors.white70),
        ];
        break;
      case 'playroom':
      default:
        colors = isDark
            ? const [Color(0xFF334155), Color(0xFF1E293B), Color(0xFF0F172A)]
            : const [Color(0xFFFEF3C7), Color(0xFFFDE68A), Color(0xFFFACC15)];
        dots = [
          _SceneDot(
              const Offset(-0.40, -0.38), 4.5, Colors.amber.withOpacity(0.7)),
          _SceneDot(
              const Offset(0.44, -0.35), 3.8, Colors.amber.withOpacity(0.5)),
        ];
        break;
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
        ),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(28),
          bottom: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: colors.last.withOpacity(0.4),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double w = constraints.maxWidth;
          final double h = constraints.maxHeight;
          return Stack(
            children: [
              for (final dot in dots)
                Positioned(
                  left: w * (0.5 + dot.offset.dx),
                  top: h * (0.5 + dot.offset.dy),
                  child: Container(
                    width: dot.size,
                    height: dot.size,
                    decoration: BoxDecoration(
                      color: dot.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildCelebrationStars(double size, double jumpT) {
    final double s = size * 0.14;
    final style = TextStyle(fontSize: s);
    return [
      Positioned(
          top: size * 0.16,
          left: -s * 0.4,
          child: Opacity(opacity: 0.9, child: Text('⭐', style: style))),
      Positioned(
          top: size * 0.05,
          right: -s * 0.3,
          child: Opacity(opacity: 0.85, child: Text('🌟', style: style))),
      Positioned(
          bottom: size * 0.30,
          left: -s * 0.6,
          child: Opacity(opacity: 0.75, child: Text('✨', style: style))),
      Positioned(
          bottom: size * 0.22,
          right: -s * 0.5,
          child: Opacity(opacity: 0.8, child: Text('⭐', style: style))),
      Positioned(
        top: size * 0.28,
        right: s * 0.2,
        child: Transform.scale(
          scale: 0.8 + jumpT * 0.4,
          child: const Text('✨', style: TextStyle(fontSize: 14)),
        ),
      ),
    ];
  }

  Widget _buildSpeechBubble(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: math.max(160, widget.size * 1.3)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppDesignTokens.primaryPurple.withOpacity(0.6),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Text(
          widget.speechText!,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            height: 1.3,
          ),
        ),
      ),
    );
  }
}

class _SceneDot {
  final Offset offset;
  final double size;
  final Color color;
  const _SceneDot(this.offset, this.size, this.color);
}
