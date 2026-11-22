import 'package:flutter/material.dart';
import 'package:haneen_kids_vod/haneen_kids_exports.dart';

/// Represents a single animated visual image card in an Interactive Story Carousel (`PageView`),
/// supporting Ken Burns slow zoom/pan, multi-layer parallax, touch pulse micro-animations,
/// and dual-voice narration alternating between:
/// - Primary Voice Assistant (`cUDXOxxuLZJdTcxEyGVB`)
/// - Superhero Voice Assistant (`L14QZl4DxSQ6xGvib36i`)
class StoryImageCardPage {
  final int pageIndex;
  final String imageIllustration;
  final String parallaxLayerEmoji;
  final String sceneTitle;
  final String narrationText;
  /// Either `'primary_assistant'` (`cUDXOxxuLZJdTcxEyGVB`) or `'superhero'` (`L14QZl4DxSQ6xGvib36i`).
  final String speakerRole;
  final String speakerNameAr;
  final String speakerAvatar;
  final int estimatedDurationSeconds;
  final double kenBurnsZoomTarget;
  final List<Color> gradientColors;

  const StoryImageCardPage({
    required this.pageIndex,
    required this.imageIllustration,
    this.parallaxLayerEmoji = '✨🌟☁️',
    required this.sceneTitle,
    required this.narrationText,
    required this.speakerRole,
    required this.speakerNameAr,
    required this.speakerAvatar,
    this.estimatedDurationSeconds = 36,
    this.kenBurnsZoomTarget = 1.08,
    this.gradientColors = const [Color(0xFF1E1B4B), Color(0xFF0F172A)],
  });

  bool get isSuperheroSpeaker => speakerRole == 'superhero';

  String get assignedVoiceId => isSuperheroSpeaker
      ? ElevenLabsVoiceService.kSuperheroCompanionVoiceId
      : ElevenLabsVoiceService.kPrimaryCustomVoiceId;

  String get assignedPersonaId =>
      isSuperheroSpeaker ? 'cheerful_friend' : 'storyteller';
}

class InteractiveEducationalStoryModel {
  final String id;
  final int storyNumber;
  final int academicTier; // 1 (2-3 yrs), 2 (3-4 yrs), 3 (4-5 yrs), 4 (5-6+ yrs)
  final String categoryId; // bedtime, habits, arabic, science, crafts
  final String categoryBadge;
  final String ageGroup;
  final String pedagogicalConcept;
  final List<String> learningOutcomes;
  final int totalEstimatedDurationSeconds; // 180..300 seconds (3 to 5 minutes)
  final String title;
  final String illustration;
  final String partOneText;
  final String choicePrompt;
  final String optionAText;
  final String optionAOutcome;
  final String optionBText;
  final String optionBOutcome;
  final String quizQuestion;
  final List<String> quizOptions;
  final String correctQuizAnswer;
  final String moralSummary;
  final List<StoryImageCardPage> storyCards;

  const InteractiveEducationalStoryModel({
    required this.id,
    this.storyNumber = 1,
    this.academicTier = 2,
    this.categoryId = 'bedtime',
    required this.categoryBadge,
    required this.ageGroup,
    this.pedagogicalConcept = 'التربية الأخلاقية والذكاء العاطفي',
    this.learningOutcomes = const [
      'تنمية الاستماع النشط والتركيز البصري',
      'اكتساب مفردات عربية فصيحة وسلوك إيجابي',
    ],
    this.totalEstimatedDurationSeconds = 216,
    required this.title,
    required this.illustration,
    required this.partOneText,
    required this.choicePrompt,
    required this.optionAText,
    required this.optionAOutcome,
    required this.optionBText,
    required this.optionBOutcome,
    required this.quizQuestion,
    required this.quizOptions,
    required this.correctQuizAnswer,
    required this.moralSummary,
    this.storyCards = const [],
  });

  int get totalEstimatedMinutes =>
      (totalEstimatedDurationSeconds / 60.0).round().clamp(3, 5);
}

const List<InteractiveEducationalStoryModel> kInteractiveOriginalStories = [
  InteractiveEducationalStoryModel(
    id: 'story_moon_rabbit',
    storyNumber: 1,
    academicTier: 1,
    categoryId: 'bedtime',
    categoryBadge: '🌙 قصة قبل النوم',
    ageGroup: '2–6 سنوات',
    pedagogicalConcept: 'عادات النوم الصحي والهدوء المسائي',
    learningOutcomes: [
      'ربط وقت المساء بالهدوء وتنظيف الأسنان وترتيب الغرفة',
      'تنمية الشعور بالأمان والسكينة قبل النوم',
    ],
    totalEstimatedDurationSeconds: 220,
    title: 'الأرنب الأبيض ونجمة المساء الهادئة',
    illustration: '🐰🌙✨',
    partOneText:
        'في المساء الهادئ، نظر الأرنب الصغير «سمسم» من نافذة غرفته فرأى نجمة لامعة في السماء تبتسم له وتقول: حان وقت الراحة يا سمسم ليستيقظ جسمك قوياً في الصباح.',
    choicePrompt: 'ماذا يختار الأرنب سمسم أن يفعل قبل أن ينام؟',
    optionAText: '(أ) يرتب لعبته وينظف أسنانه ويقرأ دعاء النوم 🪥🌙',
    optionAOutcome:
        'اختيار رائع! شعر سمسم بالنظافة والراحة، ونام نوماً هادئاً وجميلاً ورأى أحلاماً سعيدة في البستان الأخضر.',
    optionBText: '(ب) يتنفس ٣ أنفاس عميقة ويستمع لصوت الليل الهادئ 🧘✨',
    optionBOutcome:
        'اختيار لطيف! هدأ قلب سمسم تماماً، وأغمض عينيه بابتسامة مطمئنة حتى الصباح المشرق.',
    quizQuestion: 'ماذا تعلمنا من قصة الأرنب سمسم قبل النوم؟',
    quizOptions: [
      'الاستعداد الهادئ للنوم المبكر 🌙',
      'السهر الطويل المرهق',
      'اللعب الصاخب ليلاً',
    ],
    correctQuizAnswer: 'الاستعداد الهادئ للنوم المبكر 🌙',
    moralSummary: 'النوم المبكر والهادئ يمنح الجسم والعقل صحة وذكاءً ونشاطاً.',
    storyCards: [
      StoryImageCardPage(
        pageIndex: 0,
        imageIllustration: '🐰🪟🌙',
        parallaxLayerEmoji: '✨🌌⭐',
        sceneTitle: 'نافذة المساء',
        narrationText:
            'في المساء الهادئ، نظر الأرنب الصغير سمسم من نافذة غرفته فرأى نجمة لامعة تبتسم له في السماء.',
        speakerRole: 'primary_assistant',
        speakerNameAr: 'المساعد الصوتي الرئيسي',
        speakerAvatar: '🎙️✨',
        estimatedDurationSeconds: 38,
        gradientColors: [Color(0xFF1E1B4B), Color(0xFF0F172A)],
      ),
      StoryImageCardPage(
        pageIndex: 1,
        imageIllustration: '🦸‍♂️⭐💪',
        parallaxLayerEmoji: '🌟⚡🌙',
        sceneTitle: 'نصيحة البطل الخارق',
        narrationText:
            'قال البطل الخارق للأرنب سمسم بحماس: يا سمسم الشجاع، الأبطال ينامون مبكراً ليصبحوا أقوياء وأذكياء في الصباح!',
        speakerRole: 'superhero',
        speakerNameAr: 'السوبر هيرو (البطل الخارق)',
        speakerAvatar: '🦸‍♂️⚡',
        estimatedDurationSeconds: 38,
        gradientColors: [Color(0xFF0F766E), Color(0xFF1E293B)],
      ),
      StoryImageCardPage(
        pageIndex: 2,
        imageIllustration: '🐰🪥🧸',
        parallaxLayerEmoji: '🫧✨🧺',
        sceneTitle: 'ترتيب الغرفة وتنظيف الأسنان',
        narrationText:
            'ابتسم الأرنب سمسم ورتب ألعابه في الصندوق، ثم نظف أسنانه البيضاء بالفرشاة والمعجون بهدوء.',
        speakerRole: 'primary_assistant',
        speakerNameAr: 'المساعد الصوتي الرئيسي',
        speakerAvatar: '🎙️✨',
        estimatedDurationSeconds: 36,
        gradientColors: [Color(0xFF312E81), Color(0xFF0F172A)],
      ),
      StoryImageCardPage(
        pageIndex: 3,
        imageIllustration: '🐰🧘‍♂️🌿',
        parallaxLayerEmoji: '🍃🌙💫',
        sceneTitle: 'تنفس الاسترخاء العميق',
        narrationText:
            'همس البطل الخارق بلطف: هيا نأخذ ثلاثة أنفاس عميقة وهادئة مع سمسم لنشعر بالراحة والسكينة.',
        speakerRole: 'superhero',
        speakerNameAr: 'السوبر هيرو (البطل الخارق)',
        speakerAvatar: '🦸‍♂️⚡',
        estimatedDurationSeconds: 36,
        gradientColors: [Color(0xFF134E4A), Color(0xFF0F172A)],
      ),
      StoryImageCardPage(
        pageIndex: 4,
        imageIllustration: '🛏️📖🕯️',
        parallaxLayerEmoji: '🌙✨☁️',
        sceneTitle: 'حكاية ما قبل النوم',
        narrationText:
            'جلس سمسم في سريره الدافئ واستمع إلى حكاية المساء اللطيفة بينما ضوء القمر ينير الغرفة بهدوء.',
        speakerRole: 'primary_assistant',
        speakerNameAr: 'المساعد الصوتي الرئيسي',
        speakerAvatar: '🎙️✨',
        estimatedDurationSeconds: 36,
        gradientColors: [Color(0xFF1E1B4B), Color(0xFF0F172A)],
      ),
      StoryImageCardPage(
        pageIndex: 5,
        imageIllustration: '🐰💤🌈',
        parallaxLayerEmoji: '🌟💤🌙',
        sceneTitle: 'أحلام الأبطال السعيدة',
        narrationText:
            'هتف البطل الخارق: أحسنت يا سمسم! الآن أغمض عينيك بسلام واستمتع بأجمل الأحلام حتى الصباح المشرق!',
        speakerRole: 'superhero',
        speakerNameAr: 'السوبر هيرو (البطل الخارق)',
        speakerAvatar: '🦸‍♂️⚡',
        estimatedDurationSeconds: 36,
        gradientColors: [Color(0xFF1E3A8A), Color(0xFF0F172A)],
      ),
    ],
  ),
  InteractiveEducationalStoryModel(
    id: 'story_honest_bird',
    storyNumber: 2,
    academicTier: 2,
    categoryId: 'habits',
    categoryBadge: '❤️ أخلاق وسلوكيات',
    ageGroup: '3–6 سنوات',
    pedagogicalConcept: 'الأمانة والتعاون مع الأصدقاء والجيران',
    learningOutcomes: [
      'إدراك قيمة الأمانة وإعادة الأشياء لأصحابها',
      'تعزيز سلوك المشاركة والتعاون الإيجابي',
    ],
    totalEstimatedDurationSeconds: 216,
    title: 'العصفور الصادق وحبة القمح الذهبية',
    illustration: '🐦🌾🤝',
    partOneText:
        'وجد العصفور الصغير «ريشة» حبة قمح كبيرة سقطت من سلة جارته السنجابة «بندقة» وهي عائدة إلى شجرتها.',
    choicePrompt: 'كيف يتصرف العصفور الأمين «ريشة» الآن؟',
    optionAText: '(أ) يطير فوراً إلى السنجابة بندقة ويعيد إليها حبة القمح 🤝',
    optionAOutcome:
        'ما أجمل الأمانة! فرحت السنجابة بندقة جداً بأمانة العصفور ريشة، وأهدته نصف الحبة ليأكلاها معاً بمحبة!',
    optionBText: '(ب) ينادي أصدقاءه في الغابة ليساعدوا السنجابة في حمل سلتها 🐿️',
    optionBOutcome:
        'تعاون نبيل! شكر الجميع العصفور ريشة على أمانته وحبه لمساعدة جيرانه.',
    quizQuestion: 'ما الخلق الجميل الذي تحلى به العصفور ريشة؟',
    quizOptions: [
      'الأمانة والتعاون مع الجيران 🤝',
      'الأنانية',
      'إهمال الآخرين',
    ],
    correctQuizAnswer: 'الأمانة والتعاون مع الجيران 🤝',
    moralSummary: 'الأمانة والصدق والمشاركة تجعل الجميع يحبوننا ويثقون بنا.',
    storyCards: [
      StoryImageCardPage(
        pageIndex: 0,
        imageIllustration: '🐦🌾🌳',
        parallaxLayerEmoji: '🍃☀️🌸',
        sceneTitle: 'حبة القمح الذهبية',
        narrationText:
            'في صباح مشرق، وجد العصفور الصغير ريشة حبة قمح ذهبية سقطت من سلة جارته السنجابة بندقة.',
        speakerRole: 'primary_assistant',
        speakerNameAr: 'المساعد الصوتي الرئيسي',
        speakerAvatar: '🎙️✨',
        estimatedDurationSeconds: 36,
        gradientColors: [Color(0xFF065F46), Color(0xFF0F172A)],
      ),
      StoryImageCardPage(
        pageIndex: 1,
        imageIllustration: '🦸‍♂️🦅✨',
        parallaxLayerEmoji: '⚡🌟🛡️',
        sceneTitle: 'نداء الأمانة والشجاعة',
        narrationText:
            'ظهر البطل الخارق وقال: الأمانة قوة خارقة يا ريشة! البطل الحقيقي يعيد الأمانات لأصحابها فوراً!',
        speakerRole: 'superhero',
        speakerNameAr: 'السوبر هيرو (البطل الخارق)',
        speakerAvatar: '🦸‍♂️⚡',
        estimatedDurationSeconds: 36,
        gradientColors: [Color(0xFF1E3A8A), Color(0xFF0F172A)],
      ),
      StoryImageCardPage(
        pageIndex: 2,
        imageIllustration: '🐦🐿️🤝',
        parallaxLayerEmoji: '🌳🌺🦋',
        sceneTitle: 'إعادة الأمانة للسنجابة',
        narrationText:
            'طار العصفور ريشة بجناحيه السريعين نحو شجرة السنجابة بندقة وأعاد إليها حبة القمح الذهبية بابتسامة.',
        speakerRole: 'primary_assistant',
        speakerNameAr: 'المساعد الصوتي الرئيسي',
        speakerAvatar: '🎙️✨',
        estimatedDurationSeconds: 36,
        gradientColors: [Color(0xFF312E81), Color(0xFF0F172A)],
      ),
      StoryImageCardPage(
        pageIndex: 3,
        imageIllustration: '🐿️🧺💛',
        parallaxLayerEmoji: '✨🌾🌼',
        sceneTitle: 'فرحة الجارة بندقة',
        narrationText:
            'قال البطل الخارق بابتسامة: انظر كيف أشرق وجه السنجابة بندقة بالسعادة عندما رأت أمانتك يا ريشة!',
        speakerRole: 'superhero',
        speakerNameAr: 'السوبر هيرو (البطل الخارق)',
        speakerAvatar: '🦸‍♂️⚡',
        estimatedDurationSeconds: 36,
        gradientColors: [Color(0xFF0F766E), Color(0xFF0F172A)],
      ),
      StoryImageCardPage(
        pageIndex: 4,
        imageIllustration: '🐦🐿️🥖',
        parallaxLayerEmoji: '☀️🍃🎶',
        sceneTitle: 'اقتسام الخير بمحبة',
        narrationText:
            'قدمت السنجابة بندقة نصف حبة القمح هدية للعصفور الأمين ريشة ليأكلا معاً في ظل الشجرة.',
        speakerRole: 'primary_assistant',
        speakerNameAr: 'المساعد الصوتي الرئيسي',
        speakerAvatar: '🎙️✨',
        estimatedDurationSeconds: 36,
        gradientColors: [Color(0xFF1E1B4B), Color(0xFF0F172A)],
      ),
      StoryImageCardPage(
        pageIndex: 5,
        imageIllustration: '🏆🎉💛',
        parallaxLayerEmoji: '🌟👑✨',
        sceneTitle: 'وسام الأمانة الذهبي',
        narrationText:
            'صفق البطل الخارق بحماس: برافو يا ريشة الأمين! الأمانة والصدق يجعلان كل أصدقاء الغابة يحبونك!',
        speakerRole: 'superhero',
        speakerNameAr: 'السوبر هيرو (البطل الخارق)',
        speakerAvatar: '🦸‍♂️⚡',
        estimatedDurationSeconds: 36,
        gradientColors: [Color(0xFF065F46), Color(0xFF0F172A)],
      ),
    ],
  ),
  InteractiveEducationalStoryModel(
    id: 'story_letters_garden',
    storyNumber: 3,
    academicTier: 3,
    categoryId: 'arabic',
    categoryBadge: '🔤 تعلم الكلمات والحروف',
    ageGroup: '4–6 سنوات',
    pedagogicalConcept: 'الفصاحة اللغوية وتمييز الحروف العربية',
    learningOutcomes: [
      'ربط الحروف العربية بأصواتها وكلماتها المصورة',
      'نطق جمل عربية فصيحة بوضوح وثقة',
    ],
    totalEstimatedDurationSeconds: 224,
    title: 'مغامرة بستان الحروف العربية المضيئة',
    illustration: '🌳📖🦋',
    partOneText:
        'في بستان الحروف العربية المضيئة، ظهرت ثلاث لافتات ذهبية مكتوباً عليها كلمات عربية فصيحة: (شَمْسٌ ☀️) و(قَمَرٌ 🌙) و(نَجْمَةٌ ⭐).',
    choicePrompt: 'أي لافتة نختار قراءتها أولاً؟',
    optionAText: '(أ) لافتة (شَمْسٌ مُشْرِقَةٌ) التي تبدأ بحرف الشين ☀️',
    optionAOutcome:
        'أشرق البستان بالضوء الدافئ، وتعلمنا أن كلمة (شَمْس) تبدأ بحرف الشين (ش) ذي الثلاث نقاط!',
    optionBText: '(ب) لافتة (قَمَرٌ مُنِيرٌ) التي تبدأ بحرف القاف 🌙',
    optionBOutcome:
        'تلألأ نور القمر اللطيف، وتعلمنا أن كلمة (قَمَر) تبدأ بحرف القاف (ق) الفصيح!',
    quizQuestion: 'بأي حرف تبدأ كلمة (شَمْسٌ)؟',
    quizOptions: ['بحرف الشين (ش) ☀️', 'بحرف الباء (ب)', 'بحرف الميم (م)'],
    correctQuizAnswer: 'بحرف الشين (ش) ☀️',
    moralSummary: 'قراءة الكلمات العربية الفصحى تزيدنا ذكاءً وفصاحة وجمالاً.',
    storyCards: [
      StoryImageCardPage(
        pageIndex: 0,
        imageIllustration: '🌳☀️🔤',
        parallaxLayerEmoji: '🦋🌸✨',
        sceneTitle: 'بوابة بستان الحروف',
        narrationText:
            'عند بوابة بستان الحروف العربية المضيئة، ظهرت لافتة ذهبية جميلة مكتوباً عليها كلمة شمس.',
        speakerRole: 'primary_assistant',
        speakerNameAr: 'المساعد الصوتي الرئيسي',
        speakerAvatar: '🎙️✨',
        estimatedDurationSeconds: 38,
        gradientColors: [Color(0xFF4C1D95), Color(0xFF0F172A)],
      ),
      StoryImageCardPage(
        pageIndex: 1,
        imageIllustration: '🦸‍♂️☀️🔊',
        parallaxLayerEmoji: '☀️⚡🌟',
        sceneTitle: 'تحدي السوبر هيرو لحرف الشين',
        narrationText:
            'نطق البطل الخارق بصوت واضح وحماسي: شين، شمس مشرقة! فوق حرف الشين ثلاث نقاط جميلة تضيء السماء!',
        speakerRole: 'superhero',
        speakerNameAr: 'السوبر هيرو (البطل الخارق)',
        speakerAvatar: '🦸‍♂️⚡',
        estimatedDurationSeconds: 38,
        gradientColors: [Color(0xFF0F766E), Color(0xFF0F172A)],
      ),
      StoryImageCardPage(
        pageIndex: 2,
        imageIllustration: '🌙⭐📖',
        parallaxLayerEmoji: '🌌✨🌙',
        sceneTitle: 'لافتة القمر والنجمة',
        narrationText:
            'وتابعت الراوية السرد قائلة: وعند البحيرة الهادئة، ظهرت كلمة قمر التي تبدأ بحرف القاف الفصيح.',
        speakerRole: 'primary_assistant',
        speakerNameAr: 'المساعد الصوتي الرئيسي',
        speakerAvatar: '🎙️✨',
        estimatedDurationSeconds: 36,
        gradientColors: [Color(0xFF1E1B4B), Color(0xFF0F172A)],
      ),
      StoryImageCardPage(
        pageIndex: 3,
        imageIllustration: '🦸‍♂️🌙🎯',
        parallaxLayerEmoji: '💫🌟⚡',
        sceneTitle: 'ترديد الكلمات الفصيحة',
        narrationText:
            'قال البطل الخارق: هيا نردد معاً بصوت واضح وجميل: شمس مشرقة، قمر منير، نجمة لامعة!',
        speakerRole: 'superhero',
        speakerNameAr: 'السوبر هيرو (البطل الخارق)',
        speakerAvatar: '🦸‍♂️⚡',
        estimatedDurationSeconds: 36,
        gradientColors: [Color(0xFF134E4A), Color(0xFF0F172A)],
      ),
      StoryImageCardPage(
        pageIndex: 4,
        imageIllustration: '📚🌈🕊️',
        parallaxLayerEmoji: '🌸🍃✨',
        sceneTitle: 'شجرة الكلمات الذكية',
        narrationText:
            'أثمرت شجرة المعرفة في البستان حروفاً ملونة تبتسم لكل طفل يقرأ الكلمات بوضوح وهدوء.',
        speakerRole: 'primary_assistant',
        speakerNameAr: 'المساعد الصوتي الرئيسي',
        speakerAvatar: '🎙️✨',
        estimatedDurationSeconds: 38,
        gradientColors: [Color(0xFF312E81), Color(0xFF0F172A)],
      ),
      StoryImageCardPage(
        pageIndex: 5,
        imageIllustration: '👑🌟🎓',
        parallaxLayerEmoji: '🏆✨🎉',
        sceneTitle: 'وسام الفصاحة والذكاء',
        narrationText:
            'أعلن البطل الخارق بفخر: أنتم أبطال الفصاحة! لقد أتقنتم قراءة كلمات البستان بكل ذكاء وتميز!',
        speakerRole: 'superhero',
        speakerNameAr: 'السوبر هيرو (البطل الخارق)',
        speakerAvatar: '🦸‍♂️⚡',
        estimatedDurationSeconds: 38,
        gradientColors: [Color(0xFF1E3A8A), Color(0xFF0F172A)],
      ),
    ],
  ),
];

/// Scalable Academic Story Repository supporting 100 to 500 structured educational stories
/// (each timed at 3 to 5 minutes = 180 to 300 seconds across 6 animated dual-voice image cards).
class AcademicStoriesRepository {
  static const int kMinSupportedStories = 100;
  static const int kMaxSupportedStories = 500;
  static const int kDefaultCatalogSize = 200;

  static final List<Map<String, dynamic>> _academicDomains = [
    {
      'categoryId': 'bedtime',
      'badge': '🌙 قصص النوم والهدوء',
      'concept': 'الاسترخاء المسائي وتنظيم النوم الصحي',
      'heroEmoji': '🐰🌙✨',
      'parallax': '🌌⭐☁️',
      'titlePrefix': 'حكاية نجمة المساء والهدوء',
      'gradientStart': const Color(0xFF1E1B4B),
      'gradientEnd': const Color(0xFF0F172A),
    },
    {
      'categoryId': 'habits',
      'badge': '🧸 السلوكيات والأخلاق',
      'concept': 'الأمانة والتعاون والنظام واحترام الوالدين',
      'heroEmoji': '🦁🤝🌟',
      'parallax': '🌿🌸✨',
      'titlePrefix': 'مغامرة البطل الأمين في الغابة',
      'gradientStart': const Color(0xFF065F46),
      'gradientEnd': const Color(0xFF0F172A),
    },
    {
      'categoryId': 'arabic',
      'badge': '🗣️ الفصاحة والنطق العربي',
      'concept': 'مخارج الحروف العربية وبناء الجمل الفصيحة',
      'heroEmoji': '📖🔤🦋',
      'parallax': '✨📚🌈',
      'titlePrefix': 'رحلة الكلمات المضيئة في بستان الفصاحة',
      'gradientStart': const Color(0xFF312E81),
      'gradientEnd': const Color(0xFF0F172A),
    },
    {
      'categoryId': 'science',
      'badge': '🦋 العلوم والطبيعة المبسطة',
      'concept': 'التفكير العلمي واكتشاف عجائب الطبيعة والفضاء',
      'heroEmoji': '🔬🌍🐬',
      'parallax': '🌊☀️🍃',
      'titlePrefix': 'المستكشف الصغير وأسرار الطبيعة',
      'gradientStart': const Color(0xFF0F766E),
      'gradientEnd': const Color(0xFF0F172A),
    },
    {
      'categoryId': 'crafts',
      'badge': '🎨 الإبداع والمهارات اليدوية',
      'concept': 'تنمية المهارات الحركية الدقيقة والتفكير الابتكاري',
      'heroEmoji': '🎨🧩🚀',
      'parallax': '🎈✨⭐',
      'titlePrefix': 'مرسم الإبداع وبناء الأبراج الذكية',
      'gradientStart': const Color(0xFF78350F),
      'gradientEnd': const Color(0xFF0F172A),
    },
  ];

  static final List<String> _ageGroupsByTier = [
    '2–3 سنوات',
    '3–4 سنوات',
    '4–5 سنوات',
    '5–6 سنوات',
  ];

  /// Generates an academic catalog of `count` stories (clamped between 100 and 500).
  static List<InteractiveEducationalStoryModel> getStoriesCatalog({
    int count = kDefaultCatalogSize,
  }) {
    final int targetCount =
        count.clamp(kMinSupportedStories, kMaxSupportedStories);
    final List<InteractiveEducationalStoryModel> catalog = [
      ...kInteractiveOriginalStories,
    ];

    for (int i = catalog.length; i < targetCount; i++) {
      final int storyNum = i + 1;
      final int tier = (i % 4) + 1;
      final String ageGroup = _ageGroupsByTier[tier - 1];
      final Map<String, dynamic> domain =
          _academicDomains[i % _academicDomains.length];
      final String catId = domain['categoryId'] as String;
      final String badge = domain['badge'] as String;
      final String concept = domain['concept'] as String;
      final String emoji = domain['heroEmoji'] as String;
      final String parallax = domain['parallax'] as String;
      final String title = '${domain['titlePrefix']} (القصة الأكاديمية $storyNum)';
      // Duration strictly between 180 and 300 seconds (3 to 5 minutes)
      final int durationSecs = 192 + ((i * 18) % 102);
      final int perCardSecs = (durationSecs / 6).round();

      final List<StoryImageCardPage> cards = [
        StoryImageCardPage(
          pageIndex: 0,
          imageIllustration: emoji,
          parallaxLayerEmoji: parallax,
          sceneTitle: 'بداية الرحلة التعليمية ($storyNum)',
          narrationText:
              'في هذه القصة التفاعلية رقم $storyNum، نبدأ رحلتنا الهادئة لتعلم $concept بأسلوب ممتع ومصور.',
          speakerRole: 'primary_assistant',
          speakerNameAr: 'المساعد الصوتي الرئيسي',
          speakerAvatar: '🎙️✨',
          estimatedDurationSeconds: perCardSecs,
          gradientColors: [
            domain['gradientStart'] as Color,
            domain['gradientEnd'] as Color,
          ],
        ),
        StoryImageCardPage(
          pageIndex: 1,
          imageIllustration: '🦸‍♂️⚡🌟',
          parallaxLayerEmoji: parallax,
          sceneTitle: 'إشراقة السوبر هيرو',
          narrationText:
              'قال السوبر هيرو بحماس: أهلاً بك يا بطل! عندما نطبق $concept نصبح أكثر ذكاءً وشجاعة كل يوم!',
          speakerRole: 'superhero',
          speakerNameAr: 'السوبر هيرو (البطل الخارق)',
          speakerAvatar: '🦸‍♂️⚡',
          estimatedDurationSeconds: perCardSecs,
          gradientColors: const [Color(0xFF0F766E), Color(0xFF1E293B)],
        ),
        StoryImageCardPage(
          pageIndex: 2,
          imageIllustration: '📖🌱🔍',
          parallaxLayerEmoji: parallax,
          sceneTitle: 'الملاحظة والاكتشاف',
          narrationText:
              'تابعت الراوية قائلة: تأمل الصور المتحركة بهدوء والمس الشاشة لتتفاعل مع عناصر القصة وتكتشف سر المهارة.',
          speakerRole: 'primary_assistant',
          speakerNameAr: 'المساعد الصوتي الرئيسي',
          speakerAvatar: '🎙️✨',
          estimatedDurationSeconds: perCardSecs,
          gradientColors: const [Color(0xFF312E81), Color(0xFF0F172A)],
        ),
        StoryImageCardPage(
          pageIndex: 3,
          imageIllustration: '🦸‍♂️🎯💡',
          parallaxLayerEmoji: parallax,
          sceneTitle: 'خطوة البطل الذكية',
          narrationText:
              'هتف السوبر هيرو: يا لها من فكرة ذكية! التعاون والتركيز الهادئ يساعداننا على النجاح في كل مهمة!',
          speakerRole: 'superhero',
          speakerNameAr: 'السوبر هيرو (البطل الخارق)',
          speakerAvatar: '🦸‍♂️⚡',
          estimatedDurationSeconds: perCardSecs,
          gradientColors: const [Color(0xFF1E3A8A), Color(0xFF0F172A)],
        ),
        StoryImageCardPage(
          pageIndex: 4,
          imageIllustration: '🌈🕊️🤝',
          parallaxLayerEmoji: parallax,
          sceneTitle: 'تطبيق المهارة في يومنا',
          narrationText:
              'والآن نطبق ما تعلمناه في القصة رقم $storyNum بهدوء وثقة مع العائلة والأصدقاء.',
          speakerRole: 'primary_assistant',
          speakerNameAr: 'المساعد الصوتي الرئيسي',
          speakerAvatar: '🎙️✨',
          estimatedDurationSeconds: perCardSecs,
          gradientColors: const [Color(0xFF1E1B4B), Color(0xFF0F172A)],
        ),
        StoryImageCardPage(
          pageIndex: 5,
          imageIllustration: '🏆👑🎉',
          parallaxLayerEmoji: parallax,
          sceneTitle: 'وسام الإتقان والبطولة',
          narrationText:
              'اختتم السوبر هيرو القصة قائلاً: أحسنت الاستماع والتركيز يا بطل! أنت مستعد الآن لسؤال القصة الممتع!',
          speakerRole: 'superhero',
          speakerNameAr: 'السوبر هيرو (البطل الخارق)',
          speakerAvatar: '🦸‍♂️⚡',
          estimatedDurationSeconds: perCardSecs,
          gradientColors: const [Color(0xFF065F46), Color(0xFF0F172A)],
        ),
      ];

      catalog.add(
        InteractiveEducationalStoryModel(
          id: 'story_academic_$storyNum',
          storyNumber: storyNum,
          academicTier: tier,
          categoryId: catId,
          categoryBadge: badge,
          ageGroup: ageGroup,
          pedagogicalConcept: concept,
          learningOutcomes: [
            'إتقان مفهوم ($concept) للمستوى العمري ($ageGroup)',
            'التفاعل البصري والصوتي مع السرد المزدوج لمدة ٣–٥ دقائق',
          ],
          totalEstimatedDurationSeconds: durationSecs,
          title: title,
          illustration: emoji,
          partOneText: cards.first.narrationText,
          choicePrompt: 'ما التصرف الأفضل الذي نتعلمه من هذه القصة؟',
          optionAText: '(أ) تطبيق $concept بهدوء وذكاء 🌟',
          optionAOutcome: 'اختيار ممتاز يعكس فهمك العميق للقصة!',
          optionBText: '(ب) مشاركة ما تعلمناه مع الأسرة 🤝',
          optionBOutcome: 'مشاركة رائعة تزيد المعرفة والمحبة!',
          quizQuestion: 'ما المفهوم التربوي الأساسي في «$title»؟',
          quizOptions: [
            concept,
            'التسرع وعدم التركيز',
            'إهمال الترتيب',
          ],
          correctQuizAnswer: concept,
          moralSummary: 'تعلم ($concept) يمنح الطفل ثقة وذكاءً وسلوكاً راقياً.',
          storyCards: cards,
        ),
      );
    }

    return catalog;
  }

  static final List<InteractiveEducationalStoryModel> defaultCatalog =
      getStoriesCatalog(count: kDefaultCatalogSize);

  static InteractiveEducationalStoryModel findStoryForFeedItem(
    String idOrTitle, {
    String category = 'bedtime',
  }) {
    for (final s in defaultCatalog) {
      if (s.id == idOrTitle || s.title == idOrTitle) {
        return s;
      }
    }
    return defaultCatalog.firstWhere(
      (s) => s.categoryId == category,
      orElse: () => defaultCatalog.first,
    );
  }
}
