import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:haneen_kids_vod/haneen_kids_exports.dart';

/// One reward moment: how many stars the child just earned and for what.
class StarRewardEvent {
  final int stars;
  final String title;
  final int id;
  StarRewardEvent(this.stars, this.title, this.id);
}

/// Wraps the whole app. Whenever [AppStateManager.starRewards] changes it plays
/// a short celebration on top of any screen: a pop-up card, bursting stars and
/// a gentle haptic tick. It never blocks touches.
class StarRewardHost extends StatefulWidget {
  final AppStateManager appState;
  final Widget child;
  const StarRewardHost({super.key, required this.appState, required this.child});

  @override
  State<StarRewardHost> createState() => _StarRewardHostState();
}

class _StarRewardHostState extends State<StarRewardHost>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );
  StarRewardEvent? _event;

  @override
  void initState() {
    super.initState();
    widget.appState.starRewards.addListener(_onReward);
    _c.addStatusListener((s) {
      if (s == AnimationStatus.completed && mounted) {
        setState(() => _event = null);
      }
    });
  }

  @override
  void dispose() {
    widget.appState.starRewards.removeListener(_onReward);
    _c.dispose();
    super.dispose();
  }

  void _onReward() {
    final e = widget.appState.starRewards.value;
    if (e == null || !mounted) return;
    HapticFeedback.lightImpact();
    setState(() => _event = e);
    _c.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      textDirection: TextDirection.rtl,
      children: [
        widget.child,
        if (_event != null)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _c,
                builder: (context, _) =>
                    _RewardLayer(event: _event!, t: _c.value),
              ),
            ),
          ),
      ],
    );
  }
}

class _RewardLayer extends StatelessWidget {
  final StarRewardEvent event;
  final double t;
  const _RewardLayer({required this.event, required this.t});

  @override
  Widget build(BuildContext context) {
    // Card: pops in (0..0.2), stays, fades out (0.85..1).
    final double pop = Curves.elasticOut.transform((t / 0.3).clamp(0.0, 1.0));
    final double fade = t > 0.85 ? (1 - (t - 0.85) / 0.15) : 1.0;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _BurstPainter(event.id, event.stars, t)),
          ),
          Align(
            alignment: const Alignment(0, -0.25),
            child: Opacity(
              opacity: fade.clamp(0.0, 1.0),
              child: Transform.scale(
                scale: 0.4 + 0.6 * pop,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 26, vertical: 16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFD54F), Color(0xFFFFA726)],
                      ),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x55000000),
                          blurRadius: 18,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '⭐ +${event.stars}',
                          style: const TextStyle(
                            fontSize: 38,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          event.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BurstPainter extends CustomPainter {
  final int seed;
  final int stars;
  final double t;
  _BurstPainter(this.seed, this.stars, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final math.Random r = math.Random(seed);
    final int count = 14 + stars.clamp(1, 5) * 4;
    final Offset origin = Offset(size.width / 2, size.height * 0.37);
    final double p = Curves.easeOutCubic.transform((t / 0.8).clamp(0.0, 1.0));
    final double alpha = t > 0.7 ? (1 - (t - 0.7) / 0.3).clamp(0.0, 1.0) : 1.0;
    for (int i = 0; i < count; i++) {
      final double ang = r.nextDouble() * math.pi * 2;
      final double dist = (80 + r.nextDouble() * 170) * p;
      final double fall = 40 * t * t * (0.5 + r.nextDouble());
      final Offset pos =
          origin + Offset(math.cos(ang) * dist, math.sin(ang) * dist + fall);
      final double sz = 14 + r.nextDouble() * 14;
      final tp = TextPainter(
        text: TextSpan(
          text: r.nextBool() ? '⭐' : '✨',
          style: TextStyle(
              fontSize: sz, color: Colors.white.withValues(alpha: alpha)),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate((r.nextDouble() - 0.5) * 2 * t);
      canvas.translate(-tp.width / 2, -tp.height / 2);
      if (alpha < 1) {
        canvas.saveLayer(
            Offset.zero & Size(tp.width, tp.height),
            Paint()..color = Colors.white.withValues(alpha: alpha));
        tp.paint(canvas, Offset.zero);
        canvas.restore();
      } else {
        tp.paint(canvas, Offset.zero);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _BurstPainter old) => old.t != t;
}
