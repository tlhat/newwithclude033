import 'package:flutter/material.dart';

class SecuritySettingsBadge extends StatelessWidget {
  final String label;
  const SecuritySettingsBadge({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Chip(label: Text(label, style: const TextStyle(fontSize: 11)));
  }
}
