class BrainGameCategorySummary {
  final String id;
  final String titleAr;
  final int totalLevels;
  final String skillDomainKey;
  final String iconEmoji;

  const BrainGameCategorySummary({
    required this.id,
    required this.titleAr,
    this.totalLevels = 100,
    this.skillDomainKey = 'puzzles_logic',
    this.iconEmoji = '🧩',
  });
}

class EducationalMasteryBadge {
  final String id;
  final String titleAr;
  final String descriptionAr;
  final String emoji;
  final String domainKey;
  final int requiredThreshold;

  const EducationalMasteryBadge({
    required this.id,
    required this.titleAr,
    required this.descriptionAr,
    required this.emoji,
    required this.domainKey,
    required this.requiredThreshold,
  });
}

const List<EducationalMasteryBadge> kEducationalMasteryBadges = [
  EducationalMasteryBadge(
    id: 'first_lesson',
    titleAr: 'بداية المستكشف الذكي',
    descriptionAr: 'إتمام وإتقان أول درس في أكاديمية حنين',
    emoji: '🌱',
    domainKey: 'letters_words',
    requiredThreshold: 1,
  ),
  EducationalMasteryBadge(
    id: 'five_lessons',
    titleAr: 'فارس الأكاديمية المتفوق',
    descriptionAr: 'إتقان ٥ دروس تعليمية متدرجة بنسبة ٨٠٪ فأكثر',
    emoji: '🎓',
    domainKey: 'letters_words',
    requiredThreshold: 5,
  ),
  EducationalMasteryBadge(
    id: 'vocab_explorer',
    titleAr: 'مستكشف الكلمات والمفردات',
    descriptionAr: 'التدرب على ٥ كلمات ومفردات عربية',
    emoji: '📚',
    domainKey: 'letters_words',
    requiredThreshold: 5,
  ),
  EducationalMasteryBadge(
    id: 'games_champion',
    titleAr: 'بطل ألعاب الذكاء والتفكير',
    descriptionAr: 'اجتياز ٥ مراحل متنوعة في واحة الألعاب الذكية',
    emoji: '🏆',
    domainKey: 'puzzles_logic',
    requiredThreshold: 5,
  ),
  EducationalMasteryBadge(
    id: 'star_collector_15',
    titleAr: 'جامع النجوم الذهبية',
    descriptionAr: 'جمع ١٥ نجمة من التقدم التعليمي الحقيقي',
    emoji: '⭐',
    domainKey: 'general_mastery',
    requiredThreshold: 15,
  ),
  EducationalMasteryBadge(
    id: 'clear_speaker',
    titleAr: 'بلبل الفصاحة والنطق الواضح',
    descriptionAr: 'إتمام ٣ تدريبات استماع ونطق صحيح مع حنين',
    emoji: '🎙️',
    domainKey: 'listening_pronunciation',
    requiredThreshold: 3,
  ),
  EducationalMasteryBadge(
    id: 'memory_master',
    titleAr: 'عبقري الذاكرة والتركيز',
    descriptionAr: 'التقدم في مراحل الذاكرة البصرية والتركيز',
    emoji: '🃏',
    domainKey: 'memory_focus',
    requiredThreshold: 2,
  ),
  EducationalMasteryBadge(
    id: 'logic_detective',
    titleAr: 'محقق الأنماط والألغاز',
    descriptionAr: 'حل الألغاز المنطقية وإكمال الأنماط المتدرجة',
    emoji: '🔍',
    domainKey: 'puzzles_logic',
    requiredThreshold: 2,
  ),
  EducationalMasteryBadge(
    id: 'math_genius',
    titleAr: 'عبقري الأرقام والحساب',
    descriptionAr: 'التفوق في مسائل العد والجمع البصري',
    emoji: '🔢',
    domainKey: 'math_counting',
    requiredThreshold: 2,
  ),
  EducationalMasteryBadge(
    id: 'classification_expert',
    titleAr: 'خبير التصنيف والمطابقة',
    descriptionAr: 'فرز وتصنيف المجموعات ومطابقة الصور بدقة',
    emoji: '🗂️',
    domainKey: 'classification_sorting',
    requiredThreshold: 2,
  ),
  EducationalMasteryBadge(
    id: 'kind_etiquette_hero',
    titleAr: 'فنان الأخلاق والآداب',
    descriptionAr: 'إنجاز لوحات الآداب والسلوكيات الجميلة',
    emoji: '🎨',
    domainKey: 'etiquette_social',
    requiredThreshold: 2,
  ),
  EducationalMasteryBadge(
    id: 'tier_up_champion',
    titleAr: 'وسام الترقية للمستوى الأعلى',
    descriptionAr: 'تحقيق إتقان ٨٠٪ والترقية إلى مستوى منهج أعلى',
    emoji: '👑',
    domainKey: 'general_mastery',
    requiredThreshold: 3,
  ),
];

/// Arabic badge lookup by stored id. Unknown ids never show raw.
EducationalMasteryBadge? badgeById(String id) {
  for (final EducationalMasteryBadge b in kEducationalMasteryBadges) {
    if (b.id == id) return b;
  }
  return null;
}

String badgeTitleAr(String id) => badgeById(id)?.titleAr ?? 'إنجاز جديد';

/// "2026-11-25T..." -> "2026-11-25"
String badgeDateShort(String iso) => iso.length >= 10 ? iso.substring(0, 10) : iso;
