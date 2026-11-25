import 'package:flutter/material.dart';

class AcademyTrackLessonModel {
  final String id;
  final String trackId;
  final String trackTitle;
  final String trackIcon;
  final Color accentColor;
  final String ageSuitability;
  final String levelName;
  final int tierLevel; // 1: تمهيدي (2-3), 2: مبتدئ (3-4), 3: متوسط (4-5), 4: متقدم (5-6)
  final String skillKey;
  final int requiredMasteryScore;
  final String title;
  final String illustrationEmoji;
  final String introductionText;
  final String targetWordOrPhrase;
  final String interactivePrompt;
  final List<Map<String, String>> interactiveVisualCards;
  final String quizQuestion;
  final List<String> quizOptions;
  final String correctOption;
  final String alternativeRemediationQuestion;
  final List<String> alternativeRemediationOptions;
  final String alternativeRemediationCorrect;
  final String alternativeRemediationActivity;
  final String parentHomeTip;
  final String rewardSticker;
  /// Phase 2: explicit opt-in for the separate answer-reveal action.
  /// Default false — existing lessons never expose their original answers
  /// unless this is enabled per lesson. Tier 3 hints always show a worked
  /// example of a similar problem instead.
  final bool allowsAnswerReveal;

  const AcademyTrackLessonModel({
    required this.id,
    required this.trackId,
    required this.trackTitle,
    required this.trackIcon,
    required this.accentColor,
    required this.ageSuitability,
    required this.levelName,
    this.tierLevel = 1,
    this.skillKey = '',
    this.requiredMasteryScore = 80,
    required this.title,
    required this.illustrationEmoji,
    required this.introductionText,
    required this.targetWordOrPhrase,
    required this.interactivePrompt,
    required this.interactiveVisualCards,
    required this.quizQuestion,
    required this.quizOptions,
    required this.correctOption,
    this.alternativeRemediationQuestion = '',
    this.alternativeRemediationOptions = const [],
    this.alternativeRemediationCorrect = '',
    this.alternativeRemediationActivity =
        '🎵 نشاط بديل ممتع: المس البطاقات بالترتيب واستمع للنغمة الصوتية البطيئة ثم صفق بيديك مع كل كلمة!',
    this.parentHomeTip =
        '🏠 نشاط منزلي للوالدين: أشر إلى أشياء حقيقية في المنزل مرتبطة بالدرس واطلب من طفلك تسميتها بابتسامة.',
    required this.rewardSticker,
    this.allowsAnswerReveal = false,
  });

  String get emoji =>
      illustrationEmoji.isNotEmpty ? illustrationEmoji : trackIcon;
  String get recommendedLevel => levelName;
  String get ageRange => ageSuitability;
  String get pedagogicalGoal => introductionText;

  int get correctOptionIndex {
    final int idx = quizOptions.indexOf(correctOption);
    return idx >= 0 ? idx : 0;
  }

  int get alternativeRemediationCorrectIndex {
    final int idx =
        alternativeRemediationOptions.indexOf(alternativeRemediationCorrect);
    return idx >= 0 ? idx : 0;
  }

  List<AcademyLessonVisualCard> get cards => interactiveVisualCards
      .map(
        (m) => AcademyLessonVisualCard(
          symbol: m['label'] ?? m['symbol'] ?? m['title'] ?? '',
          wordExample: m['label'] ?? m['wordExample'] ?? title,
          emoji: m['emoji'] ?? emoji,
          spokenNarration:
              m['speak'] ?? m['spokenNarration'] ?? introductionText,
        ),
      )
      .toList();
}

typedef AcademyTrackLesson = AcademyTrackLessonModel;

class AcademyLessonVisualCard {
  final String symbol;
  final String wordExample;
  final String emoji;
  final String spokenNarration;

  const AcademyLessonVisualCard({
    required this.symbol,
    required this.wordExample,
    required this.emoji,
    required this.spokenNarration,
  });
}

const List<AcademyTrackLessonModel> kHaneenAcademyCurriculum = [
  // ===========================================================================
  // المسار ١: الحروف العربية (Arabic Letters — Tiers 1 to 4)
  // ===========================================================================
  AcademyTrackLessonModel(
    id: 'les_arabic_alif',
    trackId: 'arabic_letters',
    trackTitle: '١. الحروف العربية',
    trackIcon: '🔤',
    accentColor: Color(0xFF14B8A6),
    ageSuitability: '2–3 سنوات',
    levelName: 'تمهيدي',
    tierLevel: 1,
    skillKey: 'arabic_letter_alif',
    title: 'حرف الألف (أ) — أَسَدٌ وَأَرْنَبٌ',
    illustrationEmoji: '🦁🐰',
    introductionText:
        'حرف الألف (أ) هو أول حروف لغتنا العربية! المس الصور لتسمع صوت الحرف والكلمة.',
    targetWordOrPhrase: 'أ — أَسَدٌ ، أَرْنَبٌ ، أَنَانَاسٌ',
    interactivePrompt: 'المس كل صورة لتستمع إلى نطقها وترددها:',
    interactiveVisualCards: [
      {'emoji': '🦁', 'label': 'أَسَدٌ', 'speak': 'أَ ، أَسَدٌ شُجَاعٌ'},
      {'emoji': '🐰', 'label': 'أَرْنَبٌ', 'speak': 'أَ ، أَرْنَبٌ سَرِيعٌ'},
      {'emoji': '🍍', 'label': 'أَنَانَاسٌ', 'speak': 'أَ ، أَنَانَاسٌ لَذِيذٌ'},
    ],
    quizQuestion: 'أي صورة تبدأ بحرف الألف (أ)؟',
    quizOptions: ['🐰 أَرْنَبٌ', '🦆 بَطَّةٌ', '🍎 تُفَّاحَةٌ'],
    correctOption: '🐰 أَرْنَبٌ',
    alternativeRemediationQuestion:
        '🎲 سؤال بديل بالصوت والصورة: من هو ملك الغابة الذي يبدأ اسمه بصوت (أَ)؟',
    alternativeRemediationOptions: ['🦁 أَسَدٌ', '🐟 سَمَكَةٌ'],
    alternativeRemediationCorrect: '🦁 أَسَدٌ',
    alternativeRemediationActivity:
        '🎭 إعادة تقديم ممتعة: قفز الأرنب (أَرْنَبٌ 🐰) ثلاث قفزات وقال: اسمي يبدأ بصوت (أَ)! قلد قفزة الأرنب وقل: أَ - أَرْنَب!',
    parentHomeTip:
        '🏠 نصيحة للوالدين: ارسم حرف (أ) كبيراً في الهواء بإصبعك مع طفلك، وابحثا في الغرفة عن شيء يبدأ بحرف الألف.',
    rewardSticker: '🌟 وسام حرف الألف',
  ),
  AcademyTrackLessonModel(
    id: 'les_arabic_baa',
    trackId: 'arabic_letters',
    trackTitle: '١. الحروف العربية',
    trackIcon: '🔤',
    accentColor: Color(0xFF14B8A6),
    ageSuitability: '3–4 سنوات',
    levelName: 'مبتدئ',
    tierLevel: 2,
    skillKey: 'arabic_letters_baa_taa',
    title: 'حرف الباء والتاء (ب ، ت) — بَطَّةٌ وَتُفَّاحَةٌ',
    illustrationEmoji: '🦆🍎',
    introductionText:
        'حرف الباء (ب) تحته نقطة واحدة، وحرف التاء (ت) فوقه نقطتان جميلتان كالعينين!',
    targetWordOrPhrase: 'ب — بَطَّةٌ ، بَيْتٌ | ت — تُفَّاحَةٌ ، تَاجٌ',
    interactivePrompt: 'المس البطاقات لتسمع الفرق بين صوت (ب) وصوت (ت):',
    interactiveVisualCards: [
      {'emoji': '🦆', 'label': 'بَطَّةٌ', 'speak': 'بَ ، بَطَّةٌ تَسْبَحُ'},
      {'emoji': '🏠', 'label': 'بَيْتٌ', 'speak': 'بَ ، بَيْتٌ جَمِيلٌ'},
      {'emoji': '🍎', 'label': 'تُفَّاحَةٌ', 'speak': 'تَ ، تُفَّاحَةٌ حَمْرَاءُ'},
    ],
    quizQuestion: 'أي كلمة تبدأ بحرف الباء (ب)؟',
    quizOptions: ['🦆 بَطَّةٌ', '🦁 أَسَدٌ', '☀️ شَمْسٌ'],
    correctOption: '🦆 بَطَّةٌ',
    alternativeRemediationQuestion:
        '🎲 طريقة أخرى: أي فاكهة حمراء لذيذة تبدأ بحرف التاء (ت) ذي النقطتين؟',
    alternativeRemediationOptions: ['🍎 تُفَّاحَةٌ', '🍌 مَوْزٌ'],
    alternativeRemediationCorrect: '🍎 تُفَّاحَةٌ',
    alternativeRemediationActivity:
        '🎵 أغنية النقاط: الباء (ب) نقطة تحت الطبق 🦆، والتاء (ت) نقطتان فوق الطبق 🍎!',
    parentHomeTip:
        '🏠 نصيحة للوالدين: ضع حبة فاكهة أو لعبة تحت الطاولة لتمثيل نقطة الباء (ب)، وحبتين فوق الطاولة لتمثيل نقطتي التاء (ت).',
    rewardSticker: '🌟 وسام الباء والتاء',
  ),
  AcademyTrackLessonModel(
    id: 'les_arabic_jeem',
    trackId: 'arabic_letters',
    trackTitle: '١. الحروف العربية',
    trackIcon: '🔤',
    accentColor: Color(0xFF14B8A6),
    ageSuitability: '4–5 سنوات',
    levelName: 'متوسط',
    tierLevel: 3,
    skillKey: 'arabic_letters_jeem_haa',
    title: 'حروف الجيم والحاء والخاء (ج ، ح ، خ)',
    illustrationEmoji: '🐪🕊️🐑',
    introductionText:
        'الجيم (ج) في بطنه نقطة مثل جَمَل 🐪، والحاء (ح) بلا نقاط مثل حَمَامَة 🕊️، والخاء (خ) فوق رأسه نقطة مثل خَرُوف 🐑!',
    targetWordOrPhrase: 'جَمَلٌ ، حَمَامَةٌ ، خَرُوفٌ',
    interactivePrompt: 'المس كل حيوان لتكتشف حرف اسمه ومكان النقطة:',
    interactiveVisualCards: [
      {'emoji': '🐪', 'label': 'ج — جَمَلٌ', 'speak': 'جَ ، جَمَلٌ صَبُورٌ فِي الصَّحْرَاءِ'},
      {'emoji': '🕊️', 'label': 'ح — حَمَامَةٌ', 'speak': 'حَ ، حَمَامَةٌ بَيْضَاءُ تَطِيرُ'},
      {'emoji': '🐑', 'label': 'خ — خَرُوفٌ', 'speak': 'خَ ، خَرُوفٌ يَأْكُلُ العُشْبَ'},
    ],
    quizQuestion: 'أي كلمة تبدأ بحرف الجيم (ج) الذي في بطنه نقطة؟',
    quizOptions: ['🐪 جَمَلٌ', '🕊️ حَمَامَةٌ', '🐑 خَرُوفٌ'],
    correctOption: '🐪 جَمَلٌ',
    alternativeRemediationActivity:
        '🎨 قصة الأخوة الثلاثة: الجيم أكل تفاحة فصارت النقطة في بطنه (ج)، والحاء لم يأكل شيئاً (ح)، والخاء وضع قبعة فوق رأسه (خ)!',
    parentHomeTip:
        '🏠 نصيحة للوالدين: العب مع طفلك لعبة «أين النقطة؟» بالإشارة إلى البطن لحرف الجيم وفوق الرأس لحرف الخاء.',
    rewardSticker: '🐪 وسام عائلة الجيم',
  ),
  AcademyTrackLessonModel(
    id: 'les_arabic_harakat',
    trackId: 'arabic_letters',
    trackTitle: '١. الحروف العربية',
    trackIcon: '🔤',
    accentColor: Color(0xFF14B8A6),
    ageSuitability: '5–6 سنوات',
    levelName: 'متقدم',
    tierLevel: 4,
    skillKey: 'arabic_short_vowels_reading',
    title: 'الحركات القصيرة وتكوين الكلمات (أَ ، أُ ، إِ)',
    illustrationEmoji: '📖✨',
    introductionText:
        'الفتحة تفتح فمنا للأعلى (أَ)، والضمة تضم شفتينا (أُ)، والكسرة تبتسم للأسفل (إِ)!',
    targetWordOrPhrase: 'أَ (أَسَدٌ) — أُ (أُذُنٌ) — إِ (إِبْرِيقٌ)',
    interactivePrompt: 'المس كل حركة لتسمع تغيّر صوت الحرف وتقرأ الكلمة:',
    interactiveVisualCards: [
      {'emoji': '🦁', 'label': 'أَ — فَتْحَة', 'speak': 'أَ ، فَتْحَة ، أَسَدٌ'},
      {'emoji': '👂', 'label': 'أُ — ضَمَّة', 'speak': 'أُ ، ضَمَّة ، أُذُنٌ'},
      {'emoji': '🫖', 'label': 'إِ — كَسْرَة', 'speak': 'إِ ، كَسْرَة ، إِبْرِيقٌ'},
    ],
    quizQuestion: 'بأي حركة نضمّ شفتينا عندما ننطق كلمة (أُذُنٌ 👂)؟',
    quizOptions: ['أُ — الضَّمَّة', 'أَ — الفَتْحَة', 'إِ — الكَسْرَة'],
    correctOption: 'أُ — الضَّمَّة',
    alternativeRemediationActivity:
        '🤸 حركة الجسم: ارفع يدك فوق رأسك للفتحة (أَ)، وضم يديك للأمام للضمة (أُ)، واخفض يدك للكسرة (إِ)!',
    parentHomeTip:
        '🏠 نصيحة للوالدين: تدرب مع طفلك أمام المرآة على شكل الفم عند نطق الفتحة والضمة والكسرة.',
    rewardSticker: '👑 وسام القارئ الماهر',
  ),

  // ===========================================================================
  // المسار ٢: الحروف والمفردات الإنجليزية (English Letters & Phonics — Tiers 1 to 4)
  // ===========================================================================
  AcademyTrackLessonModel(
    id: 'les_english_abc',
    trackId: 'english_letters',
    trackTitle: '٢. الإنجليزية',
    trackIcon: '🅰️',
    accentColor: Color(0xFF3B82F6),
    ageSuitability: '2–4 سنوات',
    levelName: 'تمهيدي',
    tierLevel: 1,
    skillKey: 'english_letters_abc',
    title: 'الحروف A و B و C: تفاحة وكرة وقطة',
    illustrationEmoji: '🍎⚽🐱',
    introductionText:
        'هيا نتعرف على أول ثلاثة حروف إنجليزية بالصوت والصورة: A مثل تفاحة Apple، وB مثل كرة Ball، وC مثل قطة Cat!',
    targetWordOrPhrase: 'A Apple ، B Ball ، C Cat',
    interactivePrompt: 'المس كل بطاقة لتستمع إلى الحرف الإنجليزي ومعناه بالعربية:',
    interactiveVisualCards: [
      {'emoji': '🍎', 'label': 'A — Apple', 'speak': 'A , Apple , تُفَّاحَة'},
      {'emoji': '⚽', 'label': 'B — Ball', 'speak': 'B , Ball , كُرَة'},
      {'emoji': '🐱', 'label': 'C — Cat', 'speak': 'C , Cat , قِطَّة'},
    ],
    quizQuestion: 'أي كلمة إنجليزية تبدأ بحرف (A)؟',
    quizOptions: ['🍎 Apple (تفاحة)', '⚽ Ball (كرة)', '🐱 Cat (قطة)'],
    correctOption: '🍎 Apple (تفاحة)',
    alternativeRemediationActivity:
        '🎶 إيقاع الحروف: صفق بيديك وردد بهدوء: A for Apple 🍎, B for Ball ⚽, C for Cat 🐱!',
    parentHomeTip:
        '🏠 نصيحة للوالدين: عندما يتناول طفلك تفاحة أو يلعب بالكرة، اذكر له اسمها بالعربية والإنجليزية (تفاحة - Apple).',
    rewardSticker: '🅰️ وسام ABC الأول',
  ),
  AcademyTrackLessonModel(
    id: 'les_english_def',
    trackId: 'english_letters',
    trackTitle: '٢. الإنجليزية',
    trackIcon: '🅰️',
    accentColor: Color(0xFF3B82F6),
    ageSuitability: '3–5 سنوات',
    levelName: 'مبتدئ',
    tierLevel: 2,
    skillKey: 'english_letters_def',
    title: 'الحروف D و E و F: بطة وفيل وسمكة',
    illustrationEmoji: '🦆🐘🐟',
    introductionText:
        'نكمل رحلة الحروف الإنجليزية مع أصدقائنا الحيوانات: D بطة Duck، وE فيل Elephant، وF سمكة Fish!',
    targetWordOrPhrase: 'D Duck ، E Elephant ، F Fish',
    interactivePrompt: 'المس كل حيوان لتسمع اسمه بالإنجليزية والعربية:',
    interactiveVisualCards: [
      {'emoji': '🦆', 'label': 'D — Duck', 'speak': 'D , Duck , بَطَّة'},
      {'emoji': '🐘', 'label': 'E — Elephant', 'speak': 'E , Elephant , فِيل'},
      {'emoji': '🐟', 'label': 'F — Fish', 'speak': 'F , Fish , سَمَكَة'},
    ],
    quizQuestion: 'ما اسم السمكة 🐟 باللغة الإنجليزية التي تبدأ بحرف (F)؟',
    quizOptions: ['🐟 Fish', '🦆 Duck', '🍎 Apple'],
    correctOption: '🐟 Fish',
    alternativeRemediationActivity:
        '🌊 لعبة السباحة: حرك يدك مثل السمكة في الماء وقل: F - Fish 🐟!',
    parentHomeTip:
        '🏠 نصيحة للوالدين: اربط الحرف الإنجليزي بحركة الحيوان (مثل خرطوم الفيل لحرف E - Elephant).',
    rewardSticker: '🐘 وسام مستكشف الحروف الإنجليزية',
  ),
  AcademyTrackLessonModel(
    id: 'les_english_words',
    trackId: 'english_letters',
    trackTitle: '٢. الإنجليزية',
    trackIcon: '🅰️',
    accentColor: Color(0xFF3B82F6),
    ageSuitability: '4–6 سنوات',
    levelName: 'متقدم',
    tierLevel: 4,
    skillKey: 'english_greetings_vocab',
    title: 'تحيات وكلمات يومية بالإنجليزية',
    illustrationEmoji: '👋☀️📘',
    introductionText:
        'نتعلم كلمات التحية المهذبة والطبيعة بالإنجليزية: مرحباً Hello، وشكراً Thank You، وشمس Sun!',
    targetWordOrPhrase: 'Hello ، Thank You ، Sun ، Book',
    interactivePrompt: 'المس البطاقات لتستمع للنطق الصحيح وتكرره:',
    interactiveVisualCards: [
      {'emoji': '👋', 'label': 'Hello (مرحباً)', 'speak': 'Hello , مَرْحَبًا'},
      {'emoji': '💝', 'label': 'Thank You (شكراً)', 'speak': 'Thank You , شُكْرًا لَكَ'},
      {'emoji': '☀️', 'label': 'Sun (شمس)', 'speak': 'Sun , شَمْسٌ مُشْرِقَةٌ'},
    ],
    quizQuestion: 'ماذا نقول بالإنجليزية عندما نشكر شخصاً ساعدنا 💝؟',
    quizOptions: ['💝 Thank You', '⚽ Ball', '🐱 Cat'],
    correctOption: '💝 Thank You',
    alternativeRemediationActivity:
        '🤝 تمثيل الأدوار: لوّح بيدك وقل Hello 👋، ثم ضع يدك على صدرك بابتسامة وقل Thank You 💝!',
    parentHomeTip:
        '🏠 نصيحة للوالدين: تبادل مع طفلك تحية الصباح بالعربية ثم بالإنجليزية (صباح الخير - Good Morning / Hello).',
    rewardSticker: '🌍 وسام المتحدث الصغير ثنائي اللغة',
  ),

  // ===========================================================================
  // المسار ٣: الأرقام والعدّ والحساب المبسط (Numbers, Counting & Early Math — Tiers 1 to 4)
  // ===========================================================================
  AcademyTrackLessonModel(
    id: 'les_numbers_count',
    trackId: 'numbers_counting',
    trackTitle: '٣. الأرقام والحساب',
    trackIcon: '🔢',
    accentColor: Color(0xFF38BDF8),
    ageSuitability: '2–3 سنوات',
    levelName: 'تمهيدي',
    tierLevel: 1,
    skillKey: 'numbers_1_to_3',
    title: 'الأرقام (١ ، ٢ ، ٣) والعدّ بالصور',
    illustrationEmoji: '🍎🍎🍎',
    introductionText:
        'هيا نعدّ معاً بالصوت والصورة: واحد (١)، اثنان (٢)، ثلاثة (٣)!',
    targetWordOrPhrase: 'وَاحِدٌ (١) ، اِثْنَانِ (٢) ، ثَلَاثَةٌ (٣)',
    interactivePrompt: 'اضغط على كل رقم لتسمع اسمه وتعدّ العناصر:',
    interactiveVisualCards: [
      {'emoji': '1️⃣🍎', 'label': 'وَاحِد (١)', 'speak': 'وَاحِد ، تُفَّاحَةٌ وَاحِدَةٌ'},
      {'emoji': '2️⃣🍎', 'label': 'اِثْنَان (٢)', 'speak': 'اِثْنَان ، تُفَّاحَتَانِ اثْنَتَانِ'},
      {'emoji': '3️⃣🍎', 'label': 'ثَلَاثَة (٣)', 'speak': 'ثَلَاثَة ، ثَلَاثُ تُفَّاحَاتٍ'},
    ],
    quizQuestion: 'أي سلة فيها ثلاث (٣) تفاحات؟',
    quizOptions: ['🍎', '🍎🍎', '🍎🍎🍎'],
    correctOption: '🍎🍎🍎',
    alternativeRemediationActivity:
        '🖐️ العدّ بالأصابع: ارفع إصبعاً واحداً وقل (واحد ١)، ثم إصبعين (اثنان ٢)، ثم ثلاثة أصابع (ثلاثة ٣)!',
    parentHomeTip:
        '🏠 نصيحة للوالدين: عدّ مع طفلك ٣ ملاعق أو ٣ مكعبات أثناء اللعب أو إعداد المائدة.',
    rewardSticker: '🔢 وسام العدّ الذكي',
  ),
  AcademyTrackLessonModel(
    id: 'les_numbers_compare',
    trackId: 'numbers_counting',
    trackTitle: '٣. الأرقام والحساب',
    trackIcon: '🔢',
    accentColor: Color(0xFF38BDF8),
    ageSuitability: '3–4 سنوات',
    levelName: 'مبتدئ',
    tierLevel: 2,
    skillKey: 'numbers_4_to_5_compare',
    title: 'الأرقام (٤ ، ٥) والمقارنة: أكثر وأقل',
    illustrationEmoji: '⭐⭐⭐⭐⭐',
    introductionText:
        'خمس نجوم (٥) أكثر من نجمتين (٢)! هيا نلمس البطاقات لنقارن بين الكميات.',
    targetWordOrPhrase: 'أَرْبَعَةٌ (٤) ، خَمْسَةٌ (٥) — أَكْثَرُ وَأَقَلُّ',
    interactivePrompt: 'المس البطاقات لتسمع المقارنة بين الأعداد:',
    interactiveVisualCards: [
      {'emoji': '⭐⭐⭐⭐', 'label': 'أَرْبَعَة (٤)', 'speak': 'أَرْبَعُ نُجُومٍ لَامِعَةٍ'},
      {'emoji': '⭐⭐⭐⭐⭐', 'label': 'خَمْسَة (٥)', 'speak': 'خَمْسُ نُجُومٍ ، الخَمْسَةُ أَكْثَرُ'},
      {'emoji': '⭐⭐', 'label': 'اِثْنَان (٢)', 'speak': 'نَجْمَتَانِ اثْنَتَانِ ، أَقَلُّ مِنَ الخَمْسَةِ'},
    ],
    quizQuestion: 'أي مجموعة تحتوي على نجوم أكثر؟',
    quizOptions: ['⭐⭐⭐⭐⭐ (٥)', '⭐⭐ (٢)', '⭐ (١)'],
    correctOption: '⭐⭐⭐⭐⭐ (٥)',
    alternativeRemediationActivity:
        '🖐️ كف اليد: افتح أصابع يدك الخمسة كلها — هذه خمسة (٥) كاملة!',
    parentHomeTip:
        '🏠 نصيحة للوالدين: ضع مجموعتين من المكعبات (٢ و٥) واسأل طفلك: أي كومة أكبر وأكثر؟',
    rewardSticker: '🔢 وسام المقارنة الرياضية',
  ),
  AcademyTrackLessonModel(
    id: 'les_numbers_to_ten',
    trackId: 'numbers_counting',
    trackTitle: '٣. الأرقام والحساب',
    trackIcon: '🔢',
    accentColor: Color(0xFF38BDF8),
    ageSuitability: '4–5 سنوات',
    levelName: 'متوسط',
    tierLevel: 3,
    skillKey: 'numbers_6_to_10',
    title: 'الأرقام من (٦) إلى (١٠) والعدّ التصاعدي',
    illustrationEmoji: '🔟🎈',
    introductionText:
        'نعدّ بأصابع يدينا الاثنتين من ستة (٦) حتى عشرة (١٠): ٦ ، ٧ ، ٨ ، ٩ ، ١٠!',
    targetWordOrPhrase: 'سِتَّةٌ (٦) ، سَبْعَةٌ (٧) ، ثَمَانِيَةٌ (٨) ، تِسْعَةٌ (٩) ، عَشَرَةٌ (١٠)',
    interactivePrompt: 'المس البطاقات لتسمع الأرقام حتى عشرة:',
    interactiveVisualCards: [
      {'emoji': '6️⃣🎈', 'label': 'سِتَّة وسبعة (٦-٧)', 'speak': 'سِتَّة ، سَبْعَة'},
      {'emoji': '8️⃣🎈', 'label': 'ثَمَانِيَة وتسعة (٨-٩)', 'speak': 'ثَمَانِيَة ، تِسْعَة'},
      {'emoji': '🔟🌟', 'label': 'عَشَرَة كاملة (١٠)', 'speak': 'عَشَرَة ، عَشْرُ نُجُومٍ كَامِلَةٍ'},
    ],
    quizQuestion: 'ما الرقم الذي يأتي بعد الرقم تسعة (٩) ويكمل أصابع اليدين؟',
    quizOptions: ['🔟 عَشَرَة (١٠)', '2️⃣ اِثْنَان (٢)', '4️⃣ أَرْبَعَة (٤)'],
    correctOption: '🔟 عَشَرَة (١٠)',
    alternativeRemediationActivity:
        '🙌 صفق بيديك عشر تصفيقات هادئة مع العدّ من ١ إلى ١٠!',
    parentHomeTip:
        '🏠 نصيحة للوالدين: عدّ مع طفلك درجات السلم أو خطوات المشي من ١ إلى ١٠.',
    rewardSticker: '🔟 وسام بطل الأرقام العشرة',
  ),
  AcademyTrackLessonModel(
    id: 'les_simple_addition',
    trackId: 'numbers_counting',
    trackTitle: '٣. الأرقام والحساب',
    trackIcon: '🔢',
    accentColor: Color(0xFF38BDF8),
    ageSuitability: '5–6 سنوات',
    levelName: 'متقدم',
    tierLevel: 4,
    skillKey: 'math_simple_addition',
    title: 'الجمع المبسط بالصور (١ + ١ = ٢ ، ٢ + ١ = ٣)',
    illustrationEmoji: '➕🍎',
    introductionText:
        'الجمع يعني أن نضع الأشياء معاً! تفاحة واحدة 🍎 زائد تفاحة واحدة 🍎 يساوي تفاحتين (٢)!',
    targetWordOrPhrase: 'وَاحِدٌ زَائِدُ وَاحِدٍ يُسَاوِي اثْنَيْنِ (١ + ١ = ٢)',
    interactivePrompt: 'المس كل معادلة مصورة لتسمع كيف نجمع الأعداد:',
    interactiveVisualCards: [
      {'emoji': '🍎+🍎=2️⃣', 'label': '١ + ١ = ٢', 'speak': 'تُفَّاحَةٌ زَائِدُ تُفَّاحَةٍ يُسَاوِي اثْنَتَيْنِ'},
      {'emoji': '⭐⭐+⭐=3️⃣', 'label': '٢ + ١ = ٣', 'speak': 'نَجْمَتَانِ زَائِدُ نَجْمَةٍ يُسَاوِي ثَلَاثَ نُجُومٍ'},
      {'emoji': '🚗🚗+🚗🚗=4️⃣', 'label': '٢ + ٢ = ٤', 'speak': 'اِثْنَانِ زَائِدُ اثْنَيْنِ يُسَاوِي أَرْبَعَةً'},
    ],
    quizQuestion: 'إذا كان معك نجمتان ⭐⭐ وأعطتك ماما نجمة أخرى ⭐، فكم نجمة تصبح معك؟',
    quizOptions: ['3️⃣ ثَلَاث نجوم (٣)', '1️⃣ نجمة واحدة (١)', '🔟 عشر نجوم'],
    correctOption: '3️⃣ ثَلَاث نجوم (٣)',
    alternativeRemediationActivity:
        '🧸 ضع لعبتين أمامك، ثم أضف لعبة ثالثة وعدّها كلها بصوتك: ١ ، ٢ ، ٣!',
    parentHomeTip:
        '🏠 نصيحة للوالدين: استخدم قطع الفاكهة أو المكعبات لتمثيل مسائل جمع حسية بسيطة (٢ + ١) أمام الطفل.',
    rewardSticker: '➕ وسام العبقري الرياضي الصغير',
  ),

  // ===========================================================================
  // المسار ٤: الألوان والأشكال (Colors & Shapes — Tiers 1 to 3)
  // ===========================================================================
  AcademyTrackLessonModel(
    id: 'les_colors_shapes',
    trackId: 'colors_shapes',
    trackTitle: '٤. الألوان والأشكال',
    trackIcon: '🎨',
    accentColor: Color(0xFFF59E0B),
    ageSuitability: '2–4 سنوات',
    levelName: 'تمهيدي',
    tierLevel: 1,
    skillKey: 'basic_colors_shapes',
    title: 'الألوان الأساسية والأشكال الهندسية',
    illustrationEmoji: '🔴🟦🔺',
    introductionText:
        'الدائرة الحمراء 🔴 مثل التفاحة، والمربع الأزرق 🟦 له ٤ أضلاع، والمثلث الأصفر 🔺 له ٣ زوايا!',
    targetWordOrPhrase: 'دَائِرَةٌ حَمْرَاءُ ، مُرَبَّعٌ أَزْرَقُ ، مُثَلَّثٌ أَصْفَرُ',
    interactivePrompt: 'المس كل شكل لتستمع لاسمه ولونه:',
    interactiveVisualCards: [
      {'emoji': '🔴', 'label': 'دَائِرَة حَمْرَاء', 'speak': 'دَائِرَةٌ حَمْرَاءُ مُسْتَدِيرَةٌ'},
      {'emoji': '🟦', 'label': 'مُرَبَّع أَزْرَق', 'speak': 'مُرَبَّعٌ أَزْرَقُ لَهُ أَرْبَعَةُ أَضْلَاعٍ'},
      {'emoji': '🔺', 'label': 'مُثَلَّث أَصْفَر', 'speak': 'مُثَلَّثٌ لَهُ ثَلَاثُ زَوَايَا'},
    ],
    quizQuestion: 'ما الشكل الهندسي المستدير الذي يشبه الشمس؟',
    quizOptions: ['🔴 الدائرة', '🟦 المربع', '🔺 المثلث'],
    correctOption: '🔴 الدائرة',
    parentHomeTip:
        '🏠 نصيحة للوالدين: اطلب من طفلك البحث عن شكل دائري في الغرفة (مثل الطبق أو الساعة) وشكل مربع (مثل النافذة).',
    rewardSticker: '🎨 وسام الأشكال والألوان',
  ),

  // ===========================================================================
  // المسار ٥: الحيوانات والطبيعة (Animals & Environment — Tiers 1 to 3)
  // ===========================================================================
  AcademyTrackLessonModel(
    id: 'les_animals_nature',
    trackId: 'animals_nature',
    trackTitle: '٥. الحيوانات والطبيعة',
    trackIcon: '🦁',
    accentColor: Color(0xFF10B981),
    ageSuitability: '2–4 سنوات',
    levelName: 'تمهيدي',
    tierLevel: 1,
    skillKey: 'animals_habitats',
    title: 'الحيوانات وأصواتها وبيئاتها الطبيعية',
    illustrationEmoji: '🦁🐬🐪',
    introductionText:
        'الأسد في الغابة، والدلفين في البحر، والجمل في الصحراء، والعصفور يغرد فوق الشجرة!',
    targetWordOrPhrase: 'أَسَدُ الغَابَةِ ، دُلْفِينُ البَحْرِ ، جَمَلُ الصَّحْرَاءِ',
    interactivePrompt: 'المس كل حيوان لتسمع صوته وأين يعيش:',
    interactiveVisualCards: [
      {'emoji': '🦁', 'label': 'الأَسَد (الغابة)', 'speak': 'الأَسَدُ يَزْأَرُ وَيَعِيشُ فِي الغَابَةِ'},
      {'emoji': '🐬', 'label': 'الدُّلْفِين (البحر)', 'speak': 'الدُّلْفِينُ الذَّكِيُّ يَسْبَحُ فِي البَحْرِ'},
      {'emoji': '🐪', 'label': 'الجَمَل (الصحراء)', 'speak': 'الجَمَلُ سَفِينَةُ الصَّحْرَاءِ'},
    ],
    quizQuestion: 'أين يعيش ويسبح الدلفين الذكي 🐬؟',
    quizOptions: ['🌊 في البحر', '🏜️ في الصحراء', '🌳 فوق الشجرة'],
    correctOption: '🌊 في البحر',
    parentHomeTip:
        '🏠 نصيحة للوالدين: العب مع طفلك لعبة تقليد أصوات الحيوانات الهادئة وسؤاله أين يعيش كل حيوان.',
    rewardSticker: '🌿 وسام مستكشف الطبيعة',
  ),

  // ===========================================================================
  // المسار ٦: الكلمات والمفردات (Vocabulary & Opposites — Tiers 2 to 4)
  // ===========================================================================
  AcademyTrackLessonModel(
    id: 'les_vocab_words',
    trackId: 'vocabulary',
    trackTitle: '٦. الكلمات والمفردات',
    trackIcon: '📚',
    accentColor: Color(0xFFA855F7),
    ageSuitability: '3–5 سنوات',
    levelName: 'مبتدئ',
    tierLevel: 2,
    skillKey: 'everyday_vocabulary',
    title: 'مفردات البيت والمدرسة والفواكه',
    illustrationEmoji: '🏡🎒🍎',
    introductionText:
        'نتعلم كلمات جديدة بالصور والصوت والتكرار: كتاب، قلم، حقيبة، وتفاحة!',
    targetWordOrPhrase: 'كِتَابٌ ، قَلَمٌ ، حَقِيبَةٌ ، تُفَّاحَةٌ',
    interactivePrompt: 'المس الصورة لتسمع الكلمة وتكررها بصوتك:',
    interactiveVisualCards: [
      {'emoji': '📘', 'label': 'كِتَابٌ', 'speak': 'كِتَابٌ ، نَقْرَأُ فِيهِ القِصَصَ'},
      {'emoji': '✏️', 'label': 'قَلَمٌ', 'speak': 'قَلَمٌ ، نَكْتُبُ وَنَرْسُمُ بِهِ'},
      {'emoji': '🎒', 'label': 'حَقِيبَةٌ', 'speak': 'حَقِيبَةٌ مَدْرَسِيَّةٌ مُرَتَّبَةٌ'},
    ],
    quizQuestion: 'ماذا نستخدم لنكتب ونرسم على الورقة؟',
    quizOptions: ['✏️ القَلَم', '⚽ الكُرَة', '🥄 المِلْعَقَة'],
    correctOption: '✏️ القَلَم',
    parentHomeTip:
        '🏠 نصيحة للوالدين: شجّع طفلك على تسمية أدواته الشخصية باللغة العربية السليمة عند ترتيبها.',
    rewardSticker: '📚 وسام حصيلة المفردات',
  ),
  AcademyTrackLessonModel(
    id: 'les_vocab_opposites',
    trackId: 'vocabulary',
    trackTitle: '٦. الكلمات والمفردات',
    trackIcon: '📚',
    accentColor: Color(0xFFA855F7),
    ageSuitability: '4–6 سنوات',
    levelName: 'متقدم',
    tierLevel: 4,
    skillKey: 'vocabulary_opposites',
    title: 'الكلمات المتضادة: كبير وصغير، سريع وبطيء',
    illustrationEmoji: '🐘🐭🐢',
    introductionText:
        'الفيل كبير 🐘 والفأر صغير 🐭! والأرنب سريع 🐰 والسلحفاة بطيئة 🐢!',
    targetWordOrPhrase: 'كَبِيرٌ وَصَغِيرٌ — سَرِيعٌ وَبَطِيءٌ — لَيْلٌ وَنَهَارٌ',
    interactivePrompt: 'المس كل بطاقة لتكتشف الكلمة وعكسها:',
    interactiveVisualCards: [
      {'emoji': '🐘🐭', 'label': 'كَبِير / صَغِير', 'speak': 'الفِيلُ كَبِيرٌ ، وَالفَأْرُ صَغِيرٌ'},
      {'emoji': '🐰🐢', 'label': 'سَرِيع / بَطِيء', 'speak': 'الأَرْنَبُ سَرِيعٌ ، وَالسُّلَحْفَاةُ بَطِيئَةٌ'},
      {'emoji': '☀️🌙', 'label': 'نَهَار / لَيْل', 'speak': 'فِي النَّهَارِ تُشْرِقُ الشَّمْسُ ، وَفِي اللَّيْلِ يَظْهَرُ القَمَرُ'},
    ],
    quizQuestion: 'ما عكس كلمة (كَبِيرٌ 🐘)؟',
    quizOptions: ['🐭 صَغِيرٌ', '☀️ طويل', '🌊 عميق'],
    correctOption: '🐭 صَغِيرٌ',
    parentHomeTip:
        '🏠 نصيحة للوالدين: اسأل طفلك أثناء اللعب: هل هذه الكرة كبيرة أم صغيرة؟ هل نمشي الآن بسرعة أم ببطء؟',
    rewardSticker: '⚖️ وسام ذكاء المفردات والمتضادات',
  ),

  // ===========================================================================
  // المسار ٧: الاستماع والنطق الصحيح (Listening & Speaking — Tiers 2 to 4)
  // ===========================================================================
  AcademyTrackLessonModel(
    id: 'les_communication',
    trackId: 'communication',
    trackTitle: '٧. الاستماع والنطق',
    trackIcon: '🗣️',
    accentColor: Color(0xFFEC4899),
    ageSuitability: '3–5 سنوات',
    levelName: 'مبتدئ',
    tierLevel: 2,
    skillKey: 'polite_speaking_phrases',
    title: 'جمل التواصل المهذب: من فضلك وشكراً لك',
    illustrationEmoji: '🤝💬',
    introductionText:
        'نستخدم جملنا العربية الجميلة للتحدث بلطف مع ماما وبابا وأصدقائنا.',
    targetWordOrPhrase: 'مِنْ فَضْلِكَ ، شُكْرًا لَكَ ، صَبَاحُ الخَيْرِ',
    interactivePrompt: 'المس كل عبارة لتستمع إليها وترددها:',
    interactiveVisualCards: [
      {'emoji': '☀️', 'label': 'صَبَاحُ الخَيْرِ', 'speak': 'صَبَاحُ الخَيْرِ يَا أُمِّي وَأَبِي'},
      {'emoji': '🙏', 'label': 'مِنْ فَضْلِكَ', 'speak': 'مِنْ فَضْلِكَ ، هَلْ تُسَاعِدُنِي؟'},
      {'emoji': '💝', 'label': 'شُكْرًا لَكَ', 'speak': 'شُكْرًا لَكَ عَلَى مُسَاعَدَتِكَ'},
    ],
    quizQuestion: 'ماذا نقول لمن يقدم لنا هدية أو مساعدة؟',
    quizOptions: ['🌟 شُكْرًا لَكَ', 'أعطني بسرعة', 'لا أتكلم'],
    correctOption: '🌟 شُكْرًا لَكَ',
    parentHomeTip:
        '🏠 نصيحة للوالدين: امدح طفلك فوراً عندما يستخدم عبارة «من فضلك» أو «شكراً لك» في حديثه اليومي.',
    rewardSticker: '🗣️ وسام المتحدث الفصيح',
  ),

  // ===========================================================================
  // المسار ٨: العلوم المبسطة (Simple Science — Tier 3)
  // ===========================================================================
  AcademyTrackLessonModel(
    id: 'les_simple_science',
    trackId: 'simple_science',
    trackTitle: '٨. العلوم المبسطة',
    trackIcon: '🔬',
    accentColor: Color(0xFF06B6D4),
    ageSuitability: '4–6 سنوات',
    levelName: 'متوسط',
    tierLevel: 3,
    skillKey: 'five_senses_and_plants',
    title: 'الجسم والحواس الخمس والنبات والطقس',
    illustrationEmoji: '👀👂🌱☀️',
    introductionText:
        'نرى بالعين 👀، ونسمع بالأذن 👂، ونشم الأزهار بالأنف 👃، والنبات ينمو بالماء وضوء الشمس ☀️!',
    targetWordOrPhrase: 'العَيْنُ لِلرُّؤْيَةِ ، وَالأُذُنُ لِلسَّمْعِ ، وَالشَّمْسُ لِلنَّبَاتِ',
    interactivePrompt: 'المس كل رمز علمي لتكتشف وظيفته:',
    interactiveVisualCards: [
      {'emoji': '👀', 'label': 'حَاسَّةُ البَصَر', 'speak': 'أَرَى الأَلْوَانَ وَالأَشْيَاءَ بِعَيْنَيَّ'},
      {'emoji': '👃', 'label': 'حَاسَّةُ الشَّمّ', 'speak': 'أَشُمُّ رَائِحَةَ الوَرْدِ بِأَنْفِي'},
      {'emoji': '🌱☀️', 'label': 'نُمُوُّ النَّبَات', 'speak': 'النَّبَاتُ يَحْتَاجُ إِلَى المَاءِ وَضَوْءِ الشَّمْسِ'},
    ],
    quizQuestion: 'بأي حاسة نشمّ رائحة الأزهار الذكية 🌸؟',
    quizOptions: ['👃 بالأنف', '👂 بالأذن', '🦶 بالقدم'],
    correctOption: '👃 بالأنف',
    parentHomeTip:
        '🏠 نصيحة للوالدين: دع طفلك يسقي نبتة صغيرة في المنزل ويراقب نموها يومياً.',
    rewardSticker: '🔬 وسام العالم الصغير',
  ),

  // ===========================================================================
  // المسار ٩: المهارات الاجتماعية والعادات اليومية (Social & Life Skills — Tiers 1 to 3)
  // ===========================================================================
  AcademyTrackLessonModel(
    id: 'les_daily_habits',
    trackId: 'daily_habits',
    trackTitle: '٩. المهارات الحياتية',
    trackIcon: '🪥',
    accentColor: Color(0xFF8B5CF6),
    ageSuitability: '2–5 سنوات',
    levelName: 'تمهيدي',
    tierLevel: 1,
    skillKey: 'hygiene_and_tidiness',
    title: 'النظافة وترتيب الألعاب والاستعداد للنوم',
    illustrationEmoji: '🧼🧸🌙',
    introductionText:
        'نغسل يدينا بالماء والصابون 🧼، ونعيد ألعابنا للسلة 🧸، وننظف أسناننا قبل النوم المبكر 🌙!',
    targetWordOrPhrase: 'أَغْسِلُ يَدَيَّ ، وَأُرَتِّبُ غُرْفَتِي ، وَأَنَامُ مُبَكِّرًا',
    interactivePrompt: 'المس كل عادة يومية لتسمعها وتطبقها في يومك:',
    interactiveVisualCards: [
      {'emoji': '🧼', 'label': 'غَسْلُ اليَدَيْن', 'speak': 'أَغْسِلُ يَدَيَّ بِالمَاءِ وَالصَّابُونِ قَبْلَ الطَّعَامِ'},
      {'emoji': '🧸', 'label': 'تَرْتِيبُ الأَلْعَاب', 'speak': 'أَضَعُ أَلْعَابِي فِي السَّلَّةِ بَعْدَ اللَّعِبِ'},
      {'emoji': '🪥🌙', 'label': 'تَنْظِيفُ الأَسْنَان', 'speak': 'أُنَظِّفُ أَسْنَانِي بِالفُرْشَاةِ قَبْلَ النَّوْمِ'},
    ],
    quizQuestion: 'متى نعيد الألعاب إلى سلتها المخصصة 🧸؟',
    quizOptions: [
      '✅ فور الانتهاء من اللعب',
      'نتركها على الأرض',
      'لا نرتبها أبداً',
    ],
    correctOption: '✅ فور الانتهاء من اللعب',
    parentHomeTip:
        '🏠 نصيحة للوالدين: حوّل ترتيب الألعاب إلى سباق مرح لمدة دقيقتين قبل العشاء.',
    rewardSticker: '🪥 وسام البطل المنظم',
  ),
  AcademyTrackLessonModel(
    id: 'les_social_skills',
    trackId: 'social_skills',
    trackTitle: '٩. المهارات الاجتماعية',
    trackIcon: '❤️',
    accentColor: Color(0xFFF43F5E),
    ageSuitability: '3–6 سنوات',
    levelName: 'متوسط',
    tierLevel: 3,
    skillKey: 'sharing_and_empathy',
    title: 'المشاركة واللطف والتعبير عن المشاعر',
    illustrationEmoji: '🤗🎁😊',
    introductionText:
        'نشارك ألعابنا بمحبة، ونحترم الكبير، ونعبّر عن مشاعرنا بهدوء وابتسامة.',
    targetWordOrPhrase: 'أَنَا أُشَارِكُ أَصْدِقَائِي وَأَحْتَرِمُ الجَمِيعَ',
    interactivePrompt: 'المس كل موقف اجتماعي لتسمع التصرف الجميل:',
    interactiveVisualCards: [
      {'emoji': '🤝', 'label': 'المُشَارَكَة', 'speak': 'أُشَارِكُ أَلْعَابِي مَعَ إِخْوَتِي وَأَصْدِقَائِي'},
      {'emoji': '😊', 'label': 'اللُّطْفُ وَالابْتِسَامَة', 'speak': 'الابْتِسَامَةُ فِي وَجْهِ أَخِيكَ صَدَقَةٌ'},
      {'emoji': '🧘', 'label': 'الهُدُوءُ عِنْدَ الغَضَب', 'speak': 'عِنْدَمَا أَغْضَبُ أَتَنَفَّسُ بِعُمْقٍ وَأَتَحَدَّثُ بِهُدُوءٍ'},
    ],
    quizQuestion: 'إذا أراد أخوك الصغير اللعب معك بالمكعبات، ماذا تفعل؟',
    quizOptions: [
      '🤝 أشاركه اللعب بلطف',
      'أخفي الألعاب وحدي',
      'أصرخ بصوت عالٍ',
    ],
    correctOption: '🤝 أشاركه اللعب بلطف',
    parentHomeTip:
        '🏠 نصيحة للوالدين: شجّع طفلك على تسمية مشاعره بهدوء («أنا سعيد»، «أحتاج للمساعدة») بدلاً من الانفعال.',
    rewardSticker: '❤️ وسام القلب الطيب',
  ),

  // ===========================================================================
  // المسار ١٠: التفكير والذاكرة والتركيز وحل المشكلات (Thinking, Memory & Problem Solving — Tiers 2 to 4)
  // ===========================================================================
  AcademyTrackLessonModel(
    id: 'les_thinking_sorting',
    trackId: 'thinking_problem_solving',
    trackTitle: '١٠. التفكير والتركيز',
    trackIcon: '🧩',
    accentColor: Color(0xFF10B981),
    ageSuitability: '3–4 سنوات',
    levelName: 'مبتدئ',
    tierLevel: 2,
    skillKey: 'thinking_classification',
    title: 'تصنيف الأشياء واكتشاف العلاقة المنطقية',
    illustrationEmoji: '🧩🍎🚗',
    introductionText:
        'العقل الذكي يلاحظ الأشياء المتشابهة! التفاحة والموزة من الفواكه 🍎🍌، والسيارة والقطار من وسائل المواصلات 🚗🚂!',
    targetWordOrPhrase: 'أُصَنِّفُ الأَشْيَاءَ وَأُفَكِّرُ بِذَكَاءٍ',
    interactivePrompt: 'المس كل مجموعة لتفهم لماذا تنتمي لبعضها:',
    interactiveVisualCards: [
      {'emoji': '🍎🍌🍇', 'label': 'مجموعة الفواكه', 'speak': 'التُّفَّاحُ وَالمَوْزُ وَالعِنَبُ فَوَاكِهُ لَذِيذَةٌ'},
      {'emoji': '🚗🚂✈️', 'label': 'وسائل المواصلات', 'speak': 'السَّيَّارَةُ وَالقِطَارُ وَالطَّائِرَةُ وَسَائِلُ نَقْلٍ'},
      {'emoji': '🦁🐰🐘', 'label': 'مجموعة الحيوانات', 'speak': 'الأَسَدُ وَالأَرْنَبُ وَالفِيلُ حَيَوَانَاتٌ'},
    ],
    quizQuestion: 'أي عنصر ينتمي إلى مجموعة الفواكه اللذيذة (🍎 🍌)؟',
    quizOptions: ['🍇 العِنَب', '🚗 السَّيَّارَة', '✏️ القَلَم'],
    correctOption: '🍇 العِنَب',
    alternativeRemediationActivity:
        '🧺 لعبة الفرز: ضع الألعاب الحمراء في جهة والألعاب الزرقاء في جهة أخرى!',
    parentHomeTip:
        '🏠 نصيحة للوالدين: اطلب من طفلك فرز الجوارب المتشابهة في اللون أو الحجم لتنمية التركيز والتصنيف.',
    rewardSticker: '🧩 وسام المفكر الذكي',
  ),
  AcademyTrackLessonModel(
    id: 'les_thinking_problem_solving',
    trackId: 'thinking_problem_solving',
    trackTitle: '١٠. التفكير والتركيز',
    trackIcon: '🧩',
    accentColor: Color(0xFF10B981),
    ageSuitability: '5–6 سنوات',
    levelName: 'متقدم',
    tierLevel: 4,
    skillKey: 'thinking_logical_sequences',
    title: 'ترتيب الأحداث وحل المشكلات اليومية بهدوء',
    illustrationEmoji: '🌱🌿🌳',
    introductionText:
        'كل شيء ينمو بالترتيب: أولاً نزرع البذرة 🌱، ثم نسقيها بالماء 💧، فتكبر وتصبح شجرة مثمرة 🌳!',
    targetWordOrPhrase: 'أُفَكِّرُ بِهُدُوءٍ وَأَحُلُّ المُشْكِلَةَ خُطْوَةً بِخُطْوَةٍ',
    interactivePrompt: 'المس الخطوات بالترتيب لتكتشف كيف نحل المشكلات:',
    interactiveVisualCards: [
      {'emoji': '1️⃣🌱', 'label': '١. نزرع البذرة', 'speak': 'الخُطْوَةُ الأُولَى: نَضَعُ البَذْرَةَ فِي التُّرْبَةِ'},
      {'emoji': '2️⃣💧', 'label': '٢. نسقيها بالماء', 'speak': 'الخُطْوَةُ الثَّانِيَةُ: نَسْقِيهَا بِالمَاءِ وَضَوْءِ الشَّمْسِ'},
      {'emoji': '3️⃣🌳', 'label': '٣. تنمو الشجرة', 'speak': 'الخُطْوَةُ الثَّالِثَةُ: تَكْبُرُ وَتُصْبِحُ شَجَرَةً جَمِيلَةً'},
    ],
    quizQuestion: 'إذا انسكب قليل من الماء على الطاولة، ما الحل الذكي الهادئ؟',
    quizOptions: [
      '🧻 أحضر منديلاً أو فوطة وأجففه بهدوء',
      'أبكي وأغضب',
      'أتركه دون تنظيف',
    ],
    correctOption: '🧻 أحضر منديلاً أو فوطة وأجففه بهدوء',
    alternativeRemediationActivity:
        '🧠 خطوات الحل الثلاث: ١. أتنفس بهدوء، ٢. أفكر في الحل، ٣. أنفذ الحل بابتسامة!',
    parentHomeTip:
        '🏠 نصيحة للوالدين: عندما يواجه طفلك مشكلة صغيرة (مثل سقوط مكعب)، اسأله بهدوء: «ما الفكرة الذكية لنصلحها معاً؟».',
    rewardSticker: '🏆 وسام حلال المشكلات العبقري',
  ),
];

// =============================================================================
// English Learning Curriculum (Phonics, Numbers, Social Skills & Science)
// Matches Learning Language: 'en'
// =============================================================================
const List<AcademyTrackLessonModel> kHaneenAcademyCurriculumEn = [
  // 1. Phonics & Letters (Tier 1 & 2)
  AcademyTrackLessonModel(
    id: 'les_en_letter_a',
    trackId: 'en_phonics',
    trackTitle: '1. English Phonics',
    trackIcon: '🔤',
    accentColor: Color(0xFF14B8A6),
    ageSuitability: '2–4 years',
    levelName: 'Preschool',
    tierLevel: 1,
    skillKey: 'en_phonics_letter_a',
    title: 'حرف A: تفاحة ورائد فضاء',
    illustrationEmoji: '🍎🚀',
    introductionText: 'Letter A makes the /æ/ sound like Apple and Astronaut! Tap the cards to listen and repeat.',
    targetWordOrPhrase: 'A — Apple, Astronaut, Alligator',
    interactivePrompt: 'Tap each picture to hear the English pronunciation:',
    interactiveVisualCards: [
      {'emoji': '🍎', 'label': 'Apple', 'speak': 'A is for sweet red Apple'},
      {'emoji': '🚀', 'label': 'Astronaut', 'speak': 'A is for brave Astronaut flying high'},
      {'emoji': '🐊', 'label': 'Alligator', 'speak': 'A is for friendly Alligator'},
    ],
    quizQuestion: 'Which word starts with the /æ/ sound of Letter A?',
    quizOptions: ['🍎 Apple', '🍌 Banana', '🐱 Cat'],
    correctOption: '🍎 Apple',
    alternativeRemediationQuestion: 'What crunchy fruit starts with the letter A?',
    alternativeRemediationOptions: ['🍎 Apple', '🍊 Orange'],
    alternativeRemediationCorrect: '🍎 Apple',
    alternativeRemediationActivity: 'Say the sound: /æ/ /æ/ Apple! Can you point to your favorite fruit?',
    parentHomeTip: 'Parent Tip: Practice finding objects around the house starting with the /æ/ sound.',
    rewardSticker: '🌟 Letter A Hero Badge',
  ),
  AcademyTrackLessonModel(
    id: 'les_en_letter_b',
    trackId: 'en_phonics',
    trackTitle: '1. English Phonics',
    trackIcon: '🔤',
    accentColor: Color(0xFF14B8A6),
    ageSuitability: '2–4 years',
    levelName: 'Preschool',
    tierLevel: 1,
    skillKey: 'en_phonics_letter_b',
    title: 'حرف B: فراشة وبالون',
    illustrationEmoji: '🦋🎈',
    introductionText: 'Letter B makes the /b/ sound like Butterfly and Balloon!',
    targetWordOrPhrase: 'B — Butterfly, Balloon, Bear',
    interactivePrompt: 'Tap each picture to hear the sound:',
    interactiveVisualCards: [
      {'emoji': '🦋', 'label': 'Butterfly', 'speak': 'B is for colorful Butterfly'},
      {'emoji': '🎈', 'label': 'Balloon', 'speak': 'B is for bright party Balloon'},
      {'emoji': '🐻', 'label': 'Bear', 'speak': 'B is for kind cuddly Bear'},
    ],
    quizQuestion: 'Which picture starts with the /b/ sound of Letter B?',
    quizOptions: ['🎈 Balloon', '🍎 Apple', '🐶 Dog'],
    correctOption: '🎈 Balloon',
    alternativeRemediationActivity: 'Flap your arms like a butterfly and say: /b/ /b/ Butterfly!',
    parentHomeTip: 'Encourage your child to blow gentle breaths like a floating balloon.',
    rewardSticker: '🦋 Gentle Butterfly Star',
  ),

  // 2. Numbers & Counting (Tier 2)
  AcademyTrackLessonModel(
    id: 'les_en_numbers_123',
    trackId: 'en_math',
    trackTitle: '2. Fun Math & Numbers',
    trackIcon: '🔢',
    accentColor: Color(0xFF8B5CF6),
    ageSuitability: '3–5 years',
    levelName: 'Beginner',
    tierLevel: 2,
    skillKey: 'en_numbers_1_to_3',
    title: 'العد بالإنجليزية: ١ و٢ و٣',
    illustrationEmoji: '🔢🌟',
    introductionText: 'Let’s learn how to count to three in English with fun stars and happy friends!',
    targetWordOrPhrase: 'One, Two, Three',
    interactivePrompt: 'Tap each number card to count together:',
    interactiveVisualCards: [
      {'emoji': '1️⃣☀️', 'label': 'One', 'speak': 'One bright shining sun'},
      {'emoji': '2️⃣👟', 'label': 'Two', 'speak': 'Two comfortable shoes'},
      {'emoji': '3️⃣⭐', 'label': 'Three', 'speak': 'Three sparkling night stars'},
    ],
    quizQuestion: 'How many shoes do you wear on your feet?',
    quizOptions: ['2️⃣ Two', '1️⃣ One', '5️⃣ Five'],
    correctOption: '2️⃣ Two',
    alternativeRemediationActivity: 'Clap your hands three times: One, Two, Three! Fantastic!',
    parentHomeTip: 'Ask your child to count toys before tidying up.',
    rewardSticker: '⭐ Math Wizard Badge',
  ),

  // 3. Social Manners & Emotional Intelligence (Tier 3)
  AcademyTrackLessonModel(
    id: 'les_en_manners_thankyou',
    trackId: 'en_social',
    trackTitle: '3. Polite Manners & Kindness',
    trackIcon: '🤝',
    accentColor: Color(0xFFF59E0B),
    ageSuitability: '4–6 years',
    levelName: 'Intermediate',
    tierLevel: 3,
    skillKey: 'en_social_polite_words',
    title: 'الكلمات السحرية: من فضلك وشكرًا',
    illustrationEmoji: '🌸🙏',
    introductionText: 'Kind heroes always use polite magic words when speaking with family and teachers.',
    targetWordOrPhrase: 'Please, Thank You, You are Welcome',
    interactivePrompt: 'Tap the magic words to learn how they spread happiness:',
    interactiveVisualCards: [
      {'emoji': '🙏', 'label': 'Please', 'speak': 'When asking for something, we always say: Please'},
      {'emoji': '💖', 'label': 'Thank You', 'speak': 'When someone helps us, we smile and say: Thank You'},
      {'emoji': '😊', 'label': 'Welcome', 'speak': 'We answer with: You are welcome, my friend'},
    ],
    quizQuestion: 'What magic words do you say when someone gives you a gift?',
    quizOptions: ['💖 Thank You', '🏃 I run away', '😡 I shout'],
    correctOption: '💖 Thank You',
    alternativeRemediationActivity: 'Smile brightly and say: Thank You so much! Notice how happy it makes everyone feel.',
    parentHomeTip: 'Model saying "Please" and "Thank You" at family dinner.',
    rewardSticker: '🏆 Polite Hero Trophy',
  ),
];
