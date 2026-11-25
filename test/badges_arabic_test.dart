import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:haneen_kids_vod/features/brain_games/models/brain_game_models.dart';

void main() {
  test('every badge id the app can unlock has Arabic text', () {
    final String repo = File('lib/data/repositories/child_profile_repository.dart').readAsStringSync();
    final ids = RegExp(r"unlockedAchievements\['(\w+)'\]").allMatches(repo).map((m) => m.group(1)!).toSet();
    expect(ids, isNotEmpty);
    for (final String id in ids) {
      final b = badgeById(id);
      expect(b, isNotNull, reason: id);
      expect(RegExp(r'[A-Za-z]').hasMatch(b!.titleAr), false, reason: id);
      expect(RegExp(r'[A-Za-z]').hasMatch(b.descriptionAr), false, reason: id);
      expect(RegExp(r'[\u0600-\u06FF]').hasMatch(badgeTitleAr(id)), true);
    }
    expect(badgeTitleAr('something_unknown'), 'إنجاز جديد');
    expect(badgeDateShort('2026-11-25T10:00:00.000'), '2026-11-25');
  });
}
