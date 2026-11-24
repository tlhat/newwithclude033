import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haneen_kids_vod/haneen_kids_exports.dart';

void main() {
  testWidgets('report shows the child numbers and recent activity',
      (tester) async {
    final child = ChildProfile(
        id: 'c1', name: 'سلمى', age: '5', dailyTimeLimit: 60, chosenAvatar: 'a')
      ..starsEarned = 7
      ..gamesCompletedCount = 3
      ..usedMinutesToday = 12
      ..gameProgressByGameId['memory_match_lvl'] = 40;
    child.liveActivityTimeline.add(ChildActivityLogEntry(
      timestampIso: DateTime.now().toIso8601String(),
      actionTitle: 'أنجز تحدياً جديداً',
      categoryBadge: 'ألعاب الذكاء',
    ));
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: ParentProgressReport(child: child)),
    ));
    expect(find.text('تقرير تقدم سلمى'), findsOneWidget);
    expect(find.text('7'), findsOneWidget);
    expect(find.textContaining('استخدم 12 من'), findsOneWidget);
    expect(find.text('الذاكرة البصرية'), findsOneWidget);
    expect(find.text('أنجز تحدياً جديداً'), findsOneWidget);
  });

  test('ago formats minutes, hours and days', () {
    final now = DateTime(2026, 1, 10, 12);
    expect(ParentProgressReport.ago(now.toIso8601String(), now), 'الآن');
    expect(
        ParentProgressReport.ago(
            now.subtract(const Duration(minutes: 5)).toIso8601String(), now),
        'منذ 5 دقيقة');
    expect(
        ParentProgressReport.ago(
            now.subtract(const Duration(days: 2)).toIso8601String(), now),
        'منذ 2 يوم');
  });
}
