/// 3-tier progressive hint ladder (Khan Academy style).
/// Tier 1: gentle directional nudge (no strategy, no answer).
/// Tier 2: strategy suggestion (how to think, still no answer).
/// Tier 3: worked example of a SIMILAR problem — never the original answer.
/// The answer itself is only available via the separate, opt-in answer-reveal
/// action (`lesson.allowsAnswerReveal`, default false).
enum HintLadderTier {
  none,
  gentleDirection,
  strategy,
  workedExample,
}

class HintLadderTierInfo {
  final HintLadderTier tier;
  final int level; // 1..3
  const HintLadderTierInfo(this.tier, this.level);
}

const HintLadderTierInfo kHintLadderT1 =
    HintLadderTierInfo(HintLadderTier.gentleDirection, 1);
const HintLadderTierInfo kHintLadderT2 =
    HintLadderTierInfo(HintLadderTier.strategy, 2);
const HintLadderTierInfo kHintLadderT3 =
    HintLadderTierInfo(HintLadderTier.workedExample, 3);

/// Tier 3 content: a curriculum-appropriate worked example built from the
/// lesson's own data — never the original answer.
class WorkedExampleContent {
  /// Word/phrase used in the worked example. Non-empty only when
  /// [isCurriculumExample] is true.
  final String exampleWord;
  final String exampleEmoji;
  /// False when no safe similar example could be derived from lesson data;
  /// callers should then show a generic strategy-based worked example.
  final bool isCurriculumExample;
  const WorkedExampleContent({
    required this.exampleWord,
    required this.exampleEmoji,
    required this.isCurriculumExample,
  });
}

/// Pure hint-ladder logic, independent of any UI state.
class HintLadderEngine {
  /// Next tier from the current level; returns null at the top (tier 3).
  static HintLadderTierInfo? nextTier(int currentLevel) {
    switch (currentLevel) {
      case 0:
        return kHintLadderT1;
      case 1:
        return kHintLadderT2;
      case 2:
        return kHintLadderT3;
      default:
        return null;
    }
  }

  /// Whether the original answer may be revealed for this lesson: only when
  /// the lesson explicitly opts in (`allowsAnswerReveal`, default false).
  static bool canRevealAnswer({required bool lessonAllowsAnswerReveal}) =>
      lessonAllowsAnswerReveal;

  /// Builds a Tier 3 worked example from the lesson's own curriculum data.
  ///
  /// Safety rules:
  /// - Never uses the correct option or any quiz/remediation option as the
  ///   example (that would reveal the original answer or its distractors).
  /// - Prefers a visual card whose label is NOT one of the quiz options and
  ///   does not contain the correct option text.
  /// - Trims and rejects empty/blank strings.
  /// - When no safe candidate exists, returns a fallback so the caller shows
  ///   a generic strategy-based example instead of inventing content.
  ///
  /// All inputs are plain strings, keeping this pure and easily testable.
  static WorkedExampleContent buildSafeWorkedExample({
    required List<String> forbiddenAnswers,
    List<String> candidateWords = const <String>[],
    List<String> candidateEmojis = const <String>[],
  }) {
    // Normalize the forbidden set once.
    final Set<String> forbidden = forbiddenAnswers
        .map(_normalize)
        .where((s) => s.isNotEmpty)
        .toSet();

    // Walk candidate words in curriculum order; pick the first one that is
    // non-empty and does not reveal the original answer.
    for (int i = 0; i < candidateWords.length; i++) {
      final String word = _normalize(candidateWords[i]);
      if (word.isEmpty) continue;
      if (_revealsAnswer(word, forbidden)) continue;
      final String emoji =
          (i < candidateEmojis.length ? candidateEmojis[i] : '').trim();
      return WorkedExampleContent(
        exampleWord: word,
        exampleEmoji: emoji,
        isCurriculumExample: true,
      );
    }
    // Safe fallback: generic strategy-based worked example.
    return const WorkedExampleContent(
      exampleWord: '',
      exampleEmoji: '',
      isCurriculumExample: false,
    );
  }

  static String _normalize(String s) => s.trim();

  /// True when [candidate] matches a forbidden answer, either exactly or as
  /// a substring (an option like "🐱 cat" must not be "solved" as the
  /// example, nor must an example whose label contains the option).
  static bool _revealsAnswer(String candidate, Set<String> forbidden) {
    for (final String f in forbidden) {
      if (candidate == f || candidate.contains(f) || f.contains(candidate)) {
        return true;
      }
    }
    return false;
  }
}

/// Stateful per-lesson-quiz-session hint state used by the Academy screen.
/// Tracks `hintLevelUsed` and `answerRevealed` independently; these are
/// consumed by `LessonAttemptLedgerEngine.buildRecord` when recording the
/// attempt outcome.
class HintLadderSessionState {
  final String lessonId;
  final bool allowsAnswerReveal;
  int hintLevelUsed = 0;
  bool answerRevealed = false;
  final List<HintLadderTierInfo> shownTiers = [];

  HintLadderSessionState({
    required this.lessonId,
    this.allowsAnswerReveal = false,
  });

  HintLadderTierInfo? advanceHint() {
    final next = HintLadderEngine.nextTier(hintLevelUsed);
    if (next == null) return null;
    hintLevelUsed = next.level;
    shownTiers.add(next);
    return next;
  }

  /// Separate answer-reveal action. Only allowed when the lesson opted in;
  /// independent of hint level.
  bool revealAnswer() {
    if (!HintLadderEngine.canRevealAnswer(
        lessonAllowsAnswerReveal: allowsAnswerReveal)) {
      return false;
    }
    answerRevealed = true;
    return true;
  }

  void reset() {
    hintLevelUsed = 0;
    answerRevealed = false;
    shownTiers.clear();
  }
}
