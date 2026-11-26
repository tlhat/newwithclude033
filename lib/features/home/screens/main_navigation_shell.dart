import 'package:shared_preferences/shared_preferences.dart';
import 'package:haneen_kids_vod/core/regional/dialect_pack.dart';
import 'package:haneen_kids_vod/core/services/app_rating_service.dart';
import 'package:haneen_kids_vod/features/home/screens/my_path_screen.dart';
import 'package:flutter/material.dart' hide Text;
import 'package:haneen_kids_vod/core/regional/dialect_text.dart';
import 'package:haneen_kids_vod/features/kidlock/kid_lock.dart';
import 'package:haneen_kids_vod/features/home/screens/entry_gate_screens.dart' show startForgotPin;
import 'package:haneen_kids_vod/features/subscriptions/screens/subscriptions_tab.dart';
import 'package:haneen_kids_vod/features/development/dev_cards.dart';
import 'package:haneen_kids_vod/l10n/app_localizations.dart';
import 'package:haneen_kids_vod/haneen_kids_exports.dart';

enum MainNavDestination {
  stories,
  academy,
  games,
  achievements,
  account,
  subscriptions,
  parentGate,
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
    _loadPathBadge();
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
                : '🔥 ${days} أيام متتالية! برافو يا بطل +١ ⭐',
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
  bool _showPathBadge = false;

  Future<void> _loadPathBadge() async {
    final p = await SharedPreferences.getInstance();
    if (mounted && !(p.getBool('path_badge_seen') ?? false)) {
      setState(() => _showPathBadge = true);
    }
  }

  Future<void> _dismissPathBadge() async {
    if (!_showPathBadge) return;
    setState(() => _showPathBadge = false);
    final p = await SharedPreferences.getInstance();
    await p.setBool('path_badge_seen', true);
  }

  void _selectIndex(int idx) {
    if (!mounted) return;
    if (idx == _currentIndex) {
      // Tapping the section you are already in: stop and replay its intro.
      SectionIntroService.instance.playForTab(idx);
      return;
    }
    CalmVoiceService.instance.stopAllAudioImmediatelyForParentalGate();
    setState(() {
      _prevIndex = _currentIndex;
      _currentIndex = idx;
    });
    SectionIntroService.instance.playForTab(idx);
    if (idx == MainNavDestination.parentGate.index) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _openParentalGate();
      });
    }
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
                onPressed: () {
                  Navigator.pop(ctx);
                  startForgotPin(context, widget.appState);
                },
                child: const Text('نسيت رمز البين'),
              ),
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

  final Set<int> _visited = <int>{};
  final Map<int, Widget> _pageCache = <int, Widget>{};
  int _prevIndex = -1;

  Widget _buildPage(int i) {
    switch (i) {
      case 0:
        return VerticalVideoFeedPlayerScreen(
          appState: widget.appState,
          embeddedInShell: true,
          tabActive: _currentIndex == MainNavDestination.stories.index,
          onNavigateToGames: () => _switchTo(MainNavDestination.games),
          onNavigateToAcademy: () => _switchTo(MainNavDestination.academy),
        );
      case 1:
        return HaneenAcademyScreen(appState: widget.appState);
      case 2:
        return DevGate(
            appState: widget.appState,
            active: _currentIndex == MainNavDestination.games.index,
            child: BrainGamesHubScreen(appState: widget.appState));
      case 3:
        return AchievementsCenterTab(
          appState: widget.appState,
          onExploreAcademy: () => _switchTo(MainNavDestination.academy),
        );
      case 5:
        return const SubscriptionsTab();
      case 6:
        return _ParentGatePage(onOpen: _openParentalGate);
      default:
        return ChildAccountTab(
          appState: widget.appState,
          onOpenParentalGate: _openParentalGate,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // Speed: a section is built the first time it is opened, and when you
    // switch only the section you leave and the one you enter are rebuilt.
    // The other sections reuse their old widget, so a tab change no longer
    // rebuilds all five heavy screens.
    _visited.add(_currentIndex);
    final List<Widget> pages = <Widget>[];
    for (int i = 0; i < 7; i++) {
      if (!_visited.contains(i)) {
        pages.add(const SizedBox.shrink());
        continue;
      }
      if (i == _currentIndex || i == _prevIndex || _pageCache[i] == null) {
        _pageCache[i] = RepaintBoundary(child: _buildPage(i));
      }
      pages.add(_pageCache[i]!);
    }

    return ValueListenableBuilder<bool>(
      valueListenable: KidLock.on,
      // Child lock: the Back button cannot leave the app from the root screen.
      builder: (context, locked, child) => PopScope(canPop: !locked, child: child!),
      child: Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: _currentIndex <= 2
          ? FloatingActionButton.extended(
              heroTag: 'my_path_fab',
              onPressed: () {
                CalmVoiceService.instance.stopSpeaking();
                _dismissPathBadge();
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => MyPathScreen(
                        appState: widget.appState,
                        onGoToTab: _selectIndex)));
              },
              icon: const Icon(Icons.explore_rounded),
              label: Row(mainAxisSize: MainAxisSize.min, children: [
                const Text('مساري'),
                if (_showPathBadge) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                        color: const Color(0xFFFDE68A),
                        borderRadius: BorderRadius.circular(10)),
                    child: Text(DialectPacks.t('path.badge', 'اضغط هنا، مخصص ليك'),
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF78350F))),
                  ),
                ],
              ]),
            )
          : null,
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
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
          const NavigationDestination(
            icon: Icon(Icons.workspace_premium_outlined),
            selectedIcon: Icon(Icons.workspace_premium_rounded),
            label: 'الاشتراك',
          ),
          const NavigationDestination(
            icon: Icon(Icons.admin_panel_settings_outlined),
            selectedIcon: Icon(Icons.admin_panel_settings_rounded),
            label: 'بوابة الوالدين',
          ),
        ],
      ),
    ));
  }
}

/// Top-level "بوابة الوالدين" tab. The PIN is asked when the tab opens, and
/// again from the button here.
class _ParentGatePage extends StatelessWidget {
  final VoidCallback onOpen;
  const _ParentGatePage({required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('🔐', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 10),
            const Text('بوابة الوالدين',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            const Text(
                'ضوابط الطفل، تقرير التقدم، الحساب، الدعم والتقييم. محمية بالرمز السري.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.white70)),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: onOpen,
              icon: const Icon(Icons.lock_open_rounded),
              label: const Text('فتح بالرمز السري'),
            ),
          ]),
        ),
      ),
    );
  }
}
