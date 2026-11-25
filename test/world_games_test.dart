import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:haneen_kids_vod/features/exercises/exercise_models.dart';
import 'package:haneen_kids_vod/features/brain_games/screens/world_games.dart';

void main() {
  test('house: stars are spent by owned items, never negative', () {
    expect(HouseLogic.available(10, {}), 10);
    expect(HouseLogic.available(10, {'balloon', 'plant'}), 7);
    expect(HouseLogic.available(1, {'trophy'}), 0);
    final HouseItem trophy = kHouseItems.firstWhere((x) => x.id == 'trophy');
    expect(HouseLogic.canBuy(5, {}, trophy), false);
    expect(HouseLogic.canBuy(6, {}, trophy), true);
    expect(HouseLogic.canBuy(60, {'trophy'}, trophy), false);
  });
  test('pet grows with stars and gets hungry after 8 hours', () {
    expect(PetLogic.stage(0), 0);
    expect(PetLogic.stage(5), 1);
    expect(PetLogic.stage(40), 3);
    final DateTime n = DateTime(2026, 1, 1, 12);
    expect(PetLogic.hungry(null, n), true);
    expect(PetLogic.hungry(n.subtract(const Duration(hours: 2)), n), false);
    expect(PetLogic.hungry(n.subtract(const Duration(hours: 9)), n), true);
  });
  test('stickers unlock from stats', () {
    const StickerStats none = StickerStats();
    expect(kStickers.where((s) => s.test(none)).length, 0);
    const StickerStats rich = StickerStats(
        stars: 100, games: 50, mastered: 3, dailyDone: 3, houseItems: 5, petStage: 3);
    expect(kStickers.every((s) => s.test(rich)), true);
  });
  test('daily challenge: same day same questions, 5 of them, no bars', () {
    final List<Exercise> bank = Exercise.parseList(
        File('assets/exercises/exercises_v1.json').readAsStringSync());
    final List<Exercise> a = dailyPick(bank, '20261125');
    final List<Exercise> b = dailyPick(bank, '20261125');
    expect(a.map((e) => e.id).toList(), b.map((e) => e.id).toList());
    expect(a.length, 5);
    expect(a.map((e) => e.skill).toSet().length, 5);
    expect(dailyPick(bank, '20261126').map((e) => e.id).toList() == a.map((e) => e.id).toList(), false);
  });
  test('spoken quiz text', () {
    final Exercise e = Exercise(
        id: 'x', type: 'choice', prompt: 'سؤال', hints: const [], correctFeedback: '', wrongFeedback: '',
        data: {'options': ['أ', 'ب'], 'correct': 1});
    expect(spokenAnswer(e), 'ب');
    expect(spokenQuestion(e).contains('الاختيارات'), true);
    final Exercise o = Exercise(
        id: 'y', type: 'ordering', prompt: 'p', hints: const [], correctFeedback: '', wrongFeedback: '',
        data: {'items': ['a'], 'order': ['a']});
    expect(spokenAnswer(o), null);
  });
  test('arabic numerals', () {
    expect(arNum(2026), '٢٠٢٦');
  });
}
