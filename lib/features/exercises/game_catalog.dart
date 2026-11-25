/// One card in the games hub that plays a single skill of the JSON engine.
class ExerciseGameDef {
  final String skill;
  final String title;
  final String icon;
  final String hint;
  final int color;
  const ExerciseGameDef(this.skill, this.title, this.icon, this.hint, this.color);
}

const List<ExerciseGameDef> kExerciseGames = [
  ExerciseGameDef('number_line', 'خط الأعداد', '📏', 'حرّك النقطة على الرقم الصح', 0xFF0EA5E9),
  ExerciseGameDef('fill_blank', 'املأ الفراغ', '✍️', 'اختر الكلمة الناقصة', 0xFFF97316),
  ExerciseGameDef('multi_select', 'اختر كل الصح', '☑️', 'فيه أكتر من إجابة صحيحة', 0xFF22C55E),
  ExerciseGameDef('grid_points', 'أين النقطة؟', '📍', 'اضغط على المكان الصح في الشبكة', 0xFFEF4444),
  ExerciseGameDef('bar_chart', 'ارسم الأعمدة', '📊', 'ارفع الأعمدة للعدد المطلوب', 0xFFA855F7),
  // ---- batch 1: language and numbers
  ExerciseGameDef('missing_letter', 'حرف ناقص', '🔤', 'ما الحرف الناقص في الكلمة؟', 0xFF14B8A6),
  ExerciseGameDef('build_word', 'ركّب الكلمة', '🧩', 'رتّب الحروف لتكوّن الكلمة', 0xFFF59E0B),
  ExerciseGameDef('same_start', 'نفس البداية', '🅰️', 'كلمات تبدأ بنفس الحرف', 0xFF6366F1),
  ExerciseGameDef('same_end', 'نفس النهاية', '🔚', 'كلمات تنتهي بنفس الحرف', 0xFFEC4899),
  ExerciseGameDef('pic_word', 'وصّل الصورة بكلمتها', '🖼️', 'وصّل كل صورة باسمها', 0xFF10B981),
  ExerciseGameDef('scrambled', 'حروف مبعثرة', '🌀', 'رتّب الحروف المبعثرة', 0xFF8B5CF6),
  ExerciseGameDef('harakat', 'الفتحة والضمة والكسرة', '🔡', 'اعرف حركة الحرف', 0xFFEF4444),
  ExerciseGameDef('rhyme', 'قافية', '🎵', 'ما الكلمة التي تتقفّى؟', 0xFF0EA5E9),
  ExerciseGameDef('bigger_smaller', 'أكبر وأصغر', '⚖️', 'اختر الرقم الأكبر أو الأصغر', 0xFF22C55E),
  ExerciseGameDef('missing_number', 'الرقم الناقص', '❓', 'أكمل تسلسل الأرقام', 0xFFF97316),
  ExerciseGameDef('add_pics', 'جمع بالصور', '➕', 'اجمع الصور', 0xFFA855F7),
  ExerciseGameDef('subtract_apples', 'طرح بالتفاح', '🍎', 'حنين بتاكل تفاح، كام فاضل؟', 0xFFDC2626),
  ExerciseGameDef('before_after', 'قبل وبعد الرقم', '↔️', 'ما الرقم قبل أو بعد؟', 0xFF14B8A6),
  ExerciseGameDef('even_odd', 'زوجي وفردي', '🎲', 'صنّف الأرقام زوجي أو فردي', 0xFF6366F1),
  ExerciseGameDef('money', 'الفلوس والعملة', '🪙', 'احسب الجنيهات والقروش', 0xFFF59E0B),
  // ---- batch 2: logic, measuring, science
  ExerciseGameDef('complete_pattern', 'أكمل النمط', '🔁', 'ما الشكل اللي بعد؟', 0xFF14B8A6),
  ExerciseGameDef('odd_one', 'مين المختلف', '🕵️', 'اختر الشكل الغريب', 0xFFEF4444),
  ExerciseGameDef('size_order', 'رتّب بالحجم', '📐', 'من الأصغر للأكبر', 0xFF6366F1),
  ExerciseGameDef('color_mix', 'مزج الألوان', '🎨', 'أي لون يطلع من الخلط؟', 0xFFEC4899),
  ExerciseGameDef('hidden_shapes', 'أشكال مخفية', '🔍', 'عُد الأشكال', 0xFFF59E0B),
  ExerciseGameDef('mirror', 'المرآة والتماثل', '🪞', 'تماثل وانعكاس', 0xFF0EA5E9),
  ExerciseGameDef('length', 'قياس الطول والوزن', '📏', 'أطول وأقصر وأثقل', 0xFF22C55E),
  ExerciseGameDef('animal_home', 'بيت كل حيوان', '🏡', 'أين يعيش الحيوان؟', 0xFF10B981),
  ExerciseGameDef('what_eats', 'إيه بياكل', '🥕', 'ماذا يأكل الحيوان؟', 0xFFF97316),
  ExerciseGameDef('seasons', 'الفصول الأربعة', '🍂', 'تعرّف على الفصول', 0xFFA855F7),
  ExerciseGameDef('weather_clothes', 'الطقس واللبس المناسب', '☂️', 'ماذا نلبس؟', 0xFF38BDF8),
  ExerciseGameDef('jobs', 'المهن', '👩‍🚒', 'من يعمل ماذا؟', 0xFFDC2626),
  ExerciseGameDef('transport', 'المواصلات', '🚌', 'وسائل المواصلات', 0xFF14B8A6),
  ExerciseGameDef('fruit_veg', 'فواكه وخضار', '🍅', 'فاكهة ولا خضار؟', 0xFF84CC16),
  ExerciseGameDef('five_senses', 'الحواس الخمس', '👁️', 'العين والأذن والأنف', 0xFF8B5CF6),
  // ---- batch 3: life skills and values
  ExerciseGameDef('first_letter', 'الحرف الأول', '🔤', 'أي حرف يبدأ به الاسم؟', 0xFF14B8A6),
  ExerciseGameDef('day_routine', 'رتّب روتين اليوم', '⏰', 'رتّب أحداث اليوم', 0xFFF59E0B),
  ExerciseGameDef('right_wrong', 'صح ولا غلط في الآداب', '✅', 'تصرفات جميلة وغير جميلة', 0xFF22C55E),
  ExerciseGameDef('teeth', 'تنضيف الأسنان', '🪥', 'خطوات غسل الأسنان', 0xFF0EA5E9),
  ExerciseGameDef('tidy_room', 'رتّب الأوضة', '🧺', 'حط كل حاجة في مكانها', 0xFFA855F7),
  ExerciseGameDef('emotions', 'المشاعر', '😊', 'اختار الوش المناسب للإحساس', 0xFFEC4899),
  ExerciseGameDef('emotions_choice', 'تصرّف مع المشاعر', '🤗', 'ماذا نفعل؟', 0xFFF97316),
  ExerciseGameDef('story_order', 'رتّب أحداث القصة', '📜', 'أي حدث أولا؟', 0xFF6366F1),
  ExerciseGameDef('road_safety', 'سلامة الطريق', '🚦', 'ازاي نعدّي بأمان', 0xFFEF4444),
  ExerciseGameDef('wash_hands', 'غسل الإيدين', '🧼', 'خطوات غسل الإيدين', 0xFF38BDF8),
  ExerciseGameDef('please_thanks', 'من فضلك وشكراً', '🙏', 'كلمات جميلة', 0xFF10B981),
  ExerciseGameDef('sharing', 'المشاركة والتقسيم', '🤝', 'نقسم بالتساوي', 0xFFDC2626),
];

final Set<String> kExerciseGameSkills = {
  for (final ExerciseGameDef g in kExerciseGames) g.skill
};
