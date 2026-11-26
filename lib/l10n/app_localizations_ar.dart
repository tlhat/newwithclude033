// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'حنين كيدز — منصة التعلم الآمنة للأطفال';

  @override
  String get freeForeverTagline =>
      'محتوى مجاني ومحتوى بالاشتراك — بدون إعلانات';

  @override
  String get navStories => 'قصص حنين';

  @override
  String get navAcademy => 'أكاديمية حنين';

  @override
  String get navGames => 'واحة اللعب والتعلم';

  @override
  String get navAchievements => 'إنجازاتي';

  @override
  String get navAccount => 'حسابي';

  @override
  String get achievementsTitle => 'إنجازاتي';

  @override
  String greatJobChild(String name) {
    return 'أحسنت يا $name!';
  }

  @override
  String get achievementsSubtitle =>
      'كل خطوة صغيرة في التعلم واللعب تضيف لك مهارة جديدة.';

  @override
  String get starsEarnedLabel => 'النجوم المكتسبة';

  @override
  String get iqPointsLabel => 'نقاط الذكاء';

  @override
  String get completedLessonsLabel => 'دروس مكتملة';

  @override
  String get unlockedBadgesLabel => 'الشارات المفتوحة';

  @override
  String get unlockedBadgesHeading => 'الشارات التي حصلت عليها';

  @override
  String get noBadgesYet =>
      'ابدأ أول درس في الأكاديمية أو العب تحدياً في واحة اللعب والتعلم لفتح أول شارة لك.';

  @override
  String get goToAcademy => 'انتقل إلى أكاديمية حنين';

  @override
  String badgeUnlockedAt(String date) {
    return 'تم الفتح: $date';
  }

  @override
  String get accountTitle => 'حسابي';

  @override
  String ageGroupAndLevel(String age, String level) {
    return 'الفئة العمرية: $age • $level';
  }

  @override
  String get dailyUsageLabel => 'وقت الاستخدام اليومي';

  @override
  String minutesProgress(int used, int limit) {
    return '$used / $limit دقيقة';
  }

  @override
  String get darkModeTitle => 'الوضع الداكن';

  @override
  String get darkModeSubtitle => 'مظهر موحد ومريح للعين في كل الشاشات';

  @override
  String get switchChildTitle => 'تبديل ملف الطفل';

  @override
  String registeredProfilesCount(int count) {
    return 'عدد الملفات المسجلة: $count';
  }

  @override
  String get uiLanguageTitle => 'لغة الواجهة (العربية / English)';

  @override
  String get learningLanguageTitle => 'لغة تعلم الطفل';

  @override
  String get languageArabic => 'العربية';

  @override
  String get languageEnglish => 'English';

  @override
  String get parentalGateButton => 'بوابة الوالدين والإعدادات (محمية بالرمز)';

  @override
  String get parentGateTitle => 'بوابة الوالدين';

  @override
  String get parentGatePrompt =>
      'للدخول إلى بوابة الوالدين، يرجى إدخال الرمز السري للوالدين (المكوّن من ٦ أرقام):';

  @override
  String get parentGateHint => 'أدخل الرمز السري (٦ أرقام)';

  @override
  String get parentGateError =>
      'الرمز السري غير صحيح. يرجى إدخال ٦ أرقام صحيحة.';

  @override
  String get cancelButton => 'إلغاء';

  @override
  String get enterButton => 'دخول';

  @override
  String get retryButton => 'إعادة المحاولة';

  @override
  String get voiceLanguageTitle => 'لغة المساعد الصوتي والنطق';

  @override
  String get parentStudioTitle => 'استوديو الوالدين';

  @override
  String get authPhoneLabel => 'رقم الموبايل';

  @override
  String get authParentNameLabel => 'اسم ولي الأمر';

  @override
  String get authChildNameLabel => 'اسم الطفل';

  @override
  String get authChildAgeLabel => 'سن الطفل';

  @override
  String get authOtpLabel => 'رمز التحقق OTP';

  @override
  String get authSendOtpButton => 'إرسال رمز التحقق (OTP) 📲';

  @override
  String get authVerifyButton => 'تأكيد الرمز وبدء الرحلة 🚀';

  @override
  String get authEditPhoneButton => 'تعديل الرقم';

  @override
  String get betaFeedbackTitle => 'ملاحظات الإصدار التجريبي (Beta)';

  @override
  String get betaFeedbackSent => 'تم الإرسال';

  @override
  String get betaFeedbackPending => 'قيد الانتظار';

  @override
  String get betaFeedbackFailed => 'فشل الإرسال';

  @override
  String get tierBeginner => 'تمهيدي (٢-٣ سنوات)';

  @override
  String get tierElementary => 'مبتدئ (٣-٤ سنوات)';

  @override
  String get tierIntermediate => 'متوسط (٤-٥ سنوات)';

  @override
  String get tierAdvanced => 'متقدم (٥-٦ سنوات)';

  @override
  String get deleteChildConfirmation =>
      'هل أنت متأكد من حذف ملف الطفل نهائياً؟';

  @override
  String get confirmDelete => 'تأكيد الحذف';

  @override
  String get cancel => 'إلغاء';

  @override
  String get companionStudioTitle => 'استوديو شخصيتي';

  @override
  String get companionGenderBoy => 'ولد';

  @override
  String get companionGenderGirl => 'بنت';

  @override
  String get companionCategoryGender => 'الجنس';

  @override
  String get companionCategoryFace => 'الوجه';

  @override
  String get companionCategoryHair => 'الشعر';

  @override
  String get companionCategoryOutfit => 'الملابس';

  @override
  String get companionCategoryBackground => 'الخلفية';

  @override
  String get companionCategoryPose => 'الحركة';

  @override
  String get companionSaveButton => 'حفظ شخصيتي ✨';

  @override
  String get companionUnlockTitle => 'فتح عنصر جديد';

  @override
  String companionUnlockPrompt(String itemName, int stars) {
    return 'هل تريد فتح \"$itemName\" مقابل $stars ⭐؟';
  }

  @override
  String get companionUnlockButton => 'فتح الآن';

  @override
  String get companionNotEnoughStars =>
      'لا يوجد نجوم كافية! اجمع المزيد من التعلم واللعب.';

  @override
  String get companionCustomizeButton => 'تخصيص شخصيتي 🎨';

  @override
  String get companionShopDisabled =>
      'تم تعطيل متجر الشخصيات من قبل ولي الأمر.';

  @override
  String companionGreeting(String childName) {
    return 'أهلاً يا $childName! 👋 ما رأيك نتعلم شيئاً جديداً اليوم؟';
  }

  @override
  String get companionEncourageCorrect => 'أحسنت! إجابة رائعة يا بطل! 🌟';

  @override
  String get companionEncourageHint =>
      'لا تقلق، جرب مرة ثانية! أنت قريب جداً من الإجابة الصحيحة 💪';

  @override
  String get companionExplorePrompt => 'هيا نكتشف مغامرة جديدة معاً!';

  @override
  String get companionHintButton => 'أعطني تلميحاً';

  @override
  String companionHintTier1(String targetWord) {
    return 'انظر إلى الصور واستمع مرة أخرى — أيّ صورة تناسب كلمة «$targetWord»؟';
  }

  @override
  String companionHintTier2(String targetWord) {
    return 'الاستراتيجية: قل «$targetWord» ببطء بصوت عالٍ، ثم ابحث عن الصورة التي تبدأ بنفس الصوت الأول.';
  }

  @override
  String companionHintTier3(String exampleWord, String emoji) {
    return 'مثال محلول: لنجد كلمة «$exampleWord» $emoji نقولها ببطء ونختار الصورة المناسبة. الآن جرّب الحيلة نفسها في سؤالك!';
  }

  @override
  String companionHintTier3Fallback(String targetWord) {
    return 'مثال محلول: لنجد كلمة مثل «$targetWord»، قلها ببطء بصوت عالٍ، واستمع إلى صوتها الأول، ثم ابحث عن الصورة المناسبة. جرّب الحيلة نفسها الآن!';
  }

  @override
  String get companionRevealAnswerButton => 'أرني الإجابة';

  @override
  String get companionAnswerRevealed =>
      'الإجابة الصحيحة مضيئة — انظر إليها جيداً وحاول أن تتذكرها! 💡';
}
