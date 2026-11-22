import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:haneen_kids_vod/haneen_kids_exports.dart';

class AppInitializer {
  static Future<AppStateManager> initializeAppState() async {
    WidgetsFlutterBinding.ensureInitialized();
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    await LocalCredentialSecurityService.ensureKeystorePinPepperInitialized();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final AppStateManager appState = AppStateManager(prefs);
    await appState.initialize();
    return appState;
  }

  static Future<void> initializeAndRun() async {
    final AppStateManager appState = await initializeAppState();
    runApp(HaneenKidsApp(appState: appState));
  }
}
