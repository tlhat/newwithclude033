import 'dart:math';

class HundredLevelGamesGenerator {
  static List<Map<String, dynamic>> get oddOneOutLevels =>
      List<Map<String, dynamic>>.generate(100, getOddOneOutLevel);

  static List<List<String>> get memoryLevels =>
      List<List<String>>.generate(100, (i) => getMemoryBoardForLevel(i + 1));

  static List<Map<String, dynamic>> get patternLevels =>
      List<Map<String, dynamic>>.generate(100, getPatternLogicLevel);

  static List<Map<String, dynamic>> get wordLevels =>
      List<Map<String, dynamic>>.generate(100, getArabicWordLevel);

  static List<Map<String, dynamic>> get mathLevels =>
      List<Map<String, dynamic>>.generate(100, getVisualMathLevel);

  static List<Map<String, dynamic>> get etiquetteSteps =>
      List<Map<String, dynamic>>.generate(100, getEtiquetteDrawingLevel);

  static const List<Map<String, dynamic>> _categoryClusters = [
    {
      'name': 'الفواكه الطازجة',
      'items': ['🍎', '🍌', '🍇', '🍉', '🍓', '🍒', '🍑', '🍍', '🥝', '🍊'],
    },
    {
      'name': 'حيوانات الغابة والمزرعة',
      'items': ['🦁', '🐰', '🐱', '🐶', '🐼', '🐨', '🐯', '🦊', '🐮', '🐑'],
    },
    {
      'name': 'وسائل النقل والمواصلات',
      'items': ['🚗', '🚌', '🚂', '✈️', '🚀', '🚁', '🚢', '🚲', '🚜', '🚑'],
    },
    {
      'name': 'عجائب السماء والفضاء',
      'items': ['☀️', '🌙', '⭐', '🌟', '🌈', '☁️', '⚡', '🪐', '☄️', '🌍'],
    },
    {
      'name': 'الأدوات المدرسية والتعلم',
      'items': ['✏️', '📘', '🖍️', '📏', '📐', '🎒', '✂️', '🖊️', '📓', '🔍'],
    },
    {
      'name': 'الكائنات البحرية',
      'items': ['🐬', '🐠', '🐙', '🐳', '🦀', '🦈', '🐡', '🦐', '🦑', '🐚'],
    },
    {
      'name': 'النباتات والزهور',
      'items': ['🌸', '🌹', '🌻', '🌷', '🌲', '🌳', '🌴', '🌵', '🍀', '🌿'],
    },
    {
      'name': 'الأشكال الهندسية والألوان',
      'items': ['🟥', '🟦', '🟩', '🟨', '🟪', '🟧', '🔵', '🟢', '🟡', '🔺'],
    },
    {
      'name': 'الخضروات الصحية',
      'items': ['🥕', '🥒', '🥦', '🍅', '🌽', '🍆', '🥔', '🥬', '🫑', '🧄'],
    },
    {
      'name': 'الرياضة والنشاط البدني',
      'items': ['⚽', '🏀', '🎾', '🏐', '🏈', '⚾', '🏓', '🏸', '🥊', '🏆'],
    },
  ];

  /// Computes adaptive difficulty tier (1..4) from child's age group, curriculum tier, and completed games.
  static int computeAdaptiveDifficultyTier({
    required String ageGroup,
    required int currentCurriculumTier,
    required int gamesCompletedCount,
  }) {
    int baseTier = currentCurriculumTier.clamp(1, 4);
    final String normAge = ageGroup.trim();
    if (normAge.contains('2') || normAge.startsWith('٢')) {
      baseTier = min(baseTier, 2);
    } else if (normAge.contains('5–6') || normAge.contains('5-6')) {
      baseTier = max(baseTier, 3);
    }
    if (gamesCompletedCount >= 12 && baseTier < 4) {
      baseTier++;
    }
    return baseTier.clamp(1, 4);
  }

  /// Advances to the next level without monotonous repetition:
  /// when a child is on a winning streak (`streakCount >= 3`), it steps forward
  /// into a slightly higher challenge cluster while staying within 0..99.
  static int selectNextNonRepetitiveLevelIndex({
    required int currentIndex,
    int streakCount = 1,
    int difficultyTier = 2,
  }) {
    final int step = (streakCount >= 3) ? (1 + (difficultyTier.clamp(1, 4))) : 1;
    return (currentIndex + step) % 100;
  }

  static Map<String, dynamic> getEtiquetteDrawingLevel(int index) {
    final int levelNum = (index % 100) + 1;
    const List<Map<String, String>> baseLessons = [
      {
        'shape': 'قلب المحبة والرحمة ❤️',
        'badge': 'آداب العائلة وبر الوالدين',
        'lesson':
            'من أجمل الآداب أن نبتسم في وجه ماما وبابا ونقول لهما بقلب محب: شكراً لكما، أنا أحبكما كثيراً!',
        'phrase': '«رَبِّ ارْحَمْهُمَا كَمَا رَبَّيَانِي صَغِيراً»',
      },
      {
        'shape': 'الوجه المبتسم وإلقاء السلام 😊',
        'badge': 'آداب التحية والابتسامة',
        'lesson':
            'الطفل المؤدب يبدأ من يقابله بابتسامة لطيفة ويقول بصوت هادئ: السلام عليكم ورحمة الله.',
        'phrase': '«السَّلَامُ عَلَيْكُمْ وَرَحْمَةُ اللَّهِ»',
      },
      {
        'shape': 'نجمة الصدق والأمانة ⭐',
        'badge': 'الأخلاق الحميدة',
        'lesson':
            'الصدق يجعلنا مضيئين مثل النجمة اللامعة في السماء! البطل يقول الحقيقة دائماً ويحافظ على الأمانة.',
        'phrase': '«أَنَا صَادِقٌ وَأَمِينٌ دَائِماً»',
      },
      {
        'shape': 'زهرة النظافة والنظام 🌸',
        'badge': 'آداب النظافة والطهارة',
        'lesson':
            'النظافة من الإيمان! نغسل أيدينا بالماء والصابون قبل الأكل وبعده، ونحافظ على نظافة غرفتنا.',
        'phrase': '«الطُّهُورُ شَطْرُ الإِيمَانِ»',
      },
      {
        'shape': 'بيت الكرم والاستئذان 🏠',
        'badge': 'آداب الاستئذان والضيافة',
        'lesson':
            'نطرق الباب برفق ثلاث مرات ونستأذن قبل الدخول، ونرحب بضيوفنا بابتسامة وكرم.',
        'phrase': '«أَسْتَأْذِنُ بِأَدَبٍ قَبْلَ الدُّخُولِ»',
      },
      {
        'shape': 'شمس النشاط وذكر الصباح ☀️',
        'badge': 'آداب الاستيقاظ والنشاط',
        'lesson':
            'ننام مبكراً ونستيقظ بنشاط فنرتب فراشنا ونفرش أسناننا ونشكر الله على نعمه.',
        'phrase': '«الحَمْدُ لِلَّهِ الَّذِي أَحْيَانَا بَعْدَ مَا أَمَاتَنَا»',
      },
      {
        'shape': 'تاج الكلمة الطيبة والشكر 👑',
        'badge': 'آداب الحديث والشكر',
        'lesson':
            'من يصنع لنا معروفاً نقول له: جزاك الله خيراً وشكراً لك، ونتحدث دائماً بصوت هادئ وجميل.',
        'phrase': '«الكَلِمَةُ الطَّيِّبَةُ صَدَقَةٌ»',
      },
      {
        'shape': 'كتاب العلم والحكمة 📘',
        'badge': 'آداب طالب العلم',
        'lesson':
            'نستمع لمعلمنا ولوالدينا بإنصات، ونحافظ على كتبنا وأدواتنا لنصبح علماء وأبطالاً نافعين.',
        'phrase': '«وَقُلْ رَبِّ زِدْنِي عِلْماً»',
      },
      {
        'shape': 'قلب إماطة الأذى عن الطريق 💚',
        'badge': 'آداب الطريق والبيئة',
        'lesson':
            'لا نلقي الأوراق في الشارع أبداً، بل نضعها في سلة المهملات ونبعد أي أذى عن طريق الناس.',
        'phrase': '«إِمَاطَةُ الأَذَى عَنِ الطَّرِيقِ صَدَقَةٌ»',
      },
      {
        'shape': 'ابتسامة المشاركة والتعاون مع الأصدقاء 🤝',
        'badge': 'آداب الصداقة والتعاون',
        'lesson':
            'نشارك ألعابنا مع إخوتنا وأصدقائنا بحب، ونساعد من يحتاج إلى المساعدة.',
        'phrase': '«المُؤْمِنُ لِلْمُؤْمِنِ كَالبُنْيَانِ يَشُدُّ بَعْضُهُ بَعْضاً»',
      },
    ];
    final item = baseLessons[index % baseLessons.length];
    return {
      'levelNumber': levelNum,
      'title': 'لوحة الآداب رقم $levelNum من ١٠٠: ${item['shape']}',
      'badge': item['badge']!,
      'etiquetteLesson': item['lesson']!,
      'arabicDuaOrPhrase': item['phrase']!,
      'instruction':
          'لوّن وارسم بيدك اللوحة رقم ($levelNum) واستمع لتشجيع حنين والأبطال الخارقين!',
    };
  }

  static Map<String, dynamic> getOddOneOutLevel(int index) {
    final int levelNum = (index % 100) + 1;
    final int mainClusterIdx = index % _categoryClusters.length;
    final int oddClusterIdx =
        (mainClusterIdx + 1 + (index ~/ 10)) % _categoryClusters.length;

    final mainCluster = _categoryClusters[mainClusterIdx];
    final oddCluster = _categoryClusters[oddClusterIdx];

    final List<String> mainItems =
        List<String>.from(mainCluster['items'] as List);
    final List<String> oddItems =
        List<String>.from(oddCluster['items'] as List);

    final int offset = (index * 3) % mainItems.length;
    final String m1 = mainItems[offset % mainItems.length];
    final String m2 = mainItems[(offset + 1) % mainItems.length];
    final String m3 = mainItems[(offset + 2) % mainItems.length];
    final String oddItem = oddItems[(index * 2) % oddItems.length];

    final List<String> choices = [m1, m2, m3, oddItem];
    final int pos = index % 4;
    final String temp = choices[pos];
    choices[pos] = choices[3];
    choices[3] = temp;

    return {
      'levelNumber': levelNum,
      'category': '${mainCluster['name']} × ${oddCluster['name']}',
      'visualTheme': index % 4,
      'title':
          'المرحلة $levelNum من ١٠٠: أخرج الرمز المختلف عن مجموعة (${mainCluster['name']}):',
      'items': choices,
      'odd': oddItem,
      'explanation':
          'الرمز ($oddItem) ينتمي إلى (${oddCluster['name']})، بينما البقية من (${mainCluster['name']})!',
    };
  }

  static Map<String, dynamic> getPatternLogicLevel(int index) {
    final int levelNum = (index % 100) + 1;
    final clusterA = _categoryClusters[index % _categoryClusters.length];
    final clusterB = _categoryClusters[(index + 2) % _categoryClusters.length];
    final List<String> listA = List<String>.from(clusterA['items'] as List);
    final List<String> listB = List<String>.from(clusterB['items'] as List);

    final String a = listA[index % listA.length];
    final String b = listA[(index + 3) % listA.length];
    final String c = listB[index % listB.length];
    final String d = listB[(index + 4) % listB.length];

    final int patternType = index % 4;
    List<String> sequence;
    String answer;
    String hint;

    if (patternType == 0) {
      sequence = [a, b, a, b, a];
      answer = b;
      hint =
          'اللغز $levelNum من ١٠٠: نمط متبادل ($a ثم $b ثم $a ثم $b)... ما التالي؟';
    } else if (patternType == 1) {
      sequence = [a, a, b, a, a];
      answer = b;
      hint =
          'اللغز $levelNum من ١٠٠: عنصران متشابهان ($a $a) ثم ($b)... أكمل النمط!';
    } else if (patternType == 2) {
      sequence = [a, b, c, a, b];
      answer = c;
      hint =
          'اللغز $levelNum من ١٠٠: ثلاثية مرتبة ($a ثم $b ثم $c)... ما العنصر الثالث؟';
    } else {
      sequence = [a, b, b, a, b];
      answer = b;
      hint =
          'اللغز $levelNum من ١٠٠: ($a) يتبعه مرتان ($b $b)... ماذا يأتي الآن؟';
    }

    final List<String> options = [a, b, c, d];
    return {
      'levelNumber': levelNum,
      'sequence': sequence,
      'options': options,
      'answer': answer,
      'hint': hint,
    };
  }

  static List<String> getMemoryBoardForLevel(
    int levelNumber, {
    int? difficultyTier,
  }) {
    final int idx = (levelNumber - 1).clamp(0, 99);
    final cluster1 = _categoryClusters[idx % _categoryClusters.length];
    final cluster2 = _categoryClusters[(idx + 1) % _categoryClusters.length];
    final List<String> pool = [
      ...List<String>.from(cluster1['items'] as List),
      ...List<String>.from(cluster2['items'] as List),
    ];
    final int pairCount = difficultyTier == 1
        ? 4
        : (difficultyTier == 4 ? 8 : 6);
    final int start = (idx * 2) % (pool.length - pairCount);
    final List<String> chosen = pool.sublist(start, start + pairCount);
    final List<String> pairs = [];
    for (final item in chosen) {
      pairs.add(item);
      pairs.add(item);
    }
    pairs.shuffle(Random(levelNumber * 97));
    return pairs;
  }

  static Map<String, dynamic> getVisualMathLevel(
    int index, {
    int difficultyTier = 2,
  }) {
    final int levelNum = (index % 100) + 1;
    final cluster = _categoryClusters[index % _categoryClusters.length];
    final List<String> items = List<String>.from(cluster['items'] as List);
    final String emoji = items[index % items.length];

    final bool isAdd = difficultyTier >= 2 && (index % 2 == 1);
    int target;
    int a = 1;
    int b = 1;
    if (!isAdd) {
      final int maxCount = difficultyTier == 1 ? 5 : 9;
      target = (index % maxCount) + 1;
    } else {
      final int maxAddend = difficultyTier >= 3 ? 6 : 4;
      a = (index % maxAddend) + 1;
      b = ((index ~/ 2) % maxAddend) + 1;
      target = a + b;
    }

    final List<int> options = [
      target,
      max(1, target - 1),
      target + 1,
      target + 2,
    ];
    final int swapPos = index % 4;
    final int tmp = options[swapPos];
    options[swapPos] = options[0];
    options[0] = tmp;

    return {
      'levelNumber': levelNum,
      'mode': isAdd ? 'add' : 'count',
      'a': a,
      'b': b,
      'target': target,
      'emoji': emoji,
      'options': options,
    };
  }

  static const List<Map<String, dynamic>> _baseArabicVocabulary = [
    {'emoji': '🦁', 'word': 'أَسَد', 'missing': 'ـسَد', 'ans': 'أ', 'opts': ['أ', 'ب', 'ت', 'س']},
    {'emoji': '🏠', 'word': 'بَيْت', 'missing': 'ـيْت', 'ans': 'ب', 'opts': ['ب', 'ت', 'ث', 'ن']},
    {'emoji': '🍎', 'word': 'تُفَّاحَة', 'missing': 'ـفَّاحَة', 'ans': 'ت', 'opts': ['ج', 'ت', 'خ', 'م']},
    {'emoji': '🦊', 'word': 'ثَعْلَب', 'missing': 'ـعْلَب', 'ans': 'ث', 'opts': ['ب', 'ت', 'ث', 'ف']},
    {'emoji': '🐪', 'word': 'جَمَل', 'missing': 'ـمَل', 'ans': 'ج', 'opts': ['ج', 'ح', 'خ', 'ع']},
    {'emoji': '🕊️', 'word': 'حَمَامَة', 'missing': 'ـمَامَة', 'ans': 'ح', 'opts': ['ج', 'ح', 'خ', 'هـ']},
    {'emoji': '🐑', 'word': 'خَرُوف', 'missing': 'ـرُوف', 'ans': 'خ', 'opts': ['ح', 'خ', 'غ', 'ق']},
    {'emoji': '🐻', 'word': 'دُبّ', 'missing': 'ـبّ', 'ans': 'د', 'opts': ['د', 'ذ', 'ر', 'ز']},
    {'emoji': '🌽', 'word': 'ذُرَة', 'missing': 'ـرَة', 'ans': 'ذ', 'opts': ['د', 'ذ', 'ز', 'ظ']},
    {'emoji': '🍎', 'word': 'رُمَّان', 'missing': 'ـمَّان', 'ans': 'ر', 'opts': ['د', 'ر', 'ز', 'و']},
    {'emoji': '🦒', 'word': 'زَرَافَة', 'missing': 'ـرَافَة', 'ans': 'ز', 'opts': ['ر', 'ز', 'س', 'ص']},
    {'emoji': '🐟', 'word': 'سَمَكَة', 'missing': 'ـمَكَة', 'ans': 'س', 'opts': ['ش', 'س', 'ص', 'ز']},
    {'emoji': '☀️', 'word': 'شَمْس', 'missing': 'ـمْس', 'ans': 'ش', 'opts': ['س', 'ش', 'ص', 'ض']},
    {'emoji': '🦅', 'word': 'صَقْر', 'missing': 'ـقْر', 'ans': 'ص', 'opts': ['س', 'ش', 'ص', 'ط']},
    {'emoji': '🐸', 'word': 'ضِفْدَع', 'missing': 'ـفْدَع', 'ans': 'ض', 'opts': ['ص', 'ض', 'ط', 'ظ']},
    {'emoji': '✈️', 'word': 'طَائِرَة', 'missing': 'ـائِرَة', 'ans': 'ط', 'opts': ['ت', 'ط', 'ظ', 'د']},
    {'emoji': '✉️', 'word': 'ظَرْف', 'missing': 'ـرْف', 'ans': 'ظ', 'opts': ['ذ', 'ز', 'ط', 'ظ']},
    {'emoji': '🍇', 'word': 'عِنَب', 'missing': 'ـنَب', 'ans': 'ع', 'opts': ['ع', 'غ', 'ف', 'ق']},
    {'emoji': '☁️', 'word': 'غَيْمَة', 'missing': 'ـيْمَة', 'ans': 'غ', 'opts': ['ع', 'غ', 'خ', 'ق']},
    {'emoji': '🦋', 'word': 'فَرَاشَة', 'missing': 'ـرَاشَة', 'ans': 'ف', 'opts': ['ص', 'ض', 'ف', 'ن']},
    {'emoji': '🌙', 'word': 'قَمَر', 'missing': 'ـمَر', 'ans': 'ق', 'opts': ['ف', 'ق', 'ك', 'ل']},
    {'emoji': '📘', 'word': 'كِتَاب', 'missing': 'ـتَاب', 'ans': 'ك', 'opts': ['ق', 'ك', 'ل', 'م']},
    {'emoji': '🍋', 'word': 'لَيْمُون', 'missing': 'ـيْمُون', 'ans': 'ل', 'opts': ['ك', 'ل', 'م', 'ن']},
    {'emoji': '🍌', 'word': 'مَوْز', 'missing': 'ـوْز', 'ans': 'م', 'opts': ['ل', 'م', 'ن', 'هـ']},
    {'emoji': '🐝', 'word': 'نَحْلَة', 'missing': 'ـحْلَة', 'ans': 'ن', 'opts': ['ب', 'ت', 'ن', 'ي']},
    {'emoji': '🎁', 'word': 'هَدِيَّة', 'missing': 'ـدِيَّة', 'ans': 'هـ', 'opts': ['ع', 'هـ', 'و', 'ي']},
    {'emoji': '🌹', 'word': 'وَرْدَة', 'missing': 'ـرْدَة', 'ans': 'و', 'opts': ['ر', 'ز', 'و', 'ي']},
    {'emoji': '🖐️', 'word': 'يَد', 'missing': 'ـد', 'ans': 'ي', 'opts': ['ب', 'ت', 'ن', 'ي']},
  ];

  static Map<String, dynamic> getArabicWordLevel(int index) {
    final int levelNum = (index % 100) + 1;
    final item = _baseArabicVocabulary[index % _baseArabicVocabulary.length];
    final String emoji = (item['emoji'] as String).trim() == 'pomegranate'
        ? '🍎'
        : item['emoji'] as String;
    final String word = item['word'] as String;
    return {
      'levelNumber': levelNum,
      'emoji': emoji,
      'word': word,
      'missingDisplay': item['missing'] as String,
      'prompt': 'المرحلة $levelNum من ١٠٠ — اختر الحرف الأول لكلمة ($word):',
      'options': List<String>.from(item['opts'] as List),
      'answer': item['ans'] as String,
    };
  }

  /// 100 Levels of Picture-Word & Bilingual Vocabulary Matching
  static Map<String, dynamic> getPictureWordMatchLevel(
    int index, {
    int difficultyTier = 2,
  }) {
    final int levelNum = (index % 100) + 1;
    const List<Map<String, dynamic>> pool = [
      {'word': 'تُفَّاحَةٌ حَمْرَاءُ', 'hint': 'فاكهة لذيذة ومفيدة للجسم', 'correct': '🍎', 'options': ['🍎', '🚗', '🦁', '⚽']},
      {'word': 'أَسَدٌ شُجَاعٌ', 'hint': 'يعيش في الغابة ويسمى ملك الغابة', 'correct': '🦁', 'options': ['🐟', '🦁', '🍌', '✈️']},
      {'word': 'طَائِرَةٌ سَرِيعَةٌ', 'hint': 'وسيلة نقل تطير في السماء فوق السحاب', 'correct': '✈️', 'options': ['🚢', '🚲', '✈️', '🐢']},
      {'word': 'فَرَاشَةٌ مُلَوَّنَةٌ', 'hint': 'تطير بهدوء بين الأزهار في الحديقة', 'correct': '🦋', 'options': ['🐘', '🦋', '🏠', '📚']},
      {'word': 'كِتَابٌ مُفِيدٌ', 'hint': 'نقرأ فيه القصص الجميلة ونتعلم منه العلوم', 'correct': '📘', 'options': ['📘', '🍕', '🎈', '👟']},
      {'word': 'شَمْسٌ مُشْرِقَةٌ', 'hint': 'تضيء السماء في الصباح وتمنحنا الدفء', 'correct': '☀️', 'options': ['☀️', '🌙', '🐟', '🚗']},
      {'word': 'سَمَكَةٌ سَابِحَةٌ', 'hint': 'تعيش وتسبح تحت الماء في البحر', 'correct': '🐟', 'options': ['🦁', '🐟', '🦅', '🍎']},
      {'word': 'قِطَارٌ طَوِيلٌ', 'hint': 'يسير على القضبان الحديدية وينقل المسافرين', 'correct': '🚂', 'options': ['🚂', '⛵', '🍌', '🐱']},
      {'word': 'نَحْلَةٌ نَشِيطَةٌ', 'hint': 'تجمع الرحيق من الأزهار وتصنع العسل', 'correct': '🐝', 'options': ['🐢', '🐝', '🐘', '⚽']},
      {'word': 'شَجَرَةٌ خَضْرَاءُ', 'hint': 'نبات كبير يعطينا الظل والأكسجين والثمار', 'correct': '🌳', 'options': ['🌳', '🚗', '📘', '🌙']},
    ];
    final current = pool[index % pool.length];
    return {
      'levelNumber': levelNum,
      'word': current['word'],
      'hint': 'المرحلة $levelNum من ١٠٠ (المستوى $difficultyTier): ${current['hint']}',
      'correct': current['correct'],
      'options': List<String>.from(current['options'] as List),
    };
  }

  /// 100 Levels of Smart Classification & Sorting
  static Map<String, dynamic> getSmartClassificationLevel(
    int index, {
    int difficultyTier = 2,
  }) {
    final int levelNum = (index % 100) + 1;
    const List<Map<String, dynamic>> pool = [
      {'itemEmoji': '🍌', 'itemName': 'الموز اللذيذ', 'correctCategory': 'فواكه وغذاء 🍎', 'categories': ['حيوانات الغابة 🦁', 'فواكه وغذاء 🍎', 'وسائل نقل 🚗']},
      {'itemEmoji': '🚂', 'itemName': 'القطار السريع', 'correctCategory': 'وسائل نقل 🚗', 'categories': ['حيوانات الغابة 🦁', 'فواكه وغذاء 🍎', 'وسائل نقل 🚗']},
      {'itemEmoji': '🦒', 'itemName': 'الزرافة الطويلة', 'correctCategory': 'حيوانات الغابة 🦁', 'categories': ['حيوانات الغابة 🦁', 'فواكه وغذاء 🍎', 'وسائل نقل 🚗']},
      {'itemEmoji': '🍓', 'itemName': 'الفراولة الحمراء', 'correctCategory': 'فواكه وغذاء 🍎', 'categories': ['حيوانات الغابة 🦁', 'فواكه وغذاء 🍎', 'وسائل نقل 🚗']},
      {'itemEmoji': '🐬', 'itemName': 'الدولفين الذكي', 'correctCategory': 'كائنات بحرية 🌊', 'categories': ['كائنات بحرية 🌊', 'طيور السماء 🦅', 'أدوات مدرسية ✏️']},
      {'itemEmoji': '✏️', 'itemName': 'قلم الرصاص', 'correctCategory': 'أدوات مدرسية ✏️', 'categories': ['كائنات بحرية 🌊', 'فواكه وغذاء 🍎', 'أدوات مدرسية ✏️']},
      {'itemEmoji': '🥦', 'itemName': 'البروكلي الأخضر', 'correctCategory': 'خضروات صحية 🥕', 'categories': ['خضروات صحية 🥕', 'وسائل نقل 🚗', 'أجرام الفضاء 🪐']},
      {'itemEmoji': '🪐', 'itemName': 'كوكب زحل ذو الحلقات', 'correctCategory': 'أجرام الفضاء 🪐', 'categories': ['خضروات صحية 🥕', 'أجرام الفضاء 🪐', 'حيوانات المزرعة 🐑']},
    ];
    final current = pool[index % pool.length];
    return {
      'levelNumber': levelNum,
      'itemEmoji': current['itemEmoji'],
      'itemName': current['itemName'],
      'correctCategory': current['correctCategory'],
      'categories': List<String>.from(current['categories'] as List),
    };
  }

  /// 100 Levels of Auditory Discrimination & Sound Source Identification
  static Map<String, dynamic> getSoundAndListeningLevel(
    int index, {
    int difficultyTier = 2,
  }) {
    final int levelNum = (index % 100) + 1;
    const List<Map<String, dynamic>> pool = [
      {'soundText': 'مُوَاءٌ لَطِيفٌ: مِيَاوْ.. مِيَاوْ!', 'question': 'من صاحب هذا الصوت اللطيف الذي يحب شرب الحليب؟', 'correct': '🐱 القطة الأليفة', 'options': ['🐱 القطة الأليفة', '🦁 الأسد', '🚂 القطار']},
      {'soundText': 'زَئِيرٌ قَوِيٌّ فِي الغَابَةِ!', 'question': 'من صاحب صوت الزئير ويعيش في الغابة؟', 'correct': '🦁 الأسد الشجاع', 'options': ['🐦 العصفور', '🦁 الأسد الشجاع', '🐑 الخروف']},
      {'soundText': 'زَقْزَقَةٌ جَمِيلَةٌ فَوْقَ الشَّجَرَةِ: سِيو سِيو!', 'question': 'من الذي يغرد فوق أغصان الشجرة في الصباح؟', 'correct': '🐦 العصفور المغرد', 'options': ['🐦 العصفور المغرد', '🐘 الفيل', '🚗 السيارة']},
      {'soundText': 'طَنِينٌ هَادِئٌ بَيْنَ الأَزْهَارِ: ززززز!', 'question': 'من الحشرة النشيطة التي تصنع لنا العسل المفيد؟', 'correct': '🐝 النحلة النشيطة', 'options': ['🐢 السلحفاة', '🐝 النحلة النشيطة', '🐟 السمكة']},
      {'soundText': 'ثُغَاءٌ فِي المَزْرَعَةِ: مَاااء.. مَاااء!', 'question': 'من الحيوان الأليف الذي يعطينا الصوف الدافئ؟', 'correct': '🐑 الخروف الوديع', 'options': ['🐑 الخروف الوديع', '🦅 الصقر', '🐸 الضفدع']},
      {'soundText': 'صَفِيرُ القِطَارِ عَلى السِّكَّةِ: تُوت.. تُوت!', 'question': 'ما وسيلة النقل التي تصدر هذا الصوت فوق القضبان؟', 'correct': '🚂 القطار السريع', 'options': ['🚲 الدراجة', '🚂 القطار السريع', '🐱 القطة']},
    ];
    final current = pool[index % pool.length];
    return {
      'levelNumber': levelNum,
      'soundText': current['soundText'],
      'question': 'المرحلة $levelNum من ١٠٠: ${current['question']}',
      'correct': current['correct'],
      'options': List<String>.from(current['options'] as List),
    };
  }

  /// 100 Levels of Logical Sequencing & Smart Riddles
  static Map<String, dynamic> getLogicalSequenceAndRiddleLevel(
    int index, {
    int difficultyTier = 2,
  }) {
    final int levelNum = (index % 100) + 1;
    const List<Map<String, dynamic>> sequences = [
      {
        'title': 'ترتيب خطوات غسل اليدين قبل الطعام',
        'riddleTip': 'لغز النظافة: نبدأ بالماء ثم الصابون ثم التجفيف!',
        'steps': [
          '١. أفتح الصنبور وأبلل يديّ بالماء باعتدال 💧',
          '٢. أضع الصابون وأفرك يديّ جيداً 🧼',
          '٣. أغسل يديّ بالماء وأجففهما بالمنشفة النظيفة 🤲',
        ],
      },
      {
        'title': 'ترتيب خطوات الاستعداد للنوم الهادئ',
        'riddleTip': 'لغز المساء: نرتب الغرفة ثم نفرش أسناننا ثم ننام!',
        'steps': [
          '١. أرتب ألعابي وأضعها في السلة 🧸',
          '٢. أنظف أسناني بالفرشاة والمعجون 🪥',
          '٣. أقرأ دعاء النوم وأغمض عينيّ بهدوء 🌙',
        ],
      },
      {
        'title': 'مراحل نمو النبتة الجميلة',
        'riddleTip': 'لغز الطبيعة: من البذرة الصغيرة إلى الزهرة المتفتحة!',
        'steps': [
          '١. نضع البذرة الصغيرة في التربة ونسقيها 🌱',
          '٢. تكبر الساق والأوراق الخضراء مع ضوء الشمس 🌿',
          '٣. تتفتح الزهرة الملونة الجميلة 🌸',
        ],
      },
      {
        'title': 'ترتيب وجبات اليوم الصحي للبطل',
        'riddleTip': 'لغز الأوقات: الصباح ثم الظهيرة ثم المساء!',
        'steps': [
          '١. أتناول فطوري الصحي في الصباح الباكر 🥛',
          '٢. أتناول وجبة الغداء المفيدة مع عائلتي ظهراً 🍲',
          '٣. أتناول عشاءً خفيفاً قبل النوم المبكر 🍎',
        ],
      },
    ];
    final current = sequences[index % sequences.length];
    return {
      'levelNumber': levelNum,
      'title': 'المرحلة $levelNum من ١٠٠: ${current['title']}',
      'riddleTip': current['riddleTip'],
      'steps': List<String>.from(current['steps'] as List),
    };
  }
}
