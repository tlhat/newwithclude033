import 'dart:math';
import 'package:flutter/material.dart';

class EtiquetteStrokePath {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;

  const EtiquetteStrokePath({
    required this.points,
    required this.color,
    required this.strokeWidth,
  });
}

class EtiquetteDrawingCanvasPainter extends CustomPainter {
  final List<EtiquetteStrokePath> strokes;
  final int templateIndex;

  const EtiquetteDrawingCanvasPainter({
    required this.strokes,
    required this.templateIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint guidePaint = Paint()
      ..color = Colors.white.withOpacity(0.38)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = min(size.width, size.height) * 0.34;

    switch (templateIndex % 8) {
      case 0:
        final Path heartPath = Path();
        heartPath.moveTo(center.dx, center.dy + radius * 0.75);
        heartPath.cubicTo(
          center.dx - radius * 1.3,
          center.dy + radius * 0.1,
          center.dx - radius * 0.8,
          center.dy - radius * 0.95,
          center.dx,
          center.dy - radius * 0.3,
        );
        heartPath.cubicTo(
          center.dx + radius * 0.8,
          center.dy - radius * 0.95,
          center.dx + radius * 1.3,
          center.dy + radius * 0.1,
          center.dx,
          center.dy + radius * 0.75,
        );
        canvas.drawPath(heartPath, guidePaint);
        break;
      case 1:
        canvas.drawCircle(center, radius, guidePaint);
        canvas.drawCircle(
            Offset(center.dx - radius * 0.35, center.dy - radius * 0.25),
            radius * 0.12,
            guidePaint);
        canvas.drawCircle(
            Offset(center.dx + radius * 0.35, center.dy - radius * 0.25),
            radius * 0.12,
            guidePaint);
        final Rect smileRect = Rect.fromCircle(
            center: Offset(center.dx, center.dy + radius * 0.05),
            radius: radius * 0.55);
        canvas.drawArc(smileRect, 0.2, pi - 0.4, false, guidePaint);
        break;
      case 2:
        final Path starPath = Path();
        const int pointsCount = 5;
        for (int i = 0; i < pointsCount * 2; i++) {
          final double r = (i.isEven) ? radius : radius * 0.45;
          final double angle = (i * pi / pointsCount) - (pi / 2);
          final Offset pt = Offset(
            center.dx + r * cos(angle),
            center.dy + r * sin(angle),
          );
          if (i == 0) {
            starPath.moveTo(pt.dx, pt.dy);
          } else {
            starPath.lineTo(pt.dx, pt.dy);
          }
        }
        starPath.close();
        canvas.drawPath(starPath, guidePaint);
        break;
      case 3:
        for (int i = 0; i < 6; i++) {
          final double angle = i * pi / 3;
          canvas.drawCircle(
            Offset(center.dx + radius * 0.55 * cos(angle),
                center.dy + radius * 0.55 * sin(angle)),
            radius * 0.38,
            guidePaint,
          );
        }
        canvas.drawCircle(center, radius * 0.3, guidePaint);
        canvas.drawLine(
          Offset(center.dx, center.dy + radius * 0.6),
          Offset(center.dx, size.height - 20),
          guidePaint,
        );
        break;
      case 4:
        final Rect houseBody = Rect.fromCenter(
          center: Offset(center.dx, center.dy + radius * 0.25),
          width: radius * 1.4,
          height: radius * 1.1,
        );
        canvas.drawRect(houseBody, guidePaint);
        final Path roof = Path()
          ..moveTo(houseBody.left - 15, houseBody.top)
          ..lineTo(center.dx, center.dy - radius * 0.85)
          ..lineTo(houseBody.right + 15, houseBody.top)
          ..close();
        canvas.drawPath(roof, guidePaint);
        break;
      case 5:
        canvas.drawCircle(center, radius, guidePaint);
        for (int i = 0; i < 8; i++) {
          final double angle = i * pi / 4;
          canvas.drawLine(
            Offset(center.dx + radius * 1.1 * cos(angle),
                center.dy + radius * 1.1 * sin(angle)),
            Offset(center.dx + radius * 1.45 * cos(angle),
                center.dy + radius * 1.45 * sin(angle)),
            guidePaint,
          );
        }
        break;
      case 6:
        final Path crown = Path()
          ..moveTo(center.dx - radius, center.dy + radius * 0.5)
          ..lineTo(center.dx - radius * 0.8, center.dy - radius * 0.5)
          ..lineTo(center.dx - radius * 0.3, center.dy)
          ..lineTo(center.dx, center.dy - radius * 0.7)
          ..lineTo(center.dx + radius * 0.3, center.dy)
          ..lineTo(center.dx + radius * 0.8, center.dy - radius * 0.5)
          ..lineTo(center.dx + radius, center.dy + radius * 0.5)
          ..close();
        canvas.drawPath(crown, guidePaint);
        break;
      default:
        final Rect bookRect = Rect.fromCenter(
          center: center,
          width: radius * 1.7,
          height: radius * 1.2,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(bookRect, const Radius.circular(12)),
          guidePaint,
        );
        canvas.drawLine(
          Offset(center.dx, bookRect.top),
          Offset(center.dx, bookRect.bottom),
          guidePaint,
        );
        break;
    }

    for (final stroke in strokes) {
      if (stroke.points.isEmpty) continue;
      final Paint p = Paint()
        ..color = stroke.color
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..isAntiAlias = true
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke.strokeWidth;

      if (stroke.points.length < 3) {
        // A tap or a very short touch: draw a round dot.
        canvas.drawCircle(
            stroke.points.first,
            stroke.strokeWidth / 2,
            Paint()
              ..color = stroke.color
              ..isAntiAlias = true);
        if (stroke.points.length == 2) {
          canvas.drawLine(stroke.points[0], stroke.points[1], p);
        }
        continue;
      }
      // Smooth curve: quadratic curves through the midpoints of the points.
      final List<Offset> pts = stroke.points;
      final Path path = Path()..moveTo(pts.first.dx, pts.first.dy);
      for (int i = 1; i < pts.length - 1; i++) {
        final Offset mid = Offset(
            (pts[i].dx + pts[i + 1].dx) / 2, (pts[i].dy + pts[i + 1].dy) / 2);
        path.quadraticBezierTo(pts[i].dx, pts[i].dy, mid.dx, mid.dy);
      }
      path.lineTo(pts.last.dx, pts.last.dy);
      canvas.drawPath(path, p);
    }
  }

  @override
  bool shouldRepaint(covariant EtiquetteDrawingCanvasPainter oldDelegate) =>
      true;
}
