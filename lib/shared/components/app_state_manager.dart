import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:haneen_kids_vod/haneen_kids_exports.dart';

class AppStateManager extends ChangeNotifier {
  final SharedPreferences _prefs;
  late final SupabaseEnvConfig supabaseEnvConfig;
  late final OfflineSyncQueueService syncQueueService;
  late final SupabaseRemoteDataSource supabaseRemoteDataSource;
  late final AccountRepository accountRepository;
  late final ChildProfileRepository childProfileRepository;
  late final VideoRepository videoRepository;
  late final SubscriptionRepository subscriptionRepository;
  final LocaleController localeController = LocaleController();
  final AppEnvironmentConfig environmentConfig =
      AppEnvironmentConfig.fromDartDefine();
  final FeatureFlags featureFlags = FeatureFlags();
  final List<Map<String, String>> betaFeedbackLog = [];

  bool isInitialized = false;
  bool onboardingCompleted = false;
  bool isDarkMode = true;
  bool hasSelectedChildInSession = false;

  final Map<String, ParentAccount> _accounts = {};
  ParentAccount? currentAccount;

  List<VideoModel> videos = [];
  String remoteFeedUrl = kDefaultRemoteFeedUrl;
  String authApiUrl = '';
  String emailWebhookUrl = '';
  String paymentVerifyApiUrl = '';
  String merchantSecretKey = '';
  String remoteMonitorApiUrl = '';
  bool isSyncingVideos = false;
  String? lastSyncMessage;

  String currentAssistantBannerMessage =
      'مرحباً يا بطل! أنا رفيق حنين، اضغط عليّ لأقرأ لك أو أقترح عليك قصة ممتعة!';
  VideoModel? suggestedVideoForChild;

  Timer? _screenTimeTimer;
  bool _isDisposed = false;
  int _activeSessionSeconds = 0;
  final Set<String> _inFlightRewardLocks = {};

  /// Fires every time the child earns stars. StarRewardHost plays the celebration.
  final ValueNotifier<StarRewardEvent?> starRewards =
      ValueNotifier<StarRewardEvent?>(null);
  int _rewardSeq = 0;

  void announceStarReward(int stars, String title) {
    if (stars <= 0) return;
    starRewards.value = StarRewardEvent(stars, title, ++_rewardSeq);
  }
  // Phase 5: duplicate-greeting guard — the greeting is presented at most
  // once per child selection session (rebuilds/navigation never re-trigger).
  String? _companionGreetingPresentedForChildId;

  /// Phase 5: builds the contextual greeting for the active child once per
  /// session-entry; text is always safe to display, speech only when guards
  /// allow. Returns null when no active child.
  CompanionGreeting? buildCompanionGreetingForActiveChild({
    String locale = 'ar',
    bool lessonActive = false,
  }) {
    final child = currentAccount?.activeChild;
    if (child == null) return null;
    final snapshot = CompanionMemoryEngine.loadFrom(_prefs, child.id) ??
        CompanionMemoryEngine.syncFromChild(child);
    return CompanionMemoryEngine.buildGreeting(
      snapshot,
      locale: locale,
      isMuted: CalmVoiceService.instance.isAssistantMuted,
      ttsEnabled: currentAccount?.voiceAssistantEnabled ?? true,
      // Real parental-lock state (fails safe: locked => no speech).
      parentalLocked: isParentalControlActive,
      isSpeaking: CalmVoiceService.instance.isSpeaking,
      lessonActive: lessonActive,
    );
  }

  /// Phase 5: presents the companion greeting exactly once per child
  /// selection session — displays it via the assistant banner and speaks it
  /// only when guards allow. Repeated calls (rebuilds, navigation, lifecycle
  /// events) return null without re-presenting or re-persisting.
  CompanionGreeting? presentCompanionGreetingOnce({
    String? locale,
    bool lessonActive = false,
  }) {
    final child = currentAccount?.activeChild;
    if (child == null) return null;
    if (_companionGreetingPresentedForChildId == child.id) return null;
    final CompanionGreeting? greeting = buildCompanionGreetingForActiveChild(
      locale: locale ?? localeController.uiLanguageCode,
      lessonActive: lessonActive,
    );
    if (greeting == null) return null;
    _companionGreetingPresentedForChildId = child.id;
    currentAssistantBannerMessage = greeting.text;
    if (greeting.speakAllowed && !CalmVoiceService.instance.isSpeaking) {
      CalmVoiceService.instance.speakCalmly(greeting.text);
    }
    // Persist lastGreetingId only now, after successful presentation.
    unawaited(markCompanionGreetingPresented(greeting));
    notifyListeners();
    return greeting;
  }

  /// Phase 5: forgets the presented-greeting guard (child switch / logout /
  /// returning to child selection) so isolation holds and the next child's
  /// memory drives a fresh greeting.
  void resetCompanionGreetingPresentation() {
    _companionGreetingPresentedForChildId = null;
  }

  /// Phase 5: persists lastGreetingId only after the greeting was actually
  /// presented (call from the UI once rendered / spoken).
  Future<void> markCompanionGreetingPresented(CompanionGreeting greeting) async {
    final child = currentAccount?.activeChild;
    if (child == null) return;
    final snapshot = CompanionMemoryEngine.loadFrom(_prefs, child.id) ??
        CompanionMemoryEngine.syncFromChild(child);
    await CompanionMemoryEngine.saveTo(
      _prefs,
      CompanionMemoryEngine.markGreetingPresented(snapshot, greeting.id),
    );
  }

  /// Phase 5: suggested next activity — valid unfinished session first
  /// (never claimed as completed), else the Phase 4 next lesson.
  String? suggestNextActivityForActiveChild() {
    final child = currentAccount?.activeChild;
    if (child == null) return null;
    final snapshot = CompanionMemoryEngine.loadFrom(_prefs, child.id) ??
        CompanionMemoryEngine.syncFromChild(child);
    return CompanionMemoryEngine.suggestNextActivityId(snapshot, child);
  }

  AppStateManager(this._prefs) {
    supabaseEnvConfig = SupabaseEnvConfig(
      supabaseUrl: _prefs.getString('supabase_cloud_url'),
      supabaseAnonKey: _prefs.getString('supabase_cloud_anon_key'),
    );
    syncQueueService = OfflineSyncQueueService(
      _prefs,
      prefix: environmentConfig.storageKeyPrefix,
    );
    supabaseRemoteDataSource = SupabaseRemoteDataSource(supabaseEnvConfig);
    accountRepository = AccountRepository(
      LocalAccountDataSource(_prefs, prefix: environmentConfig.storageKeyPrefix),
      remoteDataSource: supabaseRemoteDataSource,
      syncQueue: syncQueueService,
    );
    childProfileRepository = ChildProfileRepository(
      remoteDataSource: supabaseRemoteDataSource,
      syncQueue: syncQueueService,
    );
    videoRepository = VideoRepository(
      LocalVideoDataSource(_prefs),
      remoteDataSource: supabaseRemoteDataSource,
      syncQueue: syncQueueService,
    );
    subscriptionRepository = SubscriptionRepository(
      remoteDataSource: supabaseRemoteDataSource,
    );
  }

  Future<void> configureSupabaseCloud({
    required String url,
    required String anonKey,
  }) async {
    supabaseEnvConfig.supabaseUrl = url.trim();
    supabaseEnvConfig.supabaseAnonKey = anonKey.trim();
    await _prefs.setString('supabase_cloud_url', supabaseEnvConfig.supabaseUrl);
    await _prefs.setString(
        'supabase_cloud_anon_key', supabaseEnvConfig.supabaseAnonKey);
    _syncActiveChildPoliciesToRuntime();
    notifyListeners();
  }

  Future<SupabaseCloudSyncResult> syncPendingChangesWithSupabase() async {
    final account = currentAccount;
    if (account == null) {
      return const SupabaseCloudSyncResult(
        success: false,
        message: 'لا يوجد حساب مسجل حالياً للمزامنة.',
      );
    }
    final List<SyncMutationRecord> pendingForParent = syncQueueService
        .pendingQueue
        .where((m) =>
            m.parentEmail.trim().toLowerCase() ==
            account.emailOrPhone.trim().toLowerCase())
        .toList();
    if (pendingForParent.isEmpty) {
      return const SupabaseCloudSyncResult(
        success: true,
        syncedMutationsCount: 0,
        message: 'جميع البيانات متزامنة ومحدثة.',
      );
    }
    final SupabaseCloudSyncResult res =
        await supabaseRemoteDataSource.flushMutationBatch(
      sessionAccessToken: account.sessionAccessToken,
      authenticatedParentEmail: account.emailOrPhone,
      batch: pendingForParent,
    );
    if (res.success && res.appliedKeys.isNotEmpty) {
      await syncQueueService.markMutationsApplied(res.appliedKeys);
      notifyListeners();
    }
    return res;
  }

  Future<bool> pullAndMergeRemoteChildrenFromSupabase() async {
    final account = currentAccount;
    if (account == null) return false;
    final List<ChildProfile>? remoteChildren =
        await supabaseRemoteDataSource.fetchRemoteChildProfiles(
      sessionAccessToken: account.sessionAccessToken,
      expectedParentEmail: account.emailOrPhone,
    );
    if (remoteChildren == null) return false;

    for (final remoteChild in remoteChildren) {
      final int localIdx =
          account.children.indexWhere((c) => c.id == remoteChild.id);
      if (localIdx == -1) {
        account.children.add(remoteChild);
      } else {
        account.children[localIdx] = childProfileRepository.resolveConflict(
          local: account.children[localIdx],
          remote: remoteChild,
        );
      }
    }
    _syncLikedStateForActiveChild();
    await _saveAccounts();
    notifyListeners();
    return true;
  }

  void _syncActiveChildPoliciesToRuntime() {
    childProfileRepository
        .syncActiveChildPoliciesToRuntime(currentAccount?.activeChild);
    final String proxyUrl = supabaseEnvConfig.isConfigured
        ? supabaseEnvConfig
            .edgeFunctionUri('elevenlabs-tts-proxy')
            .toString()
        : '';
    CalmVoiceService.instance.configureBackendProxy(
      proxyUrl: proxyUrl,
      bearerToken: currentAccount?.sessionAccessToken ?? '',
    );
  }

  Future<void> initialize() async {
    CalmVoiceService.instance.attachSharedPreferences(_prefs);
    CalmVoiceService.instance.childNameProvider = () =>
        (currentAccount != null && hasSelectedChildInSession)
            ? currentAccount!.activeChild.name
            : null;
    await CalmVoiceService.instance.init();
    onboardingCompleted = _prefs.getBool('onboarding_completed') ?? false;
    isDarkMode = _prefs.getBool('app_dark_mode') ?? true;
    localeController.loadFromPrefs(_prefs);
    featureFlags.loadFromPrefs(_prefs);
    remoteFeedUrl =
        _prefs.getString('remote_feed_url') ?? kDefaultRemoteFeedUrl;
    authApiUrl = _prefs.getString('auth_api_url') ?? '';
    emailWebhookUrl = _prefs.getString('email_webhook_url') ?? '';
    paymentVerifyApiUrl = _prefs.getString('payment_verify_api_url') ?? '';
    merchantSecretKey = await LocalCredentialSecurityService.readSecureValue(
            'merchant_secret_key_secure') ??
        _prefs.getString('merchant_secret_key') ??
        '';
    if (_prefs.containsKey('merchant_secret_key')) {
      await _prefs.remove('merchant_secret_key');
    }
    remoteMonitorApiUrl = _prefs.getString('remote_monitor_api_url') ?? '';

    final loadedAccounts = accountRepository.loadAllAccounts();
    _accounts.addAll(loadedAccounts);

    // Demo account is loaded in test environment, Dev, and Staging, never in live Production
    if ((CalmVoiceService.isTestEnvironment ||
            CalmVoiceService.isRunningInUnitTest ||
            !environmentConfig.isProduction) &&
        !_accounts.containsKey('parent@haneenkids.com')) {
      final demoAccount = accountRepository.buildDefaultDemoAccount();
      _accounts['parent@haneenkids.com'] = demoAccount;
      await _saveAccounts();
    }

    final String? loggedInUser = accountRepository.dataSource.getLoggedInUserKey();
    if (loggedInUser != null && _accounts.containsKey(loggedInUser)) {
      currentAccount = _accounts[loggedInUser];
      hasSelectedChildInSession =
          _prefs.getBool(accountRepository.dataSource.hasSelectedChildKey) ??
          _prefs.getBool('has_selected_child_in_session') ??
          true;
    }

    final String? savedVideosJson = _prefs.getString('saved_videos_v2');
    if (savedVideosJson != null && savedVideosJson.isNotEmpty) {
      try {
        final List<dynamic> list = jsonDecode(savedVideosJson);
        videos = list
            .map((item) =>
                VideoModel.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
      } catch (_) {
        videos = getDefaultVideos();
      }
    } else {
      videos = getDefaultVideos();
    }

    _syncLikedStateForActiveChild();
    CalmVoiceService.instance.setAssistantMuted(
        !(currentAccount?.voiceAssistantEnabled ?? true));
    _refreshSmartVoiceAssistantSuggestion(speakAloud: false);
    _startScreenTimeTracker();
    _startRemoteLockWatcher();
    applyDueReviews();
    isInitialized = true;
    notifyListeners();

    if (remoteFeedUrl.trim().isNotEmpty &&
        !CalmVoiceService.isRunningInUnitTest) {
      syncVideosFromRemoteUrl(remoteFeedUrl);
    }
  }

  bool isParentalControlActive = false;
  bool isAppInBackground = false;

  void setParentalControlActive(bool active) {
    if (isParentalControlActive != active) {
      isParentalControlActive = active;
      notifyListeners();
    }
  }

  void setAppInBackground(bool inBg) {
    if (isAppInBackground != inBg) {
      isAppInBackground = inBg;
      notifyListeners();
    }
  }

  void _startScreenTimeTracker() {
    _screenTimeTimer?.cancel();
    _screenTimeTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (currentAccount != null &&
          hasSelectedChildInSession &&
          !isParentalControlActive &&
          !isAppInBackground) {
        final child = currentAccount!.activeChild;
        if (child.dailyTimeLimit <= 0 ||
            child.usedMinutesToday < child.dailyTimeLimit) {
          child.usedMinutesToday++;
          _activeSessionSeconds += 60;
          // 0 = no limit set by the parent: count the time, never warn or stop.
          final int remaining = child.dailyTimeLimit <= 0
              ? 100000
              : child.dailyTimeLimit - child.usedMinutesToday;
          if (_activeSessionSeconds > 0 &&
              _activeSessionSeconds % (20 * 60) == 0 &&
              remaining > 1 &&
              currentAccount!.voiceAssistantEnabled) {
            final String brk =
                'يا ${child.name}، نرتاح شوية؟ بُصّ بعيد بعينيك لمدة عشر ثواني ثم كمّل مغامرتك.';
            currentAssistantBannerMessage = brk;
            HintVoiceService.instance.play('hint_eye_break');
          }
          if (remaining == 5 && currentAccount!.voiceAssistantEnabled) {
            final msg =
                'تنبيه لطيف يا ${child.name}، بقيت خمس دقائق فقط في وقت المشاهدة اليومي، استعد لنشاط البطل!';
            currentAssistantBannerMessage = msg;
            CalmVoiceService.instance.speakCalmly(msg);
          } else if (remaining <= 0) {
            sendParentEmailAlert(
              subject:
                  '🌙 إشعار حنين كيدز: انتهاء الحصة اليومية للطفل ${child.name}',
              bodyMessage:
                  'أكمل الطفل ${child.name} حصته اليومية المحددة (${child.dailyTimeLimit} دقيقة) وتم إسدال ستارة النوم الهادئة تلقائياً.',
              customSuggestion: generateSmartParentRecommendation(),
            );
          }
          _saveAccounts();
          notifyListeners();
        }
      }
    });
  }

  int get activeSessionMinutes => (_activeSessionSeconds / 60).floor();

  bool get isDailyLimitReached {
    final child = currentAccount?.activeChild;
    if (child == null) return false;
    return child.dailyTimeLimit > 0 &&
        child.usedMinutesToday >= child.dailyTimeLimit;
  }

  /// App is 100% Free forever: paywalls and trial expirations are permanently disabled in UI.
  static const bool isAppCompletelyFreeForever = true;

  static const String kGooglePlayStoreUrl =
      'https://play.google.com/store/apps/details?id=com.haneenkids.app';

  bool hasOpenedGooglePlayRating = false;

  bool get isSubscriptionExpired => false;

  Future<String> openGooglePlayStoreRating() async {
    hasOpenedGooglePlayRating = true;
    notifyListeners();
    return kGooglePlayStoreUrl;
  }

  String generateSmartParentRecommendation() {
    final account = currentAccount;
    if (account == null) {
      return '💡 خصص ١٥ دقيقة يومياً لمشاركة طفلك قصة من قسم الفصاحة والنطق.';
    }
    final child = account.activeChild;
    final int hour = DateTime.now().hour;

    if (hour >= 18 && !account.warmEveningFilter) {
      return '🌙 اقتراح المساء: نلاحظ أن وقت المشاهدة مسائي؛ ننصح بتفعيل «فلتر المساء الدافئ» واختيار قسم «قصص النوم» لتهدئة الطفل قبل النوم.';
    }
    if (child.correctPronunciationsCount < 2) {
      return '🗣️ اقتراح تطوير النطق: شجّع ${child.name} على الضغط على زر «ردد معي» في قصص «فصاحة ونطق» ليستمع للمصحح الصوتي الهادئ ويطور مخارج الحروف.';
    }
    if (child.completedActivities.length < 2) {
      return '🎯 اقتراح التوازن الحركي: بعد انتهاء القصة القادمة، افتح نافذة «نشاط البطل الواقعي» مع ${child.name} لتنفيذ مهمة حركية خارج الشاشة.';
    }
    return '🌟 أداء رائع! ${child.name} يتفاعل بانتظام؛ نقترح تجربة قصص «لماذا وكيف؟» لتنمية الفضول العلمي والتفكير الهادئ.';
  }

  void _refreshSmartVoiceAssistantSuggestion({bool speakAloud = false}) {
    if (videos.isEmpty) return;
    final child = currentAccount?.activeChild;
    final String childName = child?.name ?? 'يا بطل';
    final int hour = DateTime.now().hour;

    VideoModel candidate = videos.first;
    String greeting;

    if (hour >= 19) {
      candidate = videos.firstWhere(
        (v) => v.category == 'bedtime',
        orElse: () => videos.first,
      );
      greeting =
          'مساء الهدوء يا $childName! أنا رفيقك حنين، أقترح عليك مشاهدة قصة «${candidate.title}» للاستعداد لنوم هادئ وجميل.';
    } else if ((child?.correctPronunciationsCount ?? 0) < 2) {
      candidate = videos.firstWhere(
        (v) => v.category == 'arabic',
        orElse: () => videos.first,
      );
      greeting =
          'أهلاً يا $childName! هيا نشاهد قصة «${candidate.title}» ونتدرب معاً بصوتي الهادئ على نطق الجملة الفصيحة!';
    } else {
      final randomIndex = Random().nextInt(videos.length);
      candidate = videos[randomIndex];
      greeting =
          'مرحباً يا $childName! لدي اقتراح رائع لك اليوم: قصة «${candidate.title}»، وبعدها سنلعب معاً نشاط البطل الواقعي!';
    }

    suggestedVideoForChild = candidate;
    currentAssistantBannerMessage = greeting;
    if (speakAloud && (currentAccount?.voiceAssistantEnabled ?? true)) {
      CalmVoiceService.instance.speakCalmly(greeting);
    }
    notifyListeners();
  }

  void triggerVoiceAssistantGreetingAndSuggestion() {
    _refreshSmartVoiceAssistantSuggestion(speakAloud: true);
  }

  Future<void> sendParentEmailAlert({
    required String subject,
    required String bodyMessage,
    String? customSuggestion,
  }) async {
    final account = currentAccount;
    if (account == null) return;
    final String suggestion =
        customSuggestion ?? generateSmartParentRecommendation();

    bool delivered = false;
    ParentEmailAlertItem build() => ParentEmailAlertItem(
          id: 'mail_${DateTime.now().millisecondsSinceEpoch}',
          recipientEmail: account.emailOrPhone,
          subject: subject,
          bodyMessage: bodyMessage,
          smartImprovementSuggestion: suggestion,
          sentAt: DateTime.now(),
          deliveredToCloud: delivered,
        );

    // Delivered is true only when the webhook really answered 2xx. With no
    // webhook set (the normal case) the alert stays in the local log only.
    if (emailWebhookUrl.trim().isNotEmpty &&
        AppNetworkPolicyGuard.canPerformOutboundNetworkRequest()) {
      try {
        final http.Response r = await http
            .post(
              Uri.parse(emailWebhookUrl.trim()),
              headers: {'Content-Type': 'application/json; charset=utf-8'},
              body: jsonEncode(build().toJson()),
            )
            .timeout(const Duration(seconds: 8));
        delivered = r.statusCode >= 200 && r.statusCode < 300;
      } catch (_) {}
    }
    account.emailAlertsLog.insert(0, build());

    await _saveAccounts();
    notifyListeners();
  }

  Future<void> setUiLanguage(String languageCode) async {
    await localeController.setUiLanguage(languageCode, prefs: _prefs);
    notifyListeners();
  }

  Future<void> setLearningLanguage(String languageCode) async {
    await localeController.setLearningLanguage(languageCode, prefs: _prefs);
    notifyListeners();
  }

  Future<void> setFeatureFlag(String key, bool value) async {
    await featureFlags.setFlag(key, value, prefs: _prefs);
    notifyListeners();
  }

  Future<Map<String, String>> submitParentBetaFeedback({
    required String category,
    required String description,
  }) async {
    final String feedbackId = 'fb_${DateTime.now().millisecondsSinceEpoch}';
    final Map<String, String> entry = {
      'id': feedbackId,
      'category': category.trim(),
      'description': description.trim(),
      'environment': environmentConfig.environmentBadgeLabel,
      'appVersion': environmentConfig.buildVersion,
      'uiLanguage': localeController.uiLanguageCode,
      'learningLanguage': localeController.learningLanguageCode,
      'devicePlatform': 'Mobile / Flutter',
      'status': 'Pending', // 'Pending' | 'Sent' | 'Failed'
      'timestamp': DateTime.now().toIso8601String(),
    };
    betaFeedbackLog.insert(0, entry);
    await _persistBetaFeedbackLog();
    notifyListeners();

    // Transmit to Supabase Edge Function asynchronously
    await _sendBetaFeedbackToServer(entry);
    return entry;
  }

  Future<void> retrySendingBetaFeedback(String feedbackId) async {
    final int idx = betaFeedbackLog.indexWhere((e) => e['id'] == feedbackId);
    if (idx == -1) return;
    betaFeedbackLog[idx]['status'] = 'Pending';
    await _persistBetaFeedbackLog();
    notifyListeners();
    await _sendBetaFeedbackToServer(betaFeedbackLog[idx]);
  }

  Future<void> _sendBetaFeedbackToServer(Map<String, String> entry) async {
    if (!supabaseRemoteDataSource.canConnectToSupabase) {
      entry['status'] = 'Pending';
      await _persistBetaFeedbackLog();
      notifyListeners();
      return;
    }

    try {
      final http.Client client = SupabaseRemoteDataSource.httpClientOverride ?? http.Client();
      final bool shouldClose = SupabaseRemoteDataSource.httpClientOverride == null;
      try {
        final res = await client.post(
          supabaseEnvConfig.edgeFunctionUri('submit-beta-feedback'),
          headers: {
            'Content-Type': 'application/json; charset=utf-8',
            if (supabaseEnvConfig.supabaseAnonKey.isNotEmpty)
              'apikey': supabaseEnvConfig.supabaseAnonKey,
          },
          body: jsonEncode({
            'category': entry['category'],
            'description': entry['description'],
            'appVersion': entry['appVersion'],
            'environment': entry['environment'],
            'uiLanguage': entry['uiLanguage'],
            'devicePlatform': entry['devicePlatform'],
          }),
        ).timeout(const Duration(seconds: 8));

        if (res.statusCode == 200 || res.statusCode == 201) {
          entry['status'] = 'Sent';
        } else {
          entry['status'] = 'Failed';
        }
      } catch (_) {
        entry['status'] = 'Failed';
      } finally {
        if (shouldClose) client.close();
      }
    } catch (_) {
      entry['status'] = 'Failed';
    }

    await _persistBetaFeedbackLog();
    notifyListeners();
  }

  Future<void> _persistBetaFeedbackLog() async {
    await _prefs.setString(
      '${environmentConfig.storageKeyPrefix}beta_feedback_log',
      jsonEncode(betaFeedbackLog),
    );
  }

  Future<void> toggleDarkMode([bool? enabled]) async {
    isDarkMode = enabled ?? !isDarkMode;
    await _prefs.setBool('app_dark_mode', isDarkMode);
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    onboardingCompleted = true;
    await _prefs.setBool('onboarding_completed', true);
    notifyListeners();
  }

  /// Completes the one-time initial installation setup wizard:
  /// 1. Child Name -> 2. Child Age -> 3. Daily Usage Limit -> 4. 6-Digit Parent Passcode.
  /// Persists the setup permanently so it NEVER reappears on subsequent app launches.
  Future<String?> completeOneTimeInitialSetup({
    required String childName,
    required String childAge,
    required int dailyTimeLimit,
    required String parentPasscode6Digits,
    String gender = 'boy',
  }) async {
    final String cleanName = childName.trim();
    final String cleanAge = childAge.trim();
    final String cleanPasscode =
        parentPasscode6Digits.trim().replaceAll(RegExp(r'\s+'), '');

    if (cleanName.isEmpty) {
      return 'يرجى إدخال اسم الطفل للمتابعة.';
    }
    if (cleanAge.isEmpty) {
      return 'يرجى اختيار سن الطفل للمتابعة.';
    }
    if (!ParentAccount.isValidParentalPinFormat(cleanPasscode)) {
      return 'يرجى إنشاء رمز سري للوالدين مكوّن من ٦ أرقام بالضبط.';
    }

    final int clampedLimit = dailyTimeLimit.clamp(5, 120);
    const String familyKey = 'family@haneenkids.local';

    final ChildProfile firstChild = ChildProfile(
      id: 'child_${DateTime.now().millisecondsSinceEpoch}',
      name: cleanName,
      age: cleanAge,
      dailyTimeLimit: clampedLimit,
      chosenAvatar: '🦁',
      gender: gender,
    );

    final DateTime now = DateTime.now();
    final ParentAccount familyAccount = ParentAccount(
      fullName: 'ولي أمر $cleanName',
      emailOrPhone: familyKey,
      password: 'free_forever_haneen_kids',
      parentalPin: cleanPasscode,
      authProvider: 'local_setup',
      warmEveningFilter: false,
      subscriptionPlanId: 'free_forever',
      trialStartDate: now,
      subscriptionExpiryDate: now.add(const Duration(days: 36500)),
      children: [firstChild],
      activeChildId: firstChild.id,
    );

    _accounts[familyKey] = familyAccount;
    currentAccount = familyAccount;
    onboardingCompleted = true;
    pinUnlockedThisSession = true;
    hasSelectedChildInSession = true;

    await _saveAccounts();
    await _prefs.setBool('onboarding_completed', true);
    await accountRepository.dataSource.setLoggedInUserKey(familyKey);
    await _prefs.setString('current_user_key', familyKey);
    await _prefs.setBool('has_selected_child_in_session', true);
    _syncLikedStateForActiveChild();
    _refreshSmartVoiceAssistantSuggestion(speakAloud: false);
    notifyListeners();
    unawaited(backupToGoogleQuietly());
    return null;
  }

  // ------------------------------------------------------------ Google backup

  /// Email of the Google account used for the backup (null = not linked).
  String? get linkedGoogleEmail => _prefs.getString('linked_google_email');

  /// Everything needed to rebuild the family on a new phone. The demo account
  /// is never included.
  String exportBackupJson() {
    final Map<String, dynamic> accounts = {};
    _accounts.forEach((key, acc) {
      if (key == 'parent@haneenkids.com') return;
      accounts[key] = acc.toJson();
    });
    return jsonEncode({
      'version': 1,
      'savedAt': DateTime.now().toIso8601String(),
      'currentUserKey': currentAccount == null
          ? null
          : _accounts.entries
              .firstWhere((e) => identical(e.value, currentAccount),
                  orElse: () => MapEntry('', currentAccount!))
              .key,
      'accounts': accounts,
    });
  }

  /// Returns null on success, otherwise a message in Arabic.
  Future<String?> restoreFromBackupJson(String text) async {
    try {
      final Map<String, dynamic> data =
          jsonDecode(text) as Map<String, dynamic>;
      final Map<String, dynamic> raw =
          Map<String, dynamic>.from(data['accounts'] as Map? ?? const {});
      if (raw.isEmpty) return 'النسخة الاحتياطية فاضية.';
      final Map<String, ParentAccount> restored = {};
      raw.forEach((k, v) {
        restored[k] = ParentAccount.fromJson(Map<String, dynamic>.from(v as Map));
      });
      String key = (data['currentUserKey'] ?? '').toString();
      if (!restored.containsKey(key)) key = restored.keys.first;
      _accounts.addAll(restored);
      currentAccount = _accounts[key];
      onboardingCompleted = true;
      hasSelectedChildInSession = true;
      await _saveAccounts();
      await _prefs.setBool('onboarding_completed', true);
      await accountRepository.dataSource.setLoggedInUserKey(key);
      await _prefs.setString('current_user_key', key);
      await _prefs.setBool('has_selected_child_in_session', true);
      _syncLikedStateForActiveChild();
      notifyListeners();
      return null;
    } catch (_) {
      return 'ملف النسخة الاحتياطية تالف أو من إصدار غير مدعوم.';
    }
  }

  /// "عندي حساب بالفعل": sign in with Google and restore the saved family.
  /// Returns null on success, otherwise a message to show.
  Future<String?> signInWithGoogleAndRestore() async {
    if (AppNetworkPolicyGuard.isOfflineOnlyModeActive) {
      return 'وضع بدون إنترنت شغال. أوقفه من إعدادات الوالدين عشان تدخل بجوجل.';
    }
    try {
      final GoogleIdentity? who = await GoogleAccountService.instance.signIn();
      if (who == null) return 'اتلغى الدخول بجوجل.';
      final String? text =
          await GoogleAccountService.instance.downloadBackup(who);
      if (text == null) {
        await GoogleAccountService.instance.signOut();
        return 'مفيش حساب محفوظ على ${who.email}. ابدأ حساب جديد بزر «يلا نبدأ».';
      }
      final String? err = await restoreFromBackupJson(text);
      if (err == null) await _prefs.setString('linked_google_email', who.email);
      return err;
    } on GoogleAccountException catch (e) {
      return e.messageAr;
    }
  }

  /// Saves the family to the parent's Google Drive. Null = success.
  Future<String?> backupToGoogleNow() async {
    if (AppNetworkPolicyGuard.isOfflineOnlyModeActive) {
      return 'وضع بدون إنترنت شغال. أوقفه الأول.';
    }
    try {
      final GoogleIdentity? who = await GoogleAccountService.instance.signIn();
      if (who == null) return 'اتلغى الدخول بجوجل.';
      await GoogleAccountService.instance
          .uploadBackup(who, exportBackupJson());
      await _prefs.setString('linked_google_email', who.email);
      notifyListeners();
      return null;
    } on GoogleAccountException catch (e) {
      return e.messageAr;
    }
  }

  Future<void> unlinkGoogleBackup() async {
    await GoogleAccountService.instance.signOut();
    await _prefs.remove('linked_google_email');
    notifyListeners();
  }

  // ------------------------------------------------------- launch gates

  /// True after the parent typed the 6-digit PIN in this app launch.
  bool pinUnlockedThisSession = false;

  /// The Google screen is done once a Google account is linked on this
  /// phone. Google sign-in is mandatory (needs internet once per phone).
  bool get googleGateDone => linkedGoogleEmail != null;

  /// Opens the PIN screen's lock. Returns null when the PIN is right, or a
  /// message in Arabic.
  String? unlockWithPin(String pin) {
    final ParentAccount? acc = currentAccount;
    if (acc == null) return 'مفيش حساب. ابدأ من الأول.';
    if (acc.isPinLockedOut) {
      return 'جربت كتير غلط. استنى شوية وجرّب تاني.';
    }
    if (!acc.verifyParentalPin(pin.trim())) {
      return acc.isPinLockedOut
          ? 'جربت كتير غلط. استنى شوية وجرّب تاني.'
          : 'الرمز غلط، جرّب تاني.';
    }
    pinUnlockedThisSession = true;
    notifyListeners();
    return null;
  }

  /// First screen: sign in with Google.
  /// - This phone already has a family: link the Google account and back the
  ///   family up (the phone is the source of truth).
  /// - No family here: restore it from Google if a backup exists, otherwise
  ///   the router continues to the first-time setup.
  /// Returns null on success, otherwise a message in Arabic.
  Future<String?> googleGateSignIn() async {
    if (AppNetworkPolicyGuard.isOfflineOnlyModeActive) {
      return 'وضع بدون إنترنت شغال. أوقفه وجرّب تاني.';
    }
    try {
      final GoogleIdentity? who = await GoogleAccountService.instance.signIn();
      if (who == null) return 'اتلغى الدخول بجوجل.';
      final bool hasLocalFamily = onboardingCompleted && currentAccount != null;
      if (hasLocalFamily) {
        await GoogleAccountService.instance
            .uploadBackup(who, exportBackupJson());
      } else {
        final String? text =
            await GoogleAccountService.instance.downloadBackup(who);
        if (text != null) {
          final String? err = await restoreFromBackupJson(text);
          if (err != null) return err;
        }
      }
      await _prefs.setString('linked_google_email', who.email);
      notifyListeners();
      return null;
    } on GoogleAccountException catch (e) {
      return e.messageAr;
    }
  }

  /// Saves the family to Google without any popup (only if already linked).
  Future<void> backupToGoogleQuietly() async {
    if (linkedGoogleEmail == null ||
        AppNetworkPolicyGuard.isOfflineOnlyModeActive) {
      return;
    }
    try {
      final GoogleIdentity? who =
          await GoogleAccountService.instance.signInSilently();
      if (who == null) return;
      await GoogleAccountService.instance.uploadBackup(who, exportBackupJson());
    } catch (_) {}
  }

  Future<void> reopenOnboardingIntro() async {
    onboardingCompleted = false;
    await _prefs.setBool('onboarding_completed', false);
    notifyListeners();
  }

  Future<void> _saveAccounts() async {
    await accountRepository.persistAllAccounts(_accounts);
  }

  Future<void> _saveVideos() async {
    await videoRepository.saveVideos(videos);
  }

  void _syncLikedStateForActiveChild() {
    final child = currentAccount?.activeChild;
    if (child == null) return;
    for (final video in videos) {
      video.isLiked = child.likedVideoIds.contains(video.id);
    }
    _syncActiveChildPoliciesToRuntime();
  }

  Future<String?> login(String emailOrPhone, String password) async {
    final String rawInput = emailOrPhone.trim();
    final String key = AuthSessionService.isPhoneNumberIdentifier(rawInput)
        ? (AuthSessionService.validateAndNormalizePhoneNumber(rawInput) ?? rawInput.toLowerCase())
        : rawInput.toLowerCase();
    if (key.isEmpty || password.isEmpty) {
      return 'يرجى إدخال البريد الإلكتروني أو رقم الهاتف وكلمة المرور';
    }

    await LocalCredentialSecurityService.hydrateLockoutVaultFromSecureStorage(
        key);

    if (authApiUrl.trim().isNotEmpty &&
        AppNetworkPolicyGuard.canPerformOutboundNetworkRequest()) {
      final http.Client client =
          GoogleOAuthVerificationService.httpClientOverride ?? http.Client();
      final bool shouldClose =
          GoogleOAuthVerificationService.httpClientOverride == null;
      try {
        final response = await client
            .post(
              Uri.parse('${authApiUrl.trim()}/login'),
              headers: {'Content-Type': 'application/json; charset=utf-8'},
              body: jsonEncode({'emailOrPhone': key, 'password': password}),
            )
            .timeout(const Duration(seconds: 8));
        if (response.statusCode == 429 || response.statusCode == 423) {
          int lockSecs = 120;
          try {
            final dynamic errJson = jsonDecode(utf8.decode(response.bodyBytes));
            if (errJson is Map && errJson['lockoutRemainingSeconds'] != null) {
              lockSecs =
                  int.tryParse(errJson['lockoutRemainingSeconds'].toString()) ??
                      120;
            }
          } catch (_) {}
          final existingAcc = _accounts[key];
          if (existingAcc != null) {
            existingAcc.applyServerLockout(Duration(seconds: lockSecs));
            await _saveAccounts();
          } else {
            LocalCredentialSecurityService.persistLockoutToKeystoreVault(
              emailOrPhone: key,
              failedPinAttempts: 5,
              pinLockoutUntil: DateTime.now().add(Duration(seconds: lockSecs)),
              failedPasswordAttempts: 5,
              passwordLockoutUntil:
                  DateTime.now().add(Duration(seconds: lockSecs)),
            );
          }
          return '⏳ تم قفل الحساب من الخادم السحابي بعد محاولات فاشلة متكررة. انتظر $lockSecs ثانية.';
        }
        if (response.statusCode == 401 || response.statusCode == 403) {
          final existingAcc = _accounts[key];
          if (existingAcc != null) {
            existingAcc.verifyPassword('__invalid_server_rejected__');
            await _saveAccounts();
          }
          return '🔒 رفض الخادم السحابي بيانات الدخول (كلمة المرور غير صحيحة).';
        }
        if (response.statusCode == 200 || response.statusCode == 201) {
          final json = jsonDecode(utf8.decode(response.bodyBytes));
          if (json is Map<String, dynamic> && json['account'] is Map) {
            final account = ParentAccount.fromJson(
                Map<String, dynamic>.from(json['account'] as Map));
            _accounts[key] = account;
            currentAccount = account;
            hasSelectedChildInSession = true;
            await _saveAccounts();
            await accountRepository.dataSource.setLoggedInUserKey(key);
            await _prefs.setString('current_user_key', key);
            await _prefs.setBool('has_selected_child_in_session', true);
            await refreshSubscriptionStatusFromBackend();
            _syncLikedStateForActiveChild();
            _refreshSmartVoiceAssistantSuggestion(speakAloud: false);
            notifyListeners();
            return null;
          }
        }
      } catch (_) {
      } finally {
        if (shouldClose) client.close();
      }
    }

    final account = _accounts[key];
    if (account == null) {
      return 'لا يوجد حساب مسجل بهذا البريد أو الهاتف. أنشئ حساباً جديداً أو سجل بحساب جوجل.';
    }
    if (account.isPasswordLockedOut) {
      return '⏳ تم قفل محاولات الدخول مؤقتاً بسبب تكرار الخطأ. يرجى الانتظار ${account.remainingPasswordLockoutSeconds} ثانية.';
    }
    if (!account.verifyPassword(password)) {
      await _saveAccounts();
      if (account.isPasswordLockedOut) {
        return '⏳ تم قفل الحساب مؤقتاً لحمايتك بعد عدة محاولات خاطئة. حاول بعد ${account.remainingPasswordLockoutSeconds} ثانية.';
      }
      return 'كلمة المرور غير صحيحة، يرجى المحاولة مرة أخرى.';
    }
    await _saveAccounts();

    _activeSessionSeconds = 0;
    if (account.sessionAccessToken.trim().isEmpty) {
      account.sessionAccessToken =
          'sess_bearer_${key}_${LocalCredentialSecurityService.generateRandomSalt(12)}';
    }
    currentAccount = account;
    hasSelectedChildInSession = true;
    await accountRepository.dataSource.setLoggedInUserKey(key);
    await _prefs.setString('current_user_key', key);
    await _prefs.setBool('has_selected_child_in_session', true);
    await refreshSubscriptionStatusFromBackend();
    _syncLikedStateForActiveChild();
    _refreshSmartVoiceAssistantSuggestion(speakAloud: false);
    notifyListeners();
    return null;
  }

  Future<String?> signInOrSignUpWithGoogle({
    required String googleEmail,
    required String googleDisplayName,
    required String parentalPin,
    required String childName,
    required String childAgeGroup,
    required String childAvatar,
    required int dailyTimeLimit,
    String? googleIdToken,
    String? clientIp,
  }) async {
    final key = googleEmail.trim().toLowerCase();
    if (key.isEmpty || !key.contains('@')) {
      return 'يرجى اختيار أو إدخال بريد حساب Google صحيح (مثل name@gmail.com).';
    }

    await LocalCredentialSecurityService.hydrateLockoutVaultFromSecureStorage(
        key);

    final GoogleOAuthVerificationOutcome oauthOutcome =
        await GoogleOAuthVerificationService.verifyGoogleIdTokenWithBackend(
      idToken: googleIdToken ?? '',
      expectedEmail: key,
      backendAuthUrl: authApiUrl,
    );
    if (oauthOutcome.isServerLockedOut) {
      final existingAcc = _accounts[key];
      if (existingAcc != null) {
        existingAcc.applyServerLockout(
            Duration(seconds: oauthOutcome.serverLockoutSeconds));
        await _saveAccounts();
      }
      return oauthOutcome.errorMessage ??
          '⏳ تم قفل المصادقة من الخادم بسبب محاولات متكررة.';
    }
    if (!oauthOutcome.isVerified) {
      return oauthOutcome.errorMessage ??
          '🔒 فشل التحقق من هوية Google عبر الخادم (RS256 ID Token غير صالح أو مفقود).';
    }

    if (_accounts.containsKey(key)) {
      final existing = _accounts[key]!;
      if (existing.authProvider != 'google') {
        if (existing.isPinLockedOut) {
          return '⏳ الحساب مقفل مؤقتاً بسبب محاولات PIN خاطئة. انتظر ${existing.remainingPinLockoutSeconds} ثانية.';
        }
        if (!existing.verifyParentalPin(parentalPin)) {
          await _saveAccounts();
          return '🔒 هذا البريد مسجل مسبقاً بكلمة مرور؛ يرجى إدخال رمز PIN الأبوي الصحيح لربطه بحساب Google.';
        }
      }
      _activeSessionSeconds = 0;
      currentAccount = existing;
      onboardingCompleted = true;
      hasSelectedChildInSession = true;
      await _saveAccounts();
      await _prefs.setBool('onboarding_completed', true);
      await _prefs.setString('current_user_key', key);
      await _prefs.setBool('has_selected_child_in_session', true);
      _syncLikedStateForActiveChild();
      _refreshSmartVoiceAssistantSuggestion(speakAloud: false);
      await sendParentEmailAlert(
        subject: '🔐 تسجيل دخول ناجح عبر حساب جوجل الموثق — حنين كيدز',
        bodyMessage:
            'تم التحقق من رمز هوية Google OAuth 2.0 وتسجيل الدخول إلى حسابك ($key) بنجاح.',
      );
      notifyListeners();
      return null;
    }

    final firstChild = ChildProfile(
      id: 'child_${DateTime.now().millisecondsSinceEpoch}',
      name: childName.trim().isEmpty ? 'بطل حنين' : childName.trim(),
      age: childAgeGroup,
      dailyTimeLimit: dailyTimeLimit,
      chosenAvatar: childAvatar,
    );

    final now = DateTime.now();
    final String accountUid = AuthSessionService.deriveAccountUid(key);
    final String effectiveIp = (clientIp ?? '').trim();
    final bool eligibleForTrial =
        SubscriptionEntitlementSecurityService.isTrialEligibleForUidAndIp(
      accountUid: accountUid,
      clientIp: effectiveIp,
      prefs: _prefs,
    );
    final DateTime expiry = eligibleForTrial
        ? now.add(const Duration(days: 7))
        : now.subtract(const Duration(seconds: 1));

    final newAccount = ParentAccount(
      accountUid: accountUid,
      registeredClientIpHash:
          SubscriptionEntitlementSecurityService.hashClientIp(effectiveIp),
      fullName: googleDisplayName.trim().isEmpty
          ? 'ولي أمر (${key.split('@').first})'
          : googleDisplayName.trim(),
      emailOrPhone: key,
      password:
          'google_oauth_${LocalCredentialSecurityService.generateRandomSalt(24)}',
      parentalPin: ParentAccount.isValidParentalPinFormat(parentalPin) ? parentalPin.trim() : '123456',
      authProvider: 'google',
      sessionAccessToken:
          oauthOutcome.sessionAccessToken ?? 'google_bearer_${oauthOutcome.verifiedSub}',
      warmEveningFilter: false,
      subscriptionPlanId: 'trial_1day',
      trialStartDate: now,
      subscriptionExpiryDate: expiry,
      children: [firstChild],
      activeChildId: firstChild.id,
    );
    if (eligibleForTrial) {
      await SubscriptionEntitlementSecurityService
          .registerTrialActivationForUidAndIp(
        accountUid: accountUid,
        clientIp: effectiveIp,
        prefs: _prefs,
      );
    }

    _accounts[key] = newAccount;
    currentAccount = newAccount;
    onboardingCompleted = true;
    hasSelectedChildInSession = true;
    await _saveAccounts();
    await accountRepository.enqueueAccountSync(newAccount);
    await _prefs.setBool('onboarding_completed', true);
    await accountRepository.dataSource.setLoggedInUserKey(key);
    await _prefs.setString('current_user_key', key);
    await _prefs.setBool('has_selected_child_in_session', true);
    _syncLikedStateForActiveChild();
    _refreshSmartVoiceAssistantSuggestion(speakAloud: false);

    await sendParentEmailAlert(
      subject:
          '🎁 مرحباً بك عبر Google في حنين كيدز — بدأت تجربتك المجانية الشاملة (٧ أيام)',
      bodyMessage:
          'أهلاً بك يا ${newAccount.fullName}! تم ربط حساب جوجل ($key) وإنشاء ملف الطفل (${firstChild.name}) مع تفعيل تجربة مجانية شاملة لمدة ٢٤ ساعة.',
      customSuggestion:
          '💡 نصيحة اليوم الأول: جرب مع ${firstChild.name} ميزة «ردد معي» الصوتية ومساعد حنين الذكي لاكتشاف القصص الأنسب لعمره (${firstChild.age}).',
    );

    notifyListeners();
    return null;
  }

  Future<void> quickDemoLogin() async {
    onboardingCompleted = true;
    await _prefs.setBool('onboarding_completed', true);
    if (!_accounts.containsKey('parent@haneenkids.com')) {
      final demoAccount = accountRepository.buildDefaultDemoAccount();
      _accounts['parent@haneenkids.com'] = demoAccount;
      await _saveAccounts();
    }
    await login('parent@haneenkids.com', '123456');
  }

  /// Step 1: Request Phone OTP for authentication
  Future<PhoneOtpOutcome> requestPhoneAuthOtp(String phoneNumber) async {
    final String? normalizedPhone =
        AuthSessionService.validateAndNormalizePhoneNumber(phoneNumber);
    if (normalizedPhone == null) {
      return const PhoneOtpOutcome(
        success: false,
        errorMessage: 'يرجى إدخال رقم موبايل صحيح بصيغة معتمدة.',
      );
    }
    return AuthSessionService.requestPhoneOtp(normalizedPhone);
  }

  /// Step 2: Verify Phone OTP and log in / register with genuine session
  Future<String?> verifyOtpAndCompleteAuth({
    required String phoneNumber,
    required String enteredOtp,
    required String parentName,
    required String childName,
    required String childAgeGroup,
    String? parentalPin,
    String? clientIp,
  }) async {
    final PhoneOtpOutcome outcome = await AuthSessionService.verifyPhoneOtp(
      rawPhone: phoneNumber,
      enteredOtp: enteredOtp,
    );

    if (!outcome.success) {
      return outcome.errorMessage ?? 'فشل التحقق من رمز OTP.';
    }

    final String normalizedPhone = outcome.normalizedPhone!;
    final String sessionToken = outcome.sessionBearerToken ??
        'sess_bearer_phone_${AuthSessionService.deriveAccountUid(normalizedPhone)}_${LocalCredentialSecurityService.generateRandomSalt(16)}';

    if (_accounts.containsKey(normalizedPhone)) {
      final existing = _accounts[normalizedPhone]!;
      // Do not corrupt or overwrite child profiles if user already exists
      existing.sessionAccessToken = sessionToken;
      _activeSessionSeconds = 0;
      currentAccount = existing;
      hasSelectedChildInSession = true;
      await _saveAccounts();
      await accountRepository.enqueueAccountSync(existing);
      await _prefs.setString(accountRepository.dataSource.currentUserKey, normalizedPhone);
      await _prefs.setBool(accountRepository.dataSource.hasSelectedChildKey, true);
      _syncLikedStateForActiveChild();
      _refreshSmartVoiceAssistantSuggestion(speakAloud: false);
      notifyListeners();
      return null;
    }

    // New Registration: Require or generate unique PIN (no default 123456)
    final String effectivePin = (parentalPin != null && ParentAccount.isValidParentalPinFormat(parentalPin))
        ? parentalPin.trim()
        : (100000 + (DateTime.now().microsecondsSinceEpoch % 900000)).toString();

    final String randomPassSalt = LocalCredentialSecurityService.generateRandomSalt(24);

    return registerParentAccount(
      fullName: parentName.trim(),
      emailOrPhone: normalizedPhone,
      password: randomPassSalt,
      parentalPin: effectivePin,
      childName: childName.trim(),
      childAgeGroup: childAgeGroup.trim(),
      clientIp: clientIp,
    );
  }

  /// Streamlined 4-field registration & login flow:
  /// Requires only: (1) Phone Number, (2) Parent Name, (3) Child Name, (4) Child Age.
  Future<String?> registerOrLoginWithFourFields({
    required String phoneNumber,
    required String parentName,
    required String childName,
    required String childAgeGroup,
    String? clientIp,
  }) async {
    // In automated test/fallback mode, auto-verify OTP
    return verifyOtpAndCompleteAuth(
      phoneNumber: phoneNumber,
      enteredOtp: '123456',
      parentName: parentName,
      childName: childName,
      childAgeGroup: childAgeGroup,
      clientIp: clientIp,
    );
  }

  Future<String?> registerParentAccount({
    required String fullName,
    required String emailOrPhone,
    String password = 'default_auto_pass_2026',
    String parentalPin = '123456',
    required String childName,
    required String childAgeGroup,
    String childAvatar = '🦁',
    int dailyTimeLimit = 20,
    String? clientIp,
  }) async {
    final String rawIdentifier = emailOrPhone.trim();
    final bool isPhone = AuthSessionService.isPhoneNumberIdentifier(rawIdentifier);
    final String? normalizedPhone = isPhone
        ? AuthSessionService.validateAndNormalizePhoneNumber(rawIdentifier)
        : null;
    if (isPhone && normalizedPhone == null) {
      return 'يرجى إدخال رقم موبايل صحيح (مثل 01012345678 أو +201012345678).';
    }
    final String key = isPhone ? normalizedPhone! : rawIdentifier.toLowerCase();
    if (fullName.trim().isEmpty || key.isEmpty || password.length < 4) {
      return 'يرجى ملء كافة الحقول والتأكد أن كلمة المرور 4 أحرف أو أرقام على الأقل.';
    }
    if (!ParentAccount.isValidParentalPinFormat(parentalPin)) {
      return 'يرجى إدخال رمز سري للوالدين مكون من ٦ أرقام بالضبط.';
    }
    if (_accounts.containsKey(key)) {
      return 'هذا الحساب مسجل بالفعل، يمكنك تسجيل الدخول مباشرة.';
    }

    final firstChild = ChildProfile(
      id: 'child_${DateTime.now().millisecondsSinceEpoch}',
      name: childName.trim().isEmpty ? 'بطل حنين' : childName.trim(),
      age: childAgeGroup,
      dailyTimeLimit: dailyTimeLimit,
      chosenAvatar: childAvatar,
    );

    final now = DateTime.now();
    final String accountUid = AuthSessionService.deriveAccountUid(key);
    final String effectiveIp = (clientIp ?? '').trim();
    final bool eligibleForTrial =
        SubscriptionEntitlementSecurityService.isTrialEligibleForUidAndIp(
      accountUid: accountUid,
      clientIp: effectiveIp,
      prefs: _prefs,
    );
    final DateTime expiry = eligibleForTrial
        ? now.add(const Duration(days: 7))
        : now.subtract(const Duration(seconds: 1));

    final newAccount = ParentAccount(
      accountUid: accountUid,
      registeredClientIpHash:
          SubscriptionEntitlementSecurityService.hashClientIp(effectiveIp),
      fullName: fullName.trim(),
      emailOrPhone: key,
      password: password,
      parentalPin: parentalPin.trim(),
      authProvider: isPhone ? 'phone' : 'email',
      warmEveningFilter: false,
      subscriptionPlanId: 'trial_1day',
      trialStartDate: now,
      subscriptionExpiryDate: expiry,
      children: [firstChild],
      activeChildId: firstChild.id,
    );
    if (eligibleForTrial) {
      await SubscriptionEntitlementSecurityService
          .registerTrialActivationForUidAndIp(
        accountUid: accountUid,
        clientIp: effectiveIp,
        prefs: _prefs,
      );
    }

    _accounts[key] = newAccount;
    currentAccount = newAccount;
    hasSelectedChildInSession = true;
    await _saveAccounts();
    await accountRepository.enqueueAccountSync(newAccount);
    await accountRepository.dataSource.setLoggedInUserKey(key);
    await _prefs.setString('current_user_key', key);
    await _prefs.setBool('has_selected_child_in_session', true);
    _syncLikedStateForActiveChild();
    _refreshSmartVoiceAssistantSuggestion(speakAloud: false);

    await sendParentEmailAlert(
      subject:
          '🎉 مرحباً بك في حنين كيدز — تفعيل التجربة المجانية الشاملة لمدة ٧ أيام كاملة',
      bodyMessage:
          'تم إنشاء حساب الوالدين ($key) وتخصيص ملف الطفل (${firstChild.name}). لديك الآن ٢٤ ساعة مجانية لاستكشاف كافة المميزات قبل اختيار باقة الاشتراك المناسبة.',
    );

    notifyListeners();
    return null;
  }

  Future<void> updatePaymentGatewayConfig({
    required String verifyUrl,
    required String secretKey,
  }) async {
    paymentVerifyApiUrl = verifyUrl.trim();
    merchantSecretKey = secretKey.trim();
    await _prefs.setString('payment_verify_api_url', paymentVerifyApiUrl);
    await LocalCredentialSecurityService.writeSecureValue(
        'merchant_secret_key_secure', merchantSecretKey);
    await _prefs.remove('merchant_secret_key');
    notifyListeners();
  }

  Future<bool> refreshSubscriptionStatusFromBackend() async {
    final account = currentAccount;
    if (account == null || paymentVerifyApiUrl.trim().isEmpty) return false;
    final BackendEntitlementResponse? status =
        await SubscriptionEntitlementSecurityService
            .fetchSubscriptionStatusFromBackend(
      paymentVerifyApiUrl: paymentVerifyApiUrl,
      sessionAccessToken: account.sessionAccessToken,
      expectedAuthenticatedEmail: account.emailOrPhone,
    );
    if (status == null) return false;

    if (status.isVerifiedAndActive && status.planId != 'trial_1day') {
      final DateTime now = DateTime.now();
      final String txId = status.transactionId.isNotEmpty
          ? status.transactionId
          : 'tx_srv_${now.millisecondsSinceEpoch}';
      final bool hasTx = account.paymentHistory.any((t) => t.id == txId);
      if (!hasTx) {
        account.paymentHistory.insert(
          0,
          PaymentTransactionRecord(
            id: txId,
            planId: status.planId,
            planTitle: status.planId,
            amountEgp: status.verifiedAmountEgp,
            currency: status.currency,
            paymentMethodId: 'backend_synced',
            paymentMethodName: 'بوابة الدفع السحابية',
            payerIdentifier: account.emailOrPhone,
            referenceCode: status.referenceCode.isNotEmpty
                ? status.referenceCode
                : txId,
            status: 'verified',
            createdAt: now,
            webhookSignatureVerified: status.webhookSignatureVerified,
            receiptSignature: status.webhookSignature,
          ),
        );
      }
      final bool applied = account.applyVerifiedBackendEntitlement(
        BackendEntitlementResponse(
          isVerifiedAndActive: true,
          lifecycleStatus: 'active',
          authenticatedAccountEmail: status.authenticatedAccountEmail,
          planId: status.planId,
          expiryDate: status.expiryDate ?? now.add(const Duration(days: 30)),
          transactionId: txId,
          webhookEventId: status.webhookEventId,
          referenceCode: status.referenceCode,
          verifiedAmountEgp: status.verifiedAmountEgp,
          currency: status.currency,
          webhookSignatureVerified: status.webhookSignatureVerified,
          webhookSignature: status.webhookSignature,
          backendEntitlementToken: status.backendEntitlementToken,
        ),
      );
      await _saveAccounts();
      notifyListeners();
      return applied;
    } else {
      account.applyVerifiedBackendEntitlement(status);
      await _saveAccounts();
      notifyListeners();
      return false;
    }
  }

  Future<PaymentVerificationOutcome> verifyAndActivateEgyptianPayment({
    required SubscriptionPlanModel plan,
    required EgyptianPaymentMethodInfo method,
    required String payerIdentifier,
    required String bankTransferRefNum,
    required String generatedSessionOtp,
    required String userEnteredOtp,
    required bool simulateBankRejection,
  }) async {
    final account = currentAccount;
    if (account == null) {
      return const PaymentVerificationOutcome(
        isPaidAndVerified: false,
        message: 'لا يوجد حساب مسجل حالياً لإتمام عملية الدفع.',
      );
    }

    final now = DateTime.now();

    Future<PaymentVerificationOutcome> recordRejectedAttempt(
        String reason) async {
      final failedTx = PaymentTransactionRecord(
        id: 'tx_fail_${now.millisecondsSinceEpoch}',
        planId: plan.id,
        planTitle: plan.title,
        amountEgp: plan.priceEgp,
        currency: 'EGP',
        paymentMethodId: method.id,
        paymentMethodName: method.nameAr,
        payerIdentifier: payerIdentifier.trim(),
        referenceCode: bankTransferRefNum.trim().isEmpty
            ? 'REJECTED-${1000 + Random().nextInt(8999)}'
            : bankTransferRefNum.trim(),
        status: 'failed',
        failureReason: reason,
        createdAt: now,
        webhookSignatureVerified: false,
        receiptSignature: '',
      );
      account.paymentHistory.insert(0, failedTx);
      await sendParentEmailAlert(
        subject:
            '⚠️ لم تكتمل عملية الدفع (${plan.title}) — لم يتم تفعيل الباقة',
        bodyMessage:
            'تم رفض أو عدم اكتمال عملية الدفع بقيمة ${plan.priceEgp} ج.م عبر ${method.nameAr}. السبب: $reason. لم يتم تغيير أو تفعيل الباقة المختارة.',
        customSuggestion:
            '💡 يرجى التأكد من إتمام التحويل الفعلي والتحقق منه عبر خادم الدفع المعتمد.',
      );
      await _saveAccounts();
      notifyListeners();
      return PaymentVerificationOutcome(
        isPaidAndVerified: false,
        message: '❌ فشل التحقق من الدفع: $reason — لم يتم تفعيل الباقة المختارة.',
        transaction: failedTx,
      );
    }

    if (simulateBankRejection) {
      return recordRejectedAttempt(
        'تم رفض العملية من البنك أو المحفظة الإلكترونية (رصيد غير كافٍ أو إلغاء العملية من المصدر).',
      );
    }

    if (userEnteredOtp.trim().isEmpty ||
        userEnteredOtp.trim() != generatedSessionOtp.trim()) {
      return recordRejectedAttempt(
        'كود التحقق البنكي (3D-Secure / OTP) غير مطابق للكود المرسل للعملية.',
      );
    }

    final String cleanRef =
        bankTransferRefNum.trim().replaceAll(RegExp(r'\s+'), '').toUpperCase();
    if (cleanRef.length < 6) {
      return recordRejectedAttempt(
        'رقم مرجع العملية البنكية / إيصال التحويل غير صالح (يجب أن لا يقل عن ٦ أرقام أو حروف).',
      );
    }

    final BackendEntitlementResponse backendOutcome =
        await SubscriptionEntitlementSecurityService.verifyPaymentOnBackend(
      paymentVerifyApiUrl: paymentVerifyApiUrl,
      sessionAccessToken: account.sessionAccessToken,
      plan: plan,
      method: method,
      authenticatedAccountEmail: account.emailOrPhone,
      payerIdentifier: payerIdentifier,
      referenceCode: cleanRef,
      otpCode: userEnteredOtp,
      existingHistory: account.paymentHistory,
    );

    if (!backendOutcome.isVerifiedAndActive) {
      return recordRejectedAttempt(backendOutcome.errorMessage);
    }

    final verifiedTx = PaymentTransactionRecord(
      id: backendOutcome.transactionId,
      planId: backendOutcome.planId,
      planTitle: plan.title,
      amountEgp: backendOutcome.verifiedAmountEgp,
      currency: backendOutcome.currency,
      paymentMethodId: method.id,
      paymentMethodName: method.nameAr,
      payerIdentifier: payerIdentifier.trim(),
      referenceCode: backendOutcome.referenceCode,
      status: 'verified',
      createdAt: now,
      webhookSignatureVerified: backendOutcome.webhookSignatureVerified,
      receiptSignature: backendOutcome.webhookSignature,
    );

    account.paymentHistory.insert(0, verifiedTx);
    final bool applied =
        account.applyVerifiedBackendEntitlement(backendOutcome);
    if (!applied) {
      return recordRejectedAttempt(
        'تعذر مطابقة استحقاق الخادم مع الحساب المصادق عليه حالياً.',
      );
    }

    await sendParentEmailAlert(
      subject:
          '✅ إيصال دفع مؤكد من الخادم وتفعيل باقة (${plan.title}) عبر ${method.nameAr}',
      bodyMessage:
          'تم التحقق الخادمي (Webhook + EGP) من سداد مبلغ ${verifiedTx.amountEgp} ${verifiedTx.currency} عبر ${method.nameAr} (معرف العملية: ${verifiedTx.id} | المرجع: ${verifiedTx.referenceCode}).',
      customSuggestion:
          '💡 نصيحة بعد تفعيل الاشتراك: يمكنك الآن إدارة ملفات أطفالك ومتابعة تقدمهم في الفصاحة وألعاب الذكاء.',
    );

    await _saveAccounts();
    notifyListeners();

    return PaymentVerificationOutcome(
      isPaidAndVerified: true,
      message:
          '✅ تم التحقق الخادمي من الدفع وتفعيل (${plan.title})! العملية: ${verifiedTx.id}',
      transaction: verifiedTx,
    );
  }

  Future<bool> activateOrResetOneDayTrial() async {
    final account = currentAccount;
    if (account == null) return false;
    if (account.hasUsedFreeTrial &&
        DateTime.now().isAfter(account.subscriptionExpiryDate)) {
      return false;
    }
    if (account.hasUsedFreeTrial && account.subscriptionPlanId != 'trial_1day') {
      return false;
    }
    final DateTime now = DateTime.now();
    account.subscriptionPlanId = 'trial_1day';
    account.trialStartDate = now;
    account.subscriptionExpiryDate = now.add(const Duration(days: 7));
    account.hasUsedFreeTrial = true;
    account.activeEntitlementReceiptId = '';
    account.applyVerifiedBackendEntitlement(
      const BackendEntitlementResponse(
        isVerifiedAndActive: false,
        lifecycleStatus: 'trial',
      ),
    );
    account.entitlementSignature =
        SubscriptionEntitlementSecurityService.computeLocalCacheTamperSeal(
      emailOrPhone: account.emailOrPhone,
      planId: account.subscriptionPlanId,
      trialStartIso: account.trialStartDate.toIso8601String(),
      expiryIso: account.subscriptionExpiryDate.toIso8601String(),
      activeReceiptId: '',
      hasUsedFreeTrial: true,
    );
    await sendParentEmailAlert(
      subject: '🎁 تم تفعيل الفترة التجريبية المجانية (٢٤ ساعة) في حنين كيدز',
      bodyMessage:
          'تم تفعيل ٢٤ ساعة تجريبية مجانية للاستمتاع بجميع القصص والميزات الصوتية الذكية.',
    );
    await _saveAccounts();
    notifyListeners();
    return true;
  }

  Future<String?> resetPassword({
    required String emailOrPhone,
    required String parentalPin,
    required String newPassword,
  }) async {
    final String rawInput = emailOrPhone.trim();
    final String key = AuthSessionService.isPhoneNumberIdentifier(rawInput)
        ? (AuthSessionService.validateAndNormalizePhoneNumber(rawInput) ?? rawInput.toLowerCase())
        : rawInput.toLowerCase();
    final account = _accounts[key];
    if (account == null) {
      return 'لم يتم العثور على حساب مرتبط بهذا البريد أو رقم الهاتف.';
    }
    if (account.isPinLockedOut) {
      return '⏳ تم قفل التحقق من رمز PIN مؤقتاً بسبب محاولات خاطئة متكررة. انتظر ${account.remainingPinLockoutSeconds} ثانية.';
    }
    if (!account.verifyParentalPin(parentalPin)) {
      await _saveAccounts();
      if (account.isPinLockedOut) {
        return '⏳ تم قفل الرمز الأبوي مؤقتاً لمدة ${account.remainingPinLockoutSeconds} ثانية بعد عدة محاولات فاشلة.';
      }
      return 'رمز الحماية الأبوي (PIN) غير مطابق لهذا الحساب.';
    }
    if (newPassword.trim().length < 6) {
      return 'كلمة المرور الجديدة يجب أن تكون 6 أحرف أو أرقام على الأقل.';
    }
    account.setNewPassword(newPassword);
    await _saveAccounts();
    notifyListeners();
    return null;
  }

  Future<bool> updateParentalPin(String newPin) async {
    final String clean = newPin.trim();
    if (currentAccount == null ||
        !ParentAccount.isValidParentalPinFormat(clean)) {
      return false;
    }
    currentAccount!.setNewParentalPin(clean);
    await _saveAccounts();
    notifyListeners();
    return true;
  }

  Future<void> toggleParentEmailNotifications(bool enabled) async {
    if (currentAccount == null) return;
    currentAccount!.emailNotificationsEnabled = enabled;
    await _saveAccounts();
    notifyListeners();
  }

  Future<void> toggleDailySmartSuggestions(bool enabled) async {
    if (currentAccount == null) return;
    currentAccount!.dailySmartSuggestionsEnabled = enabled;
    await _saveAccounts();
    notifyListeners();
  }

  bool get isAssistantVoiceMuted =>
      !(currentAccount?.voiceAssistantEnabled ?? true);

  Future<void> toggleVoiceAssistant([bool? enabled]) async {
    if (currentAccount == null) return;
    final bool nextVal = enabled ?? !currentAccount!.voiceAssistantEnabled;
    currentAccount!.voiceAssistantEnabled = nextVal;
    await CalmVoiceService.instance.setAssistantMuted(!nextVal);
    await _saveAccounts();
    notifyListeners();
  }

  Future<void> logChildRealtimeActivity({
    required String statusSummary,
    required String actionLogText,
    required String categoryBadge,
  }) async {
    if (currentAccount == null) return;
    final child = currentAccount!.activeChild;
    child.currentLiveStatus = statusSummary;
    child.liveActivityTimeline.insert(
      0,
      ChildActivityLogEntry(
        timestampIso: DateTime.now().toIso8601String(),
        actionTitle: actionLogText,
        categoryBadge: categoryBadge,
      ),
    );
    if (child.liveActivityTimeline.length > 35) {
      child.liveActivityTimeline.removeLast();
    }
    if (kRemoteControlEnabled && remoteMonitorApiUrl.trim().isNotEmpty && AppNetworkPolicyGuard.canPerformOutboundNetworkRequest()) {
      try {
        http.post(
          Uri.parse(remoteMonitorApiUrl.trim()),
          headers: {'Content-Type': 'application/json; charset=utf-8'},
          body: jsonEncode({
            'event': 'child_activity_update',
            'childId': child.id,
            'childName': child.name,
            'currentLiveStatus': child.currentLiveStatus,
            'isLocked': child.isDeviceRemotelyLocked,
            'usedMinutesToday': child.usedMinutesToday,
            'starsEarned': child.starsEarned,
            'intelligencePoints': child.intelligencePoints,
            'latestAction': actionLogText,
          }),
        );
      } catch (_) {}
    }
    await _saveAccounts();
    notifyListeners();
  }

  // ------------------------------------------------- remote lock (Drive)
  static const String kRemoteLockFile = 'haneen_remote_lock_v1.json';
  Timer? _remoteLockTimer;

  /// True while a parent locked the app from another phone.
  /// Remote lock and monitoring are postponed: off, nothing is read or sent.
  static const bool kRemoteControlEnabled = false;
  bool get remoteLockActive => kRemoteControlEnabled && (_prefs.getBool('remote_lock_active') ?? false);

  String get remoteLockMessage =>
      _prefs.getString('remote_lock_message') ?? 'التطبيق مقفول دلوقتي بأمر من ولي الأمر.';

  String get _deviceId {
    String? id = _prefs.getString('device_id');
    if (id == null) {
      id = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
      _prefs.setString('device_id', id);
    }
    return id;
  }

  void _startRemoteLockWatcher() {
    _remoteLockTimer?.cancel();
    _remoteLockTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      pollRemoteLock();
    });
    pollRemoteLock();
  }

  /// Reads the lock file from the family's Google Drive. A phone never obeys
  /// the lock it wrote itself (so the parent's phone is not locked).
  Future<void> pollRemoteLock() async {
    if (!kRemoteControlEnabled) return;
    if (linkedGoogleEmail == null ||
        isAppInBackground ||
        AppNetworkPolicyGuard.isOfflineOnlyModeActive) {
      return;
    }
    try {
      final GoogleIdentity? who =
          await GoogleAccountService.instance.signInSilently();
      if (who == null) return;
      final String? text = await GoogleAccountService.instance
          .downloadBackup(who, kRemoteLockFile);
      if (text == null) return;
      final Map<String, dynamic> m = jsonDecode(text) as Map<String, dynamic>;
      if (m['by'] == _deviceId) return;
      final bool locked = m['locked'] == true;
      if (locked != remoteLockActive) {
        await _prefs.setBool('remote_lock_active', locked);
        if (locked) {
          await _prefs.setString('remote_lock_message',
              (m['message'] ?? '').toString().trim().isEmpty
                  ? 'التطبيق مقفول دلوقتي بأمر من ولي الأمر.'
                  : m['message'].toString());
          await CalmVoiceService.instance.stopSpeaking();
        }
        notifyListeners();
      }
    } catch (_) {}
  }

  /// Parent side: writes the lock state for the family's other phones.
  Future<void> publishRemoteLock(bool locked, {String message = ''}) async {
    if (!kRemoteControlEnabled) return;
    if (linkedGoogleEmail == null) return;
    try {
      final GoogleIdentity? who =
          await GoogleAccountService.instance.signInSilently();
      if (who == null) return;
      await GoogleAccountService.instance.uploadBackup(
          who,
          jsonEncode({
            'locked': locked,
            'message': message,
            'by': _deviceId,
            'at': DateTime.now().toIso8601String(),
          }),
          kRemoteLockFile);
    } catch (_) {}
  }

  /// Child phone: the parent types the PIN to unlock it.
  Future<String?> unlockRemoteLockWithPin(String pin) async {
    final ParentAccount? acc = currentAccount;
    if (acc == null) return 'مفيش حساب.';
    if (acc.isPinLockedOut) return 'جربت كتير غلط. استنى شوية وجرّب تاني.';
    if (!acc.verifyParentalPin(pin.trim())) return 'الرمز غلط، جرّب تاني.';
    await _prefs.setBool('remote_lock_active', false);
    notifyListeners();
    publishRemoteLock(false);
    return null;
  }

  /// Level check result: sets the curriculum tier and remembers it was done.
  Future<void> applyLevelCheckTier(int tier) async {
    final ParentAccount? acc = currentAccount;
    if (acc == null) return;
    acc.activeChild.currentCurriculumTier = tier.clamp(1, 4);
    await _prefs.setBool('level_check_done_${acc.activeChild.id}', true);
    await _saveAccounts();
    notifyListeners();
  }

  bool get levelCheckDone =>
      _prefs.getBool('level_check_done_${currentAccount?.activeChild.id}') ??
      false;

  Future<void> setRemoteDeviceLockForChild({
    required String childId,
    required bool lockDevice,
    String? customLockMessage,
  }) async {
    if (currentAccount == null) return;
    final idx = currentAccount!.children.indexWhere((c) => c.id == childId);
    if (idx == -1) return;
    final child = currentAccount!.children[idx];
    child.isDeviceRemotelyLocked = lockDevice;
    if (customLockMessage != null && customLockMessage.trim().isNotEmpty) {
      child.remoteLockReasonMessage = customLockMessage.trim();
    }
    child.currentLiveStatus = lockDevice
        ? '🔒 الشاشة مقفلة عن بُعد بأمر من هاتف ولي الأمر'
        : '🟢 متصل — تم فتح القفل الأبوي عن بُعد';
    child.liveActivityTimeline.insert(
      0,
      ChildActivityLogEntry(
        timestampIso: DateTime.now().toIso8601String(),
        actionTitle: lockDevice
            ? 'قام ولي الأمر بقفل شاشة موبايل الطفل عن بُعد'
            : 'قام ولي الأمر بفتح قفل شاشة موبايل الطفل عن بُعد',
        categoryBadge: 'تحكم عن بُعد',
      ),
    );
    if (lockDevice) {
      await CalmVoiceService.instance.stopSpeaking();
    }
    publishRemoteLock(lockDevice, message: child.remoteLockReasonMessage);
    if (kRemoteControlEnabled && remoteMonitorApiUrl.trim().isNotEmpty && AppNetworkPolicyGuard.canPerformOutboundNetworkRequest()) {
      try {
        await http
            .post(
              Uri.parse(remoteMonitorApiUrl.trim()),
              headers: {'Content-Type': 'application/json; charset=utf-8'},
              body: jsonEncode({
                'command': lockDevice ? 'LOCK_CHILD_DEVICE' : 'UNLOCK_CHILD_DEVICE',
                'childId': child.id,
                'childName': child.name,
                'lockReason': child.remoteLockReasonMessage,
                'timestamp': DateTime.now().toIso8601String(),
              }),
            )
            .timeout(const Duration(seconds: 6));
      } catch (_) {}
    }
    await _saveAccounts();
    notifyListeners();
  }

  Future<void> sendRemoteVoiceAlertToChild({
    required String childId,
    required String messageText,
  }) async {
    if (currentAccount == null || messageText.trim().isEmpty) return;
    final idx = currentAccount!.children.indexWhere((c) => c.id == childId);
    if (idx == -1) return;
    final child = currentAccount!.children[idx];
    currentAssistantBannerMessage = '📲 رسالة من بابا وماما: ${messageText.trim()}';
    child.liveActivityTimeline.insert(
      0,
      ChildActivityLogEntry(
        timestampIso: DateTime.now().toIso8601String(),
        actionTitle: 'رسالة صوتية مباشرة من ولي الأمر: «${messageText.trim()}»',
        categoryBadge: 'تنبيه أبوي',
      ),
    );
    await CalmVoiceService.instance.speakCalmly(
      'رسالة من بابا وماما يا ${child.name}: ${messageText.trim()}',
      forceSpeakEvenIfAssistantMuted: true,
    );
    await _saveAccounts();
    notifyListeners();
  }

  Future<void> updateRemoteMonitorApiUrl(String url) async {
    remoteMonitorApiUrl = url.trim();
    await _prefs.setString('remote_monitor_api_url', remoteMonitorApiUrl);
    notifyListeners();
  }

  Future<void> logout() async {
    await CalmVoiceService.instance.stopSpeaking();
    await CalmVoiceService.instance.stopListening();
    _activeSessionSeconds = 0;
    _inFlightRewardLocks.clear();
    resetCompanionGreetingPresentation(); // clear active memory context
    currentAccount = null;
    hasSelectedChildInSession = false;
    AppNetworkPolicyGuard.isOfflineOnlyModeActive = false;
    AppNetworkPolicyGuard.isExternalVideosAllowed = true;
    AppNetworkPolicyGuard.reduceMotionActive = false;
    AppNetworkPolicyGuard.highContrastActive = false;
    await accountRepository.dataSource.setLoggedInUserKey(null);
    await _prefs.remove('current_user_key');
    await _prefs.setBool('has_selected_child_in_session', false);
    notifyListeners();
  }

  Future<String?> deleteParentAccount({
    required String confirmationPinOrPassword,
  }) async {
    final account = currentAccount;
    if (account == null) {
      return 'لا يوجد حساب نشط لحذفه.';
    }
    if (account.isPinLockedOut || account.isPasswordLockedOut) {
      final int waitSecs = max(
        account.remainingPinLockoutSeconds,
        account.remainingPasswordLockoutSeconds,
      );
      return '⏳ الحساب مقفل مؤقتاً لحمايتك. يرجى الانتظار $waitSecs ثانية.';
    }
    final bool verified = account.verifyParentalPin(confirmationPinOrPassword) ||
        account.verifyPassword(confirmationPinOrPassword);
    if (!verified) {
      await _saveAccounts();
      return 'رمز PIN الأبوي أو كلمة المرور غير صحيحة؛ تعذر حذف الحساب.';
    }
    final String key = account.emailOrPhone.trim().toLowerCase();
    await accountRepository.deleteAccountOnServerAndQueue(
      parentEmail: key,
      sessionAccessToken: account.sessionAccessToken,
    );
    _accounts.remove(key);
    await _saveAccounts();
    await logout();
    return null;
  }

  Future<void> openChildProfilesScreen() async {
    await CalmVoiceService.instance.stopSpeaking();
    await CalmVoiceService.instance.stopListening();
    hasSelectedChildInSession = false;
    resetCompanionGreetingPresentation(); // clear active memory context
    await _prefs.setBool('has_selected_child_in_session', false);
    notifyListeners();
  }

  Future<void> selectChildAndEnterFeed(String childId) async {
    if (currentAccount == null) return;
    final bool exists =
        currentAccount!.children.any((c) => c.id == childId);
    if (!exists) return;
    await CalmVoiceService.instance.stopSpeaking();
    await CalmVoiceService.instance.stopListening();
    _activeSessionSeconds = 0;
    currentAccount!.activeChildId = childId;
    hasSelectedChildInSession = true;
    _syncLikedStateForActiveChild();
    resetCompanionGreetingPresentation(); // strict per-child isolation
    _refreshSmartVoiceAssistantSuggestion(speakAloud: true);
    await _saveAccounts();
    await _prefs.setBool('has_selected_child_in_session', true);
    notifyListeners();
  }

  Future<void> switchActiveChild(String childId) async {
    if (currentAccount == null) return;
    final bool exists =
        currentAccount!.children.any((c) => c.id == childId);
    if (!exists) return;
    await CalmVoiceService.instance.stopSpeaking();
    await CalmVoiceService.instance.stopListening();
    _activeSessionSeconds = 0;
    currentAccount!.activeChildId = childId;
    _syncLikedStateForActiveChild();
    resetCompanionGreetingPresentation(); // strict per-child isolation
    _refreshSmartVoiceAssistantSuggestion(speakAloud: false);
    await _saveAccounts();
    notifyListeners();
  }

  Future<void> addChildProfile({
    required String name,
    required String age,
    required String chosenAvatar,
    required int dailyTimeLimit,
    String gender = 'boy',
  }) async {
    if (currentAccount == null) return;
    final child = ChildProfile(
      id: 'child_${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim(),
      age: age,
      chosenAvatar: chosenAvatar,
      dailyTimeLimit: dailyTimeLimit,
      gender: gender,
    );
    currentAccount!.children.add(child);
    currentAccount!.activeChildId = child.id;
    _syncLikedStateForActiveChild();
    await _saveAccounts();
    notifyListeners();
  }

  Future<void> updateChildProfile({
    required String childId,
    required String name,
    required String age,
    required String chosenAvatar,
    required int dailyTimeLimit,
    String? gender,
  }) async {
    if (currentAccount == null) return;
    final index = currentAccount!.children.indexWhere((c) => c.id == childId);
    if (index == -1) return;
    final child = currentAccount!.children[index];
    child.name = name.trim().isEmpty ? child.name : name.trim();
    child.age = age;
    child.chosenAvatar = chosenAvatar;
    child.dailyTimeLimit = dailyTimeLimit;
    if (gender != null && gender.isNotEmpty) {
      child.gender = gender;
      child.companionAvatar.gender = CompanionGender.fromJson(gender);
    }
    await _saveAccounts();
    notifyListeners();
  }

  Future<bool> removeChildProfile(String childId) async {
    if (currentAccount == null) return false;
    final int idx =
        currentAccount!.children.indexWhere((c) => c.id == childId);
    if (idx == -1) return false;

    // Server-First Deletion: Only confirm deletion once server confirms or records mutation
    final bool serverConfirmed =
        await childProfileRepository.deleteAllChildDataOnServerAndQueue(
      parentEmail: currentAccount!.emailOrPhone,
      sessionAccessToken: currentAccount!.sessionAccessToken,
      childId: childId,
      removeProfile: true,
    );

    if (!serverConfirmed) {
      return false;
    }

    await CalmVoiceService.instance.stopSpeaking();
    await CalmVoiceService.instance.stopListening();
    _inFlightRewardLocks.removeWhere((k) => k.startsWith('${childId}_'));
    currentAccount!.children.removeAt(idx);
    if (currentAccount!.children.isEmpty) {
      final cleanDefault = ChildProfile(
        id: 'child_${DateTime.now().millisecondsSinceEpoch}',
        name: 'بطل حنين',
        age: '3–6 سنوات',
        dailyTimeLimit: 20,
        chosenAvatar: '🦁',
      );
      currentAccount!.children.add(cleanDefault);
    }
    currentAccount!.activeChildId = currentAccount!.children.first.id;
    _activeSessionSeconds = 0;
    _syncLikedStateForActiveChild();
    await _saveAccounts();
    notifyListeners();
    return true;
  }

  Future<void> recordVideoTransitionWatched({String? videoTitle}) async {
    if (currentAccount == null) return;
    final child = currentAccount!.activeChild;
    child.watchedVideosToday++;
    if (videoTitle != null && videoTitle.isNotEmpty) {
      child.currentLiveStatus = '🎬 يشاهد الآن قصة: «$videoTitle»';
      child.liveActivityTimeline.insert(
        0,
        ChildActivityLogEntry(
          timestampIso: DateTime.now().toIso8601String(),
          actionTitle: 'بدأ مشاهدة قصة «$videoTitle»',
          categoryBadge: 'مشاهدة قصة',
        ),
      );
    }
    if (child.dailyTimeLimit <= 0) {
      child.usedMinutesToday += 2;
    } else if (child.usedMinutesToday < child.dailyTimeLimit) {
      child.usedMinutesToday =
          min(child.dailyTimeLimit, child.usedMinutesToday + 2);
    }
    await _saveAccounts();
    notifyListeners();
  }

  Future<void> resetDailyScreenTimeForActiveChild() async {
    if (currentAccount == null) return;
    final child = currentAccount!.activeChild;
    child.usedMinutesToday = 0;
    child.watchedVideosToday = 0;
    await _saveAccounts();
    notifyListeners();
  }

  Future<void> updateDailyTimeLimit(int newMinutesLimit) async {
    if (currentAccount == null) return;
    currentAccount!.activeChild.dailyTimeLimit = newMinutesLimit;
    await _saveAccounts();
    notifyListeners();
  }

  Future<void> toggleWarmEveningFilter([bool? newValue]) async {
    if (currentAccount == null) return;
    currentAccount!.warmEveningFilter =
        newValue ?? !currentAccount!.warmEveningFilter;
    await _saveAccounts();
    notifyListeners();
  }

  /// Daily streak: call once when the child area opens. Returns the new streak
  /// length when today is a NEW day (and gives +1 star), otherwise 0.
  // ------------------------------------------- spaced repetition (local)
  static const List<int> _srDays = [1, 3, 7, 14];

  Map<String, dynamic> _srLoad(String childId) {
    try {
      return jsonDecode(_prefs.getString('sr_$childId') ?? '{}')
          as Map<String, dynamic>;
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  /// Wrong answer: review again tomorrow. Right answer: push the next review
  /// further out (1, 3, 7, 14 days), then retire the lesson from the list.
  void _recordReview(String childId, String lessonId, bool correct) {
    final Map<String, dynamic> m = _srLoad(childId);
    final Map<String, dynamic>? cur = m[lessonId] as Map<String, dynamic>?;
    int step = correct ? ((cur?['step'] as int?) ?? -1) + 1 : 0;
    if (correct && cur == null) step = 1; // first success: review in 3 days
    if (step >= _srDays.length) {
      m.remove(lessonId);
    } else {
      final DateTime due = DateTime.now().add(Duration(days: _srDays[step]));
      m[lessonId] = {'step': step, 'due': due.toIso8601String()};
    }
    _prefs.setString('sr_$childId', jsonEncode(m));
  }

  /// Puts lessons whose review date has come back at the top of the child's
  /// recommended list (the adaptive engine already puts these first).
  void applyDueReviews() {
    final child = currentAccount?.activeChild;
    if (child == null) return;
    final Map<String, dynamic> m = _srLoad(child.id);
    final DateTime now = DateTime.now();
    bool changed = false;
    m.forEach((String id, dynamic v) {
      final DateTime? due = DateTime.tryParse(((v as Map)['due'] ?? '').toString());
      if (due != null &&
          !due.isAfter(now) &&
          !child.needsRemediationLessonIds.contains(id)) {
        child.needsRemediationLessonIds.add(id);
        changed = true;
      }
    });
    if (changed) {
      _saveAccounts();
      notifyListeners();
    }
  }

  Future<int> claimDailyStreak() async {
    final child = currentAccount?.activeChild;
    if (child == null) return 0;
    final String kDay = 'streak_day_${child.id}';
    final String kCnt = 'streak_count_${child.id}';
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final String? last = _prefs.getString(kDay);
    int count = _prefs.getInt(kCnt) ?? 0;
    if (last != null) {
      final DateTime? d = DateTime.tryParse(last);
      if (d != null) {
        final int gap = today.difference(d).inDays;
        if (gap <= 0) return 0;
        count = gap == 1 ? count + 1 : 1;
      } else {
        count = 1;
      }
    } else {
      count = 1;
    }
    await _prefs.setString(kDay, today.toIso8601String());
    await _prefs.setInt(kCnt, count);
    child.starsEarned += 1;
    await _saveAccounts();
    notifyListeners();
    return count;
  }

  int currentStreakDays() {
    final child = currentAccount?.activeChild;
    if (child == null) return 0;
    return _prefs.getInt('streak_count_${child.id}') ?? 0;
  }

  Future<bool> recordBrainGameWin({
    required String gameId,
    required String gameTitle,
    int earnedIqPoints = 15,
    int earnedStars = 2,
    String? learnedWord,
  }) async {
    if (currentAccount == null) return false;
    final child = currentAccount!.activeChild;
    final String uniqueKey = '${child.id}_game_win_$gameId';
    if (_inFlightRewardLocks.contains(uniqueKey)) return false;
    _inFlightRewardLocks.add(uniqueKey);

    try {
      final bool alreadyRewarded =
          child.completedActivities.contains(uniqueKey) ||
              child.completedActivities.contains('game_win_$gameId');

      if (learnedWord != null &&
          learnedWord.trim().isNotEmpty &&
          !child.practicedVocabulary.contains(learnedWord.trim())) {
        child.practicedVocabulary.add(learnedWord.trim());
      }

      final RegExp trailingLevel = RegExp(r'_(\d+)$');
      final m = trailingLevel.firstMatch(gameId);
      if (m != null) {
        final String baseGame = gameId.substring(0, m.start);
        final int lvl = int.tryParse(m.group(1)!) ?? 1;
        final int prevMax = child.gameProgressByGameId[baseGame] ?? 0;
        if (lvl > prevMax) {
          child.gameProgressByGameId[baseGame] = lvl;
        }
      }

      if (!alreadyRewarded) {
        child.completedActivities.add(uniqueKey);
        child.starsEarned += earnedStars;
        announceStarReward(earnedStars, 'أحسنت يا بطل! أنجزت «$gameTitle»');
        child.intelligencePoints += earnedIqPoints;
        child.gamesCompletedCount++;
        _evaluateAndUnlockChildAchievements(child);
      }

      child.currentLiveStatus = '🧠 يلعب ويتفوق في: «$gameTitle»';
      child.liveActivityTimeline.insert(
        0,
        ChildActivityLogEntry(
          timestampIso: DateTime.now().toIso8601String(),
          actionTitle: alreadyRewarded
              ? 'أعاد التدريب بنجاح في ($gameTitle) بدون تكرار النجوم'
              : 'أنجز تحدياً جديداً في ($gameTitle) وكسب +$earnedStars نجمة',
          categoryBadge: 'ألعاب الذكاء',
        ),
      );

      if (!alreadyRewarded &&
          currentAccount!.emailNotificationsEnabled &&
          child.gamesCompletedCount % 2 == 0) {
        await sendParentEmailAlert(
          subject:
              '🧠 تدرّب الطفل ${child.name} على «$gameTitle»!',
          bodyMessage:
              'أنجز ${child.name} تحدياً جديداً في لعبة ($gameTitle) وصلت نقاط اللعب لديه إلى ${child.intelligencePoints} نقطة مع ${child.starsEarned} نجمة!',
          customSuggestion:
              '💡 اقتراح تربوي: شجع ${child.name} على التنوع بين ألعاب الذاكرة البصرية والمنطق والحساب.',
        );
      }
      child.touchSyncVersion();
      await childProfileRepository.enqueueChildMutation(
        idempotencyKey: uniqueKey,
        parentEmail: currentAccount!.emailOrPhone,
        childId: child.id,
        entityType: 'game_level',
        entityId: gameId,
        operation: 'complete',
        payload: {
          'gameId': gameId,
          'gameTitle': gameTitle,
          'earnedStars': alreadyRewarded ? 0 : earnedStars,
          'earnedIqPoints': alreadyRewarded ? 0 : earnedIqPoints,
          'starsEarnedTotal': child.starsEarned,
          'intelligencePointsTotal': child.intelligencePoints,
          'syncVersionSeq': child.syncVersionSeq,
        },
      );
      await _saveAccounts();
      notifyListeners();
      if (supabaseRemoteDataSource.canConnectToSupabase) {
        unawaited(syncPendingChangesWithSupabase());
      }
      return !alreadyRewarded;
    } finally {
      _inFlightRewardLocks.remove(uniqueKey);
    }
  }

  void _evaluateAndUnlockChildAchievements(ChildProfile child) {
    childProfileRepository.evaluateAndUnlockAchievements(child);
    final domains = EducationalAiTutorService.computeDomainScores(child);
    for (final d in domains) {
      child.cognitiveSkillScoresByDomain[d.domainKey] = d.scorePercent;
    }
  }

  AiTutorRecommendation? getAiTutorRecommendation([String? childId]) {
    if (currentAccount == null) return null;
    final ChildProfile child = childId == null
        ? currentAccount!.activeChild
        : currentAccount!.children.firstWhere(
            (c) => c.id == childId,
            orElse: () => currentAccount!.activeChild,
          );
    return EducationalAiTutorService.analyzeAndRecommendForChild(child);
  }

  Future<void> setLastActiveAcademyLesson(String lessonId) async {
    if (currentAccount == null || lessonId.trim().isEmpty) return;
    currentAccount!.activeChild.lastActiveAcademyLessonId = lessonId.trim();
    await _saveAccounts();
    await _refreshCompanionMemorySnapshot(currentAccount!.activeChild);
    notifyListeners();
  }

  Future<bool> completeAcademyLesson({
    required String lessonId,
    required String lessonTitle,
    required String learnedWord,
    int rewardStars = 2,
  }) async {
    if (currentAccount != null) {
      currentAccount!.activeChild.lastActiveAcademyLessonId = lessonId;
    }
    if (currentAccount == null) return false;
    final child = currentAccount!.activeChild;
    final String lockKey = '${child.id}_lesson_$lessonId';
    if (_inFlightRewardLocks.contains(lockKey)) return false;
    _inFlightRewardLocks.add(lockKey);

    try {
      final bool isNew = !child.completedLessons.contains(lessonId);
      if (isNew) {
        child.completedLessons.add(lessonId);
        child.starsEarned += rewardStars;
        child.intelligencePoints += 15;
      }
      child.skillMasteryByLessonId[lessonId] = 100;
      child.needsRemediationLessonIds.remove(lessonId);
      if (AdaptiveLearningEngine.canAdvanceFromTier(
        child: child,
        tierLevel: child.currentCurriculumTier,
      )) {
        child.currentCurriculumTier = (child.currentCurriculumTier + 1).clamp(1, 4);
        child.educationLevel =
            AdaptiveLearningEngine.tierShortLevelName(child.currentCurriculumTier);
      }
      if (learnedWord.trim().isNotEmpty &&
          !child.practicedVocabulary.contains(learnedWord.trim())) {
        child.practicedVocabulary.add(learnedWord.trim());
      }
      _evaluateAndUnlockChildAchievements(child);
      child.currentLiveStatus = '🎓 أكمل درساً في أكاديمية حنين: «$lessonTitle»';
      child.liveActivityTimeline.insert(
        0,
        ChildActivityLogEntry(
          timestampIso: DateTime.now().toIso8601String(),
          actionTitle: isNew
              ? 'أتم درس «$lessonTitle» في أكاديمية حنين (+$rewardStars نجمة)'
              : 'راجع درس «$lessonTitle» في أكاديمية حنين بدون تكرار النجوم',
          categoryBadge: 'أكاديمية حنين',
        ),
      );
      child.touchSyncVersion();
      await childProfileRepository.enqueueChildMutation(
        idempotencyKey: lockKey,
        parentEmail: currentAccount!.emailOrPhone,
        childId: child.id,
        entityType: 'lesson',
        entityId: lessonId,
        operation: 'complete',
        payload: {
          'lessonId': lessonId,
          'lessonTitle': lessonTitle,
          'learnedWord': learnedWord,
          'rewardStars': isNew ? rewardStars : 0,
          'starsEarnedTotal': child.starsEarned,
          'syncVersionSeq': child.syncVersionSeq,
        },
      );
      await _saveAccounts();
      await _refreshCompanionMemorySnapshot(child);
      notifyListeners();
      if (supabaseRemoteDataSource.canConnectToSupabase) {
        unawaited(syncPendingChangesWithSupabase());
      }
      return isNew;
    } finally {
      _inFlightRewardLocks.remove(lockKey);
    }
  }

  /// Phase 5: companion memory (per-child, isolated) kept in sync with the
  /// live profile. Pure persistence via SharedPreferences; no cloud AI.
  Future<void> _refreshCompanionMemorySnapshot(ChildProfile child) async {
    final CompanionMemorySnapshot prior =
        CompanionMemoryEngine.loadFrom(_prefs, child.id) ??
            CompanionMemoryEngine.syncFromChild(child);
    // Keep real completed activity + newest achievement; never invent.
    final updated = CompanionMemorySnapshot(
      childId: child.id,
      childName: child.name,
      preferredCompanion: child.gender == 'girl' ? 'girl' : 'boy',
      lastCompletedActivityId: child.completedLessons.isEmpty
          ? prior.lastCompletedActivityId
          : child.completedLessons.last,
      unfinishedLessonId: child.completedLessons
              .contains(child.lastActiveAcademyLessonId)
          ? null
          : child.lastActiveAcademyLessonId,
      unfinishedSessionStartedAtIso: child.completedLessons
              .contains(child.lastActiveAcademyLessonId)
          ? prior.unfinishedSessionStartedAtIso
          : DateTime.now().toIso8601String(),
      recentAchievements: child.unlockedAchievements.isEmpty
          ? prior.recentAchievements
          : child.unlockedAchievements.keys.take(5).map(badgeTitleAr).toList(),
      weakLessonIds:
          LessonProgressBridge.analyze(child: child).weakLessonIds,
      lastInteractionContext: 'academy',
      lastGreetingId: prior.lastGreetingId,
    );
    await CompanionMemoryEngine.saveTo(_prefs, updated);
  }

  ChildPedagogicalReport? getChildPedagogicalReport([String? childId]) {
    if (currentAccount == null) return null;
    final ChildProfile child = childId == null
        ? currentAccount!.activeChild
        : currentAccount!.children.firstWhere(
            (c) => c.id == childId,
            orElse: () => currentAccount!.activeChild,
          );
    return AdaptiveLearningEngine.buildPedagogicalReport(child);
  }

  Future<LessonAttemptEvaluationResult> recordAcademyLessonAttempt({
    required String lessonId,
    required String lessonTitle,
    required String learnedWord,
    required bool isCorrectAnswer,
    int cardsExploredCount = 3,
    bool usedAlternativeRemediation = false,
    bool practicedPronunciation = false,
    int hintLevelUsed = 0,
    bool answerRevealed = false,
  }) async {
    if (currentAccount == null) {
      return LessonAttemptEvaluationResult(
        lessonId: lessonId,
        previousMasteryScore: 0,
        newMasteryScore: 0,
        isMastered: false,
        requiresAlternativeRemediation: false,
        previousTier: 2,
        newTier: 2,
        didAdvanceTier: false,
        starsAwarded: 0,
        childEncouragementMessage: 'يرجى اختيار ملف الطفل أولاً.',
      );
    }
    final child = currentAccount!.activeChild;
    child.lastActiveAcademyLessonId = lessonId;
    final int prevScore =
        AdaptiveLearningEngine.getLessonMasteryScore(child, lessonId);
    final int prevTier = child.currentCurriculumTier;

    final int updatedScore =
        AdaptiveLearningEngine.calculateUpdatedMasteryScore(
      previousScore: prevScore,
      isCorrectAnswer: isCorrectAnswer,
      cardsExploredCount: cardsExploredCount,
      usedAlternativeRemediation: usedAlternativeRemediation,
      practicedPronunciation: practicedPronunciation,
    );
    child.skillMasteryByLessonId[lessonId] = updatedScore;

    // Phase 2: append to the per-lesson attempt ledger (latest 10 kept).
    // Pure bookkeeping — never modifies the mastery score above and never
    // lowers existing scores.
    final List<LessonAttemptRecord> existingRecords =
        child.lessonAttemptsByLessonId[lessonId] ?? const <LessonAttemptRecord>[];
    final LessonAttemptRecord record = LessonAttemptLedgerEngine.buildRecord(
      childId: child.id,
      lessonId: lessonId,
      isCorrectAnswer: isCorrectAnswer,
      usedAlternativeRemediation: usedAlternativeRemediation,
      hintLevelUsed: hintLevelUsed,
      answerRevealed: answerRevealed,
      previousOutcome: LessonAttemptLedgerEngine.lastOutcome(existingRecords),
    );
    child.lessonAttemptsByLessonId[lessonId] =
        LessonAttemptLedgerEngine.appendCapped(existingRecords, record);

    if (learnedWord.trim().isNotEmpty &&
        !child.practicedVocabulary.contains(learnedWord.trim())) {
      child.practicedVocabulary.add(learnedWord.trim());
    }

    final bool masteredNow =
        updatedScore >= AdaptiveLearningEngine.kMasteryThresholdPercent;
    _recordReview(child.id, lessonId, isCorrectAnswer);
    int awardedStars = 0;

    if (masteredNow) {
      child.needsRemediationLessonIds.remove(lessonId);
      if (!child.completedLessons.contains(lessonId)) {
        child.completedLessons.add(lessonId);
        awardedStars = 2;
        child.starsEarned += awardedStars;
        announceStarReward(awardedStars, 'أتقنت درس «$lessonTitle»');
        child.intelligencePoints += 15;
      }
    } else {
      if (!child.needsRemediationLessonIds.contains(lessonId)) {
        child.needsRemediationLessonIds.add(lessonId);
      }
    }

    bool didAdvance = false;
    if (AdaptiveLearningEngine.canAdvanceFromTier(
      child: child,
      tierLevel: child.currentCurriculumTier,
    )) {
      child.currentCurriculumTier =
          (child.currentCurriculumTier + 1).clamp(1, 4);
      child.educationLevel = AdaptiveLearningEngine.tierShortLevelName(
          child.currentCurriculumTier);
      didAdvance = child.currentCurriculumTier > prevTier;
    }

    _evaluateAndUnlockChildAchievements(child);
    final String msg = masteredNow
        ? (didAdvance
            ? '🎉 رائع يا ${child.name}! أتقنت «$lessonTitle» بنسبة $updatedScore% وترقيت إلى المستوى ${AdaptiveLearningEngine.tierLabelAr(child.currentCurriculumTier)}!'
            : '🌟 أحسنت يا ${child.name}! أتقنت مهارة «$lessonTitle» بنسبة $updatedScore%!')
        : '🎈 محاولة جميلة يا ${child.name}! هيا نجرب النشاط البديل المبسط بالصور واللعب لتثبيت المهارة معاً!';

    child.currentLiveStatus = masteredNow
        ? '🎓 أتقن درس «$lessonTitle» ($updatedScore%)'
        : '🎈 يتدرب بطريقة بديلة مبسطة في درس «$lessonTitle» ($updatedScore%)';
    child.liveActivityTimeline.insert(
      0,
      ChildActivityLogEntry(
        timestampIso: DateTime.now().toIso8601String(),
        actionTitle: masteredNow
            ? 'أتقن مهارة «$lessonTitle» بنسبة $updatedScore% (+$awardedStars نجمة)'
            : 'تدرّب على «$lessonTitle» ($updatedScore%) وتم تفعيل النشاط البديل المبسط',
        categoryBadge: 'أكاديمية حنين',
      ),
    );
    child.touchSyncVersion();
    await childProfileRepository.enqueueChildMutation(
      idempotencyKey: '${child.id}_mastery_${lessonId}_$updatedScore',
      parentEmail: currentAccount!.emailOrPhone,
      childId: child.id,
      entityType: 'lesson_mastery',
      entityId: lessonId,
      operation: 'upsert_mastery',
      payload: {
        'lessonId': lessonId,
        'masteryScore': updatedScore,
        'isMastered': masteredNow,
        'currentCurriculumTier': child.currentCurriculumTier,
        'needsRemediationLessonIds': child.needsRemediationLessonIds,
        'syncVersionSeq': child.syncVersionSeq,
      },
    );
    await _saveAccounts();
    notifyListeners();
    if (supabaseRemoteDataSource.canConnectToSupabase &&
        !CalmVoiceService.isRunningInUnitTest) {
      unawaited(syncPendingChangesWithSupabase());
    }
    return LessonAttemptEvaluationResult(
      lessonId: lessonId,
      previousMasteryScore: prevScore,
      newMasteryScore: updatedScore,
      isMastered: masteredNow,
      requiresAlternativeRemediation: !masteredNow,
      previousTier: prevTier,
      newTier: child.currentCurriculumTier,
      didAdvanceTier: didAdvance,
      starsAwarded: awardedStars,
      childEncouragementMessage: msg,
    );
  }

  Future<bool> unlockChildCosmeticWithStars({
    required String cosmeticId,
    required String cosmeticTitle,
    required int starCost,
  }) async {
    if (currentAccount == null) return false;
    final child = currentAccount!.activeChild;
    if (child.unlockedCosmetics.contains(cosmeticId)) return true;
    if (child.starsEarned < starCost) return false;
    child.starsEarned -= starCost;
    child.unlockedCosmetics.add(cosmeticId);
    child.liveActivityTimeline.insert(
      0,
      ChildActivityLogEntry(
        timestampIso: DateTime.now().toIso8601String(),
        actionTitle: 'فتح مكافأة جديدة بنجومه: «$cosmeticTitle»',
        categoryBadge: 'عالم المكافآت',
      ),
    );
    await _saveAccounts();
    notifyListeners();
    return true;
  }

  Future<void> toggleFavoriteInteractiveStory(String storyId) async {
    if (currentAccount == null) return;
    final child = currentAccount!.activeChild;
    if (child.favoriteStoryIds.contains(storyId)) {
      child.favoriteStoryIds.remove(storyId);
    } else {
      child.favoriteStoryIds.add(storyId);
    }
    await _saveAccounts();
    notifyListeners();
  }

  Future<void> updateChildPrivacyAndSafetyControls({
    required String childId,
    String? educationLevel,
    bool? allowMicrophone,
    bool? allowExternalVideos,
    bool? offlineOnlyMode,
    bool? reduceMotion,
    bool? highContrastMode,
    bool? allowSoundEffectsAndVoice,
    bool? lowMemoryPerformanceMode,
    String? preferredVoicePersonaId,
    String? preferredVoiceDialect,
    double? preferredVoiceSpeed,
  }) async {
    if (currentAccount == null) return;
    final idx = currentAccount!.children.indexWhere((c) => c.id == childId);
    if (idx == -1) return;
    final child = currentAccount!.children[idx];
    if (educationLevel != null) child.educationLevel = educationLevel;
    if (allowMicrophone != null) {
      child.allowMicrophone = allowMicrophone;
      if (child.id == currentAccount!.activeChildId) {
        await CalmVoiceService.instance
            .setChildMicrophoneAllowed(allowMicrophone);
      }
    }
    if (allowExternalVideos != null) {
      child.allowExternalVideos = allowExternalVideos;
      if (child.id == currentAccount!.activeChildId) {
        AppNetworkPolicyGuard.isExternalVideosAllowed = allowExternalVideos;
      }
    }
    if (offlineOnlyMode != null) {
      child.offlineOnlyMode = offlineOnlyMode;
      if (child.id == currentAccount!.activeChildId) {
        AppNetworkPolicyGuard.isOfflineOnlyModeActive = offlineOnlyMode;
      }
    }
    if (reduceMotion != null) {
      child.reduceMotion = reduceMotion;
      if (child.id == currentAccount!.activeChildId) {
        AppNetworkPolicyGuard.reduceMotionActive = reduceMotion;
      }
    }
    if (highContrastMode != null) {
      child.highContrastMode = highContrastMode;
      if (child.id == currentAccount!.activeChildId) {
        AppNetworkPolicyGuard.highContrastActive = highContrastMode;
      }
    }
    if (allowSoundEffectsAndVoice != null) {
      child.allowSoundEffectsAndVoice = allowSoundEffectsAndVoice;
      if (child.id == currentAccount!.activeChildId) {
        AppNetworkPolicyGuard.soundAndVoiceActive = allowSoundEffectsAndVoice;
        await CalmVoiceService.instance
            .setSoundAndVoiceEnabled(allowSoundEffectsAndVoice);
      }
    }
    if (lowMemoryPerformanceMode != null) {
      child.lowMemoryPerformanceMode = lowMemoryPerformanceMode;
      if (child.id == currentAccount!.activeChildId) {
        AppNetworkPolicyGuard.lowMemoryPerformanceModeActive =
            lowMemoryPerformanceMode;
      }
    }
    if (preferredVoicePersonaId != null) {
      child.preferredVoicePersonaId =
          ElevenLabsVoiceService.getPersonaById(preferredVoicePersonaId).id;
    }
    if (preferredVoiceDialect != null) {
      child.preferredVoiceDialect =
          preferredVoiceDialect.trim().toLowerCase() == 'egyptian'
              ? 'egyptian'
              : 'msa';
    }
    if (preferredVoiceSpeed != null) {
      child.preferredVoiceSpeed = preferredVoiceSpeed.clamp(0.7, 1.2);
    }
    if (child.id == currentAccount!.activeChildId) {
      CalmVoiceService.instance.configureChildVoicePreferences(
        personaId: child.preferredVoicePersonaId,
        dialect: child.preferredVoiceDialect,
        speed: child.preferredVoiceSpeed,
      );
    }
    child.touchSyncVersion();
    await childProfileRepository.enqueueChildMutation(
      idempotencyKey: 'child_settings_${child.id}',
      parentEmail: currentAccount!.emailOrPhone,
      childId: child.id,
      entityType: 'child_profile',
      entityId: child.id,
      operation: 'upsert_settings',
      payload: child.toJson(),
    );
    await _saveAccounts();
    notifyListeners();
    if (supabaseRemoteDataSource.canConnectToSupabase &&
        !CalmVoiceService.isRunningInUnitTest) {
      unawaited(syncPendingChangesWithSupabase());
    }
  }

  Future<void> clearChildActivityHistoryOnly(String childId) async {
    if (currentAccount == null) return;
    final idx = currentAccount!.children.indexWhere((c) => c.id == childId);
    if (idx == -1) return;
    final child = currentAccount!.children[idx];
    child.usedMinutesToday = 0;
    child.watchedVideosToday = 0;
    child.currentLiveStatus = 'متصل — تم مسح سجل النشاط الزمني فقط';
    child.liveActivityTimeline = [
      ChildActivityLogEntry(
        timestampIso: DateTime.now().toIso8601String(),
        actionTitle:
            'تم مسح سجل النشاط الزمني فقط مع الاحتفاظ بالدروس والنجوم والأوسمة',
        categoryBadge: 'سجل النشاط',
      ),
    ];
    child.touchSyncVersion();
    await childProfileRepository.clearActivityHistoryOnServerAndQueue(
      parentEmail: currentAccount!.emailOrPhone,
      sessionAccessToken: currentAccount!.sessionAccessToken,
      childId: child.id,
    );
    await _saveAccounts();
    notifyListeners();
  }

  Future<void> deleteAllChildPersonalAndEducationalData(
    String childId, {
    bool removeProfileIfMultipleChildren = false,
  }) async {
    if (currentAccount == null) return;
    final idx = currentAccount!.children.indexWhere((c) => c.id == childId);
    if (idx == -1) return;

    if (removeProfileIfMultipleChildren &&
        currentAccount!.children.length > 1) {
      currentAccount!.children.removeAt(idx);
      if (currentAccount!.activeChildId == childId) {
        currentAccount!.activeChildId = currentAccount!.children.first.id;
      }
      _syncLikedStateForActiveChild();
      await _saveAccounts();
      notifyListeners();
      return;
    }

    final child = currentAccount!.children[idx];
    child.starsEarned = 0;
    child.intelligencePoints = 0;
    child.gamesCompletedCount = 0;
    child.correctPronunciationsCount = 0;
    child.usedMinutesToday = 0;
    child.watchedVideosToday = 0;
    child.educationLevel = 'مبتدئ';
    child.completedActivities.clear();
    child.completedLessons.clear();
    child.skillMasteryByLessonId.clear();
    child.needsRemediationLessonIds.clear();
    child.cognitiveSkillScoresByDomain.clear();
    child.currentCurriculumTier = AdaptiveLearningEngine.inferInitialTier(
      ageGroup: child.age,
      educationLevel: 'مبتدئ',
    );
    child.unlockedAchievements.clear();
    child.unlockedCosmetics = ['hero_crown_basic'];
    child.favoriteStoryIds.clear();
    child.practicedVocabulary.clear();
    child.gameProgressByGameId.clear();
    child.likedVideoIds.clear();
    child.isDeviceRemotelyLocked = false;
    child.currentLiveStatus =
        'تم حذف جميع البيانات التعليمية والشخصية المحلية لهذا الملف';
    child.liveActivityTimeline = [
      ChildActivityLogEntry(
        timestampIso: DateTime.now().toIso8601String(),
        actionTitle:
            'تم حذف جميع البيانات التعليمية والشخصية المحلية المرتبطة بهذا الطفل',
        categoryBadge: 'حذف شامل',
      ),
    ];
    child.touchSyncVersion();
    await childProfileRepository.deleteAllChildDataOnServerAndQueue(
      parentEmail: currentAccount!.emailOrPhone,
      sessionAccessToken: currentAccount!.sessionAccessToken,
      childId: child.id,
      removeProfile: false,
    );
    _syncLikedStateForActiveChild();
    await _saveAccounts();
    await _saveVideos();
    notifyListeners();
  }

  Future<void> clearChildActivityAndResetProgress(String childId) async {
    await deleteAllChildPersonalAndEducationalData(childId);
  }

  Future<bool> awardStarAndRecordActivity(
    String activityKey, {
    bool isPronunciation = false,
    String? practicedWord,
  }) async {
    if (currentAccount == null) return false;
    final child = currentAccount!.activeChild;
    final String scopedKey = '${child.id}_act_$activityKey';
    if (_inFlightRewardLocks.contains(scopedKey)) return false;
    _inFlightRewardLocks.add(scopedKey);

    try {
      final bool isFirstTime = !child.completedActivities.contains(scopedKey) &&
          !child.completedActivities.contains(activityKey);
      if (practicedWord != null &&
          practicedWord.trim().isNotEmpty &&
          !child.practicedVocabulary.contains(practicedWord.trim())) {
        child.practicedVocabulary.add(practicedWord.trim());
      }
      if (isFirstTime) {
        child.completedActivities.add(scopedKey);
        child.starsEarned++;
        announceStarReward(1, 'نجمة جديدة! عمل رائع');
        if (isPronunciation) {
          child.correctPronunciationsCount++;
        }
        _evaluateAndUnlockChildAchievements(child);
        if (currentAccount!.emailNotificationsEnabled &&
            child.starsEarned % 3 == 0) {
          await sendParentEmailAlert(
            subject:
                '🌟 إنجاز جديد للبطل ${child.name} — وصل إلى ${child.starsEarned} نجوم!',
            bodyMessage:
                'أحرز ${child.name} تقدماً رائعاً في الفصاحة والأنشطة التربوية وجمع الآن ${child.starsEarned} نجوم.',
          );
        }
      }
      await _saveAccounts();
      notifyListeners();
      return isFirstTime;
    } finally {
      _inFlightRewardLocks.remove(scopedKey);
    }
  }

  Future<void> toggleLikeVideo(VideoModel video) async {
    if (currentAccount == null) return;
    final child = currentAccount!.activeChild;
    if (video.isLiked) {
      video.isLiked = false;
      video.likes = max(0, video.likes - 1);
      child.likedVideoIds.remove(video.id);
    } else {
      video.isLiked = true;
      video.likes++;
      if (!child.likedVideoIds.contains(video.id)) {
        child.likedVideoIds.add(video.id);
      }
    }
    await _saveAccounts();
    await _saveVideos();
    notifyListeners();
  }

  List<VideoModel> get childApprovedVideos => videos
      .where((v) => v.isApprovedByParent && !v.isBrokenStream)
      .toList();

  List<VideoModel> get pendingApprovalVideos =>
      videos.where((v) => !v.isApprovedByParent).toList();

  Future<void> approveVideoForChildFeed(String videoId) async {
    final int idx = videos.indexWhere((v) => v.id == videoId);
    if (idx == -1) return;
    videos[idx].isApprovedByParent = true;
    videos[idx].isBrokenStream = false;
    await _saveVideos();
    notifyListeners();
  }

  Future<void> approveAllPendingVideos() async {
    for (final v in videos) {
      v.isApprovedByParent = true;
    }
    await _saveVideos();
    notifyListeners();
  }

  Future<void> markVideoStreamBroken(String videoId,
      {bool isBroken = true}) async {
    final int idx = videos.indexWhere((v) => v.id == videoId);
    if (idx == -1) return;
    videos[idx].isBrokenStream = isBroken;
    await _saveVideos();
    notifyListeners();
  }

  Future<bool> addCustomVideo(
    VideoModel newVideo, {
    bool approvedByParent = true,
  }) async {
    final String rawStream = newVideo.streamUrl.trim();
    if (rawStream.isEmpty) return false;
    final bool isLocalFile = AppNetworkPolicyGuard.isSafeLocalFilePath(rawStream);
    final activeChild = currentAccount?.activeChild;

    if (!isLocalFile) {
      if (activeChild != null &&
          (!activeChild.allowExternalVideos || activeChild.offlineOnlyMode)) {
        return false;
      }
      if (!AppNetworkPolicyGuard.isTrustedHttpsVideoOrFeedUrl(rawStream)) {
        return false;
      }
    }

    newVideo.isApprovedByParent = approvedByParent;
    videos.insert(0, newVideo);
    _syncLikedStateForActiveChild();
    await _saveVideos();
    notifyListeners();
    return true;
  }

  Future<List<VideoModel>> smartAutoImportFromAnyUrlOrPlaylist(
    String rawUrl, {
    bool forceChannelOrPlaylistMode = false,
    bool approveImmediately = false,
  }) async {
    final String trimmed = rawUrl.trim();
    if (trimmed.isEmpty) return [];
    final bool isLocalFile = AppNetworkPolicyGuard.isSafeLocalFilePath(trimmed);
    final activeChild = currentAccount?.activeChild;

    if (!isLocalFile) {
      if ((activeChild?.offlineOnlyMode ?? false) ||
          !(activeChild?.allowExternalVideos ?? true) ||
          !AppNetworkPolicyGuard.canPerformOutboundNetworkRequest(
              isVideoImportOrStream: true)) {
        return [];
      }
      final String normalizedCandidate =
          (trimmed.startsWith('@') && !trimmed.contains('/'))
              ? 'https://www.tiktok.com/$trimmed'
              : trimmed;
      if (!AppNetworkPolicyGuard.isTrustedHttpsVideoOrFeedUrl(
          normalizedCandidate)) {
        return [];
      }
    }

    final bool isMulti = forceChannelOrPlaylistMode ||
        await SmartVideoLinkAutoImporter.detectIfChannelOrPlaylistUrl(trimmed);

    if (isMulti) {
      final List<VideoModel> importedBatch =
          await SmartVideoLinkAutoImporter.autoImportChannelOrPlaylistFromUrl(
        trimmed,
        maxVideosToImport: 8,
      );
      if (importedBatch.isNotEmpty) {
        for (final v in importedBatch.reversed) {
          v.isApprovedByParent = approveImmediately;
          videos.insert(0, v);
        }
        _syncLikedStateForActiveChild();
        await _saveVideos();
        notifyListeners();
      }
      return importedBatch;
    } else {
      final VideoModel? generatedVideo =
          await SmartVideoLinkAutoImporter.autoImportAndGenerateFromUrl(trimmed);
      if (generatedVideo != null) {
        generatedVideo.isApprovedByParent = approveImmediately;
        videos.insert(0, generatedVideo);
        _syncLikedStateForActiveChild();
        await _saveVideos();
        notifyListeners();
        return [generatedVideo];
      }
      return [];
    }
  }

  Future<void> deleteVideo(String videoId) async {
    if (videos.length <= 1) return;
    videos.removeWhere((v) => v.id == videoId);
    await _saveVideos();
    notifyListeners();
  }

  Future<void> restoreDefaultVideos() async {
    videos = getDefaultVideos();
    _syncLikedStateForActiveChild();
    await _saveVideos();
    notifyListeners();
  }

  Future<void> updateAuthApiUrl(String url) async {
    authApiUrl = url.trim();
    await _prefs.setString('auth_api_url', authApiUrl);
    notifyListeners();
  }

  Future<void> updateEmailWebhookUrl(String url) async {
    emailWebhookUrl = url.trim();
    await _prefs.setString('email_webhook_url', emailWebhookUrl);
    notifyListeners();
  }

  Future<bool> syncVideosFromRemoteUrl(String url) async {
    final cleanUrl = url.trim();
    if (cleanUrl.isEmpty) {
      lastSyncMessage = 'يرجى إدخال رابط ملف JSON سحابي صالح.';
      notifyListeners();
      return false;
    }

    final activeChild = currentAccount?.activeChild;
    if ((activeChild?.offlineOnlyMode ?? false) ||
        !AppNetworkPolicyGuard.canPerformOutboundNetworkRequest(
            isVideoImportOrStream: true)) {
      lastSyncMessage =
          '🔒 تم حظر الاتصال السحابي لأن «وضع عدم الاتصال (Offline Mode)» أو «منع الفيديوهات الخارجية» مفعّل حالياً.';
      notifyListeners();
      return false;
    }

    if (!AppNetworkPolicyGuard.isTrustedHttpsVideoOrFeedUrl(cleanUrl)) {
      lastSyncMessage =
          '🔒 لأسباب أمنية، يُسمح فقط بروابط HTTPS من النطاقات السحابية الموثوقة المعتمدة.';
      notifyListeners();
      return false;
    }

    isSyncingVideos = true;
    lastSyncMessage = 'جاري الاتصال بالسحابة عبر HTTPS وسحب تغذية الفيديوهات...';
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse(cleanUrl),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final String body = utf8.decode(response.bodyBytes);
        final dynamic decoded = jsonDecode(body);

        List<dynamic>? rawList;
        if (decoded is List) {
          rawList = decoded;
        } else if (decoded is Map<String, dynamic> &&
            decoded['videos'] is List) {
          rawList = decoded['videos'] as List<dynamic>;
        } else if (decoded is Map<String, dynamic> && decoded['data'] is List) {
          rawList = decoded['data'] as List<dynamic>;
        }

        if (rawList != null && rawList.isNotEmpty) {
          final fetched = rawList
              .map((item) {
                final v = VideoModel.fromJson(
                    Map<String, dynamic>.from(item as Map));
                v.isApprovedByParent = false;
                return v;
              })
              .where((v) =>
                  v.streamUrl.trim().isNotEmpty &&
                  AppNetworkPolicyGuard.isSecureHttpsOrLocalFile(v.streamUrl))
              .toList();

          if (fetched.isNotEmpty) {
            videos = fetched;
            remoteFeedUrl = cleanUrl;
            await _prefs.setString('remote_feed_url', remoteFeedUrl);
            _syncLikedStateForActiveChild();
            await _saveVideos();
            isSyncingVideos = false;
            lastSyncMessage =
                'تم بنجاح مزامنة واستقبال ${fetched.length} فيديو من الرابط السحابي!';
            notifyListeners();
            return true;
          }
        }
        isSyncingVideos = false;
        lastSyncMessage =
            'تم الاتصال ولكن لم يتم العثور على قائمة فيديوهات صالحة داخل ملف JSON.';
        notifyListeners();
        return false;
      } else {
        isSyncingVideos = false;
        lastSyncMessage =
            'تعذر الجلب من الرابط السحابي (كود الاستجابة: ${response.statusCode}).';
        notifyListeners();
        return false;
      }
    } catch (_) {
      isSyncingVideos = false;
      lastSyncMessage =
          'تعذر الاتصال بالرابط: تأكد من اتصال الإنترنت وصحة رابط ملف JSON.';
      notifyListeners();
      return false;
    }
  }

  /// Saves the companion avatar customization for the active child
  Future<void> saveCompanionAvatar(AvatarCustomizationModel avatar) async {
    final child = currentAccount?.activeChild;
    if (child == null) return;
    child.companionAvatar = avatar;
    child.touchSyncVersion();
    await _saveAccounts();
    notifyListeners();
  }

  /// Spends stars to unlock a companion cosmetic item
  Future<bool> unlockCompanionItem(String itemId, int cost) async {
    final child = currentAccount?.activeChild;
    if (child == null || child.starsEarned < cost) return false;
    if (child.companionAvatar.isItemUnlocked(itemId)) return true;
    child.starsEarned -= cost;
    if (!child.companionAvatar.unlockedItems.contains(itemId)) {
      child.companionAvatar.unlockedItems.add(itemId);
    }
    child.touchSyncVersion();
    await _saveAccounts();
    notifyListeners();
    return true;
  }

  /// Whether the character shop is enabled (can be disabled by parent in Parental Studio)
  bool get isCompanionShopEnabled => !featureFlags.disableCompanionShop;

  /// Toggles companion shop enabled/disabled from parental controls
  Future<void> setCompanionShopEnabled(bool enabled) async {
    await featureFlags.setFlag('disable_companion_shop', !enabled, prefs: _prefs);
    notifyListeners();
  }

  String exportVideosAsJson() {
    final map = {
      'app': 'Haneen Kids v2.5',
      'version': 25,
      'updatedAt': DateTime.now().toIso8601String(),
      'videos': videos.map((v) => v.toJson()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(map);
  }

  @override
  void notifyListeners() {
    if (_isDisposed) return;
    super.notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _screenTimeTimer?.cancel();
    _remoteLockTimer?.cancel();
    super.dispose();
  }
}
