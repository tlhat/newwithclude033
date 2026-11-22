import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:haneen_kids_vod/haneen_kids_exports.dart';

/// Kid-friendly, oversized (`>= 56x56 dp`), high-contrast Back Button widget
/// designed for toddlers (ages 2–6) and parents across all screens.
class KidFriendlyBigBackButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  final bool compact;
  final Color backgroundColor;
  final Color borderColor;
  final Color iconAndTextColor;
  final bool showLabel;

  const KidFriendlyBigBackButton({
    super.key,
    this.onPressed,
    String? label,
    String? labelAr,
    this.compact = false,
    this.backgroundColor = const Color(0xFF1E293B),
    Color? accentColor,
    this.iconAndTextColor = Colors.white,
    this.showLabel = true,
  })  : label = labelAr ?? label ?? 'رجوع',
        borderColor = accentColor ?? const Color(0xFFF59E0B);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            HapticFeedback.lightImpact();
            if (onPressed != null) {
              onPressed!();
            } else {
              Navigator.of(context).maybePop();
            }
          },
          child: Container(
            constraints: BoxConstraints(
              minWidth: compact ? 52 : 56,
              minHeight: compact ? 48 : 56,
            ),
            padding: EdgeInsets.symmetric(
              horizontal: showLabel ? (compact ? 12 : 16) : 14,
              vertical: compact ? 8 : 10,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  backgroundColor,
                  const Color(0xFF0F172A),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: borderColor,
                width: 2.4,
              ),
              boxShadow: [
                BoxShadow(
                  color: borderColor.withOpacity(0.28),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: compact ? 30 : 34,
                  height: compact ? 30 : 34,
                  decoration: BoxDecoration(
                    color: borderColor.withOpacity(0.22),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_back_rounded,
                    size: compact ? 20 : 24,
                    color: borderColor,
                  ),
                ),
                if (showLabel) ...[
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: compact ? 13.5 : 15,
                      fontWeight: FontWeight.w800,
                      color: iconAndTextColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Smooth, non-intrusive 7-Day Free Trial status banner that displays remaining trial days
/// without interrupting the child's learning or viewing experience.
class SmoothFreeTrialStatusBanner extends StatelessWidget {
  final ParentAccount account;
  final VoidCallback? onUpgradeTap;

  const SmoothFreeTrialStatusBanner({
    super.key,
    required this.account,
    this.onUpgradeTap,
  });

  @override
  Widget build(BuildContext context) {
    // App is 100% Free forever: never display any trial countdown or paywall banner.
    return const SizedBox.shrink();

    final Duration rem = account.remainingSubscriptionDuration;
    final int remainingDays = (rem.inHours / 24).ceil().clamp(1, 7);
    final int remainingHours = rem.inHours;
    final double progress = (rem.inHours / (7 * 24)).clamp(0.05, 1.0);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF0F766E).withOpacity(0.88),
            const Color(0xFF1E1B4B).withOpacity(0.90),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF14B8A6).withOpacity(0.65),
          width: 1.1,
        ),
      ),
      child: Row(
        children: [
          const Text('🎁', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  remainingDays > 1
                      ? 'التجربة المجانية الشاملة (٧ أيام): متبقي $remainingDays أيام مجانية'
                      : 'التجربة المجانية الشاملة: متبقي $remainingHours ساعة مجانية',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 3),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 4,
                    backgroundColor: Colors.white12,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFFFDE68A),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (onUpgradeTap != null) ...[
            const SizedBox(width: 8),
            InkWell(
              onTap: onUpgradeTap,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withOpacity(0.22),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: const Color(0xFFF59E0B).withOpacity(0.6)),
                ),
                child: const Text(
                  'الباقات ✨',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFDE68A),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Modern 3D App Icon Preview Widget (`const`-constructible) for Android & iOS Squircle preview.
class HaneenAppIconPreviewWidget extends StatelessWidget {
  final double size;

  const HaneenAppIconPreviewWidget({
    super.key,
    this.size = 84,
  });

  @override
  Widget build(BuildContext context) {
    final double borderRadius = size * 0.24;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1E1B4B),
            Color(0xFF0F766E),
            Color(0xFF14B8A6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: const Color(0xFFF59E0B),
          width: size >= 70 ? 2.5 : 1.6,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x5514B8A6),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: size * 0.08,
            right: size * 0.10,
            child: Text(
              '🌙✨',
              style: TextStyle(fontSize: size * 0.18),
            ),
          ),
          Positioned(
            bottom: size * 0.08,
            left: size * 0.10,
            child: Text(
              'أ•1',
              style: TextStyle(
                fontSize: size * 0.15,
                fontWeight: FontWeight.w900,
                color: const Color(0xFFFDE68A),
              ),
            ),
          ),
          Text(
            '👧🎧',
            style: TextStyle(fontSize: size * 0.42),
          ),
        ],
      ),
    );
  }
}
