import 'package:flutter/material.dart';
import 'package:haneen_kids_vod/core/localization/tr.dart';
import 'package:haneen_kids_vod/haneen_kids_exports.dart';

class ChildProfileSummaryBadge extends StatelessWidget {
  final ChildProfile child;
  const ChildProfileSummaryBadge({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Text(
      tr('⏱️ {0}/{1} د • ⭐ {2}', [child.usedMinutesToday, child.dailyTimeLimit, child.starsEarned]),
      style: const TextStyle(
        fontSize: 11,
        color: Color(0xFFF59E0B),
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
