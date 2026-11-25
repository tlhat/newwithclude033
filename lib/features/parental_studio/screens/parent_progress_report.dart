import 'package:flutter/material.dart';
import 'package:haneen_kids_vod/core/localization/tr.dart';
import 'package:haneen_kids_vod/haneen_kids_exports.dart';

/// "تقرير التقدم": a read-only summary of what the child did and learned.
/// Everything here comes from data the app already stores on [ChildProfile].
class ParentProgressReport extends StatelessWidget {
  final ChildProfile child;
  ParentProgressReport({super.key, required this.child});

  static Map<String, String> kGameNames = {
    'memory_match_lvl': 'الذاكرة البصرية',
    'memory_match': 'الذاكرة البصرية',
    'etiquette_draw': 'مرسم الآداب',
    'pic_match': 'مطابقة الصور والكلمات',
    'odd_one_out': 'قوة الملاحظة',
    'pattern_logic': 'الألغاز والمنطق',
    'visual_math': 'الحساب والجمع',
    'arabic_word': 'الحروف والكلمات',
    'classify': 'لعبة التصنيف الذكي',
    'sound_id': tr('أصوات الحيوانات والبيئة'),
    'seq': tr('الترتيب والتسلسل المنطقي'),
  };

  /// Turns an ISO time into "منذ ٣ دقائق" style text.
  static String ago(String iso, [DateTime? now]) {
    final DateTime? t = DateTime.tryParse(iso);
    if (t == null) return '';
    final Duration d = (now ?? DateTime.now()).difference(t);
    if (d.inMinutes < 1) return tr('الآن');
    if (d.inMinutes < 60) return tr('منذ {0} دقيقة', [d.inMinutes]);
    if (d.inHours < 24) return tr('منذ {0} ساعة', [d.inHours]);
    return tr('منذ {0} يوم', [d.inDays]);
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
      textDirection: Tr.dir,
      child: ListView(
        padding: EdgeInsets.all(20),
        children: [
          Text(
            tr('تقرير تقدم {0}', [child.name]),
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _stat('⭐', tr('النجوم'), '${child.starsEarned}'),
              _stat('🧠', tr('نقاط الذكاء'), '${child.intelligencePoints}'),
              _stat('🎮', tr('ألعاب أنجزها'), '${child.gamesCompletedCount}'),
              _stat('🎓', tr('دروس أتقنها'), '${child.completedLessons.length}'),
              _stat(
                  '📖', tr('كلمات تعلمها'), '${child.practicedVocabulary.length}'),
              _stat('🎙️', tr('نطق صحيح'), '${child.correctPronunciationsCount}'),
            ],
          ),
          SizedBox(height: 18),
          _card(
            title: tr('⏱️ وقت اليوم'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LinearProgressIndicator(
                  value: usedFrac,
                  minHeight: 10,
                  borderRadius: BorderRadius.circular(8),
                ),
                SizedBox(height: 6),
                Text(
                    tr('استخدم {0} من {1} دقيقة', [child.usedMinutesToday, child.dailyTimeLimit]) +
                        tr(' • شاهد {0} فيديو', [child.watchedVideosToday])),
              ],
            ),
          ),
          if (skills.isNotEmpty)
            _card(
              title: tr('📊 المهارات'),
              child: Column(
                children: [
                  for (final e in skills)
                    _bar(e.key, e.value.clamp(0, 100) / 100.0, '${e.value}%'),
                ],
              ),
            ),
          if (games.isNotEmpty)
            _card(
              title: tr('🎮 تقدم الألعاب (من ١٠٠ مرحلة)'),
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
              title: tr('💡 يحتاج تدريباً'),
              child: Text(
                  tr('{0} درس يحتاج إعادة تدريب. شجّعه على إعادة الدروس بهدوء.', [child.needsRemediationLessonIds.length])),
            ),
          if (child.unlockedAchievements.isNotEmpty)
            _card(
              title: tr('🏅 الإنجازات'),
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
            title: tr('🕒 آخر الأنشطة'),
            child: timeline.isEmpty
                ? Text(tr('لا توجد أنشطة بعد.'))
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
