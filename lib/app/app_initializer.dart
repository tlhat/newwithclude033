import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:haneen_kids_vod/haneen_kids_exports.dart';
import 'package:haneen_kids_vod/features/kidlock/kid_lock.dart';
import 'package:haneen_kids_vod/features/billing/billing_service.dart';
import 'package:haneen_kids_vod/features/home/path_progress.dart';

class AppInitializer {
  static Future<AppStateManager> initializeAppState() async {
    WidgetsFlutterBinding.ensureInitialized();
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    await LocalCredentialSecurityService.ensureKeystorePinPepperInitialized();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final AppStateManager appState = AppStateManager(prefs);
    await appState.initialize();
    try {
      await KidLock.restore();
    } catch (_) {}
    PathProgress.activeChildIdProvider =
        () => appState.currentAccount?.activeChild.id;
    // Do not block start-up on the store.
    BillingService.instance.init();
    return appState;
  }

  static Future<void> initializeAndRun() async {
    final AppStateManager appState = await initializeAppState();
    runApp(HaneenKidsApp(appState: appState));
  }
}
