import 'package:flutter_test/flutter_test.dart';
import 'package:haneen_kids_vod/haneen_kids_exports.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('fast start: PIN only, no limit, intro pending then finished', () async {
    SharedPreferences.setMockInitialValues({});
    final a = AppStateManager(await SharedPreferences.getInstance());
    final err = await a.completeOneTimeInitialSetup(
        childName: 'بطل',
        childAge: '3–4 سنوات',
        dailyTimeLimit: 0,
        parentPasscode6Digits: '482917',
        childIntroPending: true);
    expect(err, isNull);
    expect(a.childIntroPending, true);
    expect(a.currentAccount!.activeChild.dailyTimeLimit, 0);
    await a.finishChildIntro(name: 'سلمى', age: '4–5 سنوات', gender: 'girl');
    expect(a.childIntroPending, false);
    expect(a.currentAccount!.activeChild.name, 'سلمى');
    expect(a.currentAccount!.activeChild.age, '4–5 سنوات');
    expect(a.currentAccount!.activeChild.gender, 'girl');
  });
}
