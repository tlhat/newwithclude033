import 'dart:math';
import 'package:flutter/material.dart';
import 'package:haneen_kids_vod/haneen_kids_exports.dart';

class Interactive3DSuperheroAvatar extends StatefulWidget {
  final CuteHeroCharacterModel hero;
  final double size;
  final bool isJumping;
  final VoidCallback? onTap;

  const Interactive3DSuperheroAvatar({
    super.key,
    required this.hero,
    this.size = 56,
    this.isJumping = false,
    this.onTap,
  });

  @override
  State<Interactive3DSuperheroAvatar> createState() =>
      _Interactive3DSuperheroAvatarState();
}

class _Interactive3DSuperheroAvatarState
    extends State<Interactive3DSuperheroAvatar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  bool _localBurst = false;

  bool get _shouldThrottleAnimations =>
      AppNetworkPolicyGuard.reduceMotionActive ||
      AppNetworkPolicyGuard.lowMemoryPerformanceModeActive;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    if (!_shouldThrottleAnimations) {
      _animCtrl.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant Interactive3DSuperheroAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_shouldThrottleAnimations && _animCtrl.isAnimating) {
      _animCtrl.stop();
    } else if (!_shouldThrottleAnimations && !_animCtrl.isAnimating) {
      _animCtrl.repeat();
    }
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (!_shouldThrottleAnimations) {
      setState(() => _localBurst = true);
      Future.delayed(const Duration(milliseconds: 650), () {
        if (mounted) setState(() => _localBurst = false);
      });
    }
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: GestureDetector(
        onTap: _handleTap,
        child: AnimatedBuilder(
          animation: _animCtrl,
          builder: (context, _) {
            final bool calmMotion = _shouldThrottleAnimations ||
                (MediaQuery.maybeOf(context)?.disableAnimations ?? false);
            final bool lowMem =
                AppNetworkPolicyGuard.lowMemoryPerformanceModeActive;
            final double t = calmMotion ? 0.0 : _animCtrl.value * 2 * pi;
            final bool excited =
                !calmMotion && (widget.isJumping || _localBurst);
            final double hoverOffset = calmMotion
                ? 0.0
                : (excited ? -sin(t * 3).abs() * 5.0 : sin(t) * 2.2);
            final double tiltY = calmMotion ? 0.0 : sin(t) * 0.14;
            final double tiltX = calmMotion ? 0.0 : cos(t * 0.5) * 0.06;
            final double scaleBoost = excited ? 1.08 : 1.0;

            final Matrix4 perspectiveMatrix = Matrix4.identity()
              ..setEntry(3, 2, 0.0018)
              ..rotateY(tiltY)
              ..rotateX(tiltX)
              ..scale(scaleBoost);

            return Transform.translate(
              offset: Offset(0, hoverOffset),
              child: Transform(
                alignment: Alignment.center,
                transform: perspectiveMatrix,
                child: SizedBox(
                  width: widget.size,
                  height: widget.size,
                  child: CustomPaint(
                    painter: _Superhero3DCharacterPainter(
                      hero: widget.hero,
                      phase: t,
                      isExcited: excited,
                      lowMemoryMode: lowMem,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Superhero3DCharacterPainter extends CustomPainter {
  final CuteHeroCharacterModel hero;
  final double phase;
  final bool isExcited;
  final bool lowMemoryMode;

  const _Superhero3DCharacterPainter({
    required this.hero,
    required this.phase,
    required this.isExcited,
    this.lowMemoryMode = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double cy = size.height / 2;
    final double r = min(size.width, size.height) * 0.34;

    final Paint shadowPaint = Paint()..color = Colors.black.withOpacity(0.32);
    if (!lowMemoryMode) {
      shadowPaint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    }
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, size.height * 0.91),
        width: r * (1.2 - sin(phase) * 0.12),
        height: r * 0.26,
      ),
      shadowPaint,
    );

    if (!lowMemoryMode) {
      final Paint auraPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            hero.primaryColor.withOpacity(isExcited ? 0.58 : 0.36),
            hero.secondaryColor.withOpacity(0.12),
            Colors.transparent,
          ],
        ).createShader(
            Rect.fromCircle(center: Offset(cx, cy), radius: r * 1.40));
      canvas.drawCircle(Offset(cx, cy), r * 1.38, auraPaint);
    }

    final Path capePath = Path();
    final double capeWave = sin(phase * 1.5) * (r * 0.20);
    capePath.moveTo(cx - r * 0.55, cy - r * 0.1);
    capePath.quadraticBezierTo(
      cx - r * 0.85 + capeWave,
      cy + r * 0.55,
      cx - r * 0.50 + capeWave,
      cy + r * 0.92,
    );
    capePath.lineTo(cx + r * 0.50 + capeWave * 0.6, cy + r * 0.90);
    capePath.quadraticBezierTo(
      cx + r * 0.80,
      cy + r * 0.45,
      cx + r * 0.55,
      cy - r * 0.1,
    );
    capePath.close();
    final Paint capePaint = Paint()
      ..color = hero.secondaryColor.withOpacity(0.9);
    canvas.drawPath(capePath, capePaint);

    final Rect torsoRect = Rect.fromCenter(
      center: Offset(cx, cy + r * 0.46),
      width: r * 1.05,
      height: r * 0.82,
    );
    final Paint torsoPaint = Paint()..color = hero.primaryColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(torsoRect, Radius.circular(r * 0.42)),
      torsoPaint,
    );

    final Paint emblemPaint = Paint()
      ..color = const Color(0xFFFDE047)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy + r * 0.42), r * 0.18, emblemPaint);

    final double leftArmAngle = -0.35 + cos(phase) * 0.15;
    canvas.save();
    canvas.translate(cx - r * 0.52, cy + r * 0.25);
    canvas.rotate(leftArmAngle);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-r * 0.22, 0, r * 0.22, r * 0.52),
        Radius.circular(r * 0.12),
      ),
      torsoPaint,
    );
    canvas.restore();

    final double waveSpeed = isExcited ? 2.8 : 1.6;
    final double rightArmWaveAngle = -2.25 + sin(phase * waveSpeed) * 0.42;
    canvas.save();
    canvas.translate(cx + r * 0.48, cy + r * 0.22);
    canvas.rotate(rightArmWaveAngle);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-r * 0.12, 0, r * 0.24, r * 0.58),
        Radius.circular(r * 0.12),
      ),
      torsoPaint,
    );
    final Paint glovePaint = Paint()..color = const Color(0xFFFDE047);
    canvas.drawCircle(Offset(0, r * 0.62), r * 0.16, glovePaint);
    canvas.restore();

    final Offset headCenter = Offset(cx, cy - r * 0.18);
    final double headRadius = r * 0.62;
    final Paint head3DPaint = Paint()
      ..color = hero.id == 'sponge_smile' || hero.id == 'pika_spark'
          ? const Color(0xFFFDE047)
          : (hero.id == 'spidey_hero'
              ? const Color(0xFFEF4444)
              : const Color(0xFFFDBA74));
    canvas.drawCircle(headCenter, headRadius, head3DPaint);

    if (hero.id == 'elsa_princess' ||
        hero.id == 'simba_cub' ||
        hero.id == 'haneen_companion') {
      final Paint crownPaint = Paint()..color = const Color(0xFFFACC15);
      final Path crown = Path()
        ..moveTo(headCenter.dx - headRadius * 0.45,
            headCenter.dy - headRadius * 0.82)
        ..lineTo(headCenter.dx - headRadius * 0.35,
            headCenter.dy - headRadius * 1.18)
        ..lineTo(headCenter.dx - headRadius * 0.12,
            headCenter.dy - headRadius * 0.92)
        ..lineTo(headCenter.dx, headCenter.dy - headRadius * 1.25)
        ..lineTo(headCenter.dx + headRadius * 0.12,
            headCenter.dy - headRadius * 0.92)
        ..lineTo(headCenter.dx + headRadius * 0.35,
            headCenter.dy - headRadius * 1.18)
        ..lineTo(headCenter.dx + headRadius * 0.45,
            headCenter.dy - headRadius * 0.82)
        ..close();
      canvas.drawPath(crown, crownPaint);
    }

    final Rect maskRect = Rect.fromCenter(
      center: Offset(headCenter.dx, headCenter.dy - headRadius * 0.06),
      width: headRadius * 1.55,
      height: headRadius * 0.65,
    );
    final Paint maskPaint = Paint()
      ..color = hero.primaryColor.withOpacity(0.90);
    canvas.drawRRect(
      RRect.fromRectAndRadius(maskRect, Radius.circular(headRadius * 0.32)),
      maskPaint,
    );

    final bool isBlinking = (sin(phase * 2.2) > 0.94);
    final double eyeH = isBlinking ? headRadius * 0.05 : headRadius * 0.26;
    final Paint eyeWhite = Paint()..color = Colors.white;
    final Paint pupilPaint = Paint()..color = const Color(0xFF0F172A);

    final Offset leftEyeCenter = Offset(
        headCenter.dx - headRadius * 0.32, headCenter.dy - headRadius * 0.06);
    final Offset rightEyeCenter = Offset(
        headCenter.dx + headRadius * 0.32, headCenter.dy - headRadius * 0.06);

    canvas.drawOval(
      Rect.fromCenter(
          center: leftEyeCenter, width: headRadius * 0.30, height: eyeH),
      eyeWhite,
    );
    canvas.drawOval(
      Rect.fromCenter(
          center: rightEyeCenter, width: headRadius * 0.30, height: eyeH),
      eyeWhite,
    );

    if (!isBlinking) {
      final double lookOffset = sin(phase) * (headRadius * 0.05);
      canvas.drawCircle(
        leftEyeCenter.translate(lookOffset, 0),
        headRadius * 0.11,
        pupilPaint,
      );
      canvas.drawCircle(
        rightEyeCenter.translate(lookOffset, 0),
        headRadius * 0.11,
        pupilPaint,
      );
    }

    final Paint smilePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(1.5, headRadius * 0.09)
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(headCenter.dx, headCenter.dy + headRadius * 0.24),
        width: headRadius * 0.65,
        height: headRadius * 0.42,
      ),
      0.15,
      pi - 0.3,
      false,
      smilePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _Superhero3DCharacterPainter oldDelegate) {
    return oldDelegate.phase != phase ||
        oldDelegate.isExcited != isExcited ||
        oldDelegate.lowMemoryMode != lowMemoryMode ||
        oldDelegate.hero.id != hero.id;
  }
}
