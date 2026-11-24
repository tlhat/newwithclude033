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

/// Only the child's own companion (the boy or girl avatar). The licensed-style
/// cartoon characters were removed on purpose.
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
];
