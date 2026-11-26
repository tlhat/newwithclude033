// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Haneen Kids — Safe Learning Platform';

  @override
  String get freeForeverTagline =>
      'Free content plus subscription content — no ads';

  @override
  String get navStories => 'Stories';

  @override
  String get navAcademy => 'Academy';

  @override
  String get navGames => 'Brain Oasis';

  @override
  String get navAchievements => 'Achievements';

  @override
  String get navAccount => 'My Account';

  @override
  String get achievementsTitle => 'My Achievements';

  @override
  String greatJobChild(String name) {
    return 'Great job, $name!';
  }

  @override
  String get achievementsSubtitle =>
      'Every small step in learning and play builds a new skill.';

  @override
  String get starsEarnedLabel => 'Stars Earned';

  @override
  String get iqPointsLabel => 'IQ Points';

  @override
  String get completedLessonsLabel => 'Lessons Done';

  @override
  String get unlockedBadgesLabel => 'Badges Earned';

  @override
  String get unlockedBadgesHeading => 'Your Earned Badges';

  @override
  String get noBadgesYet =>
      'Start your first Academy lesson or play a Brain Oasis challenge to unlock your first badge.';

  @override
  String get goToAcademy => 'Go to Haneen Academy';

  @override
  String badgeUnlockedAt(String date) {
    return 'Unlocked: $date';
  }

  @override
  String get accountTitle => 'My Account';

  @override
  String ageGroupAndLevel(String age, String level) {
    return 'Age Group: $age • $level';
  }

  @override
  String get dailyUsageLabel => 'Daily Screen Time';

  @override
  String minutesProgress(int used, int limit) {
    return '$used / $limit min';
  }

  @override
  String get darkModeTitle => 'Dark Mode';

  @override
  String get darkModeSubtitle => 'Unified, comfortable look across all screens';

  @override
  String get switchChildTitle => 'Switch Child Profile';

  @override
  String registeredProfilesCount(int count) {
    return 'Registered profiles: $count';
  }

  @override
  String get uiLanguageTitle => 'Interface Language (العربية / English)';

  @override
  String get learningLanguageTitle => 'Child Learning Language';

  @override
  String get languageArabic => 'العربية';

  @override
  String get languageEnglish => 'English';

  @override
  String get parentalGateButton => 'Parental Hub & Settings (PIN Protected)';

  @override
  String get parentGateTitle => 'Parental Gate';

  @override
  String get parentGatePrompt =>
      'To enter the Parental Hub, please enter your 6-digit Parental PIN:';

  @override
  String get parentGateHint => 'Enter 6-digit PIN';

  @override
  String get parentGateError => 'Incorrect PIN. Please enter 6 valid digits.';

  @override
  String get cancelButton => 'Cancel';

  @override
  String get enterButton => 'Enter';

  @override
  String get retryButton => 'Retry';

  @override
  String get voiceLanguageTitle => 'Voice Assistant & Pronunciation Language';

  @override
  String get parentStudioTitle => 'Parental Studio';

  @override
  String get authPhoneLabel => 'Mobile Phone Number';

  @override
  String get authParentNameLabel => 'Parent Name';

  @override
  String get authChildNameLabel => 'Child Name';

  @override
  String get authChildAgeLabel => 'Child Age';

  @override
  String get authOtpLabel => 'Verification Code (OTP)';

  @override
  String get authSendOtpButton => 'Send Verification Code (OTP) 📲';

  @override
  String get authVerifyButton => 'Verify Code & Start Journey 🚀';

  @override
  String get authEditPhoneButton => 'Edit Phone Number';

  @override
  String get betaFeedbackTitle => 'Beta Feedback & Developer Notes';

  @override
  String get betaFeedbackSent => 'Sent';

  @override
  String get betaFeedbackPending => 'Pending';

  @override
  String get betaFeedbackFailed => 'Failed';

  @override
  String get tierBeginner => 'Preschool (2-3 yrs)';

  @override
  String get tierElementary => 'Beginner (3-4 yrs)';

  @override
  String get tierIntermediate => 'Intermediate (4-5 yrs)';

  @override
  String get tierAdvanced => 'Advanced (5-6 yrs)';

  @override
  String get deleteChildConfirmation =>
      'Are you sure you want to permanently delete this child profile?';

  @override
  String get confirmDelete => 'Confirm Delete';

  @override
  String get cancel => 'Cancel';

  @override
  String get companionStudioTitle => 'My Character Studio';

  @override
  String get companionGenderBoy => 'Boy';

  @override
  String get companionGenderGirl => 'Girl';

  @override
  String get companionCategoryGender => 'Gender';

  @override
  String get companionCategoryFace => 'Face';

  @override
  String get companionCategoryHair => 'Hair';

  @override
  String get companionCategoryOutfit => 'Outfit';

  @override
  String get companionCategoryBackground => 'Background';

  @override
  String get companionCategoryPose => 'Pose';

  @override
  String get companionSaveButton => 'Save My Character ✨';

  @override
  String get companionUnlockTitle => 'Unlock New Item';

  @override
  String companionUnlockPrompt(String itemName, int stars) {
    return 'Do you want to unlock \"$itemName\" for $stars ⭐?';
  }

  @override
  String get companionUnlockButton => 'Unlock Now';

  @override
  String get companionNotEnoughStars =>
      'Not enough stars! Earn more by learning and playing.';

  @override
  String get companionCustomizeButton => 'Customize My Character 🎨';

  @override
  String get companionShopDisabled =>
      'Character shop has been disabled by parent.';

  @override
  String companionGreeting(String childName) {
    return 'Hi $childName! 👋 Shall we learn something new today?';
  }

  @override
  String get companionEncourageCorrect => 'Well done! Amazing answer, hero! 🌟';

  @override
  String get companionEncourageHint =>
      'Don\'t worry, try again! You\'re very close 💪';

  @override
  String get companionExplorePrompt =>
      'Let\'s discover a new adventure together!';

  @override
  String get companionHintButton => 'Give me a hint';

  @override
  String companionHintTier1(String targetWord) {
    return 'Look at the pictures and listen again — which one matches \"$targetWord\"?';
  }

  @override
  String companionHintTier2(String targetWord) {
    return 'Strategy: say \"$targetWord\" slowly out loud, then look for the picture whose first sound is the same.';
  }

  @override
  String companionHintTier3(String exampleWord, String emoji) {
    return 'Worked example: to find the word \"$exampleWord\" $emoji we say it slowly and pick the matching picture. Now try the same trick with your question!';
  }

  @override
  String companionHintTier3Fallback(String targetWord) {
    return 'Worked example: to find a word like \"$targetWord\", say it slowly out loud, listen to its first sound, then find the picture that matches. Try the same trick now!';
  }

  @override
  String get companionRevealAnswerButton => 'Show me the answer';

  @override
  String get companionAnswerRevealed =>
      'The correct answer is highlighted — look carefully and try to remember it! 💡';
}
