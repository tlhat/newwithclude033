import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:haneen_kids_vod/haneen_kids_exports.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeGateway implements GoogleSignInGateway {
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
  test('backup is created, then found and downloaded', () async {
    String? stored;
    bool created = false;
    final client = MockClient((req) async {
      if (req.method == 'GET' && req.url.queryParameters['alt'] == 'media') {
        return http.Response.bytes(utf8.encode(stored!), 200);
      }
      if (req.method == 'GET') {
        return http.Response(
            jsonEncode({'files': created ? [{'id': 'f1'}] : []}), 200);
      }
      created = true;
      stored = '{"x":"حنين"}';
      return http.Response('{}', 200);
    });
    final svc = GoogleAccountService(gateway: _FakeGateway(), client: client);
    final who = (await svc.signIn())!;
    expect(await svc.downloadBackup(who), isNull);
    await svc.uploadBackup(who, '{"x":"حنين"}');
    expect(await svc.downloadBackup(who), '{"x":"حنين"}');
  });

  test('family survives export then restore on a fresh phone', () async {
    SharedPreferences.setMockInitialValues({});
    final a = AppStateManager(await SharedPreferences.getInstance());
    await a.completeOneTimeInitialSetup(
        childName: 'سلمى',
        childAge: '5',
        dailyTimeLimit: 30,
        parentPasscode6Digits: '482917',
        gender: 'girl');
    final backup = a.exportBackupJson();

    SharedPreferences.setMockInitialValues({});
    final b = AppStateManager(await SharedPreferences.getInstance());
    expect(await b.restoreFromBackupJson(backup), isNull);
    expect(b.onboardingCompleted, true);
    expect(b.currentAccount?.activeChild?.name, 'سلمى');
    expect(await b.restoreFromBackupJson('not json'), isNotNull);
  });
}
