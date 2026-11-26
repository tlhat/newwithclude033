import 'dart:convert';
import 'package:flutter/material.dart' hide Text;
import 'package:haneen_kids_vod/core/regional/dialect_text.dart';
import 'game_catalog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:haneen_kids_vod/features/exercises/exercise_models.dart';
import 'package:haneen_kids_vod/haneen_kids_exports.dart';

/// Parent-side view: mastery per skill for the active child.
/// Reads only the progress saved on this phone. Nothing is sent anywhere.
class SkillMasteryCard extends StatefulWidget {
  final AppStateManager appState;
  const SkillMasteryCard({super.key, required this.appState});

  static const Map<String, String> skillNames = {
    'letters': 'الحروف',
    'counting': 'العد',
    'numbers_order': 'ترتيب الأرقام',
    'addition': 'الجمع',
    'subtraction': 'الطرح',
    'compare': 'المقارنة',
    'classify': 'التصنيف',
    'patterns': 'الأنماط',
    'shapes': 'الأشكال',
    'colors': 'الألوان',
    'animals': 'الحيوانات',
    'animal_sounds': 'أصوات الحيوانات',
    'opposites': 'الأضداد',
    'vocabulary': 'المفردات',
    'daily_routine': 'الروتين اليومي',
    'body_parts': 'أجزاء الجسم',
    'number_line': 'خط الأعداد',
    'fill_blank': 'املأ الفراغ',
    'multi_select': 'اختر كل الصح',
    'grid_points': 'أين النقطة؟',
    'bar_chart': 'ارسم الأعمدة',
  };

  @override
  State<SkillMasteryCard> createState() => _SkillMasteryCardState();
}

class _SkillMasteryCardState extends State<SkillMasteryCard> {
  ExerciseProgress? _p;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(
        'ex_progress_${widget.appState.currentAccount?.activeChild.id}');
    ExerciseProgress p = ExerciseProgress();
    if (raw != null) {
      try {
        p = ExerciseProgress.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {}
    }
    if (mounted) setState(() => _p = p);
  }

  int _dueCount(ExerciseProgress p) {
    final now = DateTime.now();
    int n = 0;
    for (final v in p.review.values) {
      final d = DateTime.tryParse('${v['due']}');
      if (d != null && !d.isAfter(now)) n++;
    }
    return n;
  }

  @override
  Widget build(BuildContext context) {
    final p = _p;
    final name = widget.appState.currentAccount?.activeChild.name ?? '';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('🎯 إتقان المهارات',
                style: const TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            const SizedBox(height: 4),
            Text(
                'تقدّم ${name} في كل مهارة (محفوظ على هذا الهاتف فقط)',
                style: const TextStyle(fontSize: 12.5, color: Colors.white70)),
            const SizedBox(height: 12),
            if (p == null)
              const LinearProgressIndicator()
            else ...[
              for (final e in {
                ...SkillMasteryCard.skillNames,
                for (final ExerciseGameDef g in kExerciseGames) g.skill: g.title,
              }.entries)
                _row(p, e.key, e.value),
              const SizedBox(height: 8),
              Text('مراجعات مستحقة اليوم: ${_dueCount(p)}',
                  style: const TextStyle(
                      fontSize: 13, color: Color(0xFFA7F3D0))),
              const SizedBox(height: 4),
              Text('يُعتبر المتقن: 5 محاولات على الأقل و80% صح والمستوى 3 أو أعلى.',
                  style:
                      const TextStyle(fontSize: 11.5, color: Colors.white54)),
            ],
          ],
        ),
      ),
    );
  }

  /// Our own four-step ladder (idea only: show progress as clear steps).
  static String _tier(int total, int pct, bool done) {
    if (done) return '🏆 متقن';
    if (total >= 5 && pct >= 70) return '⭐ متمكّن';
    if (total >= 2) return '🌿 يتقدّم';
    return '🌱 بداية';
  }

  Widget _row(ExerciseProgress p, String key, String label) {
    final int total = p.skills[key]?['total'] ?? 0;
    final int pct = p.percentOf(key);
    final bool done = p.mastered(key);
    final Color c = total == 0
        ? Colors.white38
        : done
            ? const Color(0xFF34D399)
            : pct >= 50
                ? const Color(0xFFFBBF24)
                : const Color(0xFFF87171);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
                child: Text('${_tier(total, pct, done)} $label',
                    style: const TextStyle(color: Colors.white, fontSize: 14))),
            Text(
                total == 0
                    ? 'لم يبدأ بعد'
                    : '${pct}% • المستوى ${p.levelOf(key)} • ${total} محاولة',
                style: TextStyle(color: c, fontSize: 12)),
          ]),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: total == 0 ? 0 : pct / 100,
              minHeight: 7,
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation<Color>(c),
            ),
          ),
        ],
      ),
    );
  }
}
