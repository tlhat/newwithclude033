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
];

final Set<String> kExerciseGameSkills = {
  for (final ExerciseGameDef g in kExerciseGames) g.skill
};
