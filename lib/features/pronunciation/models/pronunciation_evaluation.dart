class PronunciationEvaluation {
  final int stars;
  final String feedbackMessage;
  final double matchRatio;
  final String supportiveTier; // 'excellent' | 'good_effort' | 'gentle_retry'
  final String syllableBreakdown;
  final bool ageToleranceApplied;

  // Legacy & Video Player compatibility fields
  final double accuracyScore;
  final bool isCorrect;
  final List<String> matchedWords;
  final List<String> missingOrWrongWords;
  final String correctionAdvice;

  const PronunciationEvaluation({
    int? stars,
    String? feedbackMessage,
    double? matchRatio,
    this.supportiveTier = 'excellent',
    this.syllableBreakdown = '',
    this.ageToleranceApplied = false,
    double? accuracyScore,
    bool? isCorrect,
    this.matchedWords = const [],
    this.missingOrWrongWords = const [],
    String? correctionAdvice,
  })  : matchRatio = matchRatio ?? accuracyScore ?? 1.0,
        accuracyScore = accuracyScore ?? matchRatio ?? 1.0,
        stars = stars ??
            ((accuracyScore ?? matchRatio ?? 1.0) >= 0.72
                ? 3
                : ((accuracyScore ?? matchRatio ?? 1.0) >= 0.35 ? 2 : 1)),
        isCorrect = isCorrect ?? ((matchRatio ?? accuracyScore ?? 1.0) >= 0.60),
        feedbackMessage =
            feedbackMessage ?? correctionAdvice ?? 'أحسنت النطق يا بطل!',
        correctionAdvice =
            correctionAdvice ?? feedbackMessage ?? 'أحسنت النطق يا بطل!';
}
