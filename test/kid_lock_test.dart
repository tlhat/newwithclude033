import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:haneen_kids_vod/haneen_kids_exports.dart';
import 'package:haneen_kids_vod/features/kidlock/kid_lock.dart';
import 'package:haneen_kids_vod/features/kidlock/kid_lock_card.dart';

class _FakeState extends Fake implements AppStateManager {
  @override
  ParentAccount? currentAccount;
  @override
  bool pinUnlockedThisSession = true;
}

void main() {
  test('strength labels are honest', () {
    expect(const KidLockStatus().strengthLabel, 'غير مفعّل');
    expect(const KidLockStatus(pinned: true).strengthLabel, contains('متوسط'));
    expect(const KidLockStatus(pinned: true, defaultHome: true).strengthLabel, contains('قوي'));
    expect(const KidLockStatus(deviceOwner: true).strengthLabel, contains('كامل'));
    expect(KidLockStatus.fromMap({'pinned': true, 'sdk': 34}).sdk, 34);
  });
  test('saved choice is restored without a phone', () async {
    SharedPreferences.setMockInitialValues({'kid_lock_on': true});
    await KidLock.restore();
    expect(KidLock.on.value, true);
    SharedPreferences.setMockInitialValues({});
    await KidLock.restore();
    expect(KidLock.on.value, false);
  });
  testWidgets('lock card renders', (t) async {
    SharedPreferences.setMockInitialValues({});
    t.view.physicalSize = const Size(400, 1800);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.resetPhysicalSize);
    await t.pumpWidget(MaterialApp(home: Scaffold(body: SingleChildScrollView(child: KidLockCard(appState: _FakeState())))));
    await t.pump(const Duration(milliseconds: 200));
    expect(find.textContaining('قفل الطفل'), findsWidgets);
    expect(find.textContaining('docs/KID_LOCK.md'), findsOneWidget);
    expect(t.takeException(), isNull);
  });
}
