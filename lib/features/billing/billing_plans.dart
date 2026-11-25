/// The plans offered through Google Play Billing.
///
/// The product ids below must be created in Play Console as subscriptions
/// (Monetize > Products > Subscriptions), each with ONE base plan, with the
/// same ids. Prices shown in the app come from Google Play for the user's
/// country; the EGP prices here are only the fallback text.
class BillingPlan {
  final String id;
  final String title;
  final String fallbackPrice;
  final String period;
  final String? badge;
  final int maxChildren;
  final List<String> features;
  const BillingPlan({
    required this.id,
    required this.title,
    required this.fallbackPrice,
    required this.period,
    required this.maxChildren,
    required this.features,
    this.badge,
  });
}

const String kPlanMonthly = 'haneen_monthly';
const String kPlanAnnual = 'haneen_annual';
const String kPlanFamilyAnnual = 'haneen_family_annual';

const List<BillingPlan> kBillingPlans = [
  BillingPlan(
    id: kPlanMonthly,
    title: 'الخطة الشهرية',
    fallbackPrice: '٧٩ جنيهًا',
    period: 'شهريًا',
    maxChildren: 1,
    features: [
      'جميع المجالات والأنشطة المتاحة.',
      'التقييم داخل الألعاب والاختبارات المستقلة.',
      'التكيف مع مستوى الطفل.',
      'تقارير تقدم مفصلة.',
      'ملف طفل واحد.',
    ],
  ),
  BillingPlan(
    id: kPlanAnnual,
    title: 'الخطة السنوية',
    fallbackPrice: '٥٩٩ جنيهًا',
    period: 'سنويًا',
    maxChildren: 1,
    badge: 'أفضل قيمة للمستخدم',
    features: [
      'جميع مميزات الخطة الشهرية.',
      'توفير مقارنة بالاشتراك الشهري.',
      'تحديثات المحتوى والأنشطة خلال مدة الاشتراك.',
    ],
  ),
  BillingPlan(
    id: kPlanFamilyAnnual,
    title: 'الخطة العائلية',
    fallbackPrice: '٩٩٩ جنيهًا',
    period: 'سنويًا',
    maxChildren: 3,
    features: [
      'حتى ٣ ملفات أطفال.',
      'ملف مستقل لكل طفل.',
      'تقارير منفصلة لكل طفل.',
      'متابعة تقدم جميع الأطفال.',
    ],
  ),
];

const List<String> kFreePlanFeatures = [
  'مجموعة أنشطة وألعاب محدودة.',
  'ملف طفل واحد.',
  'تجربة مبدئية لبعض المهارات.',
  'عرض تقدم مبسط.',
];

Set<String> get kBillingProductIds => {for (final p in kBillingPlans) p.id};
