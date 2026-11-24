import 'package:flutter/material.dart';
import 'package:haneen_kids_vod/haneen_kids_exports.dart';

/// "تقرير التقدم": a read-only summary of what the child did and learned.
/// Everything here comes from data the app already stores on [ChildProfile].
class ParentProgressReport extends StatelessWidget {
  final ChildProfile child;
  const ParentProgressReport({super.key, required this.child});

  static const Map<String, String> kGameNames = {
    'memory_match_lvl': 'الذاكرة البصرية',
    'memory_match': 'الذاكرة البصرية',
    'etiquette_draw': 'مرسم الآداب',
    'pic_match': 'مطابقة الصور والكلمات',
    'odd_one_out': 'قوة الملاحظة',
    'pattern_logic': 'الألغاز والمنطق',
    'visual_math': 'الحساب والجمع',
    'arabic_word': 'الحروف والكلمات',
    'classify': 'لعبة التصنيف الذكي',
    'sound_id': 'أصوات الحيوانات والبيئة',
    'seq': 'الترتيب والتسلسل المنطقي',
  };

  /// Turns an ISO time into "منذ ٣ دقائق" style text.
  static String ago(String iso, [DateTime? now]) {
    final DateTime? t = DateTime.tryParse(iso);
    if (t == null) return '';
    final Duration d = (now ?? DateTime.now()).difference(t);
    if (d.inMinutes < 1) return 'الآن';
    if (d.inMinutes < 60) return 'منذ ${d.inMinutes} دقيقة';
    if (d.inHours < 24) return 'منذ ${d.inHours} ساعة';
    return 'منذ ${d.inDays} يوم';
  }

  @override
  Widget build(BuildContext context) {
    final int limit = child.dailyTimeLimit <= 0 ? 1 : child.dailyTimeLimit;
    final double usedFrac = (child.usedMinutesToday / limit).clamp(0.0, 1.0);
    final timeline = child.liveActivityTimeline.take(15).toList();
    final skills = child.cognitiveSkillScoresByDomain.entries.toList();
    final games = child.gameProgressByGameId.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Directionality(
      textDirection: TextDirection.rtl,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'تقرير تقدم ${child.name}',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _stat('⭐', 'النجوم', '${child.starsEarned}'),
              _stat('🧠', 'نقاط الذكاء', '${child.intelligencePoints}'),
              _stat('🎮', 'ألعاب أنجزها', '${child.gamesCompletedCount}'),
              _stat('🎓', 'دروس أتقنها', '${child.completedLessons.length}'),
              _stat(
                  '📖', 'كلمات تعلمها', '${child.practicedVocabulary.length}'),
              _stat('🎙️', 'نطق صحيح', '${child.correctPronunciationsCount}'),
            ],
          ),
          const SizedBox(height: 18),
          _card(
            title: '⏱️ وقت اليوم',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LinearProgressIndicator(
                  value: usedFrac,
                  minHeight: 10,
                  borderRadius: BorderRadius.circular(8),
                ),
                const SizedBox(height: 6),
                Text(
                    'استخدم ${child.usedMinutesToday} من ${child.dailyTimeLimit} دقيقة'
                    ' • شاهد ${child.watchedVideosToday} فيديو'),
              ],
            ),
          ),
          if (skills.isNotEmpty)
            _card(
              title: '📊 المهارات',
              child: Column(
                children: [
                  for (final e in skills)
                    _bar(e.key, e.value.clamp(0, 100) / 100.0, '${e.value}%'),
                ],
              ),
            ),
          if (games.isNotEmpty)
            _card(
              title: '🎮 تقدم الألعاب (من ١٠٠ مرحلة)',
              child: Column(
                children: [
                  for (final e in games)
                    _bar(_gameName(e.key), (e.value.clamp(0, 100)) / 100.0,
                        '${e.value}'),
                ],
              ),
            ),
          if (child.needsRemediationLessonIds.isNotEmpty)
            _card(
              title: '💡 يحتاج تدريباً',
              child: Text(
                  '${child.needsRemediationLessonIds.length} درس يحتاج إعادة '
                  'تدريب. شجّعه على إعادة الدروس بهدوء.'),
            ),
          if (child.unlockedAchievements.isNotEmpty)
            _card(
              title: '🏅 الإنجازات',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final a in child.unlockedAchievements.values.take(8))
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text('• $a'),
                    ),
                ],
              ),
            ),
          _card(
            title: '🕒 آخر الأنشطة',
            child: timeline.isEmpty
                ? const Text('لا توجد أنشطة بعد.')
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final e in timeline)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: Text(e.actionTitle)),
                              const SizedBox(width: 8),
                              Text(
                                '${e.categoryBadge} • ${ago(e.timestampIso)}',
                                style: const TextStyle(
                                    fontSize: 11, color: Colors.black54),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  static String _gameName(String id) {
    for (final e in kGameNames.entries) {
      if (id.startsWith(e.key)) return e.value;
    }
    return id;
  }

  Widget _stat(String emoji, String label, String value) {
    return Container(
      width: 104,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          Text(value,
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }

  Widget _card({required String title, required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          DefaultTextStyle.merge(
              style: const TextStyle(color: Colors.black87), child: child),
        ],
      ),
    );
  }

  Widget _bar(String label, double v, String trailing) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
              width: 110,
              child: Text(label, style: const TextStyle(fontSize: 12))),
          Expanded(
            child: LinearProgressIndicator(
              value: v,
              minHeight: 8,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(width: 8),
          Text(trailing, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
