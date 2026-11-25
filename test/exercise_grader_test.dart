import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:haneen_kids_vod/features/exercises/exercise_models.dart';

Exercise _e(String t, Map<String, dynamic> d) => Exercise(
    id: 'x', type: t, prompt: 'p', hints: const ['h1', 'h2'],
    correctFeedback: 'ok', wrongFeedback: 'no', data: d);

void main() {
  bankTests();
  test('choice and number', () {
    expect(ExerciseGrader.grade(_e('choice', {'correct': 1}), 1), true);
    expect(ExerciseGrader.grade(_e('choice', {'correct': 1}), 0), false);
    expect(ExerciseGrader.grade(_e('number', {'answer': 5}), ' 5 '), true);
    expect(ExerciseGrader.grade(_e('number', {'answer': 5}), 'x'), false);
  });
  test('ordering, matching, categorize', () {
    expect(ExerciseGrader.grade(_e('ordering', {'order': ['a', 'b']}), ['a', 'b']), true);
    expect(ExerciseGrader.grade(_e('ordering', {'order': ['a', 'b']}), ['b', 'a']), false);
    expect(ExerciseGrader.grade(_e('matching', {'pairs': {'1': 'a'}}), {'1': 'a'}), true);
    expect(ExerciseGrader.grade(_e('categorize', {'items': {'x': 'k'}}), {'x': 'z'}), false);
  });
  test('hints repeat last', () {
    final Exercise e = _e('choice', {'correct': 0});
    expect(ExerciseGrader.hintFor(e, 0), 'h1');
    expect(ExerciseGrader.hintFor(e, 5), 'h2');
  });
}

// ---- bank + progress tests (reads the real JSON the app ships)
Object _solve(Exercise e) {
  switch (e.type) {
    case 'choice':
      return (e.data['correct'] as num).toInt();
    case 'number':
      return '${e.data['answer']}';
    case 'ordering':
      return (e.data['order'] as List).map((x) => '$x').toList();
    case 'matching':
      return Map<String, String>.from(
          (e.data['pairs'] as Map).map((k, v) => MapEntry('$k', '$v')));
    default:
      return Map<String, String>.from(
          (e.data['items'] as Map).map((k, v) => MapEntry('$k', '$v')));
  }
}

void bankTests() {
  final List<Exercise> bank = Exercise.parseList(
      File('assets/exercises/exercises_v1.json').readAsStringSync());
  test('bank: unique ids, hints, solvable, sane data', () {
    expect(bank.map((e) => e.id).toSet().length, bank.length);
    for (final Exercise e in bank) {
      expect(e.hints, isNotEmpty, reason: e.id);
      expect(e.level, inInclusiveRange(1, 3), reason: e.id);
      expect(ExerciseGrader.grade(e, _solve(e)), true, reason: e.id);
      expect(StepGrading.steps(e, _solve(e)).allRight, true, reason: e.id);
      if (e.type == 'choice') {
        expect((e.data['options'] as List).length,
            greaterThan((e.data['correct'] as num).toInt()), reason: e.id);
      }
      if (e.type == 'ordering') {
        expect((e.data['items'] as List).toSet(),
            (e.data['order'] as List).toSet(), reason: e.id);
      }
    }
  });
  test('step grading reports what was wrong', () {
    final Exercise e = bank.firstWhere((x) => x.type == 'ordering');
    final List<String> rev = (_solve(e) as List<String>).reversed.toList();
    expect(StepGrading.steps(e, rev).wrongSteps, isNotEmpty);
  });
  test('adaptive level and mistake review', () {
    final Exercise e = bank.firstWhere((x) => x.skill == 'addition');
    final ExerciseProgress p = ExerciseProgress();
    final DateTime t = DateTime(2026, 1, 1);
    for (int i = 0; i < 3; i++) {
      p.record(e, true, t);
    }
    expect(p.levelOf('addition'), 2);
    p.record(e, false, t);
    expect(p.review.containsKey(e.id), true);
    expect(p.next(bank, t.add(const Duration(days: 2)), lastId: 'zz').id, e.id);
    final ExerciseProgress q = ExerciseProgress.fromJson(
        Map<String, dynamic>.from(jsonDecode(jsonEncode(p.toJson())) as Map));
    expect(q.levelOf('addition'), p.levelOf('addition'));
  });
}
