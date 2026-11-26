import 'package:flutter/material.dart' hide Text;
import 'package:haneen_kids_vod/core/regional/dialect_text.dart';
import 'package:haneen_kids_vod/haneen_kids_exports.dart';

class ChildProfileSummaryBadge extends StatelessWidget {
  final ChildProfile child;
  const ChildProfileSummaryBadge({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Text(
      '⏱️ ${child.usedMinutesToday}/${child.limitShown} د • ⭐ ${child.starsEarned}',
      style: const TextStyle(
        fontSize: 11,
        color: Color(0xFFF59E0B),
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
