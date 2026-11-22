import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:haneen_kids_vod/haneen_kids_exports.dart';

/// Interactive Animated Story Engine Widget (replaces all legacy `.mp4` videos):
/// - Displays each story as sequential animated Story Image Cards (`PageView`).
/// - Applies continuous subtle Ken Burns (Slow Zoom & Pan), Floating Animation, and Multi-Layer Parallax.
/// - Applies Interactive Touch Micro-Animations (Pulse / Scale Bounce + Sparkles) when tapped by the child.
/// - Auto-plays Dual-Voice Narration (`cUDXOxxuLZJdTcxEyGVB` ⇄ `L14QZl4DxSQ6xGvib36i`) with low-volume Calm Background Music (`14%` mix)
///   and auto-swipes cards in sync with each scene's audio!
class VerticalVideoFeedItemWidget extends StatefulWidget {
  final VideoModel video;
  final bool isActive;
  final VoidCallback onLikeTap;
  final VoidCallback onRepeatPhraseTap;
  final VoidCallback onHeroActivityTap;
  final VoidCallback onVoiceAssistantTap;
  final VoidCallback onBrainGamesTap;
  final VoidCallback? onAcademyTap;

  const VerticalVideoFeedItemWidget({
    super.key,
    required this.video,
    required this.isActive,
    required this.onLikeTap,
    required this.onRepeatPhraseTap,
    required this.onHeroActivityTap,
    required this.onVoiceAssistantTap,
    required this.onBrainGamesTap,
    this.onAcademyTap,
  });

  /// Kept for backward compatibility with URL helpers.
  static String normalizeStreamOrLocalUrl(String rawUrl) {
    final String trimmed = rawUrl.trim();
    final RegExp driveRegex =
        RegExp(r'drive\.google\.com\/file\/d\/([a-zA-Z0-9_-]+)');
    final match = driveRegex.firstMatch(trimmed);
    if (match != null && match.groupCount >= 1) {
      final String fileId = match.group(1)!;
      return 'https://drive.google.com/uc?export=download&id=$fileId';
    }
    return trimmed;
  }

  @override
  State<VerticalVideoFeedItemWidget> createState() =>
      _VerticalVideoFeedItemWidgetState();
}

class _VerticalVideoFeedItemWidgetState
    extends State<VerticalVideoFeedItemWidget>
    with TickerProviderStateMixin {
  late final PageController _cardPageController;
  late final AnimationController _kenBurnsController;
  late final AnimationController _touchBounceController;
  late final Animation<double> _touchScaleAnimation;

  late InteractiveEducationalStoryModel _story;
  int _activeCardIndex = 0;
  bool _isNarrating = false;
  bool _isMuted = false;
  bool _showTouchSparkle = false;
  bool _showFullDescription = false;
  int _narrationSessionToken = 0;

  @override
  void initState() {
    super.initState();
    _story = widget.video.resolvedInteractiveStory;
    _cardPageController = PageController();

    // 1. Subtle continuous Ken Burns (Slow Zoom & Pan) + Parallax + Floating animation (8s cycle)
    _kenBurnsController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );
    if (!CalmVoiceService.isRunningInUnitTest &&
        !AppNetworkPolicyGuard.reduceMotionActive) {
      _kenBurnsController.repeat(reverse: true);
    }

    // 2. Interactive Touch Micro-Animation (Pulse / Scale Bounce on child tap)
    _touchBounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _touchScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.92)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.92, end: 1.09)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 45,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.09, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 25,
      ),
    ]).animate(_touchBounceController);

    // 3. Auto-Play Dual-Voice Story Narration + Calm Background Music immediately on open!
    if (widget.isActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.isActive) {
          _startAutoPlayStoryNarration();
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant VerticalVideoFeedItemWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.video.id != widget.video.id) {
      _story = widget.video.resolvedInteractiveStory;
      _activeCardIndex = 0;
      if (widget.isActive) {
        _startAutoPlayStoryNarration();
      } else {
        _stopStoryNarration();
      }
    } else if (oldWidget.isActive != widget.isActive) {
      if (widget.isActive) {
        _startAutoPlayStoryNarration();
      } else {
        _stopStoryNarration();
      }
    }
  }

  Future<void> _startAutoPlayStoryNarration({int startFromCard = 0}) async {
    final int mySession = ++_narrationSessionToken;
    if (!mounted) return;
    setState(() {
      _isNarrating = true;
      _activeCardIndex =
          startFromCard.clamp(0, max(0, _story.storyCards.length - 1));
    });

    if (_cardPageController.hasClients) {
      _cardPageController.jumpToPage(_activeCardIndex);
    }

    await CalmVoiceService.instance.narrateStoryCardsWithDualVoices(
      story: _story,
      playCalmBackgroundMusic: !_isMuted,
      onCardStarted: (cardIdx, card, outcome) {
        if (!mounted || mySession != _narrationSessionToken) return;
        setState(() {
          _activeCardIndex = cardIdx;
          _isNarrating = true;
        });
      },
      onCardCompletedAndAutoSwipe: (nextIdx) async {
        if (!mounted || mySession != _narrationSessionToken) return;
        setState(() {
          _activeCardIndex = nextIdx;
        });
        if (_cardPageController.hasClients) {
          await _cardPageController.animateToPage(
            nextIdx,
            duration: const Duration(milliseconds: 480),
            curve: Curves.easeInOutCubic,
          );
        }
      },
      onStoryFinished: () {
        if (!mounted || mySession != _narrationSessionToken) return;
        setState(() {
          _isNarrating = false;
        });
      },
    );
  }

  void _stopStoryNarration() {
    _narrationSessionToken++;
    CalmVoiceService.instance.stopSpeaking();
    CalmVoiceService.instance.stopCalmBackgroundMusic();
    if (mounted) {
      setState(() {
        _isNarrating = false;
      });
    }
  }

  Future<void> _onChildTouchCardMicroAnimation() async {
    HapticFeedback.selectionClick();
    _touchBounceController.forward(from: 0.0);
    if (!_isNarrating) {
      setState(() {
        _showTouchSparkle = true;
      });
      _startAutoPlayStoryNarration(startFromCard: _activeCardIndex);
      return;
    }
    final bool nowPaused =
        await CalmVoiceService.instance.toggleStoryPauseResume();
    if (!mounted) return;
    if (nowPaused) {
      _kenBurnsController.stop();
    } else if (!CalmVoiceService.isRunningInUnitTest &&
        !AppNetworkPolicyGuard.reduceMotionActive) {
      _kenBurnsController.repeat(reverse: true);
    }
    setState(() {
      _showTouchSparkle = true;
    });
    Future.delayed(const Duration(milliseconds: 650), () {
      if (mounted) {
        setState(() {
          _showTouchSparkle = false;
        });
      }
    });
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
    });
    CalmVoiceService.instance.setAssistantMuted(_isMuted);
    if (_isMuted) {
      CalmVoiceService.instance.stopCalmBackgroundMusic();
    } else if (widget.isActive) {
      _startAutoPlayStoryNarration(startFromCard: _activeCardIndex);
    }
  }

  @override
  void dispose() {
    _narrationSessionToken++;
    _cardPageController.dispose();
    _kenBurnsController.dispose();
    _touchBounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.video;
    final List<StoryImageCardPage> cards = _story.storyCards;
    final StoryImageCardPage currentCard = cards.isNotEmpty
        ? cards[_activeCardIndex.clamp(0, cards.length - 1)]
        : StoryImageCardPage(
            pageIndex: 0,
            imageIllustration: item.emoji,
            sceneTitle: item.title,
            narrationText: item.description,
            speakerRole: 'primary_assistant',
            speakerNameAr: 'المساعد الصوتي الرئيسي',
            speakerAvatar: '🎙️✨',
          );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _onChildTouchCardMicroAnimation,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: currentCard.gradientColors.length >= 2
                ? currentCard.gradientColors
                : [item.bgGradientStart, item.bgGradientEnd],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Interactive Animated Story Image Cards Carousel (`PageView`)
            PageView.builder(
              controller: _cardPageController,
              itemCount: max(1, cards.length),
              onPageChanged: (idx) {
                setState(() {
                  _activeCardIndex = idx;
                });
              },
              itemBuilder: (context, idx) {
                final card = cards.isNotEmpty ? cards[idx] : currentCard;
                final bool isHero = card.isSuperheroSpeaker;

                return AnimatedBuilder(
                  animation: Listenable.merge([
                    _kenBurnsController,
                    _touchBounceController,
                  ]),
                  builder: (context, _) {
                    final double t = _kenBurnsController.value;
                    final double kenBurnsScale =
                        1.0 + (t * (card.kenBurnsZoomTarget - 1.0));
                    final double floatingDy = sin(t * 2 * pi) * 7.0;
                    final double parallaxDx = (t - 0.5) * 24.0;
                    final double touchScale = _touchScaleAnimation.value;

                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        // 1. Background Parallax Layer (moves at slower ratio)
                        Transform.translate(
                          offset: Offset(-parallaxDx * 0.6, -floatingDy * 0.4),
                          child: Opacity(
                            opacity: 0.22,
                            child: Text(
                              card.parallaxLayerEmoji,
                              style: const TextStyle(
                                fontSize: 88,
                                letterSpacing: 18,
                              ),
                            ),
                          ),
                        ),

                        // 2. Main Animated Story Image Card (Ken Burns Zoom/Pan + Touch Bounce)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(22, 86, 68, 150),
                            child: Transform.translate(
                              offset: Offset(parallaxDx * 0.25, floatingDy),
                              child: Transform.scale(
                                scale: kenBurnsScale * touchScale,
                                child: Container(
                                  constraints:
                                      const BoxConstraints(maxWidth: 420),
                                  padding: const EdgeInsets.all(22),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        card.gradientColors.first
                                            .withOpacity(0.92),
                                        const Color(0xFF0F172A)
                                            .withOpacity(0.94),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(30),
                                    border: Border.all(
                                      color: isHero
                                          ? const Color(0xFFF59E0B)
                                          : const Color(0xFF14B8A6),
                                      width: 2.6,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: (isHero
                                                ? const Color(0xFFF59E0B)
                                                : const Color(0xFF14B8A6))
                                            .withOpacity(0.32),
                                        blurRadius: 24,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: SingleChildScrollView(
                                    physics: const BouncingScrollPhysics(),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                      // Dual-Voice Speaker Badge
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: isHero
                                              ? const Color(0xFFF59E0B)
                                                  .withOpacity(0.22)
                                              : const Color(0xFF14B8A6)
                                                  .withOpacity(0.22),
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          border: Border.all(
                                            color: isHero
                                                ? const Color(0xFFF59E0B)
                                                : const Color(0xFF14B8A6),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              card.speakerAvatar,
                                              style:
                                                  const TextStyle(fontSize: 16),
                                            ),
                                            const SizedBox(width: 6),
                                            Flexible(
                                              child: Text(
                                                card.speakerNameAr,
                                                style: TextStyle(
                                                  fontSize: 11.5,
                                                  fontWeight: FontWeight.bold,
                                                  color: isHero
                                                      ? const Color(0xFFFDE68A)
                                                      : const Color(0xFFA7F3D0),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(
                                        height: MediaQuery.of(context).size.height < 700
                                            ? 8
                                            : 16,
                                      ),

                                      // Animated Story Scene Illustration
                                      Text(
                                        card.imageIllustration,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: MediaQuery.of(context).size.height < 700
                                              ? 48
                                              : 68,
                                        ),
                                      ),
                                      if (CalmVoiceService.instance.isStoryNarrationPaused) ...[
                                        const SizedBox(height: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.black54,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                                color: const Color(0xFFF59E0B)),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.pause_circle_filled,
                                                  size: 16,
                                                  color: Color(0xFFFDE68A)),
                                              SizedBox(width: 6),
                                              Flexible(
                                                child: Text(
                                                  'متوقف مؤقتاً — المس الشاشة للمتابعة',
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontSize: 11.5,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFFFDE68A),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ] else if (_showTouchSparkle) ...[
                                        const SizedBox(height: 4),
                                        const Text(
                                          '✨ تفاعل رائع يا بطل! ✨',
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFFFDE68A),
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 12),

                                      // Scene Title
                                      Text(
                                        card.sceneTitle,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFFFDE68A),
                                        ),
                                      ),
                                      const SizedBox(height: 8),

                                      // Dual-Voice Synchronized Narration Text
                                      Text(
                                        card.narrationText,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          height: 1.55,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 14),

                                      // Scene Progress Dots & Background Music Indicator
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.music_note_rounded,
                                            size: 14,
                                            color: Color(0xFFA7F3D0),
                                          ),
                                          const SizedBox(width: 4),
                                          Flexible(
                                            child: Text(
                                              'موسيقى هادئة + سرد تلقائي (${_story.totalEstimatedMinutes} د)',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 10.5,
                                                color: Colors.white70,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),

            // Side Action Buttons
            Positioned(
              left: 10,
              bottom: 78,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _SideActionButton(
                    icon: item.isLiked ? Icons.favorite : Icons.favorite_border,
                    iconColor: item.isLiked ? Colors.redAccent : Colors.white,
                    label: '${item.likes}',
                    onTap: widget.onLikeTap,
                  ),
                  const SizedBox(height: 8),
                  _SideActionButton(
                    icon: Icons.mic_rounded,
                    iconColor: const Color(0xFFF59E0B),
                    label: 'ردد معي',
                    onTap: widget.onRepeatPhraseTap,
                  ),
                  const SizedBox(height: 8),
                  _SideActionButton(
                    icon: Icons.emoji_events_rounded,
                    iconColor: const Color(0xFF14B8A6),
                    label: 'نشاط البطل',
                    onTap: widget.onHeroActivityTap,
                  ),
                  const SizedBox(height: 8),
                  if (widget.onAcademyTap != null) ...[
                    _SideActionButton(
                      icon: Icons.school_rounded,
                      iconColor: const Color(0xFF10B981),
                      label: 'الأكاديمية',
                      onTap: widget.onAcademyTap!,
                    ),
                    const SizedBox(height: 8),
                  ],
                  _SideActionButton(
                    icon: Icons.psychology_rounded,
                    iconColor: const Color(0xFFC084FC),
                    label: 'ألعاب الذكاء',
                    onTap: widget.onBrainGamesTap,
                  ),
                  const SizedBox(height: 8),
                  _SideActionButton(
                    icon: Icons.assistant_rounded,
                    iconColor: const Color(0xFF38BDF8),
                    label: 'مساعد ذكي',
                    onTap: widget.onVoiceAssistantTap,
                  ),
                  const SizedBox(height: 8),
                  _SideActionButton(
                    icon: _isMuted ? Icons.volume_off : Icons.volume_up,
                    iconColor: Colors.white,
                    label: _isMuted ? 'صامت' : 'الصوت',
                    onTap: _toggleMute,
                  ),
                ],
              ),
            ),

            // Bottom Story Metadata & Progress Bar
            Positioned(
              right: 12,
              left: 68,
              bottom: 18,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF14B8A6).withOpacity(0.22),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: const Color(0xFF14B8A6).withOpacity(0.5)),
                        ),
                        child: Text(
                          VideoModel.getCategoryDisplayLabel(item.category),
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '🎂 ${item.ageGroup}',
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withOpacity(0.22),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: const Color(0xFFF59E0B).withOpacity(0.6)),
                        ),
                        child: Text(
                          '✨ ${item.qualityBadge}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFDE68A),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () => setState(
                        () => _showFullDescription = !_showFullDescription),
                    child: Text(
                      '🎯 الهدف التربوي: ${_story.pedagogicalConcept}',
                      maxLines: _showFullDescription ? 6 : 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11.5,
                        height: 1.35,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: widget.onRepeatPhraseTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withOpacity(0.16),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: const Color(0xFFF59E0B).withOpacity(0.45)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.mic,
                              size: 13, color: Color(0xFFFDE68A)),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'ردد معي: ${item.repeatPhrase}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFFDE68A),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Scene Progress Bar at bottom edge
            Positioned(
              right: 0,
              left: 0,
              bottom: 0,
              child: LinearProgressIndicator(
                value: cards.isEmpty
                    ? 1.0
                    : (_activeCardIndex + 1) / cards.length,
                minHeight: 4,
                backgroundColor: Colors.white12,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF14B8A6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SideActionButton extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;

  const _SideActionButton({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Tooltip(
        message: label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.45),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white30, width: 1.0),
                  ),
                  child: Icon(icon, color: iconColor, size: 19),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
