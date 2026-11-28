import 'dart:async';
import 'package:flutter/material.dart' hide Text;
import 'package:haneen_kids_vod/core/regional/dialect_text.dart';
import 'package:haneen_kids_vod/haneen_kids_exports.dart';
import 'package:haneen_kids_vod/l10n/app_localizations.dart';

class CuteSuperheroCompanionBanner extends StatefulWidget {
  final AppStateManager appState;
  final bool compactMode;
  final String? customCheerMessage;
  final int reactionTick;
  final bool reactionIsCorrect;

  const CuteSuperheroCompanionBanner({
    super.key,
    required this.appState,
    this.compactMode = false,
    this.customCheerMessage,
    this.reactionTick = 0,
    this.reactionIsCorrect = true,
  });

  @override
  State<CuteSuperheroCompanionBanner> createState() =>
      _CuteSuperheroCompanionBannerState();
}

class _CuteSuperheroCompanionBannerState
    extends State<CuteSuperheroCompanionBanner> {
  int _heroIndex = 0;
  int _alertIndex = 0;
  bool _isJumping = false;
  final GlobalKey<HaneenCompanionAvatarWidgetState> _avatarKey =
      GlobalKey<HaneenCompanionAvatarWidgetState>();

  @override
  void didUpdateWidget(covariant CuteSuperheroCompanionBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.reactionTick != oldWidget.reactionTick) {
      final avatar = _avatarKey.currentState;
      if (widget.reactionIsCorrect) {
        avatar?.triggerCelebrateReaction();
      } else {
        avatar?.triggerHint();
      }
    }
  }

  void _triggerHeroWaveAndCheer() {
    setState(() {
      _alertIndex = (_alertIndex + 1) % 3;
      _isJumping = true;
    });
    final child = widget.appState.currentAccount?.activeChild;
    if (child != null) {
      final bool isAr = Localizations.localeOf(context).languageCode == 'ar';
      final aiRec =
          EducationalAiTutorService.analyzeAndRecommendForChild(child);
      CalmVoiceService.instance.speakCalmly(
        widget.customCheerMessage ??
            (isAr
                ? aiRec.haneenInteractiveVoicePromptAr
                : AppLocalizations.of(context).companionGreeting(child.name)),
        allowSpeechForRepeatGame: true,
      );
    }
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) setState(() => _isJumping = false);
    });
  }

  void _openHeroFriendsGalleryModal() {
    showModalBottomSheet(
      context: context,
    useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('🦸‍♂️✨', style: TextStyle(fontSize: 28)),
                      SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'حنين وأصدقاؤك الأبطال الخارقون (تفاعل صوتي و3D)',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'اضغط على حنين أو أي بطل ليستمع طفلك للتشجيع الصوتي والنصائح الذكية!',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C63FF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CharacterStudioScreen(
                                appState: widget.appState),
                          ),
                        );
                      },
                      icon: const Icon(Icons.palette_rounded, size: 18),
                      label: Text(
                        'غرفة تخصيص شخصيتي (ولد / بنت) 🎨',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 340,
                    child: ListView.builder(
                      itemCount: kCuteSuperheroCharacters.length,
                      itemBuilder: (ctx, i) {
                        final h = kCuteSuperheroCharacters[i];
                        final bool isSelected = _heroIndex == i;
                        final String alertMsg = h.encouragingAlerts[
                            _alertIndex % h.encouragingAlerts.length];
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _heroIndex = i;
                              _isJumping = true;
                            });
                            CalmVoiceService.instance.speakCalmly(
                              '${h.nameAr} يقول لك: ${alertMsg}',
                              allowSpeechForRepeatGame: true,
                            );
                            setModalState(() {});
                            Future.delayed(const Duration(milliseconds: 700),
                                () {
                              if (mounted) setState(() => _isJumping = false);
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  h.primaryColor.withOpacity(0.28),
                                  h.secondaryColor.withOpacity(0.18),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: isSelected
                                    ? h.primaryColor
                                    : Colors.white12,
                                width: isSelected ? 2.5 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Interactive3DSuperheroAvatar(
                                  hero: h,
                                  size: 64,
                                  isJumping: isSelected,
                                  onTap: () {
                                    setState(() {
                                      _heroIndex = i;
                                      _isJumping = true;
                                    });
                                    setModalState(() {});
                                  },
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              h.nameAr,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.black26,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              '🎙️ ناطق',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: h.primaryColor,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        '💬 «$alertMsg»',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFFFDE68A),
                                          height: 1.4,
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
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final child = widget.appState.currentAccount?.activeChild;
    final bool isCustomCompanion = _heroIndex == 0 && child != null;
    final hero =
        kCuteSuperheroCharacters[_heroIndex % kCuteSuperheroCharacters.length];
    final String companionName = isCustomCompanion
        ? (child.name.isNotEmpty ? 'شخصية ${child.name}' : 'شخصيتي المرافقة')
        : hero.nameAr;
    final bool isAr = Localizations.localeOf(context).languageCode == 'ar';
    String? greeting;
    if (isCustomCompanion) {
      final l10n = AppLocalizations.of(context);
      greeting = l10n.companionGreeting(child.name);
      if (!widget.compactMode) {
        final rec =
            EducationalAiTutorService.analyzeAndRecommendForChild(child);
        final String recommendedGameTitle =
            isAr ? rec.recommendedGameTitleAr : rec.recommendedGameTitleEn;
        greeting =
            '$greeting\n${isAr ? 'اقتراح اليوم' : 'Today\'s pick'}: $recommendedGameTitle';
      }
    }
    final String message = widget.customCheerMessage ??
        greeting ??
        hero.encouragingAlerts[_alertIndex % hero.encouragingAlerts.length];

    return GestureDetector(
      onTap: _openHeroFriendsGalleryModal,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: widget.compactMode ? 9 : 12,
          vertical: widget.compactMode ? 3 : 8,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              hero.primaryColor.withOpacity(widget.compactMode ? 0.26 : 0.34),
              hero.secondaryColor.withOpacity(widget.compactMode ? 0.18 : 0.25),
              const Color(0xFF1E293B)
                  .withOpacity(widget.compactMode ? 0.80 : 0.92),
            ],
          ),
          borderRadius: BorderRadius.circular(widget.compactMode ? 14 : 20),
          border: Border.all(
            color: hero.primaryColor.withOpacity(0.7),
            width: widget.compactMode ? 1.0 : 1.5,
          ),
        ),
        child: Row(
          children: [
            isCustomCompanion
                ? HaneenCompanionAvatarWidget(
                    key: _avatarKey,
                    avatar: child.companionAvatar,
                    mode: CompanionDisplayMode.bust,
                    size: widget.compactMode ? 36 : 56,
                    isCelebrating: _isJumping,
                    animateBreathing: true,
                    onTap: _triggerHeroWaveAndCheer,
                  )
                : Interactive3DSuperheroAvatar(
                    hero: hero,
                    size: widget.compactMode ? 36 : 56,
                    isJumping: _isJumping,
                    onTap: _triggerHeroWaveAndCheer,
                  ),
            SizedBox(width: widget.compactMode ? 8 : 12),
            Expanded(
              child: GestureDetector(
                onTap: _triggerHeroWaveAndCheer,
                child: widget.compactMode
                    ? Text(
                        '👋 $companionName: $message',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Text(
                                '👋 $companionName',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFFDE68A),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  isCustomCompanion
                                      ? '• رفيقك الدائم'
                                      : '• ${hero.titleBadge}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.white70,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '💬 $message',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: 'استمع لتوجيه حنين الصوتي الذكي',
              onPressed: _triggerHeroWaveAndCheer,
              icon: const Icon(
                Icons.record_voice_over_rounded,
                size: 18,
                color: Color(0xFFA7F3D0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
