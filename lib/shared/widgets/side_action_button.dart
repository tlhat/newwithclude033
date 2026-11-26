import 'package:flutter/material.dart' hide Text;
import 'package:haneen_kids_vod/core/regional/dialect_text.dart';

class SharedActionPillButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const SharedActionPillButton({
    super.key,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(onPressed: onTap, child: Text(label));
  }
}
