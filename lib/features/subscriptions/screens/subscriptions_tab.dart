import 'package:flutter/material.dart' hide Text;
import 'package:haneen_kids_vod/core/entitlements/entitlements.dart';
import 'package:haneen_kids_vod/core/regional/dialect_text.dart';
import 'package:haneen_kids_vod/features/activities/models/academy_track_lesson_model.dart';
import 'package:haneen_kids_vod/features/activities/models/interactive_educational_story_model.dart';
import 'package:haneen_kids_vod/features/subscriptions/models/subscription_models.dart';

/// Top-level tab: the plans and the locked paid content.
/// UI plus a local stub only. No billing, nothing is bought here.
class SubscriptionsTab extends StatelessWidget {
  const SubscriptionsTab({super.key});

  static List<AcademyTrackLessonModel> get _paidLessons => [
        for (final l in kHaneenAcademyCurriculum)
          if (l.tierLevel > Entitlements.freeAcademyMaxTier) l
      ];

  void _soon(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
    useSafeArea: true,
      backgroundColor: const Color(0xFF1E1B4B),
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('🛠️', style: TextStyle(fontSize: 44)),
            const SizedBox(height: 8),
            const Text('الاشتراك لسه مش متفعّل',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            const Text(
                'الدفع هيتضاف في تحديث جاي. دلوقتي ده شكل الصفحة بس، ومفيش أي دفع بيحصل.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 14),
            ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('تمام')),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final plans =
        kSubscriptionPlans.where((p) => p.priceEgp > 0).toList(); // no trial
    final paidLessons = _paidLessons;
    final paidStories = kInteractiveOriginalStories
        .skip(Entitlements.freeStoryCount)
        .toList();
    return Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        child: ValueListenableBuilder<bool>(
          valueListenable: Entitlements.subscribed,
          builder: (context, on, _) => ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
            children: [
              const Text('⭐ الاشتراك',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              Text(
                  on
                      ? 'المحتوى المدفوع مفتوح على الجهاز ده (وضع تجريبي).'
                      : 'فيه محتوى مجاني، والباقي بيفتح بالاشتراك.',
                  style: const TextStyle(fontSize: 14, color: Colors.white70)),
              const SizedBox(height: 16),
              const Text('الباقات',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              for (final p in plans)
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: p.accentColor.withOpacity(0.7)),
                  ),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.title,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Text(p.subtitle,
                            style: const TextStyle(
                                fontSize: 12.5, color: Colors.white70)),
                        const SizedBox(height: 6),
                        const Text('السعر بيتأكد قبل تفعيل الدفع',
                            style: TextStyle(
                                fontSize: 12, color: Color(0xFFFDE68A))),
                        const SizedBox(height: 8),
                        ElevatedButton(
                            onPressed: () => _soon(context),
                            child: const Text('اشترك')),
                      ]),
                ),
              const SizedBox(height: 12),
              const Text('🔒 المحتوى المدفوع',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(
                  'دروس الأكاديمية: ${paidLessons.length} درس (المستويات ٢ و٣ و٤)',
                  style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 4),
              Text('القصص التفاعلية: ${paidStories.length} قصة',
                  style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 4),
              const Text('ألعاب الذكاء: كل الألعاب بعد أول ٥ ألعاب',
                  style: TextStyle(fontSize: 14)),
              const SizedBox(height: 10),
              for (final l in paidLessons.take(12))
                ListTile(
                  dense: true,
                  leading: Text(on ? l.illustrationEmoji : '🔒',
                      style: const TextStyle(fontSize: 22)),
                  title: Text(l.title),
                  subtitle: Text('${l.trackTitle} • ${l.levelName}'),
                ),
              for (final s in paidStories)
                ListTile(
                  dense: true,
                  leading: Text(on ? s.illustration : '🔒',
                      style: const TextStyle(fontSize: 22)),
                  title: Text(s.title),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
