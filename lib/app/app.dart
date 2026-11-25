import 'package:haneen_kids_vod/core/localization/tr.dart';
import 'package:flutter/material.dart';
import 'package:haneen_kids_vod/l10n/app_localizations.dart';
import 'package:haneen_kids_vod/haneen_kids_exports.dart';

class HaneenKidsApp extends StatefulWidget {
  final AppStateManager appState;
  const HaneenKidsApp({super.key, required this.appState});

  @override
  State<HaneenKidsApp> createState() => _HaneenKidsAppState();
}

class _HaneenKidsAppState extends State<HaneenKidsApp>
    with WidgetsBindingObserver {
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
    widget.appState.setAppInBackground(isBackground);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.appState,
      builder: (context, _) {
        final activeChild = widget.appState.currentAccount?.activeChild;
        final bool highContrast = activeChild?.highContrastMode ?? false;

        Tr.lang = widget.appState.localeController.uiLanguageCode;
        return MaterialApp(
          key: ValueKey<String>(Tr.lang),
          title: 'Haneen Kids',
          debugShowCheckedModeBanner: false,
          locale: widget.appState.localeController.uiLocale,
          supportedLocales: AppLocalizations.supportedLocales,
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
              child: StarRewardHost(
                appState: widget.appState,
                child: child!,
              ),
            );
          },
          home: SplashRouterScreen(appState: widget.appState),
        );
      },
    );
  }
}
