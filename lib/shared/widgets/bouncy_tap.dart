import 'package:flutter/material.dart';

/// Gives any tappable child a soft "press and bounce back" feel.
///
/// It only listens to raw pointer events, so it never steals taps from the
/// child (InkWell, GestureDetector, buttons keep working as before).
class BouncyTap extends StatefulWidget {
  final Widget child;
  final double pressedScale;

  const BouncyTap({super.key, required this.child, this.pressedScale = 0.95});

  @override
  State<BouncyTap> createState() => _BouncyTapState();
}

class _BouncyTapState extends State<BouncyTap> {
  bool _down = false;

  void _set(bool v) {
    if (mounted && _down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final bool reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: (_down && !reduce) ? widget.pressedScale : 1.0,
        duration: Duration(milliseconds: _down ? 90 : 320),
        curve: _down ? Curves.easeOut : Curves.elasticOut,
        child: widget.child,
      ),
    );
  }
}
