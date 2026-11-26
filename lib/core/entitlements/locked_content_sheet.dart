import 'package:flutter/material.dart' hide Text;
import 'package:haneen_kids_vod/core/regional/dialect_text.dart';

/// Shown when a child taps paid content. Kid-safe: no prices, no buy button,
/// nothing is purchased here. The grown-up sees what to do next.
Future<void> showLockedContentSheet(BuildContext context, String what) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: const Color(0xFF1E1B4B),
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) => Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('🔒', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 8),
          Text(what,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('ده جزء من الاشتراك. اطلب من ماما أو بابا يفتحوه لك.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('تمام'),
          ),
        ]),
      ),
    ),
  );
}

/// Small lock badge for cards and chips.
class LockBadge extends StatelessWidget {
  const LockBadge({super.key});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(4),
        decoration: const BoxDecoration(
            color: Colors.black54, shape: BoxShape.circle),
        child: const Icon(Icons.lock_rounded, size: 16, color: Colors.amber),
      );
}
