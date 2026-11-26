import 'package:flutter/material.dart' hide Text;
import 'package:haneen_kids_vod/core/regional/dialect_text.dart';
import 'package:haneen_kids_vod/haneen_kids_exports.dart';

/// "تقرير التقدم": a read-only summary of what the child did and learned.
/// Everything here comes from data the app already stores on [ChildProfile].
class ParentProgressReport extends StatelessWidget {
  final ChildProfile child;
  final List<Widget> extras;
  ParentProgressReport(
      {super.key, required this.child, this.extras = const []});

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
    'sound_id': 'أصوات الحيوانات والبيئة',
    'seq': 'الترتيب والتسلسل المنطقي',
    'trace_letter': 'تتبّع الحروف',
    'count_pics': 'عدّ وجمّع بالصور',
    'shape_sort': 'رتّب الأشكال والألوان',
    'imagine_draw': 'ارسم خيالك',
    'exercise': 'تمارين متنوعة',
    'quick_math': 'الحساب والجمع',
    'star_collector': 'جامع النجوم',
    'letter_catcher': 'صائد الحروف',
    'clock_set': 'اضبط عقارب الساعة',
    'shadow_match': 'ظل الصورة',
    'slide_puzzle': 'بازل الأرقام',
    'maze': 'المتاهة',
    'plant_care': 'اعتني بالنبتة',
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
    final double usedFrac =
        child.dailyTimeLimit <= 0 ? 0.0 : (child.usedMinutesToday / limit).clamp(0.0, 1.0);
    final timeline = child.liveActivityTimeline.take(15).toList();
    final skills = child.cognitiveSkillScoresByDomain.entries.toList();
    final games = child.gameProgressByGameId.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Directionality(
      textDirection: TextDirection.rtl,
      child: ListView(
        padding: EdgeInsets.all(20),
        children: [
          Text(
            'تقرير تقدم ${child.name}',
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white),
          ),
          SizedBox(height: 14),
          ...extras,
          SizedBox(height: 14),
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
          SizedBox(height: 18),
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
                SizedBox(height: 6),
                Text(
                    'استخدم ${child.usedMinutesToday} من ${child.limitShown} دقيقة' +
                        ' • شاهد ${child.watchedVideosToday} فيديو',
                    style: const TextStyle(color: Colors.white)),
              ],
            ),
          ),
          if (skills.isNotEmpty)
            _card(
              title: '📊 المهارات',
              child: Column(
                children: [
                  for (final e in skills)
                    _bar(_domainName(e.key), e.value.clamp(0, 100) / 100.0, '${e.value}%'),
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
                  '${child.needsRemediationLessonIds.length} درس يحتاج إعادة تدريب. شجّعه على إعادة الدروس بهدوء.'),
            ),
          if (child.unlockedAchievements.isNotEmpty)
            _card(
              title: '🏅 الإنجازات',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final a in child.unlockedAchievements.keys.take(8).map(badgeTitleAr))
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
                ? Text('لا توجد أنشطة بعد.')
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
                                    fontSize: 11, color: Colors.white60),
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
    return 'لعبة أخرى';
  }

  static const Map<String, String> kDomainNames = {
    'memory_focus': 'الذاكرة والتركيز البصري',
    'matching_shapes': 'المطابقة وربط الصور بالكلمات',
    'classification_sorting': 'التصنيف والفرز المنطقي',
    'puzzles_logic': 'الألغاز والتفكير المنطقي',
    'math_counting': 'الأرقام والحساب المبسط',
    'letters_words': 'الحروف وتكوين الكلمات',
    'listening_pronunciation': 'الاستماع والنطق الواضح',
    'etiquette_social': 'الآداب والسلوكيات الجميلة',
    'general_mastery': 'الإتقان العام',
  };

  static String _domainName(String k) => kDomainNames[k] ?? 'مهارة أخرى';

  Widget _stat(String emoji, String label, String value) {
    return Container(
      width: 104,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          Text(value,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Colors.white)),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _card({required String title, required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFA7F3D0))),
          const SizedBox(height: 8),
          DefaultTextStyle.merge(
              style: const TextStyle(color: Colors.white), child: child),
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
              child: Text(label,
                  style: const TextStyle(fontSize: 12, color: Colors.white))),
          Expanded(
            child: LinearProgressIndicator(
              value: v,
              minHeight: 8,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(width: 8),
          Text(trailing,
              style: const TextStyle(fontSize: 12, color: Colors.white)),
        ],
      ),
    );
  }
}
