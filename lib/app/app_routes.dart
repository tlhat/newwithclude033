import 'package:flutter/material.dart' hide Text;
import 'package:haneen_kids_vod/core/regional/dialect_text.dart';
import 'package:haneen_kids_vod/features/home/screens/intro_tour_screen.dart';
import 'package:haneen_kids_vod/haneen_kids_exports.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String auth = '/auth';
  static const String childProfiles = '/child-profiles';
  static const String videoFeed = '/video-feed';
  static const String parentalStudio = '/parental-studio';
  static const String brainGames = '/brain-games';
  static const String haneenAcademy = '/haneen-academy';
}

class SplashRouterScreen extends StatefulWidget {
  final AppStateManager appState;
  const SplashRouterScreen({super.key, required this.appState});

  @override
  State<SplashRouterScreen> createState() => _SplashRouterScreenState();
}

class _SplashRouterScreenState extends State<SplashRouterScreen> {
  bool _splashTimerDone = false;
  bool _introSeen = false;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((SharedPreferences p) {
      if (mounted && (p.getBool(IntroTourScreen.seenKey) ?? false)) {
        setState(() => _introSeen = true);
      }
    });
    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted) {
        setState(() {
          _splashTimerDone = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.appState.isInitialized || !_splashTimerDone) {
      return const SplashScreen();
    }
    if (!widget.appState.googleGateDone && !_introSeen) {
      return IntroTourScreen(
        appState: widget.appState,
        onDone: () => setState(() => _introSeen = true),
      );
    }
    if (!widget.appState.googleGateDone) {
      return GoogleGateScreen(appState: widget.appState);
    }
    if (!widget.appState.onboardingCompleted ||
        widget.appState.currentAccount == null) {
      return OnboardingScreen(appState: widget.appState);
    }
    if (widget.appState.remoteLockActive) {
      return RemoteLockScreen(appState: widget.appState);
    }
    if (widget.appState.pinResetRequired) {
      return SetNewPinScreen(appState: widget.appState);
    }
    if (!widget.appState.pinUnlockedThisSession) {
      return PinUnlockScreen(appState: widget.appState);
    }
    if (widget.appState.childIntroPending) {
      return FastStartScreen(appState: widget.appState);
    }
    return MainNavigationShell(appState: widget.appState);
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1E1B4B), Color(0xFF0F172A)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const HaneenAppIconPreviewWidget(size: 96),
              const SizedBox(height: 18),
              Text(
                'حنين كيدز',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'أكاديمية حنين • القصص التفاعلية • الألعاب التعليمية (فيه محتوى مجاني ومحتوى بالاشتراك)',
                style: TextStyle(fontSize: 13.5, color: Colors.white70),
              ),
              const SizedBox(height: 24),
              const CircularProgressIndicator(color: Color(0xFF14B8A6)),
            ],
          ),
        ),
      ),
    );
  }
}
