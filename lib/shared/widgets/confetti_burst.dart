import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Short full-screen confetti celebration. Call [ConfettiBurst.show] when a
/// child finishes a lesson. It draws above everything, ignores touches and
/// removes itself after about two seconds.
class ConfettiBurst extends StatefulWidget {
  final VoidCallback onDone;
  const ConfettiBurst({super.key, required this.onDone});

  static void show(BuildContext context) {
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) return;
    final OverlayState? overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => ConfettiBurst(onDone: () => entry.remove()),
    );
    overlay.insert(entry);
  }

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _Piece {
  final double angle, speed, spin, size;
  final Color color;
  final bool round;
  const _Piece(
      this.angle, this.speed, this.spin, this.size, this.color, this.round);
}

class _ConfettiBurstState extends State<ConfettiBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final List<_Piece> _pieces;

  static const List<Color> _colors = [
    Color(0xFF6C63FF),
    Color(0xFF16C79A),
    Color(0xFFFFB84C),
    Color(0xFFFF7892),
    Color(0xFF53B9F5),
  ];

  @override
  void initState() {
    super.initState();
    final math.Random r = math.Random();
    _pieces = List.generate(70, (i) {
      return _Piece(
        -math.pi / 2 + (r.nextDouble() - 0.5) * math.pi * 1.1,
        0.55 + r.nextDouble() * 0.75,
        (r.nextDouble() - 0.5) * 12,
        6 + r.nextDouble() * 7,
        _colors[r.nextInt(_colors.length)],
        r.nextBool(),
      );
    });
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..forward().whenComplete(widget.onDone);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) => CustomPaint(
          size: Size.infinite,
          painter: _ConfettiPainter(_pieces, _c.value),
        ),
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final List<_Piece> pieces;
  final double t;
  _ConfettiPainter(this.pieces, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final Offset origin = Offset(size.width / 2, size.height * 0.62);
    final double reach = size.height * 0.75;
    for (final _Piece p in pieces) {
      final double e = Curves.easeOutCubic.transform(t);
      final double x =
          origin.dx + math.cos(p.angle) * p.speed * reach * e * 0.7;
      final double y = origin.dy +
          math.sin(p.angle) * p.speed * reach * e +
          t * t * size.height * 0.55; // gravity
      final double fade = t < 0.7 ? 1.0 : (1.0 - (t - 0.7) / 0.3);
      final Paint paint = Paint()
        ..color = p.color.withValues(alpha: fade.clamp(0.0, 1.0));
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.spin * t * 3);
      if (p.round) {
        canvas.drawCircle(Offset.zero, p.size / 2, paint);
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset.zero, width: p.size, height: p.size * 0.55),
            const Radius.circular(2),
          ),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}
