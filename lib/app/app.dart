import 'package:flutter/material.dart';
import 'package:haneen_kids_vod/l10n/app_localizations.dart';
import 'package:haneen_kids_vod/haneen_kids_exports.dart';
import 'package:haneen_kids_vod/features/billing/online_gate.dart';
import 'package:haneen_kids_vod/app/pin_relock_policy.dart';

class HaneenKidsApp extends StatefulWidget {
  final AppStateManager appState;
  const HaneenKidsApp({super.key, required this.appState});

  @override
  State<HaneenKidsApp> createState() => _HaneenKidsAppState();
}

class _HaneenKidsAppState extends State<HaneenKidsApp>
    with WidgetsBindingObserver {
  final GlobalKey<NavigatorState> _navKey = GlobalKey<NavigatorState>();
  DateTime? _pausedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    final bool isBackground = state != AppLifecycleState.resumed;
    if (state == AppLifecycleState.paused) {
      _pausedAt ??= DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      final app = widget.appState;
      if (PinRelockPolicy.shouldRelock(
        pausedAt: _pausedAt,
        now: DateTime.now(),
        pinRequiredAtAll: app.pinUnlockedThisSession && app.currentAccount != null,
      )) {
        _navKey.currentState?.popUntil((r) => r.isFirst);
        app.relockPin();
      }
      _pausedAt = null;
    }
    widget.appState.setAppInBackground(isBackground);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.appState,
      builder: (context, _) {
        final activeChild = widget.appState.currentAccount?.activeChild;
        final bool highContrast = activeChild?.highContrastMode ?? false;

        return MaterialApp(
          navigatorKey: _navKey,
          title: 'حنين كيدز',
          debugShowCheckedModeBanner: false,
          locale: widget.appState.localeController.uiLocale,
          supportedLocales: const [Locale('ar')],
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          theme: AppTheme.buildTheme(
            highContrast: highContrast,
            isDarkMode: widget.appState.isDarkMode,
          ),
          builder: (context, child) {
            final mediaQuery = MediaQuery.of(context);
            final clampedScaler = mediaQuery.textScaler.clamp(
              minScaleFactor: 0.92,
              maxScaleFactor: 1.22,
            );
            return MediaQuery(
              data: mediaQuery.copyWith(textScaler: clampedScaler),
              child: OnlineGate(
                child: StarRewardHost(
                  appState: widget.appState,
                  child: child!,
                ),
              ),
            );
          },
          home: SplashRouterScreen(appState: widget.appState),
        );
      },
    );
  }
}
