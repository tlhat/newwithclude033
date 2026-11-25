import 'package:flutter_test/flutter_test.dart';
import 'package:haneen_kids_vod/features/development/dev_core.dart';
import 'package:haneen_kids_vod/features/exercises/exercise_models.dart';

void main() {
  test('age string to band', () {
    expect(bandFromAgeString('2–4 سنوات'), AgeBand.m18to36);
    expect(bandFromAgeString('3–6 سنوات'), AgeBand.y3to5);
    expect(bandFromAgeString('6–10 سنوات'), AgeBand.y6to8);
  });
  test('stages need separate days and spacing', () {
    final d = DevData();
    final t0 = DateTime(2026, 3, 1);
    for (int i = 0; i < 5; i++) d.logAttempt('addition', 'a$i', true, t0);
    expect(d.stateOf('addition').stage, Stage.learning);
    for (int i = 0; i < 3; i++) d.logAttempt('addition', 'b$i', true, t0.add(const Duration(days: 1)));
    expect(d.stateOf('addition').stage, Stage.confident);
    d.logTransfer('addition', true, t0.add(const Duration(days: 2)));
    expect(d.stateOf('addition').stage, Stage.confident);
    for (int i = 0; i < 3; i++) d.logAttempt('addition', 'c$i', true, t0.add(const Duration(days: 5)));
    expect(d.stateOf('addition').stage, Stage.solid);
    expect(d.stateOf('addition').confidence, 1);
  });
  test('one lucky day is not mastery', () {
    final d = DevData();
    for (int i = 0; i < 9; i++) d.logAttempt('jobs', 'j$i', true, DateTime(2026, 3, 1));
    expect(d.stateOf('jobs').stage, Stage.learning);
  });
  test('json round trip', () {
    final d = DevData()..coUse = true..capOverride = 15..bandOverride = AgeBand.y9to12;
    d.logAttempt('jobs', 'j1', false, DateTime(2026, 3, 1));
    d.notes.add({'d': '2026-03-01', 'area': 'language', 't': 'قال كلمة جديدة'});
    final q = DevData.fromJson(d.toJson());
    expect(q.coUse, true);
    expect(q.capOverride, 15);
    expect(q.bandOverride, AgeBand.y9to12);
    expect(q.days['jobs']!['2026-03-01'], [0, 1, 0]);
    expect(q.notes.single['t'], 'قال كلمة جديدة');
  });
  test('screen gate: 18-36 months off by default, cap applies', () {
    expect(gateState(AgeBand.m18to36, false, 20, 0), GateState.offByDefault);
    expect(gateState(AgeBand.m18to36, true, 20, 5), GateState.ok);
    expect(gateState(AgeBand.m18to36, true, 20, 20), GateState.timeUp);
    expect(gateState(AgeBand.y6to8, false, 0, 500), GateState.ok);
  });
  test('transfer picks unseen first', () {
    final r = pickTransfer<String>(['a', 'b', 'c', 'd'], (x) => x, {'a', 'b'}, 3);
    expect(r, ['c', 'd', 'a']);
  });
  test('gentle adaptivity: one miss never lowers level', () {
    final p = ExerciseProgress();
    final e = Exercise.parseList('[{"id":"x1","skill":"s","type":"choice","level":1,"prompt":"p","data":{"options":["a","b"],"answer":0}}]').first;
    for (int i = 0; i < 3; i++) p.record(e, true, DateTime(2026, 1, 1));
    expect(p.levelOf('s'), 2);
    p.record(e, false, DateTime(2026, 1, 1));
    expect(p.levelOf('s'), 2);
    p.record(e, false, DateTime(2026, 1, 1));
    expect(p.levelOf('s'), 1);
  });
  test('extra tries and trend are logged', () {
    final d = DevData();
    d.logAttempt('jobs', 'j1', false, DateTime(2026, 3, 1));
    d.logExtraTry('jobs', DateTime(2026, 3, 1));
    d.logAttempt('jobs', 'j2', true, DateTime(2026, 3, 2));
    expect(d.extraTries('jobs'), 1);
    expect(d.trend('jobs'), [0, 100]);
    expect(DevData.fromJson(d.toJson()).extraTries('jobs'), 1);
  });
  test('every area has real-world activities for every band', () {
    for (final b in AgeBand.values) {
      for (final a in SkillArea.values) {
        expect(realWorldFor(b, a, DateTime(2026, 3, 1)), isNotEmpty);
      }
    }
  });
}
