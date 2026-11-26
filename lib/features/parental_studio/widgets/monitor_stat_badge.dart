import 'dart:math';
import 'package:flutter/material.dart' hide Text;
import 'package:haneen_kids_vod/core/regional/dialect_text.dart';

class ParentalMonitorSummaryTile extends StatelessWidget {
  final String title;
  final String value;
  const ParentalMonitorSummaryTile({
    super.key,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(title, style: const TextStyle(fontSize: 11, color: Colors.white60)),
      ],
    );
  }
}
