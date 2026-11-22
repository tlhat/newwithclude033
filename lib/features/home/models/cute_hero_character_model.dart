import 'package:flutter/material.dart';

class CuteHeroCharacterModel {
  final String id;
  final String nameAr;
  final String titleBadge;
  final String avatarEmoji;
  final Color primaryColor;
  final Color secondaryColor;
  final List<String> encouragingAlerts;

  const CuteHeroCharacterModel({
    required this.id,
    required this.nameAr,
    required this.titleBadge,
    required this.avatarEmoji,
    required this.primaryColor,
    required this.secondaryColor,
    required this.encouragingAlerts,
  });
}

const List<CuteHeroCharacterModel> kCuteSuperheroCharacters = [
  CuteHeroCharacterModel(
    id: 'haneen_companion',
    nameAr: 'حنين رفيقة التعلم الذكية',
    titleBadge: 'مرشدة الفصاحة والقصص والذكاء 🌟',
    avatarEmoji: '👧✨',
    primaryColor: Color(0xFF14B8A6),
    secondaryColor: Color(0xFF6366F1),
    encouragingAlerts: [
      'مرحباً يا بطل! أنا صديقتك حنين، اضغط على زر الصوت لأقرأ لك السؤال أو القصة بصوت واضح وهادئ!',
      'أحسنت المحاولة! تذكر أن كل محاولة تجعلك أذكى وأقوى، وأنا معك خطوة بخطوة!',
      'ما شاء الله! تقدمك اليوم في الألعاب والدروس يفتح لك شارات الأبطال الذهبية!',
    ],
  ),
  CuteHeroCharacterModel(
    id: 'spidey_hero',
    nameAr: 'سبايدي البطل اللطيف',
    titleBadge: 'بطل خفة الحركة والذكاء 🕸️',
    avatarEmoji: '🕷️🦸‍♂️',
    primaryColor: Color(0xFFEF4444),
    secondaryColor: Color(0xFF3B82F6),
    encouragingAlerts: [
      'أحسنت يا صديقي البطل! حاستك العنكبوتية الذكية تكتشف الإجابات الصحيحة بسرعة مذهلة!',
      'تذكير لطيف من سبايدي: البطل الحقيقي يرتب غرفته ويستأذن من ماما وبابا دائماً!',
      'ما شاء الله! تركيزك عالٍ جداً اليوم، هيا نكمل المرحلة التالية بهدوء وذكاء!',
    ],
  ),
  CuteHeroCharacterModel(
    id: 'bat_knight',
    nameAr: 'فارس الليل الذكي (بات هيرو)',
    titleBadge: 'محقق الألغاز والمنطق 🦇',
    avatarEmoji: '🦇🦸',
    primaryColor: Color(0xFFF59E0B),
    secondaryColor: Color(0xFF334155),
    encouragingAlerts: [
      'تحليل عبقري يا بطل! قوة ملاحظتك تشبه أعظم المحققين الأذكياء!',
      'تنبيه تشجيعي: خذ نفساً عميقاً وهادئاً، فالعقل الهادئ يحل أصعب الألغاز!',
      'رائع! كل مرحلة تنجزها تزيد نقاط ذكائك وتجعلك بطلاً في الأخلاق والعلم!',
    ],
  ),
  CuteHeroCharacterModel(
    id: 'super_star',
    nameAr: 'سوبر نور الخارق',
    titleBadge: 'بطل القوة والأخلاق الجميلة ⭐',
    avatarEmoji: '🦸‍♂️✨',
    primaryColor: Color(0xFF06B6D4),
    secondaryColor: Color(0xFFEC4899),
    encouragingAlerts: [
      'أنت تطير نحو القمة بذكائك وفصاحتك العربية الجميلة يا بطل حنين!',
      'تذكير البطل الخارق: الكلمة الطيبة والابتسامة هما أعظم قوة خارقة في العالم!',
      'فخور بك جداً! استمر في التقدم نحو المرحلة ١٠٠ بهدوء وثقة!',
    ],
  ),
  CuteHeroCharacterModel(
    id: 'elsa_princess',
    nameAr: 'أميرة الثلج الحكيمة',
    titleBadge: 'أميرة الهدوء والإبداع ❄️',
    avatarEmoji: '👸❄️',
    primaryColor: Color(0xFF38BDF8),
    secondaryColor: Color(0xFF818CF8),
    encouragingAlerts: [
      'قلبك صافي وجميل مثل بلورات الثلج اللامعة! رسمك وإجاباتك في قمة الروعة!',
      'همسة لطيفة: الهدوء واللطف مع إخوتك يجعلان البيت مملكة سعيدة!',
      'ما أجمل خطك وتفكيرك! أنتِ نجمة متألقة في واحة الذكاء!',
    ],
  ),
  CuteHeroCharacterModel(
    id: 'sponge_smile',
    nameAr: 'سبونج المبتسم المرح',
    titleBadge: 'صديق البهجة والنشاط 🧽',
    avatarEmoji: '🧽🌟',
    primaryColor: Color(0xFFFACC15),
    secondaryColor: Color(0xFF14B8A6),
    encouragingAlerts: [
      'أنا مستعد! أنا مستعد! وأنت أيضاً مستعد لحل المرحلة الجديدة بابتسامة كبيرة!',
      'تنبيه مبهج: لا تنسَ شرب الماء وغسل يديك بالصابون لتبقى نشيطاً طوال اليوم!',
      'يا سلام! إجابتك ذكية جداً وتستحق نجمة ذهبية لامعة!',
    ],
  ),
  CuteHeroCharacterModel(
    id: 'pika_spark',
    nameAr: 'بيكا الذكي المضيء',
    titleBadge: 'شرارة الحماس والذاكرة ⚡',
    avatarEmoji: '⚡🐭',
    primaryColor: Color(0xFFFBBF24),
    secondaryColor: Color(0xFFF97316),
    encouragingAlerts: [
      'بيكا بيكا! ذاكرتك تلمع بالذكاء والنشاط مثل البرق اللطيف!',
      'نصيحة لطيفة: أرح عينيك قليلاً وانظر بعيداً ثم عد لنكمل المغامرة الممتعة!',
      'إنجاز مدهش! لقد جمعت نقاط ذكاء رائعة في هذه المرحلة!',
    ],
  ),
  CuteHeroCharacterModel(
    id: 'dora_explorer',
    nameAr: 'المستكشفة الصغيرة المغامرة',
    titleBadge: 'بطلة الاكتشاف واللغات 🎒',
    avatarEmoji: '👧🎒',
    primaryColor: Color(0xFFEC4899),
    secondaryColor: Color(0xFFA855F7),
    encouragingAlerts: [
      'عمل رائع (ممتاز)! لقد اكتشفت الحل الصحيح بنفسك يا مستكشفنا الذكي!',
      'تذكير المستكشفة: قل «شكراً» و«من فضلك» دائماً لكل من يساعدك في يومك!',
      'هيا بنا إلى المرحلة التالية! لدينا ١٠٠ مغامرة ذكية بانتظارنا!',
    ],
  ),
  CuteHeroCharacterModel(
    id: 'simba_cub',
    nameAr: 'الشبل الشجاع سيمبا',
    titleBadge: 'بطل الشجاعة والصدق 🦁',
    avatarEmoji: '🦁👑',
    primaryColor: Color(0xFFF97316),
    secondaryColor: Color(0xFF10B981),
    encouragingAlerts: [
      'زئير الأبطال الهادئ! شجاعتك في المحاولة والتعلم تجعلك ملك الغابة الذكي!',
      'تنبيه البطل الشجاع: الصدق والأمانة هما تاج البطولة الحقيقي!',
      'أحسنت يا بطل! خطوة بعد خطوة تقترب من إنهاء الـ ١٠٠ مرحلة كاملة!',
    ],
  ),
];
