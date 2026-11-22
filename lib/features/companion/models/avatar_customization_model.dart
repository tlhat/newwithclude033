import 'package:flutter/foundation.dart';

enum CompanionGender {
  boy,
  girl;

  String toJson() => name;

  static CompanionGender fromJson(String? value) {
    if (value == null) return CompanionGender.boy;
    return CompanionGender.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => CompanionGender.boy,
    );
  }

  String get labelAr => this == CompanionGender.boy ? 'ولد' : 'بنت';
  String get labelEn => this == CompanionGender.boy ? 'Boy' : 'Girl';
}

enum CompanionPose {
  standing,
  waving,
  celebrating;

  String toJson() => name;

  static CompanionPose fromJson(String? value) {
    if (value == null) return CompanionPose.standing;
    return CompanionPose.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => CompanionPose.standing,
    );
  }

  String get labelAr {
    switch (this) {
      case CompanionPose.standing:
        return 'وقوف مرحب';
      case CompanionPose.waving:
        return 'تلويح باليد';
      case CompanionPose.celebrating:
        return 'قفزة احتفال';
    }
  }

  String get labelEn {
    switch (this) {
      case CompanionPose.standing:
        return 'Welcome Stand';
      case CompanionPose.waving:
        return 'Hand Wave';
      case CompanionPose.celebrating:
        return 'Victory Jump';
    }
  }
}

enum CompanionFaceExpression {
  happy,
  excited,
  calm,
  shy,
  thinking;

  String toJson() => name;

  static CompanionFaceExpression fromJson(String? value) {
    if (value == null) return CompanionFaceExpression.happy;
    return CompanionFaceExpression.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => CompanionFaceExpression.happy,
    );
  }
}

class CatalogItem {
  final String id;
  final String labelAr;
  final String labelEn;
  final int starsCost;
  final String? previewEmoji;

  const CatalogItem({
    required this.id,
    required this.labelAr,
    required this.labelEn,
    required this.starsCost,
    this.previewEmoji,
  });

  bool get isFree => starsCost <= 0;
}

class AvatarCustomizationModel {
  static const List<CatalogItem> kBoyHairStyles = [
    CatalogItem(id: 'curly', labelAr: 'شعر كيرلي', labelEn: 'Curly Hair', starsCost: 0, previewEmoji: '👦'),
    CatalogItem(id: 'spiky', labelAr: 'شعر سبايكي', labelEn: 'Spiky Hair', starsCost: 3, previewEmoji: '🦔'),
    CatalogItem(id: 'cap', labelAr: 'قبعة رياضية', labelEn: 'Sport Cap', starsCost: 5, previewEmoji: '🧢'),
  ];

  static const List<CatalogItem> kGirlHairStyles = [
    CatalogItem(id: 'ponytail', labelAr: 'ذيل حصان', labelEn: 'Ponytail', starsCost: 0, previewEmoji: '👧'),
    CatalogItem(id: 'braids', labelAr: 'ضفيرتين', labelEn: 'Braids', starsCost: 3, previewEmoji: '🎀'),
    CatalogItem(id: 'bow', labelAr: 'فيونكة زهرية', labelEn: 'Pink Bow', starsCost: 5, previewEmoji: '🌸'),
    CatalogItem(id: 'crown', labelAr: 'تاج الأميرة', labelEn: 'Princess Crown', starsCost: 8, previewEmoji: '👑'),
  ];

  static const List<CatalogItem> kSkinTones = [
    CatalogItem(id: 'light', labelAr: 'فاتحة', labelEn: 'Light', starsCost: 0, previewEmoji: '🏻'),
    CatalogItem(id: 'medium', labelAr: 'حنطية', labelEn: 'Medium', starsCost: 0, previewEmoji: '🏼'),
    CatalogItem(id: 'tan', labelAr: 'قمحية', labelEn: 'Tan', starsCost: 0, previewEmoji: '🏽'),
    CatalogItem(id: 'dark', labelAr: 'سمراء', labelEn: 'Dark', starsCost: 0, previewEmoji: '🏾'),
  ];

  static const List<CatalogItem> kFaceExpressions = [
    CatalogItem(id: 'happy', labelAr: 'سعيد', labelEn: 'Happy', starsCost: 0, previewEmoji: '😊'),
    CatalogItem(id: 'calm', labelAr: 'هادئ', labelEn: 'Calm', starsCost: 0, previewEmoji: '😌'),
    CatalogItem(id: 'excited', labelAr: 'متحمس', labelEn: 'Excited', starsCost: 2, previewEmoji: '🤩'),
    CatalogItem(id: 'shy', labelAr: 'خجول', labelEn: 'Shy', starsCost: 3, previewEmoji: '😳'),
    CatalogItem(id: 'thinking', labelAr: 'مفكر', labelEn: 'Thinking', starsCost: 3, previewEmoji: '🤔'),
  ];

  static const List<CatalogItem> kOutfits = [
    CatalogItem(id: 'casual', labelAr: 'ملابس كاجوال', labelEn: 'Casual Outfit', starsCost: 0, previewEmoji: '👕'),
    CatalogItem(id: 'sporty', labelAr: 'زي رياضي', labelEn: 'Sporty Kit', starsCost: 3, previewEmoji: '⚽'),
    CatalogItem(id: 'explorer', labelAr: 'زي المستكشف', labelEn: 'Explorer Suit', starsCost: 5, previewEmoji: '🧭'),
    CatalogItem(id: 'fancy', labelAr: 'أزياء مبهجة', labelEn: 'Celebration Outfit', starsCost: 7, previewEmoji: '✨'),
  ];

  static const List<CatalogItem> kBackgrounds = [
    CatalogItem(id: 'playroom', labelAr: 'غرفة الألعاب', labelEn: 'Playroom', starsCost: 0, previewEmoji: '🧸'),
    CatalogItem(id: 'garden', labelAr: 'حديقة خضراء', labelEn: 'Sunny Garden', starsCost: 4, previewEmoji: '🌳'),
    CatalogItem(id: 'space', labelAr: 'فضاء النجوم', labelEn: 'Starry Space', starsCost: 6, previewEmoji: '🚀'),
  ];

  static const List<CatalogItem> kPoses = [
    CatalogItem(id: 'standing', labelAr: 'وقوف ترحيبي', labelEn: 'Welcome Stand', starsCost: 0, previewEmoji: '🧍'),
    CatalogItem(id: 'waving', labelAr: 'تلويح باليد', labelEn: 'Hand Wave', starsCost: 0, previewEmoji: '👋'),
    CatalogItem(id: 'celebrating', labelAr: 'قفزة احتفال', labelEn: 'Victory Jump', starsCost: 4, previewEmoji: '🎉'),
  ];

  static const List<CatalogItem> kAccessories = [
    CatalogItem(id: 'none', labelAr: 'بدون إضافة', labelEn: 'None', starsCost: 0, previewEmoji: '🚫'),
    CatalogItem(id: 'crown', labelAr: 'التاج الذهبي', labelEn: 'Golden Crown', starsCost: 8, previewEmoji: '👑'),
    CatalogItem(id: 'glasses', labelAr: 'نظارة الذكاء', labelEn: 'Smart Glasses', starsCost: 5, previewEmoji: '🕶️'),
    CatalogItem(id: 'wings', labelAr: 'أجنحة المستكشف', labelEn: 'Explorer Wings', starsCost: 10, previewEmoji: '🪽'),
  ];

  CompanionGender gender;
  String hairStyle;
  String skinTone;
  String outfit;
  String background;
  CompanionPose pose;
  CompanionFaceExpression faceExpression;
  String accessory;
  List<String> unlockedItems;

  AvatarCustomizationModel({
    CompanionGender? gender,
    String? hairStyle,
    this.skinTone = 'medium',
    this.outfit = 'casual',
    this.background = 'playroom',
    this.pose = CompanionPose.standing,
    this.faceExpression = CompanionFaceExpression.happy,
    this.accessory = 'none',
    List<String>? unlockedItems,
  })  : gender = gender ?? CompanionGender.boy,
        hairStyle = hairStyle ?? ((gender ?? CompanionGender.boy) == CompanionGender.boy ? 'curly' : 'ponytail'),
        unlockedItems = unlockedItems ?? [
          'curly',
          'ponytail',
          'casual',
          'playroom',
          'standing',
          'waving',
          'medium',
          'light',
          'tan',
          'dark',
          'happy',
          'calm',
        ];

  bool isItemUnlocked(String itemId) {
    if (costOfItem(itemId) <= 0) return true;
    return unlockedItems.contains(itemId);
  }

  static int costOfItem(String itemId) {
    for (final item in [
      ...kBoyHairStyles,
      ...kGirlHairStyles,
      ...kSkinTones,
      ...kFaceExpressions,
      ...kOutfits,
      ...kBackgrounds,
      ...kPoses,
      ...kAccessories,
    ]) {
      if (item.id == itemId) return item.starsCost;
    }
    return 0;
  }

  bool tryUnlockItem(String itemId, int availableStars) {
    if (isItemUnlocked(itemId)) return true;
    final int cost = costOfItem(itemId);
    if (availableStars >= cost) {
      if (!unlockedItems.contains(itemId)) {
        unlockedItems.add(itemId);
      }
      return true;
    }
    return false;
  }

  AvatarCustomizationModel copyWith({
    CompanionGender? gender,
    String? hairStyle,
    String? skinTone,
    String? outfit,
    String? background,
    CompanionPose? pose,
    CompanionFaceExpression? faceExpression,
    String? accessory,
    List<String>? unlockedItems,
  }) {
    return AvatarCustomizationModel(
      gender: gender ?? this.gender,
      hairStyle: hairStyle ?? this.hairStyle,
      skinTone: skinTone ?? this.skinTone,
      outfit: outfit ?? this.outfit,
      background: background ?? this.background,
      pose: pose ?? this.pose,
      faceExpression: faceExpression ?? this.faceExpression,
      accessory: accessory ?? this.accessory,
      unlockedItems: unlockedItems ?? List<String>.from(this.unlockedItems),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'gender': gender.toJson(),
      'hairStyle': hairStyle,
      'skinTone': skinTone,
      'outfit': outfit,
      'background': background,
      'pose': pose.toJson(),
      'faceExpression': faceExpression.toJson(),
      'accessory': accessory,
      'unlockedItems': unlockedItems,
    };
  }

  factory AvatarCustomizationModel.fromJson(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) {
      return AvatarCustomizationModel();
    }
    final parsedGender = CompanionGender.fromJson(json['gender']?.toString());
    final defaultHair = parsedGender == CompanionGender.boy ? 'curly' : 'ponytail';

    return AvatarCustomizationModel(
      gender: parsedGender,
      hairStyle: (json['hairStyle'] ?? defaultHair).toString(),
      skinTone: (json['skinTone'] ?? 'medium').toString(),
      outfit: (json['outfit'] ?? 'casual').toString(),
      background: (json['background'] ?? 'playroom').toString(),
      pose: CompanionPose.fromJson(json['pose']?.toString()),
      faceExpression: CompanionFaceExpression.fromJson(json['faceExpression']?.toString()),
      accessory: (json['accessory'] ?? 'none').toString(),
      unlockedItems: (json['unlockedItems'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [
            'curly',
            'ponytail',
            'casual',
            'playroom',
            'standing',
            'waving',
            'medium',
            'light',
            'tan',
            'dark',
            'happy',
            'calm',
          ],
    );
  }
}
