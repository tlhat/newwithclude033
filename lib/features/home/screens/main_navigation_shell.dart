import 'package:haneen_kids_vod/core/services/app_rating_service.dart';
import 'package:haneen_kids_vod/features/home/screens/my_path_screen.dart';
import 'package:flutter/material.dart';
import 'package:haneen_kids_vod/l10n/app_localizations.dart';
import 'package:haneen_kids_vod/haneen_kids_exports.dart';

enum MainNavDestination {
  stories,
  academy,
  games,
  achievements,
  account,
}

/// 5-Destination Bottom Navigation Shell (Stage P0 / Sprint 2 & 3):
/// Localized via AppLocalizations with automatic RTL/LTR support.
class MainNavigationShell extends StatefulWidget {
  final AppStateManager appState;
  final MainNavDestination initialDestination;

  const MainNavigationShell({
    super.key,
    required this.appState,
    this.initialDestination = MainNavDestination.stories,
  });

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialDestination.index;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) SectionIntroService.instance.playForTab(_currentIndex);
      AppRatingService.instance.maybeAsk();
      widget.appState.claimDailyStreak().then((int days) {
        if (!mounted || days <= 0) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: const Color(0xFFF59E0B),
          duration: const Duration(seconds: 4),
          content: Text(
            days == 1
                ? '🔥 أهلاً بك! بداية مغامرة جديدة +١ ⭐'
                : '🔥 $days أيام متتالية! برافو يا بطل +١ ⭐',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ));
      });
    });
  }

  /// Every section change goes through here. The sections live in an
  /// IndexedStack, so a story keeps talking in the background unless we stop
  /// it: narration, speech and music are stopped when the section changes.
  void _selectIndex(int idx) {
    if (!mounted) return;
    if (idx == _currentIndex) {
      // Tapping the section you are already in: stop and replay its intro.
      SectionIntroService.instance.playForTab(idx);
      return;
    }
    CalmVoiceService.instance.stopAllAudioImmediatelyForParentalGate();
    setState(() {
      _currentIndex = idx;
    });
    SectionIntroService.instance.playForTab(idx);
  }

  void _switchTo(MainNavDestination dest) => _selectIndex(dest.index);

  Future<void> _openParentalGate() async {
    await CalmVoiceService.instance.stopAllAudioImmediatelyForParentalGate();
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    final TextEditingController pinCtrl = TextEditingController();
    String? err;
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: Text(l10n.parentGateTitle),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.parentGatePrompt),
                const SizedBox(height: 12),
                TextField(
                  controller: pinCtrl,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: ParentAccount.kUnifiedParentalPinLength,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: l10n.parentGateHint,
                    counterText: '',
                  ),
                ),
                if (err != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    err!,
                    style:
                        const TextStyle(color: Colors.redAccent, fontSize: 12),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(l10n.cancelButton),
              ),
              ElevatedButton(
                onPressed: () {
                  final account = widget.appState.currentAccount;
                  if (account != null &&
                      account.verifyParentalPin(pinCtrl.text.trim())) {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ParentalStudioScreen(
                          appState: widget.appState,
                        ),
                      ),
                    );
                  } else {
                    setDialogState(() {
                      err = l10n.parentGateError;
                    });
                  }
                },
                child: Text(l10n.enterButton),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final List<Widget> pages = [
      VerticalVideoFeedPlayerScreen(
        appState: widget.appState,
        embeddedInShell: true,
        tabActive: _currentIndex == MainNavDestination.stories.index,
        onNavigateToGames: () => _switchTo(MainNavDestination.games),
        onNavigateToAcademy: () => _switchTo(MainNavDestination.academy),
      ),
      HaneenAcademyScreen(appState: widget.appState),
      BrainGamesHubScreen(appState: widget.appState),
      AchievementsCenterTab(
        appState: widget.appState,
        onExploreAcademy: () => _switchTo(MainNavDestination.academy),
      ),
      ChildAccountTab(
        appState: widget.appState,
        onOpenParentalGate: _openParentalGate,
      ),
    ];

    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: _currentIndex <= 2
          ? FloatingActionButton.extended(
              heroTag: 'my_path_fab',
              onPressed: () {
                CalmVoiceService.instance.stopSpeaking();
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => MyPathScreen(
                        appState: widget.appState,
                        onGoToTab: _selectIndex)));
              },
              icon: const Icon(Icons.explore_rounded),
              label: const Text('مساري'),
            )
          : null,
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _selectIndex,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.auto_stories_outlined),
            selectedIcon: const Icon(Icons.auto_stories_rounded),
            label: l10n.navStories,
          ),
          NavigationDestination(
            icon: const Icon(Icons.school_outlined),
            selectedIcon: const Icon(Icons.school_rounded),
            label: l10n.navAcademy,
          ),
          NavigationDestination(
            icon: const Icon(Icons.extension_outlined),
            selectedIcon: const Icon(Icons.extension_rounded),
            label: l10n.navGames,
          ),
          NavigationDestination(
            icon: const Icon(Icons.emoji_events_outlined),
            selectedIcon: const Icon(Icons.emoji_events_rounded),
            label: l10n.navAchievements,
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline_rounded),
            selectedIcon: const Icon(Icons.person_rounded),
            label: l10n.navAccount,
          ),
        ],
      ),
    );
  }
}
