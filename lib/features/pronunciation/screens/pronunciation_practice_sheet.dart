import 'package:flutter/material.dart';

class PronunciationPracticeHintCard extends StatelessWidget {
  final String repeatPhrase;
  const PronunciationPracticeHintCard({super.key, required this.repeatPhrase});

  @override
  Widget build(BuildContext context) {
    return Text(
      repeatPhrase,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFFFDE68A),
      ),
    );
  }
}
