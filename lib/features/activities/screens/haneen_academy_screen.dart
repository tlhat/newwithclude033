import 'package:haneen_kids_vod/features/home/path_progress.dart';
import 'package:haneen_kids_vod/features/home/path_target.dart';
import 'package:haneen_kids_vod/features/activities/services/academy_voice_texts.dart';
import 'package:flutter/material.dart' hide Text;
import 'package:haneen_kids_vod/core/entitlements/entitlements.dart';
import 'package:haneen_kids_vod/core/entitlements/locked_content_sheet.dart';
import 'package:haneen_kids_vod/core/regional/dialect_text.dart';
import 'package:haneen_kids_vod/l10n/app_localizations.dart';
import 'package:haneen_kids_vod/haneen_kids_exports.dart';
import 'package:haneen_kids_vod/features/companion/engine/companion_interaction_engine.dart';
import 'package:haneen_kids_vod/features/companion/engine/companion_interaction_state.dart';

class HaneenAcademyScreen extends StatefulWidget {
  final AppStateManager appState;
  final int initialTabIndex;
  HaneenAcademyScreen({
    super.key,
    required this.appState,
    this.initialTabIndex = 0,
  });

  @override
  State<HaneenAcademyScreen> createState() => _HaneenAcademyScreenState();
}

class _HaneenAcademyScreenState extends State<HaneenAcademyScreen> {
  String _selectedTrackFilter = 'smart_path';

  void _applyPathTarget() {
    final t = PathTarget.pending.value;
    if (t == null || t.tab != 1) return;
    PathTarget.pending.value = null;
    final id = t.trackId;
    if (id != null && mounted) setState(() => _selectedTrackFilter = id);
  }

  @override
  void initState() {
    super.initState();
    PathTarget.pending.addListener(_applyPathTarget);
    WidgetsBinding.instance.addPostFrameCallback((_) => _applyPathTarget());
  }

  @override
  void dispose() {
    PathTarget.pending.removeListener(_applyPathTarget);
    super.dispose();
  }

  static List<Map<String, String>> _trackFilters = [
    {'id': 'smart_path', 'title': '🎯 مساري الذكي', 'emoji': '🎯'},
    {'id': 'all', 'title': 'كل المسارات', 'emoji': '🎓'},
    {'id': 'arabic_letters', 'title': 'الحروف العربية', 'emoji': '🔤'},
    {'id': 'english_letters', 'title': 'الحروف الإنجليزية', 'emoji': '🅰️'},
    {'id': 'numbers_counting', 'title': 'الأرقام والحساب', 'emoji': '🔢'},
    {'id': 'colors_shapes', 'title': 'الألوان والأشكال', 'emoji': '🎨'},
    {'id': 'animals_nature', 'title': 'الحيوانات والطبيعة', 'emoji': '🐾'},
    {'id': 'vocabulary', 'title': 'الكلمات والمفردات', 'emoji': '🗣️'},
    {'id': 'communication', 'title': 'الاستماع والنطق', 'emoji': '🎙️'},
    {'id': 'simple_science', 'title': 'العلوم المبسطة', 'emoji': '🔬'},
    {'id': 'daily_habits', 'title': 'المهارات الحياتية', 'emoji': '🪥'},
    {'id': 'thinking_problem_solving', 'title': 'التفكير والتركيز', 'emoji': '🧩'},
  ];

  String _tier3HintText(AppLocalizations l10n, AcademyTrackLesson lesson) =>
      AcademyVoiceTexts.tier3(l10n, lesson);

  void _openLessonSheet(AcademyTrackLesson lesson, ChildProfile child) {
    if (Entitlements.academyLessonLocked(lesson.tierLevel)) {
      showLockedContentSheet(context, 'الدرس ده مقفول: ${lesson.title}');
      return;
    }
    widget.appState.setLastActiveAcademyLesson(lesson.id);
    int selectedCardIndex = 0;
    final Set<int> exploredCardIndices = {0};
    int? selectedOptionIndex;
    bool quizAnsweredCorrectly = false;
    // Phase-1 interaction engine drives the companion's visual reaction to
    // quiz answers (same expressions as before, deterministic selection).
    // quiz answers (same expressions as before, deterministic selection).
    final CompanionInteractionEngine companionEngine =
        CompanionInteractionEngine();
    bool companionCelebrating = false;
    CompanionFaceExpression? companionExpression;
    bool showAlternativeRemediation =
        child.needsRemediationLessonIds.contains(lesson.id);
    int? selectedRemediationOptionIdx;
    bool practicedVoiceInSession = false;
    // The sheet is closed once. A second pop (two taps, or auto-advance firing
    // twice) would pop the last route: black screen, then the app closes.
    bool lessonSheetClosing = false;
    void closeLessonSheet(BuildContext c) {
      if (lessonSheetClosing || !c.mounted) return;
      lessonSheetClosing = true;
      Navigator.pop(c);
    }
    String? feedbackBannerText;
    // Phase 2: 3-tier hint ladder + separate opt-in answer reveal.
    final HintLadderSessionState hintLadder = HintLadderSessionState(
      lessonId: lesson.id,
      allowsAnswerReveal: lesson.allowsAnswerReveal,
    );
    String? hintBannerText;
    CalmVoiceService.instance.speak(
      'أهلاً بك يا ${child.name} في درس ${lesson.title}. ${lesson.cards.isEmpty ? lesson.introductionText : lesson.cards.first.spokenNarration}',
    );

    showModalBottomSheet(
      context: context,
    useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1B4B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final l10n = AppLocalizations.of(ctx);
            final currentCard = lesson.cards[selectedCardIndex];
            final int currentMastery =
                AdaptiveLearningEngine.getLessonMasteryScore(child, lesson.id);

            return Padding(
              padding: EdgeInsets.only(
                right: 20,
                left: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: lesson.accentColor.withOpacity(0.22),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: lesson.accentColor),
                          ),
                          child: Text(
                            lesson.emoji,
                            style: const TextStyle(fontSize: 28),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                lesson.title,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                '${lesson.trackTitle} • المستوى ${lesson.recommendedLevel} (${lesson.ageRange}) • الإتقان: ${currentMastery}%',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            CalmVoiceService.instance.stop();
                            Navigator.pop(ctx);
                          },
                          icon: const Icon(Icons.close_rounded,
                              color: Colors.white70),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: currentMastery / 100.0,
                        minHeight: 8,
                        backgroundColor: Colors.white12,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          currentMastery >= lesson.requiredMasteryScore
                              ? const Color(0xFF10B981)
                              : const Color(0xFFF59E0B),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            lesson.accentColor.withOpacity(0.28),
                            const Color(0xFF0F172A),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: lesson.accentColor.withOpacity(0.6)),
                      ),
                      child: Column(
                        children: [
                          Text(
                            currentCard.emoji,
                            style: const TextStyle(fontSize: 54),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            currentCard.symbol,
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFDE68A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            currentCard.wordExample,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            currentCard.spokenNarration,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.white70,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.center,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () {
                                  CalmVoiceService.instance
                                      .speak(currentCard.spokenNarration);
                                },
                                icon: const Icon(Icons.volume_up_rounded,
                                    size: 18),
                                label: Text('استمع للنطق الواضح'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: lesson.accentColor,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(lesson.cards.length, (idx) {
                        final card = lesson.cards[idx];
                        final isSelected = selectedCardIndex == idx;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ChoiceChip(
                            label: Text('${card.emoji} ${card.symbol}'),
                            selected: isSelected,
                            selectedColor: lesson.accentColor,
                            backgroundColor: const Color(0xFF0F172A),
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : Colors.white70,
                              fontWeight: FontWeight.bold,
                            ),
                            onSelected: (_) {
                              setSheetState(() {
                                selectedCardIndex = idx;
                                exploredCardIndices.add(idx);
                              });
                              CalmVoiceService.instance
                                  .speak(card.spokenNarration);
                            },
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '🧩 سؤال التثبيت والإتقان: ${lesson.quizQuestion}',
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFA7F3D0),
                                  ),
                                ),
                              ),
                              IconButton(
                                tooltip: 'اسمع السؤال',
                                color: const Color(0xFF38BDF8),
                                onPressed: () =>
                                    CalmVoiceService.instance.speakCalmly(
                                  AcademyVoiceTexts.quiz(lesson),
                                  allowSpeechForRepeatGame: true,
                                  forceSpeakEvenIfAssistantMuted: true,
                                ),
                                icon: const Icon(Icons.volume_up_rounded),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              if (hintLadder.hintLevelUsed < 3) ...[
                                OutlinedButton.icon(
                                  onPressed: () {
                                    final tier = hintLadder.advanceHint();
                                    if (tier == null) return;
                                    setSheetState(() {
                                      hintBannerText = switch (tier.level) {
                                        1 =>
                                          '💡 ${l10n.companionHintTier1(lesson.targetWordOrPhrase)}',
                                        2 =>
                                          '🧭 ${l10n.companionHintTier2(lesson.targetWordOrPhrase)}',
                                        _ => '📖 ${_tier3HintText(l10n, lesson)}',
                                      };
                                    });
                                    // Spoken line has no emoji and matches the recorded clip.
                                    CalmVoiceService.instance.speakCalmly(
                                      AcademyVoiceTexts.hint(
                                          l10n, lesson, tier.level),
                                      allowSpeechForRepeatGame: true,
                                      forceSpeakEvenIfAssistantMuted: true,
                                    );
                                  },
                                  icon: const Icon(Icons.lightbulb_rounded,
                                      size: 18, color: Color(0xFFF59E0B)),
                                  label: Text(
                                    l10n.companionHintButton,
                                    style: const TextStyle(
                                        color: Color(0xFFF59E0B)),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                        color: Color(0xFFF59E0B)),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              if (hintLadder.allowsAnswerReveal &&
                                  !hintLadder.answerRevealed) ...[
                                OutlinedButton.icon(
                                  onPressed: () {
                                    final revealed =
                                        hintLadder.revealAnswer();
                                    if (!revealed) return;
                                    setSheetState(() {
                                      hintBannerText =
                                          '👁️ ${l10n.companionAnswerRevealed}';
                                    });
                                    CalmVoiceService.instance.speak(
                                        l10n.companionAnswerRevealed);
                                  },
                                  icon: const Icon(Icons.visibility_rounded,
                                      size: 18, color: Color(0xFFA7F3D0)),
                                  label: Text(
                                    l10n.companionRevealAnswerButton,
                                    style: const TextStyle(
                                        color: Color(0xFFA7F3D0)),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                        color: Color(0xFF14B8A6)),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (hintBannerText != null) ...[
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF59E0B)
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: const Color(0xFFF59E0B)
                                        .withValues(alpha: 0.5)),
                              ),
                              child: Text(
                                hintBannerText!,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: Color(0xFFFDE68A),
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children:
                                List.generate(lesson.quizOptions.length, (idx) {
                              final option = lesson.quizOptions[idx];
                              final isChosen = selectedOptionIndex == idx;
                              final isCorrect =
                                  idx == lesson.correctOptionIndex;
                              return ElevatedButton(
                                onPressed: () async {
                                  if (lessonSheetClosing ||
                                      quizAnsweredCorrectly) {
                                    return;
                                  }
                                  setSheetState(() {
                                    selectedOptionIndex = idx;
                                    quizAnsweredCorrectly = isCorrect;
                                    final CompanionVisualState next =
                                        companionEngine.dispatchAndRead(
                                      CompanionEvent(
                                        kind: isCorrect
                                            ? CompanionEventKind.answerCorrect
                                            : CompanionEventKind
                                                .answerIncorrect,
                                        surface: CompanionSurface.academy,
                                        activityId: lesson.id,
                                      ),
                                    );
                                    companionCelebrating = next.isCelebrating;
                                    companionExpression =
                                        next.isCelebrating
                                            ? CompanionFaceExpression.excited
                                            : (isCorrect
                                                ? CompanionFaceExpression.happy
                                                : CompanionFaceExpression
                                                    .thinking);
                                    if (!isCorrect) {
                                      showAlternativeRemediation = true;
                                    }
                                  });
                                  final res = await widget.appState
                                      .recordAcademyLessonAttempt(
                                    lessonId: lesson.id,
                                    lessonTitle: lesson.title,
                                    learnedWord: lesson.cards.first.wordExample,
                                    isCorrectAnswer: isCorrect,
                                    cardsExploredCount:
                                        exploredCardIndices.length,
                                    usedAlternativeRemediation: false,
                                    practicedPronunciation:
                                        practicedVoiceInSession,
                                    hintLevelUsed: hintLadder.hintLevelUsed,
                                    answerRevealed:
                                        hintLadder.answerRevealed,
                                  );
                                  if (!ctx.mounted || lessonSheetClosing) return;
                                  setSheetState(() {
                                    feedbackBannerText =
                                        res.childEncouragementMessage;
                                  });
                                  if (isCorrect) {
                                    await CalmVoiceService.instance
                                        .speakSuperheroEncouragementAndAutoAdvance(
                                      encouragementText:
                                          res.childEncouragementMessage,
                                      onAutoAdvance: () => closeLessonSheet(ctx),
                                    );
                                  } else {
                                    await CalmVoiceService.instance
                                        .speak(res.childEncouragementMessage);
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isChosen
                                      ? (isCorrect
                                          ? const Color(0xFF10B981)
                                          : const Color(0xFFF59E0B))
                                      : const Color(0xFF1E293B),
                                  foregroundColor: Colors.white,
                                ),
                                child: Text(option),
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                    if (showAlternativeRemediation &&
                        lesson.alternativeRemediationQuestion.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withOpacity(0.14),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: const Color(0xFFF59E0B).withOpacity(0.6)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.auto_awesome_rounded,
                                    color: Color(0xFFFDE68A), size: 18),
                                SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    '🎈 طريقة بديلة مبسطة باللعب والصور لتثبيت المهارة:',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFFDE68A),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (lesson
                                .alternativeRemediationActivity.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                lesson.alternativeRemediationActivity,
                                style: const TextStyle(
                                    fontSize: 11.5, color: Colors.white70),
                              ),
                            ],
                            const SizedBox(height: 6),
                            Text(
                              lesson.alternativeRemediationQuestion,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: List.generate(
                                  lesson.alternativeRemediationOptions.length,
                                  (rIdx) {
                                final rOpt =
                                    lesson.alternativeRemediationOptions[rIdx];
                                final isRChosen =
                                    selectedRemediationOptionIdx == rIdx;
                                final isRCorrect = rIdx ==
                                    lesson.alternativeRemediationCorrectIndex;
                                return ElevatedButton(
                                  onPressed: () async {
                                    setSheetState(() {
                                      selectedRemediationOptionIdx = rIdx;
                                      if (isRCorrect) {
                                        quizAnsweredCorrectly = true;
                                      }
                                    });
                                    final res = await widget.appState
                                        .recordAcademyLessonAttempt(
                                      lessonId: lesson.id,
                                      lessonTitle: lesson.title,
                                      learnedWord:
                                          lesson.cards.first.wordExample,
                                      isCorrectAnswer: isRCorrect,
                                      cardsExploredCount:
                                          exploredCardIndices.length,
                                      usedAlternativeRemediation: true,
                                      practicedPronunciation:
                                          practicedVoiceInSession,
                                      hintLevelUsed: hintLadder.hintLevelUsed,
                                      answerRevealed:
                                          hintLadder.answerRevealed,
                                    );
                                    setSheetState(() {
                                      feedbackBannerText =
                                          res.childEncouragementMessage;
                                    });
                                    CalmVoiceService.instance
                                        .speak(res.childEncouragementMessage);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isRChosen
                                        ? (isRCorrect
                                            ? const Color(0xFF10B981)
                                            : const Color(0xFFF59E0B))
                                        : const Color(0xFF0F172A),
                                    foregroundColor: Colors.white,
                                  ),
                                  child: Text(rOpt),
                                );
                              }),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (feedbackBannerText != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF14B8A6).withOpacity(0.16),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: const Color(0xFF14B8A6).withOpacity(0.5)),
                        ),
                        child: Row(
                          children: [
                            HaneenRiveAvatarWidget(
                              avatar: child.companionAvatar,
                              mode: CompanionDisplayMode.bust,
                              size: 40,
                              isCelebrating: quizAnsweredCorrectly &&
                                  companionCelebrating,
                              expressionOverride: companionExpression ??
                                  (quizAnsweredCorrectly
                                      ? CompanionFaceExpression.excited
                                      : (selectedOptionIndex != null
                                          ? CompanionFaceExpression.thinking
                                          : null)),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                feedbackBannerText!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFFA7F3D0),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final res = await widget.appState
                              .recordAcademyLessonAttempt(
                            lessonId: lesson.id,
                            lessonTitle: lesson.title,
                            learnedWord: lesson.cards.first.wordExample,
                            isCorrectAnswer: quizAnsweredCorrectly ||
                                currentMastery >= lesson.requiredMasteryScore,
                            cardsExploredCount: exploredCardIndices.length,
                            usedAlternativeRemediation:
                                showAlternativeRemediation,
                            practicedPronunciation: practicedVoiceInSession,
                            hintLevelUsed: hintLadder.hintLevelUsed,
                            answerRevealed: hintLadder.answerRevealed,
                          );
                          if (!ctx.mounted || lessonSheetClosing) return;
                          closeLessonSheet(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(res.childEncouragementMessage),
                              backgroundColor: res.isMastered
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFF59E0B),
                            ),
                          );
                        },
                        icon: const Icon(Icons.stars_rounded),
                        label: Text(
                          quizAnsweredCorrectly
                              ? 'إتمام وتثبيت المهارة (+٢ نجمة إتقان)'
                              : 'حفظ تقدم المحاولة ومتابعة التدريب لاحقاً',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: quizAnsweredCorrectly
                              ? const Color(0xFF10B981)
                              : const Color(0xFF6366F1),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _openInteractiveStoryCarouselSheet(
    InteractiveEducationalStoryModel story,
    ChildProfile child,
  ) {
    final PageController storyPageController = PageController();
    int activeCardIndex = 0;
    bool isAutoNarrating = true;
    String? quizFeedback;
    bool quizSolved = false;
    bool storySheetClosing = false;
    void closeStorySheet(BuildContext c) {
      if (storySheetClosing || !c.mounted) return;
      storySheetClosing = true;
      Navigator.pop(c);
    }

    showModalBottomSheet(
      context: context,
    useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1B4B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setStoryState) {
            Future<void> triggerDualVoiceAutoNarration() async {
              setStoryState(() {
                isAutoNarrating = true;
                activeCardIndex = 0;
              });
              if (storyPageController.hasClients) {
                storyPageController.jumpToPage(0);
              }
              await CalmVoiceService.instance.narrateStoryCardsWithDualVoices(
                story: story,
                onCardStarted: (idx, card, outcome) {
                  if (!ctx.mounted) return;
                  setStoryState(() {
                    activeCardIndex = idx;
                  });
                },
                onCardCompletedAndAutoSwipe: (nextIdx) async {
                  if (!ctx.mounted) return;
                  setStoryState(() {
                    activeCardIndex = nextIdx;
                  });
                  if (storyPageController.hasClients) {
                    await storyPageController.animateToPage(
                      nextIdx,
                      duration: const Duration(milliseconds: 360),
                      curve: Curves.easeInOutCubic,
                    );
                  }
                },
                onStoryFinished: () {
                  if (!ctx.mounted) return;
                  PathProgress.record(child.id, PathProgress.story);
                  setStoryState(() {
                    isAutoNarrating = false;
                  });
                },
              );
            }

            if (activeCardIndex == 0 &&
                isAutoNarrating &&
                CalmVoiceService.instance.lastSpokenHaneenMessage.isEmpty) {
              Future.microtask(triggerDualVoiceAutoNarration);
            }

            final List<StoryImageCardPage> cards = story.storyCards;
            final StoryImageCardPage currentCard =
                cards[activeCardIndex.clamp(0, cards.length - 1)];

            return Padding(
              padding: EdgeInsets.only(
                right: 20,
                left: 20,
                top: 18,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        KidFriendlyBigBackButton(
                          compact: true,
                          labelAr: 'إغلاق',
                          onPressed: () {
                            CalmVoiceService.instance.stopSpeaking();
                            Navigator.pop(ctx);
                          },
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                story.title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                '${story.categoryBadge} • سرد ثنائي تلقائي (المساعد الرئيسي + السوبر هيرو)',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFFA7F3D0),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 245,
                      child: PageView.builder(
                        controller: storyPageController,
                        itemCount: cards.length,
                        onPageChanged: (idx) {
                          setStoryState(() {
                            activeCardIndex = idx;
                          });
                        },
                        itemBuilder: (context, idx) {
                          final card = cards[idx];
                          final bool isHero = card.isSuperheroSpeaker;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 280),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: card.gradientColors,
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: isHero
                                    ? const Color(0xFFF59E0B)
                                    : const Color(0xFF14B8A6),
                                width: 2.2,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isHero
                                        ? const Color(0xFFF59E0B)
                                            .withOpacity(0.22)
                                        : const Color(0xFF14B8A6)
                                            .withOpacity(0.22),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Text(
                                    '${card.speakerAvatar} ${card.speakerNameAr}',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                      color: isHero
                                          ? const Color(0xFFFDE68A)
                                          : const Color(0xFFA7F3D0),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                AnimatedStoryScene(
                                  illustration: card.imageIllustration,
                                  emojiSize: 44,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  card.sceneTitle,
                                  style: const TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFFDE68A),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  card.narrationText,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.white,
                                    height: 1.45,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: List.generate(
                            cards.length,
                            (i) => Container(
                              margin: const EdgeInsets.only(left: 5),
                              width: activeCardIndex == i ? 22 : 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: activeCardIndex == i
                                    ? (currentCard.isSuperheroSpeaker
                                        ? const Color(0xFFF59E0B)
                                        : const Color(0xFF14B8A6))
                                    : Colors.white24,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF14B8A6),
                            foregroundColor: Colors.white,
                          ),
                          onPressed: triggerDualVoiceAutoNarration,
                          icon: const Icon(Icons.play_circle_fill_rounded,
                              size: 18),
                          label: Text(
                            'تشغيل السرد الثنائي التلقائي',
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '🧩 سؤال القصة: ${story.quizQuestion}',
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFA7F3D0),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: story.quizOptions.map((opt) {
                              final bool isHit = opt == story.correctQuizAnswer;
                              return ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      quizSolved && isHit
                                          ? const Color(0xFF10B981)
                                          : const Color(0xFF1E293B),
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () async {
                                  if (isHit) {
                                    setStoryState(() {
                                      quizSolved = true;
                                      quizFeedback =
                                          '🦸‍♂️ أحسنت! ${story.moralSummary}';
                                    });
                                    await CalmVoiceService.instance
                                        .reactToChildAnswerAsHaneen(
                                      isCorrect: true,
                                      childName: child.name,
                                      learnedConcept: story.title,
                                      onAutoAdvanceAfterAudio: () =>
                                          closeStorySheet(ctx),
                                    );
                                  } else {
                                    final hintMsg = await CalmVoiceService
                                        .instance
                                        .reactToChildAnswerAsHaneen(
                                      isCorrect: false,
                                      childName: child.name,
                                      gentleHint: story.moralSummary,
                                    );
                                    if (ctx.mounted) {
                                      setStoryState(() {
                                        quizFeedback = hintMsg;
                                      });
                                    }
                                  }
                                },
                                child: Text(opt),
                              );
                            }).toList(),
                          ),
                          if (quizFeedback != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              quizFeedback!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFFFDE68A),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.appState,
      builder: (context, _) {
        final account = widget.appState.currentAccount;
        if (account == null) return const SizedBox.shrink();
        final child = account.activeChild;
        final activeCurriculum = AdaptiveLearningEngine.getCurriculumForLanguage(
            widget.appState.localeController.learningLanguageCode);
        final report = AdaptiveLearningEngine.buildPedagogicalReport(
          child,
          curriculum: activeCurriculum,
        );

        final List<AcademyTrackLesson> filteredLessons;
        if (_selectedTrackFilter == 'smart_path') {
          filteredLessons = AdaptiveLearningEngine.getRecommendedLessonsForChild(
            child,
            curriculum: activeCurriculum,
          );
        } else if (_selectedTrackFilter == 'all') {
          filteredLessons = activeCurriculum;
        } else {
          filteredLessons = activeCurriculum
              .where((l) => l.trackId == _selectedTrackFilter)
              .toList();
        }

        // Phase 5: valid unfinished-session navigation — prefer the
        // companion-memory suggestion (still-valid unfinished session, else
        // Phase 4 next lesson); never auto-completes anything.
        final String? suggestedLessonId =
            widget.appState.suggestNextActivityForActiveChild();
        final AcademyTrackLesson resumeLesson =
            (suggestedLessonId != null && suggestedLessonId.isNotEmpty)
                ? activeCurriculum.firstWhere(
                    (l) => l.id == suggestedLessonId,
                    orElse: () => activeCurriculum.first,
                  )
                : activeCurriculum.firstWhere(
                    (l) => l.id == child.lastActiveAcademyLessonId,
                    orElse: () => activeCurriculum.first,
                  );

        return Scaffold(
          backgroundColor: const Color(0xFF0F172A),
          appBar: AppBar(
            backgroundColor: const Color(0xFF1E1B4B),
            automaticallyImplyLeading: false,
            toolbarHeight: 70,
            titleSpacing: 12,
            title: Row(
              children: [
                KidFriendlyBigBackButton(
                  label: 'رجوع',
                  accentColor: const Color(0xFFF59E0B),
                  onPressed: () {
                    CalmVoiceService.instance.stopSpeaking();
                    Navigator.maybePop(context);
                  },
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '🎓 أكاديمية حنين الذكية (٢–٦ سنوات)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              CompanionGuideOverlay(
                appState: widget.appState,
                compactMode: true,
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: SmoothFreeTrialStatusBanner(account: account),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF312E81), Color(0xFF1E1B4B)],
                  ),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                      color: const Color(0xFF14B8A6).withOpacity(0.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        HaneenCompanionAvatarWidget(
                          avatar: child.companionAvatar,
                          mode: CompanionDisplayMode.bust,
                          size: 50,
                          animateBreathing: true,
                          speechText: Localizations.localeOf(context).languageCode == 'ar'
                              ? 'أهلاً بك يا ${child.name} في الأكاديمية! هيا نتقدم في مسارك التعليمي الذكي.'
                              : 'Welcome to the Academy, ${child.name}! Let\'s keep learning together.',
                          speakOnTap: true,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'مسار البطل الذكي: ${child.name} (${child.age})',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'المستوى الحالي: ${report.currentTierLabelAr} • إتقان المستوى: ${report.currentTierMasteryPercentage}% • النجوم: ⭐ ${child.starsEarned}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFFA7F3D0),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: report.currentTierMasteryPercentage / 100.0,
                        minHeight: 9,
                        backgroundColor: Colors.white12,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF14B8A6)),
                      ),
                    ),
                    if (child.needsRemediationLessonIds.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        '🎈 توجد (${child.needsRemediationLessonIds.length}) مهارة مقترح تثبيتها باللعب التفاعلي المبسط قبل الانتقال للمستوى الأعلى.',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFFFDE68A),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _openLessonSheet(resumeLesson, child),
                        icon: const Icon(Icons.play_circle_fill_rounded),
                        label: Text(
                          'متابعة آخر درس نشط: ${resumeLesson.emoji} ${resumeLesson.title}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF14B8A6),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: const Color(0xFFF59E0B).withOpacity(0.55)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('📖🦸‍♂️', style: TextStyle(fontSize: 22)),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'كروت القصص المصورة التفاعلية (سرد ثنائي: المساعد الرئيسي + السوبر هيرو)',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFDE68A),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 112,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: kInteractiveOriginalStories.length,
                        itemBuilder: (ctx, sIdx) {
                          final story = kInteractiveOriginalStories[sIdx];
                          return GestureDetector(
                            onTap: () {
                              if (Entitlements.storyLocked(sIdx)) {
                                showLockedContentSheet(
                                    context, 'القصة دي مقفولة');
                                return;
                              }
                              _openInteractiveStoryCarouselSheet(story, child);
                            },
                            child: Container(
                              width: 235,
                              margin: const EdgeInsets.only(left: 10),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF312E81), Color(0xFF0F172A)],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                    color: const Color(0xFF14B8A6)
                                        .withOpacity(0.55)),
                              ),
                              child: Row(
                                children: [
                                  Text(Entitlements.storyLocked(sIdx) ? '🔒' : story.illustration,
                                      style: const TextStyle(fontSize: 32)),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          story.title,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${story.storyCards.length} كروت صور • تبديل تلقائي',
                                          style: const TextStyle(
                                            fontSize: 10.5,
                                            color: Color(0xFFA7F3D0),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _trackFilters.map((track) {
                    final isSelected = _selectedTrackFilter == track['id'];
                    return Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: ChoiceChip(
                        label: Text('${track['emoji']} ${track['title']}'),
                        selected: isSelected,
                        selectedColor: const Color(0xFF6366F1),
                        backgroundColor: const Color(0xFF1E293B),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.white70,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        onSelected: (_) => setState(
                            () => _selectedTrackFilter = track['id']!),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 14),
              if (filteredLessons.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Column(
                    children: [
                      const Text('🌈', style: TextStyle(fontSize: 44)),
                      const SizedBox(height: 8),
                      Text(
                        'لا توجد دروس في هذا المسار حالياً',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () =>
                            setState(() => _selectedTrackFilter = 'smart_path'),
                        icon: const Icon(Icons.refresh_rounded),
                        label: Text('العودة لمساري الذكي'),
                      ),
                    ],
                  ),
                ),
              ...filteredLessons.map((lesson) {
                final int masteryScore =
                    AdaptiveLearningEngine.getLessonMasteryScore(
                        child, lesson.id);
                final bool isMastered =
                    masteryScore >= lesson.requiredMasteryScore;
                final bool needsRemediation =
                    child.needsRemediationLessonIds.contains(lesson.id);

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: needsRemediation
                          ? const Color(0xFFF59E0B)
                          : (isMastered
                              ? const Color(0xFF10B981)
                              : lesson.accentColor.withOpacity(0.45)),
                      width: (isMastered || needsRemediation) ? 1.8 : 1.0,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    leading: Container(
                      width: 52,
                      height: 52,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: lesson.accentColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        lesson.emoji,
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            lesson.title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        if (isMastered)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '✅ متقن ${masteryScore}%',
                              style: const TextStyle(
                                fontSize: 10.5,
                                color: Color(0xFF6EE7B7),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        else if (needsRemediation)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '🎈 تدريب بديل (${masteryScore}%)',
                              style: const TextStyle(
                                fontSize: 10.5,
                                color: Color(0xFFFDE68A),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '${lesson.trackTitle} • المستوى ${lesson.recommendedLevel} (${lesson.ageRange})\n${lesson.pedagogicalGoal}',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Colors.white70,
                          height: 1.35,
                        ),
                      ),
                    ),
                    trailing: ElevatedButton(
                      onPressed: () => _openLessonSheet(lesson, child),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: lesson.accentColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(Entitlements.academyLessonLocked(lesson.tierLevel)
                          ? '🔒 مقفول'
                          : (isMastered ? 'مراجعة' : 'ابدأ')),
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
