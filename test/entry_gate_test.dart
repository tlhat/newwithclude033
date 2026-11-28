import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:haneen_kids_vod/haneen_kids_exports.dart';
import 'package:haneen_kids_vod/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Fake implements GoogleSignInGateway {
  @override
  Future<GoogleIdentity?> signIn() async => const GoogleIdentity(
      email: 'mum@example.com',
      displayName: 'Mum',
      id: '1',
      authHeaders: {'Authorization': 'Bearer t'});
  @override
  Future<GoogleIdentity?> signInSilently() => signIn();
  @override
  Future<void> signOut() async {}
}

void main() {
  testWidgets('Google screen, then setup, then PIN screen on next launch',
      (tester) async {
    tester.view.physicalSize = const Size(540, 1080);
    tester.view.devicePixelRatio = 1.5;
    addTearDown(tester.view.reset);
    GoogleAccountService.instance = GoogleAccountService(
      gateway: _Fake(),
      // no backup on Google yet
      client: MockClient((r) async => http.Response('{"files":[]}', 200)),
    );
    SharedPreferences.setMockInitialValues({});
    final app = AppStateManager(await SharedPreferences.getInstance());
    app.isInitialized = true;
    await tester.pumpWidget(ListenableBuilder(
        listenable: app,
        builder: (_, __) =>
            MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: SplashRouterScreen(appState: app))));
    await tester.pump(const Duration(milliseconds: 400));

    // 1. First launch: the intro tour shows before the Google gate.
    expect(find.text('تخطّي'), findsOneWidget);
    await tester.tap(find.text('تخطّي'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    // 2. Then the Google screen.
    expect(find.text('الدخول بحساب جوجل'), findsOneWidget);
    await tester.tap(find.text('الدخول بحساب جوجل'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    // 3. No backup: first-time setup (welcome).
    expect(app.linkedGoogleEmail, 'mum@example.com');
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('يلا نبدأ!'), findsOneWidget);

    // 4. A family exists after setup; the next launch asks for the PIN.
    await app.completeOneTimeInitialSetup(
        childName: 'سلمى',
        childAge: '5',
        dailyTimeLimit: 30,
        parentPasscode6Digits: '482917');
    app.pinUnlockedThisSession = false; // simulate a new launch
    app.notifyListeners();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('أهلاً بك يا سلمى!'), findsOneWidget);
    for (final d in '111111'.split('')) {
      await tester.tap(find.text(d).first);
      await tester.pump();
    }
    expect(find.text('الرمز غلط، جرّب تاني.'), findsOneWidget);
    expect(app.pinUnlockedThisSession, false);
    for (final d in '482917'.split('')) {
      await tester.tap(find.text(d).first);
      await tester.pump();
    }
    expect(app.pinUnlockedThisSession, true);
  });
}
