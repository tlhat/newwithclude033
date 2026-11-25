import 'package:flutter/material.dart';
import 'package:haneen_kids_vod/app/app_theme.dart';

/// One place for colors, spacing, font sizes and radius used by new screens.
class KidTheme {
  KidTheme._();
  // colors
  static const Color bg = AppDesignTokens.darkBackground;
  static const Color surface = AppDesignTokens.darkSurface;
  static const Color surfaceHigh = Color(0xFF334155);
  static const Color primary = Color(0xFF10B981);
  static const Color accent = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);
  static const Color danger = Color(0xFFEF4444);
  static const Color text = Colors.white;
  static const Color textDim = Colors.white70;
  // spacing
  static const double s1 = 4, s2 = 8, s3 = 12, s4 = 16, s5 = 24, s6 = 32;
  // radius
  static const double rSmall = 12, rMedium = 18, rLarge = 24;
  // font sizes
  static const double fBody = 16, fTitle = 20, fBig = 28;
  // touch target: never smaller than this for children
  static const double minTouch = 56;

  static const TextStyle title = TextStyle(
      color: text, fontSize: fTitle, fontWeight: FontWeight.w800, height: 1.4);
  static const TextStyle body =
      TextStyle(color: text, fontSize: fBody, height: 1.5);
}

/// Big, rounded, easy-to-hit button.
class KidButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final IconData? icon;
  const KidButton(
      {super.key,
      required this.label,
      required this.onPressed,
      this.color = KidTheme.primary,
      this.icon});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
          minHeight: KidTheme.minTouch, minWidth: KidTheme.minTouch),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
              horizontal: KidTheme.s5, vertical: KidTheme.s3),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(KidTheme.rMedium)),
          textStyle: const TextStyle(
              fontSize: KidTheme.fTitle, fontWeight: FontWeight.w800),
        ),
        onPressed: onPressed,
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[Icon(icon), const SizedBox(width: KidTheme.s2)],
          Flexible(child: Text(label, textAlign: TextAlign.center)),
        ]),
      ),
    );
  }
}

class KidCard extends StatelessWidget {
  final Widget child;
  final Color? color;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  const KidCard(
      {super.key,
      required this.child,
      this.color,
      this.padding = const EdgeInsets.all(KidTheme.s4),
      this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color ?? KidTheme.surface,
      borderRadius: BorderRadius.circular(KidTheme.rLarge),
      child: InkWell(
        borderRadius: BorderRadius.circular(KidTheme.rLarge),
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

Future<void> showKidDialog(BuildContext context,
    {required String title, required String message, String button = 'تمام'}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        backgroundColor: KidTheme.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(KidTheme.rLarge)),
        title: Text(title, style: KidTheme.title),
        content: Text(message, style: KidTheme.body),
        actions: [
          KidButton(label: button, onPressed: () => Navigator.pop(ctx)),
        ],
      ),
    ),
  );
}
