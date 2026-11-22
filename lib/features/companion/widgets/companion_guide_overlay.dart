import 'dart:async';
import 'package:flutter/material.dart';
import 'package:haneen_kids_vod/app/app_theme.dart';
import 'package:haneen_kids_vod/core/services/calm_voice_service.dart';
import 'package:haneen_kids_vod/features/companion/models/avatar_customization_model.dart';
import 'package:haneen_kids_vod/features/companion/screens/character_studio_screen.dart';
import 'package:haneen_kids_vod/features/companion/widgets/haneen_companion_avatar_widget.dart';
import 'package:haneen_kids_vod/features/companion/widgets/haneen_rive_avatar_widget.dart';
import 'package:haneen_kids_vod/l10n/app_localizations.dart';
import 'package:haneen_kids_vod/shared/components/app_state_manager.dart';

/// Floating interactive companion guide overlay.
/// Accompanies the child across screens (Home, Academy, Brain Games),
/// offering personalized hints, cheers, and direct access to Character Studio.
class CompanionGuideOverlay extends StatefulWidget {
  final AppStateManager appState;
  final String? customMessage;
  final VoidCallback? onCustomTap;
  final bool compactMode;

  const CompanionGuideOverlay({
    super.key,
    required this.appState,
    this.customMessage,
    this.onCustomTap,
    this.compactMode = false,
  });

  @override
  State<CompanionGuideOverlay> createState() => _CompanionGuideOverlayState();
}

class _CompanionGuideOverlayState extends State<CompanionGuideOverlay> {
  final GlobalKey<HaneenCompanionAvatarWidgetState> _avatarKey =
      GlobalKey<HaneenCompanionAvatarWidgetState>();

  bool _showBubble = true;
  Timer? _bubbleDismissTimer;

  @override
  void initState() {
    super.initState();
    _resetBubbleTimer();
  }

  @override
  void didUpdateWidget(covariant CompanionGuideOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.customMessage != oldWidget.customMessage) {
      setState(() => _showBubble = true);
      _resetBubbleTimer();
    }
  }

  @override
  void dispose() {
    _bubbleDismissTimer?.cancel();
    super.dispose();
  }

  void _resetBubbleTimer() {
    _bubbleDismissTimer?.cancel();
    _bubbleDismissTimer = Timer(const Duration(seconds: 8), () {
      if (mounted) setState(() => _showBubble = false);
    });
  }

  void _handleTap() {
    setState(() => _showBubble = true);
    _resetBubbleTimer();
    _avatarKey.currentState?.triggerWave();

    final child = widget.appState.currentAccount?.activeChild;
    final l10n = AppLocalizations.of(context);
    final String textToSpeak = widget.customMessage ??
        (child != null
            ? l10n.companionGreeting(child.name)
            : l10n.companionExplorePrompt);

    CalmVoiceService.instance.speakCalmly(
      textToSpeak,
      allowSpeechForRepeatGame: true,
    );

    widget.onCustomTap?.call();
  }

  void _openCharacterStudio() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CharacterStudioScreen(appState: widget.appState),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final child = widget.appState.currentAccount?.activeChild;
    final avatar = child?.companionAvatar ?? AvatarCustomizationModel();
    final l10n = AppLocalizations.of(context);
    final String message = widget.customMessage ??
        (child != null
            ? l10n.companionGreeting(child.name)
            : l10n.companionExplorePrompt);

    final double avatarSize = widget.compactMode ? 48.0 : 60.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Interactive Avatar in Bust Mode
          Stack(
            clipBehavior: Clip.none,
            children: [
              GestureDetector(
                onTap: _handleTap,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppDesignTokens.primaryPurple.withOpacity(0.35),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: HaneenRiveAvatarWidget(
                    key: _avatarKey,
                    avatar: avatar,
                    mode: CompanionDisplayMode.bust,
                    size: avatarSize,
                    animateBreathing: true,
                  ),
                ),
              ),
              // Mini Studio Edit Button
              Positioned(
                bottom: -2,
                right: -2,
                child: GestureDetector(
                  onTap: _openCharacterStudio,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppDesignTokens.primaryPurple,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: const Icon(
                      Icons.palette_rounded,
                      size: 11,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(width: 8),

          // Speech Bubble
          if (_showBubble)
            Flexible(
              child: GestureDetector(
                onTap: _handleTap,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 240),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B).withOpacity(0.95),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppDesignTokens.primaryPurple.withOpacity(0.6),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          message,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.volume_up_rounded,
                        size: 14,
                        color: Color(0xFFA7F3D0),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
