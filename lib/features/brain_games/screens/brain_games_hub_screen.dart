import 'dart:math';
import 'package:haneen_kids_vod/core/localization/tr.dart';
import 'package:flutter/material.dart';
import 'package:haneen_kids_vod/haneen_kids_exports.dart';
import 'new_games.dart';
import 'package:haneen_kids_vod/features/exercises/exercise_screen.dart';
import 'package:haneen_kids_vod/l10n/app_localizations.dart';
import 'package:haneen_kids_vod/features/companion/engine/companion_interaction_engine.dart';
import 'package:haneen_kids_vod/features/companion/engine/companion_interaction_state.dart';

class BrainGamesHubScreen extends StatefulWidget {
  final AppStateManager appState;
  const BrainGamesHubScreen({super.key, required this.appState});

  @override
  State<BrainGamesHubScreen> createState() => _BrainGamesHubScreenState();
}

class _BrainGamesHubScreenState extends State<BrainGamesHubScreen> {
  int _selectedGameIndex = 0;
  String? _heroReactionMessage;
  int _companionReactionTick = 0;
  bool _companionReactionCorrect = true;

  /// Phase-1 companion interaction engine. Replaces the raw boolean/tick
  /// reaction logic with deterministic typed-state decisions while keeping
  /// the exact same visual output as before.
  late final CompanionInteractionEngine _companionEngine =
      CompanionInteractionEngine();

  void _companionReact(bool correct) {
    if (correct) CalmVoiceService.instance.resetWrongStreak();
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    final CompanionVisualState next = _companionEngine.dispatchAndRead(
      CompanionEvent(
        kind: correct
            ? CompanionEventKind.answerCorrect
            : CompanionEventKind.answerIncorrect,
        surface: CompanionSurface.brainGames,
        activityId: 'game_$_selectedGameIndex',
      ),
    );
    setState(() {
      _companionReactionCorrect = correct;
      _companionReactionTick = next.reactionTick;
      _heroReactionMessage =
          correct ? l10n.companionEncourageCorrect : l10n.companionEncourageHint;
    });
  }

  int _etiquetteBoardIndex = 0;
  final List<EtiquetteStrokePath> _drawingStrokes = [];
  Color _selectedBrushColor = const Color(0xFF14B8A6);
  double _selectedBrushSize = 8.0;
  int _drawnPointsCount = 0;

  int _oddQuestionIndex = 0;
  String? _oddFeedback;
  bool _oddCorrect = false;

  int _patternQuestionIndex = 0;
  String? _patternFeedback;
  bool _patternCorrect = false;

  int _memoryLevel = 1;
  int _memoryMoves = 0;
  int _memoryMatches = 0;
  List<String> _memoryBoard = [];
  List<bool> _memoryRevealed = [];
  List<bool> _memorySolved = [];
  int? _firstFlippedIndex;
  bool _memoryBusy = false;

  int _mathQuestionIndex = 0;
  String? _mathFeedback;
  bool _mathAnswered = false;

  int _wordQuestionIndex = 0;
  String? _wordFeedback;
  bool _wordCorrect = false;

  int _picMatchIndex = 0;
  String? _picMatchFeedback;

  int _classifyIndex = 0;
  String? _classifyFeedback;

  int _soundGameIndex = 0;
  String? _soundGameFeedback;

  int _seqGameIndex = 0;
  List<int> _userSequenceOrder = [];
  String? _seqGameFeedback;

  String? _loadedChildId;

  void _syncChildGameProgressLevels() {
    final child = widget.appState.currentAccount?.activeChild;
    if (child == null || _loadedChildId == child.id) return;
    _loadedChildId = child.id;
    _etiquetteBoardIndex =
        (child.gameProgressByGameId['etiquette_draw'] ?? 0) % 100;
    _oddQuestionIndex =
        (child.gameProgressByGameId['odd_one_out'] ?? 0) % 100;
    _patternQuestionIndex =
        (child.gameProgressByGameId['pattern_logic'] ?? 0) % 100;
    _memoryLevel =
        ((child.gameProgressByGameId['memory_match_lvl'] ?? 0) % 100) + 1;
    _mathQuestionIndex =
        (child.gameProgressByGameId['visual_math'] ?? 0) % 100;
    _wordQuestionIndex =
        (child.gameProgressByGameId['arabic_word'] ?? 0) % 100;
    _picMatchIndex = child.gameProgressByGameId['pic_match'] ?? 0;
    _classifyIndex = child.gameProgressByGameId['classify'] ?? 0;
    _soundGameIndex = child.gameProgressByGameId['sound_id'] ?? 0;
    _seqGameIndex = child.gameProgressByGameId['seq'] ?? 0;
  }

  @override
  void initState() {
    super.initState();
    _syncChildGameProgressLevels();
    _initMemoryGame();
    widget.appState.logChildRealtimeActivity(
      statusSummary: tr('🧠 يتفاعل داخل واحة الـ ١٠٠ مرحلة لألعاب الذكاء والآداب'),
      actionLogText: tr('دخل إلى واحة ألعاب الذكاء (١٠٠ مرحلة لكل لعبة)'),
      categoryBadge: tr('ألعاب الذكاء'),
    );
    final childName =
        widget.appState.currentAccount?.activeChild.name ?? tr('بطل حنين');
    CalmVoiceService.instance.speakCalmly(
      tr('أهلاً بك يا {0}! كل لعبة هنا تحتوي على مئة مرحلة مشوقة، وأصدقاؤك الأبطال الخارقون يشجعونك في كل خطوة!', [childName]),
    );
  }

  void _initMemoryGame() {
    final child = widget.appState.currentAccount?.activeChild;
    final int adaptiveTier = child == null
        ? 2
        : HundredLevelGamesGenerator.computeAdaptiveDifficultyTier(
            ageGroup: child.age,
            currentCurriculumTier: child.currentCurriculumTier,
            gamesCompletedCount: child.gamesCompletedCount,
          );
    final List<String> pairs =
        HundredLevelGamesGenerator.getMemoryBoardForLevel(
      _memoryLevel,
      difficultyTier: adaptiveTier,
    );
    setState(() {
      _memoryBoard = pairs;
      _memoryRevealed = List<bool>.filled(pairs.length, false);
      _memorySolved = List<bool>.filled(pairs.length, false);
      _firstFlippedIndex = null;
      _memoryMoves = 0;
      _memoryMatches = 0;
      _memoryBusy = false;
    });
  }

  Future<void> _onMemoryCardTap(int index) async {
    if (_memoryBusy || _memoryRevealed[index] || _memorySolved[index]) return;

    setState(() {
      _memoryRevealed[index] = true;
    });

    if (_firstFlippedIndex == null) {
      _firstFlippedIndex = index;
      return;
    }

    final int firstIdx = _firstFlippedIndex!;
    _firstFlippedIndex = null;
    _memoryMoves++;

    if (_memoryBoard[firstIdx] == _memoryBoard[index]) {
      setState(() {
        _memorySolved[firstIdx] = true;
        _memorySolved[index] = true;
        _memoryMatches++;
      });

      if (_memoryMatches == _memoryBoard.length ~/ 2) {
        _companionReact(true);
        await widget.appState.recordBrainGameWin(
          gameId: 'memory_match_lvl_$_memoryLevel',
          gameTitle: tr('الذاكرة البصرية (المرحلة {0} من ١٠٠)', [_memoryLevel]),
          earnedIqPoints: 20,
          earnedStars: 2,
        );
        setState(() {
          _heroReactionMessage =
              tr('🎉 الأبطال الخارقون يصفقون لك! أتممت المرحلة {0} من ١٠٠ في لعبة الذاكرة!', [_memoryLevel]);
        });
        await CalmVoiceService.instance.speakSuperheroEncouragementAndAutoAdvance(
          encouragementText:
              tr('ما شاء الله يا بطل الأبطال! أنهيت المرحلة {0} من مئة في لعبة الذاكرة البصرية بنجاح!', [_memoryLevel]),
          onAutoAdvance: () {
            if (!mounted) return;
            setState(() {
              _memoryLevel = (_memoryLevel % 100) + 1;
            });
            _initMemoryGame();
          },
        );
      } else {
        _companionReact(true);
        CalmVoiceService.instance.speakCalmly(tr('تطابق رائع!'));
      }
    } else {
      _companionReact(false);
      _memoryBusy = true;
      await Future.delayed(const Duration(milliseconds: 650));
      if (mounted) {
        setState(() {
          _memoryRevealed[firstIdx] = false;
          _memoryRevealed[index] = false;
          _memoryBusy = false;
        });
      }
    }
  }

  Widget _buildHundredLevelSelectorBar({
    required int currentLevelZeroBased,
    required Color accentColor,
    required void Function(int newZeroBasedIndex) onSelectLevel,
  }) {
    final int currentDisplay = (currentLevelZeroBased % 100) + 1;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              tr('🏆 المرحلة {0} من ١٠٠', [currentDisplay]),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: accentColor,
              ),
            ),
            Row(
              children: [
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    final int prev = (currentLevelZeroBased - 1 + 100) % 100;
                    onSelectLevel(prev);
                  },
                  icon: const Icon(Icons.arrow_back_ios_new, size: 15),
                ),
                Text(
                  '$currentDisplay / 100',
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    final int next = (currentLevelZeroBased + 1) % 100;
                    onSelectLevel(next);
                  },
                  icon: const Icon(Icons.arrow_forward_ios, size: 15),
                ),
              ],
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 5,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
          ),
          child: Slider(
            value: currentDisplay.toDouble(),
            min: 1,
            max: 100,
            divisions: 99,
            activeColor: accentColor,
            label: tr('المرحلة {0}', [currentDisplay]),
            onChanged: (v) => onSelectLevel(v.round() - 1),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.appState,
      builder: (context, _) {
        final child = widget.appState.currentAccount?.activeChild;
        if (child == null) return const SizedBox.shrink();
        if (_loadedChildId != child.id) {
          _syncChildGameProgressLevels();
        }

        final List<Map<String, dynamic>> gamesMeta = [
          {
            'title': tr('مرسم الآداب (١٠٠ لوحة)'),
            'icon': '🎨',
            'skill': tr('١٠٠ لوحة رسم وتلوين لتعلم الآداب والأخلاق'),
            'color': const Color(0xFF10B981),
          },
          {
            'title': tr('قوة الملاحظة (١٠٠ مرحلة)'),
            'icon': '🔍',
            'skill': tr('١٠٠ مرحلة لتصنيف الأشكال واكتشاف المختلف'),
            'color': const Color(0xFFEC4899),
          },
          {
            'title': tr('الألغاز والمنطق (١٠٠ لغز)'),
            'icon': '🧩',
            'skill': tr('١٠٠ لغز لاستنتاج الأنماط والتسلسل المنطقي'),
            'color': const Color(0xFFF59E0B),
          },
          {
            'title': tr('الذاكرة البصرية (١٠٠ مرحلة)'),
            'icon': '🃏',
            'skill': tr('١٠٠ مستوى متدرج لتقوية الذاكرة والتركيز'),
            'color': const Color(0xFF14B8A6),
          },
          {
            'title': tr('الحساب والجمع (١٠٠ مرحلة)'),
            'icon': '🔢',
            'skill': tr('١٠٠ مسألة عدّ وجمع بصري لتنمية الذكاء الرياضي'),
            'color': const Color(0xFF38BDF8),
          },
          {
            'title': tr('الحروف والكلمات (١٠٠ مرحلة)'),
            'icon': '🔤',
            'skill': tr('١٠٠ تحدٍ للذكاء اللغوي ومخارج الحروف العربية'),
            'color': const Color(0xFFA855F7),
          },
          {
            'title': tr('مطابقة الصور والكلمات'),
            'icon': '🖼️',
            'skill': tr('اختر الصورة الصحيحة التي تطابق الكلمة والوصف'),
            'color': const Color(0xFF06B6D4),
          },
          {
            'title': tr('لعبة التصنيف الذكي'),
            'icon': '🗂️',
            'skill': tr('صنّف الحيوانات والفواكه ووسائل النقل في مجموعاتها'),
            'color': const Color(0xFF10B981),
          },
          {
            'title': tr('أصوات الحيوانات والبيئة'),
            'icon': '🔊',
            'skill': tr('تعرّف على صاحب الصوت وبيئته الطبيعية'),
            'color': const Color(0xFFF97316),
          },
          {
            'title': tr('الترتيب والتسلسل المنطقي'),
            'icon': '🪜',
            'skill': tr('رتّب خطوات العادات اليومية بترتيبها الصحيح'),
            'color': const Color(0xFFEC4899),
          },
          {
            'title': tr('تتبّع الحروف'),
            'icon': '✏️',
            'skill': tr('امشي بصباعك على الحرف'),
            'color': const Color(0xFF10B981),
          },
          {
            'title': tr('عدّ وجمّع بالصور'),
            'icon': '🍎',
            'skill': tr('عُد الصور واجمع'),
            'color': const Color(0xFFF59E0B),
          },
          {
            'title': tr('رتّب الأشكال والألوان'),
            'icon': '🔷',
            'skill': tr('حط كل شكل في مكانه'),
            'color': const Color(0xFF3B82F6),
          },
          {
            'title': tr('ارسم خيالك'),
            'icon': '🖍️',
            'skill': tr('ارسم اللي في خيالك'),
            'color': const Color(0xFFEC4899),
          },
          {
            'title': tr('تمارين متنوعة'),
            'icon': '🧠',
            'skill': tr('اختيار وأرقام وترتيب وتوصيل وتصنيف'),
            'color': const Color(0xFF8B5CF6),
          },
        ];

        return Scaffold(
          appBar: AppBar(
            backgroundColor: const Color(0xFF1E293B),
            automaticallyImplyLeading: false,
            toolbarHeight: 70,
            titleSpacing: 12,
            title: Row(
              children: [
                KidFriendlyBigBackButton(
                  label: tr('رجوع'),
                  accentColor: const Color(0xFFF59E0B),
                  onPressed: () {
                    CalmVoiceService.instance.stopSpeaking();
                    Navigator.maybePop(context);
                  },
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    tr('🧠 واحة الـ ١٠٠ مرحلة والأبطال الخارقين'),
                    style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1E1B4B), Color(0xFF0F172A)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
                    child: CuteSuperheroCompanionBanner(
                      appState: widget.appState,
                      compactMode: false,
                      customCheerMessage: _heroReactionMessage,
                      reactionTick: _companionReactionTick,
                      reactionIsCorrect: _companionReactionCorrect,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 4),
                    child: Builder(
                      builder: (context) {
                        final aiRec = EducationalAiTutorService
                            .analyzeAndRecommendForChild(child);
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A).withOpacity(0.85),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color:
                                    const Color(0xFF14B8A6).withOpacity(0.5)),
                          ),
                          child: Row(
                            children: [
                              const Text('🤖',
                                  style: TextStyle(fontSize: 22)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  tr('مستشار حنين الذكي (صعوبة تكيفية {0}/٤): نقترح تقوية «{1}» في «{2}»', [aiRec.adaptiveDifficultyTier, aiRec.focusDomainTitleAr, aiRec.recommendedGameTitleAr]),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFFA7F3D0),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF14B8A6),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _selectedGameIndex =
                                        aiRec.recommendedGameTabIndex;
                                    _heroReactionMessage =
                                        aiRec.haneenInteractiveVoicePromptAr;
                                  });
                                  CalmVoiceService.instance
                                      .speakInstructionAsHaneen(
                                    aiRec.haneenInteractiveVoicePromptAr,
                                    childName: child.name,
                                  );
                                },
                                icon: const Icon(Icons.auto_awesome_rounded,
                                    size: 14),
                                label: Text(
                                  tr('العب المقترح'),
                                  style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(
                    height: 80,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: gamesMeta.length,
                      itemBuilder: (ctx, i) {
                        final g = gamesMeta[i];
                        final bool isSelected = _selectedGameIndex == i;
                        final Color accent = g['color'] as Color;
                        return GestureDetector(
                          onTap: () {
                            CalmVoiceService.instance.stopSpeaking();
                            setState(() {
                              _selectedGameIndex = i;
                              _heroReactionMessage = null;
                            });
                            SectionIntroService.instance.playForGame(i);
                            widget.appState.logChildRealtimeActivity(
                              statusSummary: '🎮 يلعب الآن: ${g['title']}',
                              actionLogText: 'انتقل إلى لعبة (${g['title']})',
                              categoryBadge: tr('ألعاب الذكاء'),
                            );
                            CalmVoiceService.instance.speakCalmly(
                              '${g['title']}، ${g['skill']}',
                            );
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            width: 158,
                            margin: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 4),
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(
                              gradient: isSelected
                                  ? LinearGradient(
                                      colors: [
                                        accent.withOpacity(0.38),
                                        const Color(0xFF1E293B),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : null,
                              color:
                                  isSelected ? null : const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: isSelected ? accent : Colors.white12,
                                width: isSelected ? 2.2 : 1,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(g['icon'] as String,
                                    style: const TextStyle(fontSize: 22)),
                                const SizedBox(height: 4),
                                Text(
                                  g['title'] as String,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 700),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(14),
                          child: AnimatedSwitcher(
                            duration: Duration(
                              milliseconds:
                                  AppNetworkPolicyGuard.reduceMotionActive
                                      ? 0
                                      : 220,
                            ),
                            child: KeyedSubtree(
                              key: ValueKey<int>(_selectedGameIndex),
                              child: _buildActiveBrainGameCard(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActiveBrainGameCard() {
    switch (_selectedGameIndex) {
      case 0:
        return _buildEtiquetteDrawingStudioGame();
      case 1:
        return _buildOddOneOutGame();
      case 2:
        return _buildPatternLogicGame();
      case 3:
        return _buildMemoryMatchGame();
      case 4:
        return _buildVisualMathGame();
      case 5:
        return _buildArabicWordBuilderGame();
      case 6:
        return _buildPictureWordMatchingGame();
      case 7:
        return _buildCategoryClassificationGame();
      case 8:
        return _buildSoundSourceIdentificationGame();
      case 9:
        return _buildLogicalSequenceOrderingGame();
      case 10:
        return TraceLetterGame(
            appState: widget.appState, onReact: _companionReact);
      case 11:
        return CountPicsGame(
            appState: widget.appState, onReact: _companionReact);
      case 12:
        return ShapeSortGame(
            appState: widget.appState, onReact: _companionReact);
      case 13:
        return ImagineDrawGame(
            appState: widget.appState, onReact: _companionReact);
      case 14:
        return ExerciseGame(
            appState: widget.appState, onReact: _companionReact);
      default:
        return _buildEtiquetteDrawingStudioGame();
    }
  }

  Widget _buildEtiquetteDrawingStudioGame() {
    final lesson = HundredLevelGamesGenerator.getEtiquetteDrawingLevel(
        _etiquetteBoardIndex);
    final int levelNum = lesson['levelNumber'] as int;
    final String title = lesson['title'] as String;
    final String badge = lesson['badge'] as String;
    final String etiquetteText = lesson['etiquetteLesson'] as String;
    final String phrase = lesson['arabicDuaOrPhrase'] as String;
    final String instruction = lesson['instruction'] as String;

    final List<Color> palette = [
      const Color(0xFF14B8A6),
      const Color(0xFFF59E0B),
      const Color(0xFFEC4899),
      const Color(0xFF38BDF8),
      const Color(0xFFA855F7),
      const Color(0xFFEF4444),
      const Color(0xFF22C55E),
      Colors.white,
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF064E3B), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF10B981), width: 1.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHundredLevelSelectorBar(
            currentLevelZeroBased: _etiquetteBoardIndex,
            accentColor: const Color(0xFF10B981),
            onSelectLevel: (newIdx) {
              setState(() {
                _etiquetteBoardIndex = newIdx;
                _drawingStrokes.clear();
                _drawnPointsCount = 0;
              });
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '🎨 $badge ($levelNum / 100)',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFA7F3D0),
                  ),
                ),
              ),
              IconButton(
                tooltip: tr('استمع لدرس الأدب بصوت هادئ'),
                onPressed: () {
                  CalmVoiceService.instance.speakCalmly(
                    '$title. $etiquetteText. $phrase',
                    rate: 0.35,
                  );
                },
                icon: const Icon(Icons.volume_up_rounded,
                    color: Color(0xFFFDE68A)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            etiquetteText,
            style: const TextStyle(
              fontSize: 13,
              height: 1.5,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: const Color(0xFFF59E0B).withOpacity(0.5)),
            ),
            child: Text(
              tr('🗣️ عبارة الأدب: {0}', [phrase]),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFDE68A),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '✏️ $instruction',
            style: const TextStyle(fontSize: 12, color: Colors.white),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              height: 230,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white24, width: 1.5),
              ),
              child: GestureDetector(
                onPanStart: (details) {
                  setState(() {
                    _drawingStrokes.add(
                      EtiquetteStrokePath(
                        points: [details.localPosition],
                        color: _selectedBrushColor,
                        strokeWidth: _selectedBrushSize,
                      ),
                    );
                    _drawnPointsCount++;
                  });
                },
                onPanUpdate: (details) {
                  if (_drawingStrokes.isEmpty) return;
                  setState(() {
                    _drawingStrokes.last.points.add(details.localPosition);
                    _drawnPointsCount++;
                  });
                },
                child: CustomPaint(
                  size: const Size(double.infinity, 230),
                  painter: EtiquetteDrawingCanvasPainter(
                    strokes: _drawingStrokes,
                    templateIndex: _etiquetteBoardIndex,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(tr('الألوان: '), style: TextStyle(fontSize: 12)),
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: palette.map((c) {
                    final bool isSel = _selectedBrushColor == c;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedBrushColor = c),
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSel ? Colors.white : Colors.white24,
                            width: isSel ? 3 : 1,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              IconButton(
                tooltip: tr('تراجع عن آخر خط'),
                onPressed: () {
                  if (_drawingStrokes.isEmpty) return;
                  setState(() {
                    _drawingStrokes.removeLast();
                    _drawnPointsCount =
                        _drawingStrokes.fold<int>(0, (a, s) => a + s.points.length);
                  });
                },
                icon: const Icon(Icons.undo_rounded, color: Color(0xFFFDE68A)),
              ),
              IconButton(
                tooltip: tr('مسح اللوحة'),
                onPressed: () {
                  setState(() {
                    _drawingStrokes.clear();
                    _drawnPointsCount = 0;
                  });
                },
                icon: const Icon(Icons.delete_sweep_outlined,
                    color: Colors.redAccent),
              ),
            ],
          ),
          Row(
            children: [
              Text(tr('حجم الفرشاة:'), style: TextStyle(fontSize: 12)),
              Expanded(
                child: Slider(
                  value: _selectedBrushSize,
                  min: 4.0,
                  max: 18.0,
                  activeColor: _selectedBrushColor,
                  onChanged: (v) => setState(() => _selectedBrushSize = v),
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () async {
                    if (_drawnPointsCount < 6) {
                      _companionReact(false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              tr('🎨 ارسم ولوّن أولاً داخل اللوحة بأصبعك لتكسب نقاط الذكاء والآداب!')),
                          backgroundColor: Color(0xFFF59E0B),
                        ),
                      );
                      return;
                    }
                    _companionReact(true);
                    await widget.appState.recordBrainGameWin(
                      gameId: 'etiquette_draw_$levelNum',
                      gameTitle: tr('مرسم الآداب (لوحة {0} من ١٠٠)', [levelNum]),
                      earnedIqPoints: 20,
                      earnedStars: 2,
                    );
                    setState(() {
                      _heroReactionMessage =
                          tr('🌟 الأبطال الخارقون فخورون بلوحتك رقم {0} وتعلمك لعبارة: {1}!', [levelNum, phrase]);
                    });
                    await CalmVoiceService.instance.speakSuperheroEncouragementAndAutoAdvance(
                      encouragementText:
                          tr('لوحة فنية رائعة يا فنان الآداب! أتممت اللوحة رقم {0} من مئة!', [levelNum]),
                      onAutoAdvance: () {
                        if (!mounted) return;
                        setState(() {
                          _etiquetteBoardIndex = (_etiquetteBoardIndex + 1) % 100;
                          _drawingStrokes.clear();
                          _drawnPointsCount = 0;
                        });
                      },
                    );
                  },
                  icon: const Icon(Icons.check_circle_outline),
                  label: Text(
                    tr('حفظ الرسمة (+20 ذكاء)'),
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _etiquetteBoardIndex = (_etiquetteBoardIndex + 1) % 100;
                    _drawingStrokes.clear();
                    _drawnPointsCount = 0;
                  });
                },
                icon: const Icon(Icons.navigate_next),
                label: Text(tr('اللوحة التالية')),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOddOneOutGame() {
    final q = HundredLevelGamesGenerator.getOddOneOutLevel(_oddQuestionIndex);
    final int levelNum = q['levelNumber'] as int;
    final String category = q['category'] as String;
    final int themeIdx = q['visualTheme'] as int;
    final String title = q['title'] as String;
    final List<String> items = List<String>.from(q['items'] as List);
    final String odd = q['odd'] as String;
    final String explanation = q['explanation'] as String;

    final List<List<Color>> themeGradients = [
      [const Color(0xFF31102F), const Color(0xFF1E293B)],
      [const Color(0xFF0F3D3E), const Color(0xFF1E293B)],
      [const Color(0xFF1E1B4B), const Color(0xFF172554)],
      [const Color(0xFF3B1D0A), const Color(0xFF1E293B)],
    ];
    final List<Color> themeBorders = [
      const Color(0xFFEC4899),
      const Color(0xFF14B8A6),
      const Color(0xFF38BDF8),
      const Color(0xFFF59E0B),
    ];

    final Color activeBorder = themeBorders[themeIdx % themeBorders.length];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: themeGradients[themeIdx % themeGradients.length],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: activeBorder, width: 1.8),
      ),
      child: Column(
        children: [
          _buildHundredLevelSelectorBar(
            currentLevelZeroBased: _oddQuestionIndex,
            accentColor: activeBorder,
            onSelectLevel: (newIdx) {
              setState(() {
                _oddQuestionIndex = newIdx;
                _oddCorrect = false;
                _oddFeedback = null;
              });
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '🔍 $category',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: activeBorder,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => CalmVoiceService.instance.speakCalmly(title),
                icon: Icon(Icons.volume_up_rounded, color: activeBorder),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.45,
            ),
            itemCount: items.length,
            itemBuilder: (ctx, i) {
              final String itemEmoji = items[i];
              final bool isRoundedTheme = themeIdx % 2 == 1;
              return GestureDetector(
                onTap: () async {
                  if (itemEmoji == odd) {
                    _companionReact(true);
                    setState(() {
                      _oddCorrect = true;
                      _oddFeedback = tr('✅ ملاحظة ذكية جداً! {0}', [explanation]);
                      _heroReactionMessage =
                          tr('🌟 الأبطال الصغار يقولون لك: قوة ملاحظتك خارقة في المرحلة {0}!', [levelNum]);
                    });
                    await widget.appState.recordBrainGameWin(
                      gameId: 'odd_one_out_$levelNum',
                      gameTitle: tr('قوة الملاحظة (المرحلة {0} من ١٠٠)', [levelNum]),
                      earnedIqPoints: 15,
                      earnedStars: 1,
                    );
                    await CalmVoiceService.instance.speakSuperheroEncouragementAndAutoAdvance(
                      encouragementText:
                          tr('أحسنت الملاحظة الخارقة في المرحلة {0}! {1}', [levelNum, explanation]),
                      onAutoAdvance: () {
                        if (!mounted) return;
                        setState(() {
                          _oddQuestionIndex = (_oddQuestionIndex + 1) % 100;
                          _oddCorrect = false;
                          _oddFeedback = null;
                        });
                      },
                    );
                  } else {
                    _companionReact(false);
                    setState(() {
                      _oddCorrect = false;
                      _oddFeedback =
                          tr('👀 هذا العنصر يشبه أصدقاءه في المجموعة، ابحث عن العنصر المختلف تماماً!');
                    });
                    CalmVoiceService.instance.speakCalmly(
                      tr('انظر بدقة يا بطل وابحث عن الشكل المختلف عن المجموعة.'),
                    );
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF0F172A),
                        activeBorder.withOpacity(0.18),
                      ],
                    ),
                    borderRadius:
                        BorderRadius.circular(isRoundedTheme ? 34 : 18),
                    border: Border.all(
                      color: activeBorder.withOpacity(0.65),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      itemEmoji,
                      style: const TextStyle(fontSize: 42),
                    ),
                  ),
                ),
              );
            },
          ),
          if (_oddFeedback != null) ...[
            const SizedBox(height: 12),
            Text(
              _oddFeedback!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _oddCorrect
                    ? const Color(0xFF14B8A6)
                    : const Color(0xFFF59E0B),
              ),
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: activeBorder,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                setState(() {
                  _oddQuestionIndex = (_oddQuestionIndex + 1) % 100;
                  _oddCorrect = false;
                  _oddFeedback = null;
                });
              },
              icon: const Icon(Icons.navigate_next),
              label: Text(
                tr('المرحلة التالية ({0} من ١٠٠)', [(levelNum % 100) + 1]),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatternLogicGame() {
    final q =
        HundredLevelGamesGenerator.getPatternLogicLevel(_patternQuestionIndex);
    final int levelNum = q['levelNumber'] as int;
    final List<String> seq = List<String>.from(q['sequence'] as List);
    final List<String> opts = List<String>.from(q['options'] as List);
    final String ans = q['answer'] as String;
    final String hint = q['hint'] as String;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildHundredLevelSelectorBar(
            currentLevelZeroBased: _patternQuestionIndex,
            accentColor: const Color(0xFFF59E0B),
            onSelectLevel: (newIdx) {
              setState(() {
                _patternQuestionIndex = newIdx;
                _patternFeedback = null;
                _patternCorrect = false;
              });
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  tr('🧩 مختبر المنطق والأنماط ({0} / 100)', [levelNum]),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                onPressed: () => CalmVoiceService.instance.speakCalmly(hint),
                icon: const Icon(Icons.volume_up_rounded,
                    color: Color(0xFFF59E0B)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            hint,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Colors.white70),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              children: [
                ...seq.map(
                    (s) => Text(s, style: const TextStyle(fontSize: 32))),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFF59E0B)),
                  ),
                  child: Text(tr('؟'),
                      style:
                          TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: opts.map((option) {
              return ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: Colors.white24),
                  ),
                ),
                onPressed: () async {
                  if (option == ans) {
                    _companionReact(true);
                    setState(() {
                      _patternCorrect = true;
                      _patternFeedback =
                          tr('✅ تفكير منطقي عبقري في اللغز {0}! الإجابة ({1}) صحيحة (+15 ذكاء)', [levelNum, option]);
                      _heroReactionMessage =
                          tr('🦇 فارس الليل يحييك: استنتاج منطقي مذهل في المرحلة {0} من ١٠٠!', [levelNum]);
                    });
                    await widget.appState.recordBrainGameWin(
                      gameId: 'pattern_logic_$levelNum',
                      gameTitle: tr('الألغاز والمنطق (لغز {0} من ١٠٠)', [levelNum]),
                      earnedIqPoints: 15,
                      earnedStars: 1,
                    );
                    await CalmVoiceService.instance.speakSuperheroEncouragementAndAutoAdvance(
                      encouragementText:
                          tr('أحسنت التفكير المنطقي الخارق في المرحلة {0}!', [levelNum]),
                      onAutoAdvance: () {
                        if (!mounted) return;
                        setState(() {
                          _patternQuestionIndex = (_patternQuestionIndex + 1) % 100;
                          _patternFeedback = null;
                          _patternCorrect = false;
                        });
                      },
                    );
                  } else {
                    _companionReact(false);
                    setState(() {
                      _patternCorrect = false;
                      _patternFeedback =
                          tr('💡 تأمل الترتيب مرة أخرى بهدوء وحاول مجدداً!');
                    });
                    CalmVoiceService.instance.coachWrongAnswer(
                      hint: tr('لاحظ الترتيب: إيه الشكل اللي بيتكرر؟'),
                    );
                  }
                },
                child: Text(option, style: const TextStyle(fontSize: 30)),
              );
            }).toList(),
          ),
          if (_patternFeedback != null) ...[
            const SizedBox(height: 12),
            Text(
              _patternFeedback!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _patternCorrect
                    ? const Color(0xFF14B8A6)
                    : const Color(0xFFF59E0B),
              ),
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF59E0B),
                foregroundColor: Colors.black87,
              ),
              onPressed: () {
                setState(() {
                  _patternQuestionIndex = (_patternQuestionIndex + 1) % 100;
                  _patternFeedback = null;
                  _patternCorrect = false;
                });
              },
              icon: const Icon(Icons.navigate_next),
              label: Text(
                tr('اللغز التالي ({0} من ١٠٠)', [(levelNum % 100) + 1]),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemoryMatchGame() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF14B8A6).withOpacity(0.5)),
      ),
      child: Column(
        children: [
          _buildHundredLevelSelectorBar(
            currentLevelZeroBased: _memoryLevel - 1,
            accentColor: const Color(0xFF14B8A6),
            onSelectLevel: (newIdx) {
              setState(() {
                _memoryLevel = newIdx + 1;
              });
              _initMemoryGame();
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  tr('🃏 الذاكرة البصرية (المرحلة {0} من ١٠٠)', [_memoryLevel]),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _memoryLevel = (_memoryLevel % 100) + 1;
                  });
                  _initMemoryGame();
                },
                icon: const Icon(Icons.skip_next, size: 16),
                label: Text(tr('المرحلة التالية')),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Chip(
                backgroundColor: const Color(0xFF0F172A),
                label: Text(tr('المحاولات: {0}', [_memoryMoves])),
              ),
              Chip(
                backgroundColor: const Color(0xFF0F172A),
                label: Text(
                    tr('التطابقات: {0} / {1}', [_memoryMatches, _memoryBoard.length ~/ 2])),
              ),
            ],
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.0,
            ),
            itemCount: _memoryBoard.length,
            itemBuilder: (ctx, index) {
              final bool isUp =
                  _memoryRevealed[index] || _memorySolved[index];
              final bool isSolved = _memorySolved[index];
              return GestureDetector(
                onTap: () => _onMemoryCardTap(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  decoration: BoxDecoration(
                    color: isSolved
                        ? const Color(0xFF14B8A6).withOpacity(0.3)
                        : isUp
                            ? const Color(0xFF334155)
                            : const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSolved
                          ? const Color(0xFF14B8A6)
                          : isUp
                              ? const Color(0xFFF59E0B)
                              : Colors.white24,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      isUp ? _memoryBoard[index] : '🌟',
                      style: const TextStyle(fontSize: 30),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildVisualMathGame() {
    final mathData =
        HundredLevelGamesGenerator.getVisualMathLevel(_mathQuestionIndex);
    final int levelNum = mathData['levelNumber'] as int;
    final bool isAdd = (mathData['mode'] as String) == 'add';
    final int a = mathData['a'] as int;
    final int b = mathData['b'] as int;
    final int target = mathData['target'] as int;
    final String emoji = mathData['emoji'] as String;
    final List<int> options = List<int>.from(mathData['options'] as List);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF38BDF8).withOpacity(0.5)),
      ),
      child: Column(
        children: [
          _buildHundredLevelSelectorBar(
            currentLevelZeroBased: _mathQuestionIndex,
            accentColor: const Color(0xFF38BDF8),
            onSelectLevel: (newIdx) {
              setState(() {
                _mathQuestionIndex = newIdx;
                _mathFeedback = null;
                _mathAnswered = false;
              });
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  isAdd
                      ? tr('🔢 الجمع المصور (المرحلة {0} من ١٠٠)', [levelNum])
                      : tr('🔢 العدّ البصري (المرحلة {0} من ١٠٠)', [levelNum]),
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                onPressed: () => CalmVoiceService.instance.speakCalmly(
                  isAdd
                      ? tr('المرحلة {0}: اجمع {1} زائد {2} يساوي كم؟', [levelNum, a, b])
                      : tr('المرحلة {0}: عدّ الأشكال بهدوء واختر الرقم الصحيح!', [levelNum]),
                ),
                icon: const Icon(Icons.volume_up_rounded,
                    color: Color(0xFF38BDF8)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white12),
            ),
            child: isAdd
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Flexible(
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 6,
                          runSpacing: 6,
                          children: List.generate(
                            a,
                            (_) => Text(emoji,
                                style: const TextStyle(fontSize: 30)),
                          ),
                        ),
                      ),
                      const Text(
                        '➕',
                        style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFF59E0B)),
                      ),
                      Flexible(
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 6,
                          runSpacing: 6,
                          children: List.generate(
                            b,
                            (_) => Text(emoji,
                                style: const TextStyle(fontSize: 30)),
                          ),
                        ),
                      ),
                    ],
                  )
                : Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 12,
                    runSpacing: 12,
                    children: List.generate(
                      target,
                      (_) => Text(emoji, style: const TextStyle(fontSize: 34)),
                    ),
                  ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: options.map((numOpt) {
              return ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: Color(0xFF38BDF8)),
                  ),
                ),
                onPressed: () async {
                  if (numOpt == target) {
                    _companionReact(true);
                    if (!_mathAnswered) {
                      _mathAnswered = true;
                      await widget.appState.recordBrainGameWin(
                        gameId: 'visual_math_$levelNum',
                        gameTitle: tr('الحساب البصري (المرحلة {0} من ١٠٠)', [levelNum]),
                        earnedIqPoints: 15,
                        earnedStars: 1,
                      );
                    }
                    setState(() {
                      _mathFeedback =
                          tr('🎉 عبقري في الحساب! الناتج ({0}) صحيح (+15 ذكاء)', [numOpt]);
                      _heroReactionMessage =
                          tr('⚡ الأبطال الصغار يهتفون لك: إجابة حسابية متقنة في المرحلة {0}!', [levelNum]);
                    });
                    await CalmVoiceService.instance.speakSuperheroEncouragementAndAutoAdvance(
                      encouragementText:
                          tr('رائع يا بطل الحساب الخارق! الإجابة هي {0}!', [numOpt]),
                      onAutoAdvance: () {
                        if (!mounted) return;
                        setState(() {
                          _mathQuestionIndex = (_mathQuestionIndex + 1) % 100;
                          _mathFeedback = null;
                          _mathAnswered = false;
                        });
                      },
                    );
                  } else {
                    _companionReact(false);
                    setState(() {
                      _mathFeedback =
                          tr('🔢 عدّ الأشكال بأصابعك مرة أخرى بهدوء وحاول مجدداً!');
                    });
                    CalmVoiceService.instance.coachWrongAnswer(
                      hint: tr('عدّ الأشكال واحد واحد وأنت بتشاور عليها.'),
                    );
                  }
                },
                child: Text(
                  '$numOpt',
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold),
                ),
              );
            }).toList(),
          ),
          if (_mathFeedback != null) ...[
            const SizedBox(height: 12),
            Text(
              _mathFeedback!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Color(0xFF38BDF8)),
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF38BDF8),
                foregroundColor: Colors.black87,
              ),
              onPressed: () {
                setState(() {
                  _mathQuestionIndex = (_mathQuestionIndex + 1) % 100;
                  _mathFeedback = null;
                  _mathAnswered = false;
                });
              },
              icon: const Icon(Icons.navigate_next),
              label: Text(
                tr('المرحلة الحسابية التالية ({0} من ١٠٠)', [(levelNum % 100) + 1]),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArabicWordBuilderGame() {
    final q =
        HundredLevelGamesGenerator.getArabicWordLevel(_wordQuestionIndex);
    final int levelNum = q['levelNumber'] as int;
    final String emoji = q['emoji'] as String;
    final String fullWord = q['word'] as String;
    final String missingDisplay = q['missingDisplay'] as String;
    final String prompt = q['prompt'] as String;
    final List<String> opts = List<String>.from(q['options'] as List);
    final String ans = q['answer'] as String;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFA855F7).withOpacity(0.5)),
      ),
      child: Column(
        children: [
          _buildHundredLevelSelectorBar(
            currentLevelZeroBased: _wordQuestionIndex,
            accentColor: const Color(0xFFA855F7),
            onSelectLevel: (newIdx) {
              setState(() {
                _wordQuestionIndex = newIdx;
                _wordCorrect = false;
                _wordFeedback = null;
              });
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  tr('🔤 الذكاء اللغوي ({0} / 100)', [levelNum]),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                onPressed: () => CalmVoiceService.instance.speakCalmly(
                  tr('{0} الكلمة هي {1}', [prompt, fullWord]),
                  rate: 0.34,
                ),
                icon: const Icon(Icons.volume_up_rounded,
                    color: Color(0xFFA855F7)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(emoji, style: const TextStyle(fontSize: 54)),
          const SizedBox(height: 6),
          Text(
            prompt,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Colors.white70),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              _wordCorrect ? fullWord : tr('؟ {0}', [missingDisplay]),
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFDE68A),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: opts.map((letter) {
              return ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: Color(0xFFA855F7)),
                  ),
                ),
                onPressed: () async {
                  if (letter == ans) {
                    _companionReact(true);
                    setState(() {
                      _wordCorrect = true;
                      _wordFeedback =
                          tr('✅ أحسنت يا فصيح! حرف ({0}) يكمل كلمة ({1}) (+15 ذكاء)', [letter, fullWord]);
                      _heroReactionMessage =
                          tr('👦👧 الأبطال الصغار يحيّون فصاحتك في المرحلة {0}!', [levelNum]);
                    });
                    await widget.appState.recordBrainGameWin(
                      gameId: 'arabic_word_$levelNum',
                      gameTitle: tr('الذكاء اللغوي (المرحلة {0} من ١٠٠)', [levelNum]),
                      earnedIqPoints: 15,
                      earnedStars: 1,
                    );
                    await CalmVoiceService.instance.speakSuperheroEncouragementAndAutoAdvance(
                      encouragementText:
                          tr('ممتاز يا بطل الفصاحة! حرف {0}، {1}!', [letter, fullWord]),
                      onAutoAdvance: () {
                        if (!mounted) return;
                        setState(() {
                          _wordQuestionIndex = (_wordQuestionIndex + 1) % 100;
                          _wordCorrect = false;
                          _wordFeedback = null;
                        });
                      },
                    );
                  } else {
                    _companionReact(false);
                    setState(() {
                      _wordCorrect = false;
                      _wordFeedback =
                          tr('🗣️ استمع لصوت الكلمة مرة أخرى وجرب حرفاً آخر!');
                    });
                    CalmVoiceService.instance.coachWrongAnswer(
                      hint: tr('اسمع أول صوت في الكلمة، وده هو الحرف اللي ناقص.'),
                    );
                  }
                },
                child: Text(
                  letter,
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold),
                ),
              );
            }).toList(),
          ),
          if (_wordFeedback != null) ...[
            const SizedBox(height: 12),
            Text(
              _wordFeedback!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Color(0xFFA855F7)),
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFA855F7),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                setState(() {
                  _wordQuestionIndex = (_wordQuestionIndex + 1) % 100;
                  _wordCorrect = false;
                  _wordFeedback = null;
                });
              },
              icon: const Icon(Icons.navigate_next),
              label: Text(
                tr('الكلمة التالية ({0} من ١٠٠)', [(levelNum % 100) + 1]),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildPictureWordMatchingGame() {
    final child = widget.appState.currentAccount?.activeChild;
    final int adaptiveTier = child == null
        ? 2
        : HundredLevelGamesGenerator.computeAdaptiveDifficultyTier(
            ageGroup: child.age,
            currentCurriculumTier: child.currentCurriculumTier,
            gamesCompletedCount: child.gamesCompletedCount,
          );
    final current = HundredLevelGamesGenerator.getPictureWordMatchLevel(
      _picMatchIndex,
      difficultyTier: adaptiveTier,
    );
    final int levelNum = current['levelNumber'] as int;
    final List<String> opts = List<String>.from(current['options'] as List);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF06B6D4).withOpacity(0.6)),
      ),
      child: Column(
        children: [
          _buildHundredLevelSelectorBar(
            currentLevelZeroBased: _picMatchIndex,
            accentColor: const Color(0xFF06B6D4),
            onSelectLevel: (newIdx) {
              setState(() {
                _picMatchIndex = newIdx;
                _picMatchFeedback = null;
              });
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                tr('🖼️ مطابقة الصور والكلمات ({0} / 100)', [levelNum]),
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              IconButton(
                tooltip: tr('استمع للكلمة بصوت حنين'),
                onPressed: () {
                  CalmVoiceService.instance.speakInstructionAsHaneen(
                    'اختر الصورة المطابقة لكلمة ${current['word']}. ${current['hint']}',
                    childName: child?.name,
                  );
                },
                icon: const Icon(Icons.volume_up_rounded,
                    color: Color(0xFF06B6D4)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  current['word'] as String,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFDE68A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  current['hint'] as String,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12.5, color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 14,
            runSpacing: 14,
            alignment: WrapAlignment.center,
            children: opts.map((emojiOpt) {
              return GestureDetector(
                onTap: () async {
                  final bool isHit = emojiOpt == current['correct'];
                  if (isHit) {
                    _companionReact(true);
                    final isNew = await widget.appState.recordBrainGameWin(
                      gameId: 'pic_match_$levelNum',
                      gameTitle: tr('مطابقة الصور والكلمات (المرحلة {0})', [levelNum]),
                      earnedIqPoints: 12,
                      earnedStars: 1,
                      learnedWord: current['word'] as String,
                    );
                    final reaction = await CalmVoiceService.instance
                        .reactToChildAnswerAsHaneen(
                      isCorrect: true,
                      childName: child?.name ?? tr('يا بطل'),
                      learnedConcept: current['word'] as String,
                      onAutoAdvanceAfterAudio: () {
                        if (!mounted) return;
                        setState(() {
                          _picMatchIndex = HundredLevelGamesGenerator
                              .selectNextNonRepetitiveLevelIndex(
                            currentIndex: _picMatchIndex,
                            difficultyTier: adaptiveTier,
                          );
                          _picMatchFeedback = null;
                        });
                      },
                    );
                    if (mounted) {
                      setState(() {
                        _heroReactionMessage = reaction;
                      });
                    }
                  } else {
                    _companionReact(false);
                    final reaction = await CalmVoiceService.instance
                        .reactToChildAnswerAsHaneen(
                      isCorrect: false,
                      childName: child?.name ?? tr('بطل حنين'),
                      gentleHint: current['hint'] as String,
                    );
                    setState(() {
                      _picMatchFeedback = '💡 $reaction';
                    });
                  }
                },
                child: Container(
                  width: 82,
                  height: 82,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                        color: const Color(0xFF06B6D4).withOpacity(0.6),
                        width: 1.5),
                  ),
                  child: Text(emojiOpt, style: const TextStyle(fontSize: 42)),
                ),
              );
            }).toList(),
          ),
          if (_picMatchFeedback != null) ...[
            const SizedBox(height: 12),
            Text(
              _picMatchFeedback!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Color(0xFF38BDF8)),
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF06B6D4),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                setState(() {
                  _picMatchIndex = HundredLevelGamesGenerator
                      .selectNextNonRepetitiveLevelIndex(
                    currentIndex: _picMatchIndex,
                    difficultyTier: adaptiveTier,
                  );
                  _picMatchFeedback = null;
                });
              },
              icon: const Icon(Icons.navigate_next),
              label: Text(tr('التحدي التالي')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryClassificationGame() {
    final child = widget.appState.currentAccount?.activeChild;
    final int adaptiveTier = child == null
        ? 2
        : HundredLevelGamesGenerator.computeAdaptiveDifficultyTier(
            ageGroup: child.age,
            currentCurriculumTier: child.currentCurriculumTier,
            gamesCompletedCount: child.gamesCompletedCount,
          );
    final current = HundredLevelGamesGenerator.getSmartClassificationLevel(
      _classifyIndex,
      difficultyTier: adaptiveTier,
    );
    final int levelNum = current['levelNumber'] as int;
    final List<String> cats = List<String>.from(current['categories'] as List);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.6)),
      ),
      child: Column(
        children: [
          _buildHundredLevelSelectorBar(
            currentLevelZeroBased: _classifyIndex,
            accentColor: const Color(0xFF10B981),
            onSelectLevel: (newIdx) {
              setState(() {
                _classifyIndex = newIdx;
                _classifyFeedback = null;
              });
            },
          ),
          Text(
            tr('🗂️ لعبة التصنيف الذكي ({0} / 100)', [levelNum]),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(current['itemEmoji'] as String,
              style: const TextStyle(fontSize: 58)),
          const SizedBox(height: 6),
          Text(
            'إلى أي مجموعة ينتمي «${current['itemName']}»؟',
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFDE68A)),
          ),
          const SizedBox(height: 14),
          ...cats.map((catName) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SizedBox(
                width: double.infinity,
                height: 46,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFF10B981)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () async {
                    if (catName == current['correctCategory']) {
                      await widget.appState.recordBrainGameWin(
                        gameId: 'classify_$levelNum',
                        gameTitle: tr('لعبة التصنيف الذكي (المرحلة {0})', [levelNum]),
                        earnedIqPoints: 12,
                        earnedStars: 1,
                        learnedWord: current['itemName'] as String,
                      );
                      _companionReact(true);
                      final reaction = await CalmVoiceService.instance
                          .reactToChildAnswerAsHaneen(
                        isCorrect: true,
                        childName: child?.name ?? tr('يا بطل'),
                        learnedConcept:
                            '${current['itemName']} من $catName',
                        onAutoAdvanceAfterAudio: () {
                          if (!mounted) return;
                          setState(() {
                            _classifyIndex = HundredLevelGamesGenerator
                                .selectNextNonRepetitiveLevelIndex(
                              currentIndex: _classifyIndex,
                              difficultyTier: adaptiveTier,
                            );
                            _classifyFeedback = null;
                          });
                        },
                      );
                      if (mounted) {
                        setState(() {
                          _heroReactionMessage = reaction;
                        });
                      }
                    } else {
                      _companionReact(false);
                      final reaction = await CalmVoiceService.instance
                          .reactToChildAnswerAsHaneen(
                        isCorrect: false,
                        childName: child?.name ?? tr('بطل حنين'),
                        gentleHint:
                            'فكر بهدوء: أين نرى ${current['itemName']} في حياتنا اليومية؟',
                      );
                      setState(() {
                        _classifyFeedback = '💡 $reaction';
                      });
                    }
                  },
                  child: Text(catName,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold)),
                ),
              ),
            );
          }),
          if (_classifyFeedback != null) ...[
            const SizedBox(height: 8),
            Text(
              _classifyFeedback!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Color(0xFFA7F3D0), fontWeight: FontWeight.bold),
            ),
          ],
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                setState(() {
                  _classifyIndex = HundredLevelGamesGenerator
                      .selectNextNonRepetitiveLevelIndex(
                    currentIndex: _classifyIndex,
                    difficultyTier: adaptiveTier,
                  );
                  _classifyFeedback = null;
                });
              },
              icon: const Icon(Icons.navigate_next),
              label: Text(tr('العنصر التالي')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSoundSourceIdentificationGame() {
    final child = widget.appState.currentAccount?.activeChild;
    final int adaptiveTier = child == null
        ? 2
        : HundredLevelGamesGenerator.computeAdaptiveDifficultyTier(
            ageGroup: child.age,
            currentCurriculumTier: child.currentCurriculumTier,
            gamesCompletedCount: child.gamesCompletedCount,
          );
    final current = HundredLevelGamesGenerator.getSoundAndListeningLevel(
      _soundGameIndex,
      difficultyTier: adaptiveTier,
    );
    final int levelNum = current['levelNumber'] as int;
    final List<String> opts = List<String>.from(current['options'] as List);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF97316).withOpacity(0.6)),
      ),
      child: Column(
        children: [
          _buildHundredLevelSelectorBar(
            currentLevelZeroBased: _soundGameIndex,
            accentColor: const Color(0xFFF97316),
            onSelectLevel: (newIdx) {
              setState(() {
                _soundGameIndex = newIdx;
                _soundGameFeedback = null;
              });
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                tr('🔊 تمييز الأصوات ({0} / 100)', [levelNum]),
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF97316),
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  CalmVoiceService.instance.speakStoryOrQuestionAsHaneen(
                    titleOrContext: tr('استمع مع حنين'),
                    contentToRead: current['soundText'] as String,
                    questionPrompt: current['question'] as String,
                  );
                },
                icon: const Icon(Icons.volume_up_rounded, size: 18),
                label: Text(tr('استمع للصوت')),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  current['soundText'] as String,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFDE68A),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  current['question'] as String,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          ...opts.map((opt) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SizedBox(
                width: double.infinity,
                height: 46,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFFF97316)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () async {
                    if (opt == current['correct']) {
                      _companionReact(true);
                      await widget.appState.recordBrainGameWin(
                        gameId: 'sound_id_$levelNum',
                        gameTitle: tr('لعبة تمييز الأصوات (المرحلة {0})', [levelNum]),
                        earnedIqPoints: 12,
                        earnedStars: 1,
                        learnedWord: opt,
                      );
                      final reaction = await CalmVoiceService.instance
                          .reactToChildAnswerAsHaneen(
                        isCorrect: true,
                        childName: child?.name ?? tr('يا بطل'),
                        learnedConcept: opt,
                        onAutoAdvanceAfterAudio: () {
                          if (!mounted) return;
                          setState(() {
                            _soundGameIndex = HundredLevelGamesGenerator
                                .selectNextNonRepetitiveLevelIndex(
                              currentIndex: _soundGameIndex,
                              difficultyTier: adaptiveTier,
                            );
                            _soundGameFeedback = null;
                          });
                        },
                      );
                      if (mounted) {
                        setState(() {
                          _heroReactionMessage = reaction;
                        });
                      }
                    } else {
                      _companionReact(false);
                      final reaction = await CalmVoiceService.instance
                          .reactToChildAnswerAsHaneen(
                        isCorrect: false,
                        childName: child?.name ?? tr('بطل حنين'),
                        gentleHint: tr('اضغط «استمع للصوت» بالأعلى وركز في الصوت!'),
                      );
                      setState(() {
                        _soundGameFeedback = '💡 $reaction';
                      });
                    }
                  },
                  child: Text(opt,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold)),
                ),
              ),
            );
          }),
          if (_soundGameFeedback != null) ...[
            const SizedBox(height: 8),
            Text(
              _soundGameFeedback!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Color(0xFFFDE68A), fontWeight: FontWeight.bold),
            ),
          ],
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF97316),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                setState(() {
                  _soundGameIndex = HundredLevelGamesGenerator
                      .selectNextNonRepetitiveLevelIndex(
                    currentIndex: _soundGameIndex,
                    difficultyTier: adaptiveTier,
                  );
                  _soundGameFeedback = null;
                });
              },
              icon: const Icon(Icons.navigate_next),
              label: Text(tr('الصوت التالي')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogicalSequenceOrderingGame() {
    final child = widget.appState.currentAccount?.activeChild;
    final int adaptiveTier = child == null
        ? 2
        : HundredLevelGamesGenerator.computeAdaptiveDifficultyTier(
            ageGroup: child.age,
            currentCurriculumTier: child.currentCurriculumTier,
            gamesCompletedCount: child.gamesCompletedCount,
          );
    final current =
        HundredLevelGamesGenerator.getLogicalSequenceAndRiddleLevel(
      _seqGameIndex,
      difficultyTier: adaptiveTier,
    );
    final int levelNum = current['levelNumber'] as int;
    final List<String> correctSteps =
        List<String>.from(current['steps'] as List);
    final List<int> displayOrder = [1, 2, 0];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFEC4899).withOpacity(0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHundredLevelSelectorBar(
            currentLevelZeroBased: _seqGameIndex,
            accentColor: const Color(0xFFEC4899),
            onSelectLevel: (newIdx) {
              setState(() {
                _seqGameIndex = newIdx;
                _userSequenceOrder.clear();
                _seqGameFeedback = null;
              });
            },
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  '🪜 ${current['title']}',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                tooltip: tr('استمع للغز بصوت حنين'),
                onPressed: () {
                  CalmVoiceService.instance.speakInstructionAsHaneen(
                    '${current['title']}. ${current['riddleTip']}',
                    childName: child?.name,
                  );
                },
                icon: const Icon(Icons.volume_up_rounded,
                    color: Color(0xFFFDE68A)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '💡 ${current['riddleTip']}',
            style: const TextStyle(fontSize: 12, color: Color(0xFFFDE68A)),
          ),
          const SizedBox(height: 12),
          ...displayOrder.map((stepIdx) {
            final bool isPicked = _userSequenceOrder.contains(stepIdx);
            final int pickedOrder = _userSequenceOrder.indexOf(stepIdx) + 1;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () async {
                  if (isPicked) return;
                  setState(() {
                    _userSequenceOrder.add(stepIdx);
                  });
                  if (_userSequenceOrder.length == 3) {
                    if (_userSequenceOrder[0] == 0 &&
                        _userSequenceOrder[1] == 1 &&
                        _userSequenceOrder[2] == 2) {
                      _companionReact(true);
                      await widget.appState.recordBrainGameWin(
                        gameId: 'seq_$levelNum',
                        gameTitle: tr('لعبة الترتيب المنطقي (المرحلة {0})', [levelNum]),
                        earnedIqPoints: 15,
                        earnedStars: 2,
                      );
                      final reaction = await CalmVoiceService.instance
                          .reactToChildAnswerAsHaneen(
                        isCorrect: true,
                        childName: child?.name ?? tr('يا بطل'),
                        learnedConcept: current['title'] as String,
                        onAutoAdvanceAfterAudio: () {
                          if (!mounted) return;
                          setState(() {
                            _seqGameIndex = HundredLevelGamesGenerator
                                .selectNextNonRepetitiveLevelIndex(
                              currentIndex: _seqGameIndex,
                              difficultyTier: adaptiveTier,
                            );
                            _userSequenceOrder.clear();
                            _seqGameFeedback = null;
                          });
                        },
                      );
                      if (mounted) {
                        setState(() {
                          _heroReactionMessage = reaction;
                        });
                      }
                    } else {
                      _companionReact(false);
                      final reaction = await CalmVoiceService.instance
                          .reactToChildAnswerAsHaneen(
                        isCorrect: false,
                        childName: child?.name ?? tr('بطل حنين'),
                        gentleHint: current['riddleTip'] as String,
                      );
                      setState(() {
                        _seqGameFeedback = '🔄 $reaction';
                      });
                    }
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isPicked
                        ? const Color(0xFF14B8A6).withOpacity(0.25)
                        : const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isPicked
                          ? const Color(0xFF14B8A6)
                          : Colors.white24,
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: isPicked
                            ? const Color(0xFF14B8A6)
                            : Colors.white12,
                        child: Text(
                          isPicked ? '$pickedOrder' : tr('؟'),
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          correctSteps[stepIdx],
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          if (_seqGameFeedback != null) ...[
            const SizedBox(height: 8),
            Text(
              _seqGameFeedback!,
              style: const TextStyle(
                  color: Color(0xFFFDE68A), fontWeight: FontWeight.bold),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _userSequenceOrder.clear();
                      _seqGameFeedback = null;
                    });
                  },
                  icon: const Icon(Icons.refresh, size: 16),
                  label: Text(tr('إعادة الترتيب')),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEC4899),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    setState(() {
                      _seqGameIndex = HundredLevelGamesGenerator
                          .selectNextNonRepetitiveLevelIndex(
                        currentIndex: _seqGameIndex,
                        difficultyTier: adaptiveTier,
                      );
                      _userSequenceOrder.clear();
                      _seqGameFeedback = null;
                    });
                  },
                  icon: const Icon(Icons.navigate_next),
                  label: Text(tr('التسلسل التالي')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
