import 'package:flutter/material.dart' hide Text;
import 'package:haneen_kids_vod/core/regional/dialect_text.dart';

class ParentalPinLockoutBanner extends StatelessWidget {
  final int remainingSeconds;
  const ParentalPinLockoutBanner({super.key, required this.remainingSeconds});

  @override
  Widget build(BuildContext context) {
    return Text(
      '⏳ البوابة مقفلة مؤقتاً لحماية الطفل. انتظر $remainingSeconds ثانية.',
      style: const TextStyle(color: Colors.redAccent, fontSize: 12),
    );
  }
}
