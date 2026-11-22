import 'package:flutter/material.dart';

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
