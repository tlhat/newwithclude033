import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en')
  ];

  /// No description provided for @appTitle.
  ///
  /// In ar, this message translates to:
  /// **'حنين كيدز — منصة التعلم الآمنة للأطفال'**
  String get appTitle;

  /// No description provided for @freeForeverTagline.
  ///
  /// In ar, this message translates to:
  /// **'مجاني بالكامل ١٠٠٪ — بدون اشتراكات أو إعلانات'**
  String get freeForeverTagline;

  /// No description provided for @navStories.
  ///
  /// In ar, this message translates to:
  /// **'قصص حنين'**
  String get navStories;

  /// No description provided for @navAcademy.
  ///
  /// In ar, this message translates to:
  /// **'أكاديمية حنين'**
  String get navAcademy;

  /// No description provided for @navGames.
  ///
  /// In ar, this message translates to:
  /// **'واحة الذكاء'**
  String get navGames;

  /// No description provided for @navAchievements.
  ///
  /// In ar, this message translates to:
  /// **'إنجازاتي'**
  String get navAchievements;

  /// No description provided for @navAccount.
  ///
  /// In ar, this message translates to:
  /// **'حسابي'**
  String get navAccount;

  /// No description provided for @achievementsTitle.
  ///
  /// In ar, this message translates to:
  /// **'إنجازاتي'**
  String get achievementsTitle;

  /// No description provided for @greatJobChild.
  ///
  /// In ar, this message translates to:
  /// **'أحسنت يا {name}!'**
  String greatJobChild(String name);

  /// No description provided for @achievementsSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'كل خطوة صغيرة في التعلم واللعب تضيف لك مهارة جديدة.'**
  String get achievementsSubtitle;

  /// No description provided for @starsEarnedLabel.
  ///
  /// In ar, this message translates to:
  /// **'النجوم المكتسبة'**
  String get starsEarnedLabel;

  /// No description provided for @iqPointsLabel.
  ///
  /// In ar, this message translates to:
  /// **'نقاط الذكاء'**
  String get iqPointsLabel;

  /// No description provided for @completedLessonsLabel.
  ///
  /// In ar, this message translates to:
  /// **'دروس مكتملة'**
  String get completedLessonsLabel;

  /// No description provided for @unlockedBadgesLabel.
  ///
  /// In ar, this message translates to:
  /// **'الشارات المفتوحة'**
  String get unlockedBadgesLabel;

  /// No description provided for @unlockedBadgesHeading.
  ///
  /// In ar, this message translates to:
  /// **'الشارات التي حصلت عليها'**
  String get unlockedBadgesHeading;

  /// No description provided for @noBadgesYet.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ أول درس في الأكاديمية أو العب تحدياً في واحة الذكاء لفتح أول شارة لك.'**
  String get noBadgesYet;

  /// No description provided for @goToAcademy.
  ///
  /// In ar, this message translates to:
  /// **'انتقل إلى أكاديمية حنين'**
  String get goToAcademy;

  /// No description provided for @badgeUnlockedAt.
  ///
  /// In ar, this message translates to:
  /// **'تم الفتح: {date}'**
  String badgeUnlockedAt(String date);

  /// No description provided for @accountTitle.
  ///
  /// In ar, this message translates to:
  /// **'حسابي'**
  String get accountTitle;

  /// No description provided for @ageGroupAndLevel.
  ///
  /// In ar, this message translates to:
  /// **'الفئة العمرية: {age} • {level}'**
  String ageGroupAndLevel(String age, String level);

  /// No description provided for @dailyUsageLabel.
  ///
  /// In ar, this message translates to:
  /// **'وقت الاستخدام اليومي'**
  String get dailyUsageLabel;

  /// No description provided for @minutesProgress.
  ///
  /// In ar, this message translates to:
  /// **'{used} / {limit} دقيقة'**
  String minutesProgress(int used, int limit);

  /// No description provided for @darkModeTitle.
  ///
  /// In ar, this message translates to:
  /// **'الوضع الداكن'**
  String get darkModeTitle;

  /// No description provided for @darkModeSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'مظهر موحد ومريح للعين في كل الشاشات'**
  String get darkModeSubtitle;

  /// No description provided for @switchChildTitle.
  ///
  /// In ar, this message translates to:
  /// **'تبديل ملف الطفل'**
  String get switchChildTitle;

  /// No description provided for @registeredProfilesCount.
  ///
  /// In ar, this message translates to:
  /// **'عدد الملفات المسجلة: {count}'**
  String registeredProfilesCount(int count);

  /// No description provided for @uiLanguageTitle.
  ///
  /// In ar, this message translates to:
  /// **'لغة الواجهة (العربية / English)'**
  String get uiLanguageTitle;

  /// No description provided for @learningLanguageTitle.
  ///
  /// In ar, this message translates to:
  /// **'لغة تعلم الطفل'**
  String get learningLanguageTitle;

  /// No description provided for @languageArabic.
  ///
  /// In ar, this message translates to:
  /// **'العربية'**
  String get languageArabic;

  /// No description provided for @languageEnglish.
  ///
  /// In ar, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @parentalGateButton.
  ///
  /// In ar, this message translates to:
  /// **'بوابة الوالدين والإعدادات (محمية بالرمز)'**
  String get parentalGateButton;

  /// No description provided for @parentGateTitle.
  ///
  /// In ar, this message translates to:
  /// **'بوابة الوالدين'**
  String get parentGateTitle;

  /// No description provided for @parentGatePrompt.
  ///
  /// In ar, this message translates to:
  /// **'للدخول إلى بوابة الوالدين، يرجى إدخال الرمز السري للوالدين (المكوّن من ٦ أرقام):'**
  String get parentGatePrompt;

  /// No description provided for @parentGateHint.
  ///
  /// In ar, this message translates to:
  /// **'أدخل الرمز السري (٦ أرقام)'**
  String get parentGateHint;

  /// No description provided for @parentGateError.
  ///
  /// In ar, this message translates to:
  /// **'الرمز السري غير صحيح. يرجى إدخال ٦ أرقام صحيحة.'**
  String get parentGateError;

  /// No description provided for @cancelButton.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get cancelButton;

  /// No description provided for @enterButton.
  ///
  /// In ar, this message translates to:
  /// **'دخول'**
  String get enterButton;

  /// No description provided for @retryButton.
  ///
  /// In ar, this message translates to:
  /// **'إعادة المحاولة'**
  String get retryButton;

  /// No description provided for @voiceLanguageTitle.
  ///
  /// In ar, this message translates to:
  /// **'لغة المساعد الصوتي والنطق'**
  String get voiceLanguageTitle;

  /// No description provided for @parentStudioTitle.
  ///
  /// In ar, this message translates to:
  /// **'استوديو الوالدين'**
  String get parentStudioTitle;

  /// No description provided for @authPhoneLabel.
  ///
  /// In ar, this message translates to:
  /// **'رقم الموبايل'**
  String get authPhoneLabel;

  /// No description provided for @authParentNameLabel.
  ///
  /// In ar, this message translates to:
  /// **'اسم ولي الأمر'**
  String get authParentNameLabel;

  /// No description provided for @authChildNameLabel.
  ///
  /// In ar, this message translates to:
  /// **'اسم الطفل'**
  String get authChildNameLabel;

  /// No description provided for @authChildAgeLabel.
  ///
  /// In ar, this message translates to:
  /// **'سن الطفل'**
  String get authChildAgeLabel;

  /// No description provided for @authOtpLabel.
  ///
  /// In ar, this message translates to:
  /// **'رمز التحقق OTP'**
  String get authOtpLabel;

  /// No description provided for @authSendOtpButton.
  ///
  /// In ar, this message translates to:
  /// **'إرسال رمز التحقق (OTP) 📲'**
  String get authSendOtpButton;

  /// No description provided for @authVerifyButton.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد الرمز وبدء الرحلة 🚀'**
  String get authVerifyButton;

  /// No description provided for @authEditPhoneButton.
  ///
  /// In ar, this message translates to:
  /// **'تعديل الرقم'**
  String get authEditPhoneButton;

  /// No description provided for @betaFeedbackTitle.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظات الإصدار التجريبي (Beta)'**
  String get betaFeedbackTitle;

  /// No description provided for @betaFeedbackSent.
  ///
  /// In ar, this message translates to:
  /// **'تم الإرسال'**
  String get betaFeedbackSent;

  /// No description provided for @betaFeedbackPending.
  ///
  /// In ar, this message translates to:
  /// **'قيد الانتظار'**
  String get betaFeedbackPending;

  /// No description provided for @betaFeedbackFailed.
  ///
  /// In ar, this message translates to:
  /// **'فشل الإرسال'**
  String get betaFeedbackFailed;

  /// No description provided for @tierBeginner.
  ///
  /// In ar, this message translates to:
  /// **'تمهيدي (٢-٣ سنوات)'**
  String get tierBeginner;

  /// No description provided for @tierElementary.
  ///
  /// In ar, this message translates to:
  /// **'مبتدئ (٣-٤ سنوات)'**
  String get tierElementary;

  /// No description provided for @tierIntermediate.
  ///
  /// In ar, this message translates to:
  /// **'متوسط (٤-٥ سنوات)'**
  String get tierIntermediate;

  /// No description provided for @tierAdvanced.
  ///
  /// In ar, this message translates to:
  /// **'متقدم (٥-٦ سنوات)'**
  String get tierAdvanced;

  /// No description provided for @deleteChildConfirmation.
  ///
  /// In ar, this message translates to:
  /// **'هل أنت متأكد من حذف ملف الطفل نهائياً؟'**
  String get deleteChildConfirmation;

  /// No description provided for @confirmDelete.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد الحذف'**
  String get confirmDelete;

  /// No description provided for @cancel.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get cancel;

  /// No description provided for @companionStudioTitle.
  ///
  /// In ar, this message translates to:
  /// **'استوديو شخصيتي'**
  String get companionStudioTitle;

  /// No description provided for @companionGenderBoy.
  ///
  /// In ar, this message translates to:
  /// **'ولد'**
  String get companionGenderBoy;

  /// No description provided for @companionGenderGirl.
  ///
  /// In ar, this message translates to:
  /// **'بنت'**
  String get companionGenderGirl;

  /// No description provided for @companionCategoryGender.
  ///
  /// In ar, this message translates to:
  /// **'الجنس'**
  String get companionCategoryGender;

  /// No description provided for @companionCategoryFace.
  ///
  /// In ar, this message translates to:
  /// **'الوجه'**
  String get companionCategoryFace;

  /// No description provided for @companionCategoryHair.
  ///
  /// In ar, this message translates to:
  /// **'الشعر'**
  String get companionCategoryHair;

  /// No description provided for @companionCategoryOutfit.
  ///
  /// In ar, this message translates to:
  /// **'الملابس'**
  String get companionCategoryOutfit;

  /// No description provided for @companionCategoryBackground.
  ///
  /// In ar, this message translates to:
  /// **'الخلفية'**
  String get companionCategoryBackground;

  /// No description provided for @companionCategoryPose.
  ///
  /// In ar, this message translates to:
  /// **'الحركة'**
  String get companionCategoryPose;

  /// No description provided for @companionSaveButton.
  ///
  /// In ar, this message translates to:
  /// **'حفظ شخصيتي ✨'**
  String get companionSaveButton;

  /// No description provided for @companionUnlockTitle.
  ///
  /// In ar, this message translates to:
  /// **'فتح عنصر جديد'**
  String get companionUnlockTitle;

  /// No description provided for @companionUnlockPrompt.
  ///
  /// In ar, this message translates to:
  /// **'هل تريد فتح \"{itemName}\" مقابل {stars} ⭐؟'**
  String companionUnlockPrompt(String itemName, int stars);

  /// No description provided for @companionUnlockButton.
  ///
  /// In ar, this message translates to:
  /// **'فتح الآن'**
  String get companionUnlockButton;

  /// No description provided for @companionNotEnoughStars.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد نجوم كافية! اجمع المزيد من التعلم واللعب.'**
  String get companionNotEnoughStars;

  /// No description provided for @companionCustomizeButton.
  ///
  /// In ar, this message translates to:
  /// **'تخصيص شخصيتي 🎨'**
  String get companionCustomizeButton;

  /// No description provided for @companionShopDisabled.
  ///
  /// In ar, this message translates to:
  /// **'تم تعطيل متجر الشخصيات من قبل ولي الأمر.'**
  String get companionShopDisabled;

  /// No description provided for @companionGreeting.
  ///
  /// In ar, this message translates to:
  /// **'أهلاً يا {childName}! 👋 ما رأيك نتعلم شيئاً جديداً اليوم؟'**
  String companionGreeting(String childName);

  /// No description provided for @companionEncourageCorrect.
  ///
  /// In ar, this message translates to:
  /// **'أحسنت! إجابة رائعة يا بطل! 🌟'**
  String get companionEncourageCorrect;

  /// No description provided for @companionEncourageHint.
  ///
  /// In ar, this message translates to:
  /// **'لا تقلق، جرب مرة ثانية! أنت قريب جداً من الإجابة الصحيحة 💪'**
  String get companionEncourageHint;

  /// No description provided for @companionExplorePrompt.
  ///
  /// In ar, this message translates to:
  /// **'هيا نكتشف مغامرة جديدة معاً!'**
  String get companionExplorePrompt;

  /// No description provided for @companionHintButton.
  ///
  /// In ar, this message translates to:
  /// **'أعطني تلميحاً'**
  String get companionHintButton;

  /// No description provided for @companionHintTier1.
  ///
  /// In ar, this message translates to:
  /// **'انظر إلى الصور واستمع مرة أخرى — أيّ صورة تناسب كلمة «{targetWord}»؟'**
  String companionHintTier1(String targetWord);

  /// No description provided for @companionHintTier2.
  ///
  /// In ar, this message translates to:
  /// **'الاستراتيجية: قل «{targetWord}» ببطء بصوت عالٍ، ثم ابحث عن الصورة التي تبدأ بنفس الصوت الأول.'**
  String companionHintTier2(String targetWord);

  /// No description provided for @companionHintTier3.
  ///
  /// In ar, this message translates to:
  /// **'مثال محلول: لنجد كلمة «{exampleWord}» {emoji} نقولها ببطء ونختار الصورة المناسبة. الآن جرّب الحيلة نفسها في سؤالك!'**
  String companionHintTier3(String exampleWord, String emoji);

  /// No description provided for @companionHintTier3Fallback.
  ///
  /// In ar, this message translates to:
  /// **'مثال محلول: لنجد كلمة مثل «{targetWord}»، قلها ببطء بصوت عالٍ، واستمع إلى صوتها الأول، ثم ابحث عن الصورة المناسبة. جرّب الحيلة نفسها الآن!'**
  String companionHintTier3Fallback(String targetWord);

  /// No description provided for @companionRevealAnswerButton.
  ///
  /// In ar, this message translates to:
  /// **'أرني الإجابة'**
  String get companionRevealAnswerButton;

  /// No description provided for @companionAnswerRevealed.
  ///
  /// In ar, this message translates to:
  /// **'الإجابة الصحيحة مضيئة — انظر إليها جيداً وحاول أن تتذكرها! 💡'**
  String get companionAnswerRevealed;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
