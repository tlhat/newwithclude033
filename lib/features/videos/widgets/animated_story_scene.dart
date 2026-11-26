import 'dart:math';
import 'package:flutter/material.dart' hide Text;
import 'package:haneen_kids_vod/core/regional/dialect_text.dart';
import 'package:haneen_kids_vod/haneen_kids_exports.dart';

/// A living story picture, drawn in code (works offline, no art files).
/// Every emoji of the scene bounces, sways and blinks on its own rhythm,
/// with drifting clouds, twinkling stars and floating sparkles behind it.
/// Respects the "reduce motion" setting (then it stays still).
class AnimatedStoryScene extends StatefulWidget {
  final String illustration;
  final double emojiSize;
  const AnimatedStoryScene({
    super.key,
    required this.illustration,
    this.emojiSize = 64,
  });

  @override
  State<AnimatedStoryScene> createState() => _AnimatedStorySceneState();
}

class _AnimatedStorySceneState extends State<AnimatedStoryScene>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  );

  @override
  void initState() {
    super.initState();
    if (!AppNetworkPolicyGuard.reduceMotionActive) _c.repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<String> glyphs =
        widget.illustration.characters.where((g) => g.trim().isNotEmpty).toList();
    final double size = widget.emojiSize;
    return RepaintBoundary(
      child: SizedBox(
        height: size * 1.6,
        width: double.infinity,
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final double t = _c.value;
            return Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: CustomPaint(painter: _SkyPainter(t)),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (int i = 0; i < glyphs.length; i++)
                      _glyph(glyphs[i], i, t, size),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _glyph(String g, int i, double t, double size) {
    final double phase = i * 0.37;
    // Whole number of cycles per 8s loop, so the loop is seamless.
    final double bounce = (sin((t * 3 + phase) * 2 * pi) + 1) / 2; // 0..1
    final double dy = -bounce * size * 0.16;
    final double sway = sin((t * 2 + phase) * 2 * pi) * 0.07;
    // A quick blink (squash) about twice per loop, offset for each glyph.
    final double b = ((t * 2 + phase) % 1.0);
    final double squash = b < 0.06 ? 1 - 0.2 * sin(b / 0.06 * pi) : 1;
    final double breathe = 1 + 0.03 * sin((t * 4 + phase) * 2 * pi);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: size * 0.04),
      child: Transform.translate(
        offset: Offset(0, dy),
        child: Transform.rotate(
          angle: sway,
          alignment: Alignment.bottomCenter,
          child: Transform.scale(
            scaleX: breathe,
            scaleY: breathe * squash,
            alignment: Alignment.bottomCenter,
            child: Text(g, style: TextStyle(fontSize: size)),
          ),
        ),
      ),
    );
  }
}

class _SkyPainter extends CustomPainter {
  final double t;
  _SkyPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint cloud = Paint()..color = Colors.white.withOpacity(0.20);
    for (int i = 0; i < 3; i++) {
      final double speed = 1.0 + i; // whole numbers: seamless loop
      final double x = ((t * speed + i * 0.37) % 1.0) * (size.width + 120) - 60;
      final double y = size.height * (0.18 + 0.22 * i);
      final double w = 46 + 14.0 * i;
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromCenter(center: Offset(x, y), width: w, height: w * 0.4),
              Radius.circular(w)),
          cloud);
      canvas.drawCircle(Offset(x - w * 0.15, y - w * 0.12), w * 0.2, cloud);
      canvas.drawCircle(Offset(x + w * 0.12, y - w * 0.16), w * 0.25, cloud);
    }
    const List<Offset> stars = [
      Offset(0.12, 0.2), Offset(0.28, 0.72), Offset(0.45, 0.12),
      Offset(0.62, 0.78), Offset(0.8, 0.25), Offset(0.9, 0.68),
    ];
    for (int i = 0; i < stars.length; i++) {
      final double tw = pow(sin((t * 4 + i * 0.21) * 2 * pi), 2).toDouble();
      final Paint p = Paint()
        ..color = const Color(0xFFFDE68A).withOpacity(0.25 + 0.65 * tw);
      final Offset c = Offset(stars[i].dx * size.width, stars[i].dy * size.height);
      final double r = 2.2 + 1.8 * tw;
      canvas.drawCircle(c, r, p);
      canvas.drawLine(c.translate(-r * 1.8, 0), c.translate(r * 1.8, 0),
          p..strokeWidth = 1);
      canvas.drawLine(c.translate(0, -r * 1.8), c.translate(0, r * 1.8), p);
    }
    // Sparkles floating up.
    final Paint sp = Paint()..color = Colors.white.withOpacity(0.5);
    for (int i = 0; i < 5; i++) {
      final double p = (t * 2 + i * 0.2) % 1.0;
      canvas.drawCircle(
        Offset(size.width * (0.2 + 0.15 * i) + sin(p * 2 * pi + i) * 6,
            size.height * (1 - p)),
        1.6,
        sp..color = Colors.white.withOpacity(0.55 * (1 - p)),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SkyPainter old) => old.t != t;
}
