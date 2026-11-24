import 'dart:async';
import 'dart:math' as math;

// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:haneen_kids_vod/features/companion/engine/speech_coordinator.dart';
import 'package:haneen_kids_vod/features/companion/models/avatar_customization_model.dart';
import 'package:haneen_kids_vod/features/companion/widgets/haneen_companion_avatar_widget.dart';

/// Reusable Layered 2D Character Rig and Animation Renderer for Haneen Kids.
///
/// Constructs characters from their authentic 2048x2048 transparent PNG part
/// layers in a single unified coordinate space:
///   - Boy Front
///   - Boy 3D Angle
///   - Girl Front
///   - Girl 3D Angle
///
/// Features independent hierarchical animations:
///   - Breathing (subtle torso and garment expansion/movement)
///   - Head bob & micro-tilt around the anatomical neck pivot
///   - Secondary hair pendulum sway
///   - Independent shoulder-pivoted arm sway and hand waving
///   - Organic eye blinking (eyes_open <-> eyes_closed)
///   - Smooth pupil gaze shifts / saccades
///   - Speaking mouth articulation synchronized with [SpeechCoordinator]
///   - Emotion expression switching (calm, happy, excited, shy, thinking)
///   - Full customization (hair styles, outfits, glasses, crown, wings)
///   - Graceful fallback to flat 2D sprite if requested or on asset fault.
class HaneenLayeredAvatarWidget extends StatefulWidget {
  final AvatarCustomizationModel avatar;
  final CompanionViewAngle viewAngle;
  final double size;
  final bool animateBreathing;
  final bool isWaving;
  final bool isCelebrating;
  final CompanionFaceExpression? expressionOverride;
  final SpeechCoordinator? speechCoordinator;
  final bool mouthAnimationEnabled;
  final bool debugForceMouthOpen;
  final bool fallbackToFlatSprite;
  final VoidCallback? onTap;

  const HaneenLayeredAvatarWidget({
    super.key,
    required this.avatar,
    this.viewAngle = CompanionViewAngle.front,
    this.size = 200,
    this.animateBreathing = true,
    this.isWaving = false,
    this.isCelebrating = false,
    this.expressionOverride,
    this.speechCoordinator,
    this.mouthAnimationEnabled = true,
    this.debugForceMouthOpen = false,
    this.fallbackToFlatSprite = false,
    this.onTap,
  });

  @override
  State<HaneenLayeredAvatarWidget> createState() =>
      HaneenLayeredAvatarWidgetState();
}

class HaneenLayeredAvatarWidgetState extends State<HaneenLayeredAvatarWidget>
    with TickerProviderStateMixin {
  // --- Animation Controllers ---
  late AnimationController _breathingController;
  late Animation<double> _breathingAnim;

  late AnimationController _headController;
  late Animation<double> _headAnim;

  late AnimationController _armController;
  late Animation<double> _armAnim;

  late AnimationController _waveController;
  late Animation<double> _waveAnim;

  late AnimationController _hairController;
  late Animation<double> _hairAnim;

  late AnimationController _blinkController;
  late Animation<double> _blinkAnim;

  late AnimationController _gazeController;
  Offset _currentGaze = Offset.zero;
  Offset _targetGaze = Offset.zero;

  // --- Timers ---
  Timer? _blinkTimer;
  Timer? _gazeTimer;

  // --- Speech & Interaction State ---
  CompanionSpeechSnapshot _speechSnapshot = CompanionSpeechSnapshot.idle;
  bool _hasAssetError = false;
  final math.Random _random = math.Random();

  // Anatomical rigging pivots (in 2048x2048 normalized -1..1 Alignment space)
  // Center is (0.0, 0.0) corresponding to (1024, 1024)
  static const Alignment _neckPivot = Alignment(0.0, -0.14);
  static const Alignment _leftShoulderPivot = Alignment(0.35, 0.0);
  static const Alignment _rightShoulderPivot = Alignment(-0.36, 0.0);
  static const Alignment _hairRootPivot = Alignment(0.0, -0.53);

  @override
  void initState() {
    super.initState();

    // 1. Breathing: gentle 2.6s sinusoidal cycle
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _breathingAnim = Tween<double>(begin: -4.5, end: 4.5).animate(
      CurvedAnimation(parent: _breathingController, curve: Curves.easeInOutSine),
    );
    if (widget.animateBreathing) {
      _breathingController.repeat(reverse: true);
    }

    // 2. Head micro-tilt and bob: 3.2s cadence
    _headController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    _headAnim = Tween<double>(begin: -0.06, end: 0.07).animate(
      CurvedAnimation(parent: _headController, curve: Curves.easeInOutCubic),
    );
    if (widget.animateBreathing) {
      _headController.repeat(reverse: true);
    }

    // 3. Subtle arm idle sway (in counter-balance to breath)
    _armController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );
    _armAnim = Tween<double>(begin: -0.10, end: 0.10).animate(
      CurvedAnimation(parent: _armController, curve: Curves.easeInOut),
    );
    if (widget.animateBreathing) {
      _armController.repeat(reverse: true);
    }

    // 4. Arm wave: active greeting rotation (0.06 rad to 0.38 rad)
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 620),
    );
    _waveAnim = Tween<double>(begin: 0.10, end: 0.85).animate(
      CurvedAnimation(parent: _waveController, curve: Curves.easeInOut),
    );
    if (widget.isWaving || widget.avatar.pose == CompanionPose.waving) {
      _waveController.repeat(reverse: true);
    }

    // 5. Hair secondary motion: lagging pendulum sway
    _hairController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2100),
    );
    _hairAnim = Tween<double>(begin: -0.06, end: 0.06).animate(
      CurvedAnimation(parent: _hairController, curve: Curves.easeInOutSine),
    );
    if (widget.animateBreathing) {
      _hairController.repeat(reverse: true);
    }

    // 6. Blinking: 160ms eyelid transition
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 160),
    );
    _blinkAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _blinkController, curve: Curves.easeInOut),
    );
    _scheduleNextBlink();

    // 7. Pupil gaze drift controller: 240ms transition to new fixation target
    _gazeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );
    _scheduleNextGazeShift();

    // Speech coordinator listener
    widget.speechCoordinator?.addListener(_onSpeechSnapshotChanged);
  }

  @override
  void didUpdateWidget(covariant HaneenLayeredAvatarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.speechCoordinator != widget.speechCoordinator) {
      oldWidget.speechCoordinator?.removeListener(_onSpeechSnapshotChanged);
      widget.speechCoordinator?.addListener(_onSpeechSnapshotChanged);
      _onSpeechSnapshotChanged();
    }

    if (widget.animateBreathing != oldWidget.animateBreathing) {
      if (widget.animateBreathing) {
        _breathingController.repeat(reverse: true);
        _headController.repeat(reverse: true);
        _armController.repeat(reverse: true);
        _hairController.repeat(reverse: true);
      } else {
        _breathingController.stop();
        _headController.stop();
        _armController.stop();
        _hairController.stop();
        _breathingController.value = 0.0;
        _headController.value = 0.0;
        _armController.value = 0.0;
        _hairController.value = 0.0;
      }
    }

    final bool shouldWave =
        widget.isWaving || widget.avatar.pose == CompanionPose.waving;
    if (shouldWave && !_waveController.isAnimating) {
      _waveController.repeat(reverse: true);
    } else if (!shouldWave && _waveController.isAnimating) {
      _waveController.stop();
      _waveController.value = 0.0;
    }
  }

  void _scheduleNextBlink() {
    _blinkTimer?.cancel();
    final int delayMs = 3200 + _random.nextInt(1800);
    _blinkTimer = Timer(Duration(milliseconds: delayMs), () {
      if (mounted && _blinkController.isDismissed) {
        _blinkController.forward().then((_) {
          if (mounted) {
            _blinkController.reverse().then((_) {
              if (mounted) _scheduleNextBlink();
            });
          }
        });
      } else if (mounted) {
        _scheduleNextBlink();
      }
    });
  }

  void _scheduleNextGazeShift() {
    _gazeTimer?.cancel();
    final int delayMs = 2800 + _random.nextInt(2200);
    _gazeTimer = Timer(Duration(milliseconds: delayMs), () {
      if (!mounted) return;
      _currentGaze = _targetGaze;
      final double newX = (_random.nextDouble() * 2.0 - 1.0) * 0.7;
      final double newY = (_random.nextDouble() * 2.0 - 1.0) * 0.4;
      _targetGaze = Offset(newX, newY);
      _gazeController.forward(from: 0.0).then((_) {
        if (mounted) _scheduleNextGazeShift();
      });
    });
  }

  void _onSpeechSnapshotChanged() {
    final CompanionSpeechSnapshot next = widget.speechCoordinator?.snapshot ??
        CompanionSpeechSnapshot.idle;
    if (next != _speechSnapshot) {
      setState(() => _speechSnapshot = next);
    }
  }

  @override
  void dispose() {
    widget.speechCoordinator?.removeListener(_onSpeechSnapshotChanged);
    _blinkTimer?.cancel();
    _gazeTimer?.cancel();
    _breathingController.dispose();
    _headController.dispose();
    _armController.dispose();
    _waveController.dispose();
    _hairController.dispose();
    _blinkController.dispose();
    _gazeController.dispose();
    super.dispose();
  }

  // --- Asset Path Resolvers ---
  String get _variantDir {
    final String gender =
        widget.avatar.gender == CompanionGender.boy ? 'boy' : 'girl';
    return '${gender}_${widget.viewAngle.assetSuffix}';
  }

  String _partPath(String filename) =>
      'assets/avatars/parts/$_variantDir/$filename';

  String get _resolvedHairFilename {
    final bool isBoy = widget.avatar.gender == CompanionGender.boy;
    final String style = widget.avatar.hairStyle.toLowerCase();
    if (isBoy) {
      switch (style) {
        case 'spiky':
          return 'hair_spiky.png';
        case 'cap':
          return 'hair_cap.png';
        case 'curly':
        default:
          return 'hair_curly.png';
      }
    } else {
      switch (style) {
        case 'braids':
          return 'hair_braids.png';
        case 'bow':
          return 'hair_bow.png';
        case 'crown':
          return 'hair_crown.png';
        case 'ponytail':
        default:
          return 'hair_ponytail.png';
      }
    }
  }

  String get _resolvedOutfitFilename {
    switch (widget.avatar.outfit.toLowerCase()) {
      case 'sporty':
        return 'outfit_sporty.png';
      case 'explorer':
        return 'outfit_explorer.png';
      case 'fancy':
        return 'outfit_fancy.png';
      case 'casual':
      default:
        return 'outfit_casual.png';
    }
  }

  String get _resolvedEyebrowsFilename {
    final CompanionFaceExpression expr = widget.expressionOverride ??
        widget.avatar.faceExpression;
    switch (expr) {
      case CompanionFaceExpression.excited:
        return 'eyebrows_excited.png';
      case CompanionFaceExpression.happy:
        return 'eyebrows_happy.png';
      case CompanionFaceExpression.shy:
        return 'eyebrows_shy.png';
      case CompanionFaceExpression.thinking:
        return 'eyebrows_thinking.png';
      case CompanionFaceExpression.calm:
        return 'eyebrows_calm.png';
    }
  }

  bool get _isMouthOpen {
    if (widget.debugForceMouthOpen) return true;
    if (!widget.mouthAnimationEnabled) return false;
    if (!_speechSnapshot.isSpeaking) return false;
    return _speechSnapshot.mouthOpen > 0.001;
  }

  Widget _buildImage(String assetPath, {Key? key}) {
    return Image.asset(
      assetPath,
      key: key,
      fit: BoxFit.contain,
      gaplessPlayback: true,
      filterQuality: FilterQuality.medium,
      errorBuilder: (context, error, stackTrace) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_hasAssetError) {
            setState(() => _hasAssetError = true);
          }
        });
        return const SizedBox.shrink();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    // Graceful fallback to original flat sprite if requested or on asset error
    if (widget.fallbackToFlatSprite || _hasAssetError) {
      final String gender =
          widget.avatar.gender == CompanionGender.boy ? 'boy' : 'girl';
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: Image.asset(
          'assets/avatars/${gender}_${widget.viewAngle.assetSuffix}.png',
          fit: BoxFit.contain,
          gaplessPlayback: true,
        ),
      );
    }

    return RepaintBoundary(
      key: const ValueKey('layered_avatar_rig'),
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: AspectRatio(
          aspectRatio: 1.0,
          child: AnimatedBuilder(
            animation: Listenable.merge([
              _breathingAnim,
              _headAnim,
              _armAnim,
              _waveAnim,
              _hairAnim,
              _blinkAnim,
              _gazeController,
            ]),
            builder: (context, _) {
              // Calculate active animation offsets
              final double breathDy =
                  disableAnimations ? 0.0 : _breathingAnim.value;
              final double headTilt =
                  disableAnimations ? 0.0 : _headAnim.value;
              final double leftArmRot =
                  disableAnimations ? 0.0 : _armAnim.value;
              final bool waving =
                  widget.isWaving || widget.avatar.pose == CompanionPose.waving;
              final double rightArmRot = disableAnimations
                  ? 0.0
                  : (waving ? _waveAnim.value : -_armAnim.value);
              final double hairSway =
                  disableAnimations ? 0.0 : _hairAnim.value;

              final double gazeT =
                  disableAnimations ? 1.0 : _gazeController.value;
              final Offset currentGazeOffset = Offset.lerp(
                    _currentGaze,
                    _targetGaze,
                    Curves.easeOutCubic.transform(gazeT),
                  ) ??
                  Offset.zero;
              final double gazeDx = currentGazeOffset.dx * (widget.size * 0.012);
              final double gazeDy = currentGazeOffset.dy * (widget.size * 0.007);

              final bool isBlinking = !disableAnimations && _blinkAnim.value > 0.5;

              final String accessory = widget.avatar.accessory.toLowerCase();
              final bool hasWings = accessory == 'wings';
              final bool hasGlasses = accessory == 'glasses';
              final bool hasCrown = accessory == 'crown';

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  // --- Layer 1: Back Accessories (Wings) ---
                  if (hasWings)
                    Positioned.fill(
                      child: _buildImage(
                        _partPath('acc_wings.png'),
                        key: const ValueKey('layer_acc_wings'),
                      ),
                    ),

                  // --- Layer 2: Legs (Hip pivots behind torso) ---
                  Positioned.fill(
                    child: _buildImage(
                      _partPath('leg_left.png'),
                      key: const ValueKey('layer_leg_left'),
                    ),
                  ),
                  Positioned.fill(
                    child: _buildImage(
                      _partPath('leg_right.png'),
                      key: const ValueKey('layer_leg_right'),
                    ),
                  ),

                  // --- Layer 3: Left Arm (Shoulder pivot) ---
                  Positioned.fill(
                    child: Transform.rotate(
                      angle: leftArmRot,
                      alignment: _leftShoulderPivot,
                      child: _buildImage(
                        _partPath('arm_left.png'),
                        key: const ValueKey('layer_arm_left'),
                      ),
                    ),
                  ),

                  // --- Layer 4: Right Arm (Shoulder pivot + Waving) ---
                  Positioned.fill(
                    child: Transform.rotate(
                      angle: rightArmRot,
                      alignment: _rightShoulderPivot,
                      child: _buildImage(
                        _partPath('arm_right.png'),
                        key: const ValueKey('layer_arm_right'),
                      ),
                    ),
                  ),

                  // --- Layer 5: Torso Body (Breathing translation) ---
                  Positioned.fill(
                    child: Transform.translate(
                      offset: Offset(0, breathDy),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: _buildImage(
                              _partPath('body.png'),
                              key: const ValueKey('layer_body'),
                            ),
                          ),

                          // --- Layer 6: Outfit / Garment ---
                          Positioned.fill(
                            child: _buildImage(
                              _partPath(_resolvedOutfitFilename),
                              key: const ValueKey('layer_outfit'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // --- Layer 7+: Head Hierarchy (Neck connection pivot) ---
                  Positioned.fill(
                    child: Transform.translate(
                      offset: Offset(0, breathDy * 0.6),
                      child: Transform.rotate(
                        angle: headTilt,
                        alignment: _neckPivot,
                        child: Stack(
                          children: [
                            // Head Base
                            Positioned.fill(
                              child: _buildImage(
                                _partPath('head.png'),
                                key: const ValueKey('layer_head'),
                              ),
                            ),

                            // Mouth: Neutral vs Open
                            if (_isMouthOpen)
                              Positioned.fill(
                                child: _buildImage(
                                  _partPath('mouth_open.png'),
                                  key: const ValueKey('companion_mouth_overlay'),
                                ),
                              )
                            else
                              Positioned.fill(
                                child: _buildImage(
                                  _partPath('mouth_neutral.png'),
                                  key: const ValueKey('layer_mouth_neutral'),
                                ),
                              ),

                            // Eyes: Open (with pupils & lashes) vs Closed (blink)
                            if (!isBlinking) ...[
                              Positioned.fill(
                                child: _buildImage(
                                  _partPath('eyes_open.png'),
                                  key: const ValueKey('layer_eyes_open'),
                                ),
                              ),
                              // Pupil gaze offset
                              Positioned.fill(
                                child: Transform.translate(
                                  offset: Offset(gazeDx, gazeDy),
                                  child: _buildImage(
                                    _partPath('pupils.png'),
                                    key: const ValueKey('layer_pupils'),
                                  ),
                                ),
                              ),
                              Positioned.fill(
                                child: _buildImage(
                                  _partPath('eyelashes.png'),
                                  key: const ValueKey('layer_eyelashes'),
                                ),
                              ),
                            ] else ...[
                              Positioned.fill(
                                child: _buildImage(
                                  _partPath('eyes_closed.png'),
                                  key: const ValueKey('layer_eyes_closed'),
                                ),
                              ),
                              Positioned.fill(
                                child: _buildImage(
                                  _partPath('eyelashes.png'),
                                  key: const ValueKey('layer_eyelashes_closed'),
                                ),
                              ),
                            ],

                            // Eyebrows (Active Expression)
                            Positioned.fill(
                              child: _buildImage(
                                _partPath(_resolvedEyebrowsFilename),
                                key: const ValueKey('layer_eyebrows'),
                              ),
                            ),

                            // Hair (with secondary pendulum sway)
                            Positioned.fill(
                              child: Transform.rotate(
                                angle: hairSway,
                                alignment: _hairRootPivot,
                                child: _buildImage(
                                  _partPath(_resolvedHairFilename),
                                  key: const ValueKey('layer_hair'),
                                ),
                              ),
                            ),

                            // Smart Glasses
                            if (hasGlasses)
                              Positioned.fill(
                                child: _buildImage(
                                  _partPath('acc_glasses.png'),
                                  key: const ValueKey('layer_acc_glasses'),
                                ),
                              ),

                            // Golden Crown
                            if (hasCrown)
                              Positioned.fill(
                                child: _buildImage(
                                  _partPath('acc_crown.png'),
                                  key: const ValueKey('layer_acc_crown'),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
