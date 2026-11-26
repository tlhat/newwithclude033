import 'dart:math';
import 'package:haneen_kids_vod/haneen_kids_exports.dart';

class ParentEmailAlertItem {
  final String id;
  final String recipientEmail;
  final String subject;
  final String bodyMessage;
  final String smartImprovementSuggestion;
  final DateTime sentAt;
  final bool deliveredToCloud;

  ParentEmailAlertItem({
    required this.id,
    required this.recipientEmail,
    required this.subject,
    required this.bodyMessage,
    required this.smartImprovementSuggestion,
    required this.sentAt,
    this.deliveredToCloud = false,
  });

  factory ParentEmailAlertItem.fromJson(Map<String, dynamic> json) {
    return ParentEmailAlertItem(
      id: (json['id'] ?? '').toString(),
      recipientEmail: (json['recipientEmail'] ?? '').toString(),
      subject: (json['subject'] ?? '').toString(),
      bodyMessage: (json['bodyMessage'] ?? '').toString(),
      smartImprovementSuggestion:
          (json['smartImprovementSuggestion'] ?? '').toString(),
      sentAt: DateTime.tryParse(json['sentAt']?.toString() ?? '') ??
          DateTime.now(),
      deliveredToCloud: json['deliveredToCloud'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'recipientEmail': recipientEmail,
      'subject': subject,
      'bodyMessage': bodyMessage,
      'smartImprovementSuggestion': smartImprovementSuggestion,
      'sentAt': sentAt.toIso8601String(),
      'deliveredToCloud': deliveredToCloud,
    };
  }
}

class ParentAccount {
  static const int kUnifiedParentalPinLength = 6;
  static bool isValidParentalPinFormat(String pin) => RegExp(r'^\d{6}$').hasMatch(pin.trim());

  String accountUid;
  String registeredClientIpHash;
  String fullName;
  String emailOrPhone;
  String credentialSalt;
  String pinSalt;
  String passwordHash;
  String pinHash;
  String authProvider;
  bool warmEveningFilter;
  bool emailNotificationsEnabled;
  bool dailySmartSuggestionsEnabled;
  bool voiceAssistantEnabled;
  String subscriptionPlanId;
  DateTime trialStartDate;
  DateTime subscriptionExpiryDate;
  String sessionAccessToken;
  String activeEntitlementReceiptId;
  String entitlementSignature;
  String backendEntitlementToken;
  bool _isBackendConfirmedPaidEntitlement = false;
  bool get isBackendConfirmedPaidEntitlement =>
      _isBackendConfirmedPaidEntitlement;
  bool hasUsedFreeTrial;
  int failedPinAttempts;
  DateTime? pinLockoutUntil;
  int failedPasswordAttempts;
  DateTime? passwordLockoutUntil;
  List<ChildProfile> children;
  String get activeChildId => _activeChildId;
  set activeChildId(String value) => _activeChildId = value;
  String _activeChildId;
  List<PaymentTransactionRecord> paymentHistory;
  List<ParentEmailAlertItem> emailAlertsLog;

  ParentAccount({
    String? accountUid,
    this.registeredClientIpHash = '',
    required this.fullName,
    required this.emailOrPhone,
    String? credentialSalt,
    String? pinSalt,
    String? passwordHash,
    String? password,
    String? pinHash,
    String? parentalPin,
    this.authProvider = 'email',
    this.warmEveningFilter = false,
    this.emailNotificationsEnabled = true,
    this.dailySmartSuggestionsEnabled = true,
    this.voiceAssistantEnabled = true,
    this.subscriptionPlanId = 'trial_1day',
    DateTime? trialStartDate,
    DateTime? subscriptionExpiryDate,
    this.sessionAccessToken = '',
    this.activeEntitlementReceiptId = '',
    String? entitlementSignature,
    this.backendEntitlementToken = '',
    this.hasUsedFreeTrial = true,
    this.failedPinAttempts = 0,
    this.pinLockoutUntil,
    this.failedPasswordAttempts = 0,
    this.passwordLockoutUntil,
    required this.children,
    required String activeChildId,
    List<PaymentTransactionRecord>? paymentHistory,
    List<ParentEmailAlertItem>? emailAlertsLog,
  })  : accountUid = (accountUid != null && accountUid.trim().isNotEmpty)
            ? accountUid.trim()
            : 'uid_${emailOrPhone.trim().toLowerCase().hashCode.abs()}',
        credentialSalt = '',
        pinSalt = '',
        passwordHash = '',
        pinHash = '',
        _activeChildId = activeChildId,
        trialStartDate = trialStartDate ?? DateTime.now(),
        subscriptionExpiryDate = subscriptionExpiryDate ??
            (trialStartDate ?? DateTime.now()).add(const Duration(days: 7)),
        entitlementSignature = entitlementSignature ?? '',
        paymentHistory = paymentHistory ?? [],
        emailAlertsLog = emailAlertsLog ?? [] {
    final String resolvedPwdSalt =
        (credentialSalt != null && credentialSalt.trim().isNotEmpty)
            ? credentialSalt.trim()
            : LocalCredentialSecurityService.generateRandomSalt();
    String resolvedPinSalt = (pinSalt != null && pinSalt.trim().isNotEmpty)
        ? pinSalt.trim()
        : LocalCredentialSecurityService.generateRandomSalt();
    if (resolvedPinSalt == resolvedPwdSalt) {
      resolvedPinSalt = LocalCredentialSecurityService.generateRandomSalt();
    }
    this.credentialSalt = resolvedPwdSalt;
    this.pinSalt = resolvedPinSalt;

    this.passwordHash = _initSecretHash(
      rawOrHash: passwordHash ?? password ?? '',
      salt: this.credentialSalt,
    );
    this.pinHash = _initPinSecretHash(
      rawOrHash: pinHash ?? parentalPin ?? '123456',
      salt: this.pinSalt,
      accountEmail: this.emailOrPhone,
    );

    if (this.entitlementSignature.trim().isEmpty &&
        (this.subscriptionPlanId == 'free_forever' ||
            this.subscriptionPlanId == 'trial_1day' ||
            this.subscriptionPlanId == 'trial_7days')) {
      this.entitlementSignature =
          SubscriptionEntitlementSecurityService.computeLocalCacheTamperSeal(
        emailOrPhone: this.emailOrPhone,
        planId: this.subscriptionPlanId,
        trialStartIso: this.trialStartDate.toIso8601String(),
        expiryIso: this.subscriptionExpiryDate.toIso8601String(),
        activeReceiptId: this.activeEntitlementReceiptId,
        hasUsedFreeTrial: this.hasUsedFreeTrial,
      );
    }

    _reconcileWithKeystoreLockoutVault();
  }

  static String _initSecretHash({
    required String rawOrHash,
    required String salt,
  }) {
    final String trimmed = rawOrHash.trim();
    if (trimmed.isEmpty) return '';
    if (LocalCredentialSecurityService.isFormattedHash(trimmed)) {
      return trimmed;
    }
    return LocalCredentialSecurityService.deriveKeySha256(
      secret: trimmed,
      salt: salt,
    );
  }

  static String _initPinSecretHash({
    required String rawOrHash,
    required String salt,
    required String accountEmail,
  }) {
    final String trimmed = rawOrHash.trim();
    if (trimmed.isEmpty) return '';
    if (LocalCredentialSecurityService.isFormattedHash(trimmed)) {
      return trimmed;
    }
    return LocalCredentialSecurityService.deriveKeystorePepperedPin(
      rawPin: trimmed,
      pinSalt: salt,
      accountEmail: accountEmail,
    );
  }

  bool applyVerifiedBackendEntitlement(BackendEntitlementResponse response) {
    final String normEmail = emailOrPhone.trim().toLowerCase();
    if (response.authenticatedAccountEmail.trim().toLowerCase() != normEmail) {
      return false;
    }
    if (!response.isVerifiedAndActive ||
        response.lifecycleStatus != 'active' ||
        !response.webhookSignatureVerified ||
        response.currency.toUpperCase() != 'EGP' ||
        response.backendEntitlementToken.trim().isEmpty ||
        response.expiryDate == null ||
        !response.expiryDate!.isAfter(DateTime.now())) {
      _isBackendConfirmedPaidEntitlement = false;
      backendEntitlementToken = '';
      if (response.lifecycleStatus == 'refunded' ||
          response.lifecycleStatus == 'cancelled') {
        PaymentTransactionRecord? updatedTx;
        for (int i = 0; i < paymentHistory.length; i++) {
          final tx = paymentHistory[i];
          if (tx.id == activeEntitlementReceiptId ||
              tx.id == response.transactionId) {
            updatedTx = PaymentTransactionRecord(
              id: tx.id,
              planId: tx.planId,
              planTitle: tx.planTitle,
              amountEgp: tx.amountEgp,
              currency: tx.currency,
              paymentMethodId: tx.paymentMethodId,
              paymentMethodName: tx.paymentMethodName,
              payerIdentifier: tx.payerIdentifier,
              referenceCode: tx.referenceCode,
              status: response.lifecycleStatus,
              failureReason: 'تم إلغاء أو استرداد العملية من الخادم',
              createdAt: DateTime.now(),
              webhookSignatureVerified: false,
              receiptSignature: '',
            );
            paymentHistory.removeAt(i);
            break;
          }
        }
        if (updatedTx != null) {
          paymentHistory.insert(0, updatedTx);
        }
        subscriptionExpiryDate =
            DateTime.now().subtract(const Duration(seconds: 1));
      }
      return false;
    }

    subscriptionPlanId = response.planId;
    subscriptionExpiryDate = response.expiryDate!;
    activeEntitlementReceiptId = response.transactionId;
    backendEntitlementToken = response.backendEntitlementToken;
    _isBackendConfirmedPaidEntitlement = true;
    entitlementSignature =
        SubscriptionEntitlementSecurityService.computeLocalCacheTamperSeal(
      emailOrPhone: emailOrPhone,
      planId: subscriptionPlanId,
      trialStartIso: trialStartDate.toIso8601String(),
      expiryIso: subscriptionExpiryDate.toIso8601String(),
      activeReceiptId: activeEntitlementReceiptId,
      hasUsedFreeTrial: hasUsedFreeTrial,
    );
    return true;
  }

  static Duration computeProgressiveLockoutDuration(int failedAttempts) {
    if (failedAttempts >= 7) return const Duration(seconds: 600);
    if (failedAttempts >= 5) return const Duration(seconds: 120);
    if (failedAttempts >= 3) return const Duration(seconds: 30);
    return Duration.zero;
  }

  void _reconcileWithKeystoreLockoutVault() {
    final LockoutVaultSnapshot? vault =
        LocalCredentialSecurityService.readLockoutFromKeystoreVault(
            emailOrPhone);
    if (vault == null) return;
    if (vault.failedPinAttempts > failedPinAttempts) {
      failedPinAttempts = vault.failedPinAttempts;
    }
    if (vault.pinLockoutUntil != null &&
        (pinLockoutUntil == null ||
            vault.pinLockoutUntil!.isAfter(pinLockoutUntil!))) {
      pinLockoutUntil = vault.pinLockoutUntil;
    }
    if (vault.failedPasswordAttempts > failedPasswordAttempts) {
      failedPasswordAttempts = vault.failedPasswordAttempts;
    }
    if (vault.passwordLockoutUntil != null &&
        (passwordLockoutUntil == null ||
            vault.passwordLockoutUntil!.isAfter(passwordLockoutUntil!))) {
      passwordLockoutUntil = vault.passwordLockoutUntil;
    }
  }

  void _syncLockoutToKeystoreVault() {
    LocalCredentialSecurityService.persistLockoutToKeystoreVault(
      emailOrPhone: emailOrPhone,
      failedPinAttempts: failedPinAttempts,
      pinLockoutUntil: pinLockoutUntil,
      failedPasswordAttempts: failedPasswordAttempts,
      passwordLockoutUntil: passwordLockoutUntil,
    );
  }

  void applyServerLockout(Duration duration, {bool lockPinToo = true}) {
    final DateTime until = DateTime.now().add(duration);
    passwordLockoutUntil = until;
    failedPasswordAttempts = max(failedPasswordAttempts, 5);
    if (lockPinToo) {
      pinLockoutUntil = until;
      failedPinAttempts = max(failedPinAttempts, 5);
    }
    _syncLockoutToKeystoreVault();
  }

  bool get isPasswordLockedOut {
    _reconcileWithKeystoreLockoutVault();
    if (passwordLockoutUntil == null) return false;
    return DateTime.now().isBefore(passwordLockoutUntil!);
  }

  int get remainingPasswordLockoutSeconds {
    if (!isPasswordLockedOut) return 0;
    return max(
        1, passwordLockoutUntil!.difference(DateTime.now()).inSeconds);
  }

  bool get isPinLockedOut {
    _reconcileWithKeystoreLockoutVault();
    if (pinLockoutUntil == null) return false;
    return DateTime.now().isBefore(pinLockoutUntil!);
  }

  int get remainingPinLockoutSeconds {
    if (!isPinLockedOut) return 0;
    return max(1, pinLockoutUntil!.difference(DateTime.now()).inSeconds);
  }

  void _recordFailedPasswordAttempt() {
    _reconcileWithKeystoreLockoutVault();
    failedPasswordAttempts++;
    final Duration lockDur =
        computeProgressiveLockoutDuration(failedPasswordAttempts);
    if (lockDur > Duration.zero) {
      passwordLockoutUntil = DateTime.now().add(lockDur);
    }
    _syncLockoutToKeystoreVault();
  }

  void _recordFailedPinAttempt() {
    _reconcileWithKeystoreLockoutVault();
    failedPinAttempts++;
    final Duration lockDur =
        computeProgressiveLockoutDuration(failedPinAttempts);
    if (lockDur > Duration.zero) {
      pinLockoutUntil = DateTime.now().add(lockDur);
    }
    _syncLockoutToKeystoreVault();
  }

  bool verifyPassword(String enteredPassword) {
    if (isPasswordLockedOut) {
      return false;
    }
    final bool ok = LocalCredentialSecurityService.verifySecret(
      inputSecret: enteredPassword,
      storedHashOrLegacy: passwordHash,
      fallbackSalt: credentialSalt,
    );
    if (!ok) {
      _recordFailedPasswordAttempt();
      return false;
    }
    failedPasswordAttempts = 0;
    passwordLockoutUntil = null;
    _syncLockoutToKeystoreVault();
    if (LocalCredentialSecurityService.needsIterationUpgrade(passwordHash)) {
      passwordHash = LocalCredentialSecurityService.deriveKeySha256(
        secret: enteredPassword.trim(),
        salt: credentialSalt,
        iterations: LocalCredentialSecurityService.kDefaultPbkdf2Iterations,
      );
    }
    return true;
  }

  void setNewPassword(String newRawPassword) {
    credentialSalt = LocalCredentialSecurityService.generateRandomSalt();
    if (credentialSalt == pinSalt) {
      credentialSalt = LocalCredentialSecurityService.generateRandomSalt();
    }
    passwordHash = LocalCredentialSecurityService.deriveKeySha256(
      secret: newRawPassword.trim(),
      salt: credentialSalt,
      iterations: LocalCredentialSecurityService.kDefaultPbkdf2Iterations,
    );
    failedPasswordAttempts = 0;
    passwordLockoutUntil = null;
    _syncLockoutToKeystoreVault();
  }

  bool verifyParentalPin(String enteredPin) {
    if (isPinLockedOut) {
      return false;
    }
    final bool ok = LocalCredentialSecurityService.verifySecret(
      inputSecret: enteredPin,
      storedHashOrLegacy: pinHash,
      fallbackSalt: pinSalt,
      accountEmail: emailOrPhone,
    );
    if (!ok) {
      _recordFailedPinAttempt();
      return false;
    }
    failedPinAttempts = 0;
    pinLockoutUntil = null;
    _syncLockoutToKeystoreVault();
    if (LocalCredentialSecurityService.needsPinKeystoreUpgrade(pinHash)) {
      pinHash = LocalCredentialSecurityService.deriveKeystorePepperedPin(
        rawPin: enteredPin.trim(),
        pinSalt: pinSalt,
        accountEmail: emailOrPhone,
        iterations: LocalCredentialSecurityService.kPinPbkdf2Iterations,
      );
    }
    return true;
  }

  void setNewParentalPin(String newRawPin) {
    pinSalt = LocalCredentialSecurityService.generateRandomSalt();
    if (pinSalt == credentialSalt) {
      pinSalt = LocalCredentialSecurityService.generateRandomSalt();
    }
    pinHash = LocalCredentialSecurityService.deriveKeystorePepperedPin(
      rawPin: newRawPin.trim(),
      pinSalt: pinSalt,
      accountEmail: emailOrPhone,
      iterations: LocalCredentialSecurityService.kPinPbkdf2Iterations,
    );
    failedPinAttempts = 0;
    pinLockoutUntil = null;
    _syncLockoutToKeystoreVault();
  }

  ChildProfile get activeChild {
    if (children.isEmpty) {
      final defaultChild = ChildProfile(
        id: 'c_default',
        name: 'فارس',
        age: '3–6 سنوات',
        dailyTimeLimit: 20,
        chosenAvatar: '🦁',
      );
      children.add(defaultChild);
      activeChildId = defaultChild.id;
    }
    return children.firstWhere(
      (c) => c.id == activeChildId,
      orElse: () => children.first,
    );
  }

  bool get isGuestDemoSession =>
      authProvider == 'demo' || authProvider == 'guest';

  bool get isTrialPlan =>
      subscriptionPlanId == 'trial_1day' ||
      subscriptionPlanId == 'trial_7days';

  bool get isSubscriptionTampered =>
      !SubscriptionEntitlementSecurityService.verifyLocalCacheTamperSeal(this);

  bool get isSubscriptionActive {
    if (isSubscriptionTampered) return false;
    return DateTime.now().isBefore(subscriptionExpiryDate);
  }

  Duration get remainingSubscriptionDuration {
    if (!isSubscriptionActive) return Duration.zero;
    final diff = subscriptionExpiryDate.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  int get remainingTrialDays {
    if (!isTrialPlan || !isSubscriptionActive) return 0;
    return (remainingSubscriptionDuration.inHours / 24.0).ceil().clamp(0, 7);
  }

  String get subscriptionStatusLabel {
    if (AppStateManager.isAppCompletelyFreeForever || subscriptionPlanId == 'free_forever') {
      return '🌟 محتوى مجاني محدود. باقي القصص والألعاب والدروس بتفتح بالاشتراك';
    }
    if (isSubscriptionTampered) {
      return '⚠️ تم رصد تعديل غير مصرح به في بيانات الاشتراك المحلي (يرجى التحقق من الدفع الرسمي)';
    }
    if (!isSubscriptionActive) {
      return 'انتهت الفترة التجريبية المجانية (٧ أيام) — يرجى اختيار باقة لتجديد الاشتراك';
    }
    final rem = remainingSubscriptionDuration;
    if (isTrialPlan) {
      final int days = rem.inDays;
      final int hours = rem.inHours.remainder(24);
      if (days > 0) {
        return 'فترة تجريبية مجانية شاملة (٧ أيام — متبقي $days يوم و $hours ساعة)';
      }
      final int mins = rem.inMinutes.remainder(60);
      return 'فترة تجريبية مجانية شاملة (متبقي ${rem.inHours} ساعة و $mins دقيقة)';
    }
    final plan = kSubscriptionPlans.firstWhere(
      (p) => p.id == subscriptionPlanId,
      orElse: () => kSubscriptionPlans[2],
    );
    return '${plan.title} — سارية وموثقة (${rem.inDays + 1} يوم متبقي)';
  }

  factory ParentAccount.fromJson(Map<String, dynamic> json) {
    final childrenList = (json['children'] as List<dynamic>?)
            ?.map((c) =>
                ChildProfile.fromJson(Map<String, dynamic>.from(c as Map)))
            .toList() ??
        [
          ChildProfile(
            id: 'c1',
            name: 'فارس',
            age: '3–6 سنوات',
            dailyTimeLimit: 20,
            chosenAvatar: '🦁',
          ),
        ];

    final payments = (json['paymentHistory'] as List<dynamic>?)
            ?.map((p) => PaymentTransactionRecord.fromJson(
                Map<String, dynamic>.from(p as Map)))
            .toList() ??
        [];

    final alerts = (json['emailAlertsLog'] as List<dynamic>?)
            ?.map((a) => ParentEmailAlertItem.fromJson(
                Map<String, dynamic>.from(a as Map)))
            .toList() ??
        [];

    final DateTime parsedTrialStart =
        DateTime.tryParse(json['trialStartDate']?.toString() ?? '') ??
            DateTime.now();
    final DateTime parsedExpiry =
        DateTime.tryParse(json['subscriptionExpiryDate']?.toString() ?? '') ??
            parsedTrialStart.add(const Duration(days: 7));

    final String pwdSalt =
        (json['credentialSalt'] ?? '').toString().trim().isNotEmpty
            ? json['credentialSalt'].toString().trim()
            : LocalCredentialSecurityService.generateRandomSalt();

    final String resolvedPinSalt =
        (json['pinSalt'] ?? '').toString().trim().isNotEmpty
            ? json['pinSalt'].toString().trim()
            : LocalCredentialSecurityService.generateRandomSalt();

    final String rawOrHashedPassword =
        (json['passwordHash'] ?? json['password'] ?? '').toString();
    final String rawOrHashedPin =
        (json['pinHash'] ?? json['parentalPin'] ?? '123456').toString();

    final String parsedPlanId =
        (json['subscriptionPlanId'] ?? 'trial_1day').toString();
    final String parsedReceiptId =
        (json['activeEntitlementReceiptId'] ?? '').toString();
    final String parsedEntitlementSig =
        (json['entitlementSignature'] ?? '').toString();
    final bool parsedHasUsedTrial = json['hasUsedFreeTrial'] != false;

    String effectiveSig = parsedEntitlementSig;
    if (effectiveSig.trim().isEmpty &&
        parsedPlanId != 'free_forever' &&
        parsedPlanId != 'trial_1day' &&
        parsedPlanId != 'trial_7days') {
      effectiveSig = 'unverified_tampered_local_plan';
    }

    return ParentAccount(
      accountUid: (json['accountUid'] ?? '').toString(),
      registeredClientIpHash: (json['registeredClientIpHash'] ?? '').toString(),
      fullName: (json['fullName'] ?? 'ولي الأمر').toString(),
      emailOrPhone: (json['emailOrPhone'] ?? '').toString(),
      credentialSalt: pwdSalt,
      pinSalt: resolvedPinSalt,
      passwordHash:
          _initSecretHash(rawOrHash: rawOrHashedPassword, salt: pwdSalt),
      pinHash: _initPinSecretHash(
        rawOrHash: rawOrHashedPin,
        salt: resolvedPinSalt,
        accountEmail: (json['emailOrPhone'] ?? '').toString(),
      ),
      authProvider: (json['authProvider'] ?? 'email').toString(),
      warmEveningFilter:
          json['warmEveningFilter'] == true || json['bedtimeDimming'] == true,
      emailNotificationsEnabled: json['emailNotificationsEnabled'] != false,
      dailySmartSuggestionsEnabled:
          json['dailySmartSuggestionsEnabled'] != false,
      voiceAssistantEnabled: json['voiceAssistantEnabled'] != false,
      subscriptionPlanId: parsedPlanId,
      trialStartDate: parsedTrialStart,
      subscriptionExpiryDate: parsedExpiry,
      activeEntitlementReceiptId: parsedReceiptId,
      entitlementSignature: effectiveSig,
      backendEntitlementToken: '',
      hasUsedFreeTrial: parsedHasUsedTrial,
      failedPinAttempts:
          int.tryParse(json['failedPinAttempts']?.toString() ?? '0') ?? 0,
      pinLockoutUntil: json['pinLockoutUntil'] != null
          ? DateTime.tryParse(json['pinLockoutUntil'].toString())
          : null,
      failedPasswordAttempts:
          int.tryParse(json['failedPasswordAttempts']?.toString() ?? '0') ?? 0,
      passwordLockoutUntil: json['passwordLockoutUntil'] != null
          ? DateTime.tryParse(json['passwordLockoutUntil'].toString())
          : null,
      children: childrenList,
      activeChildId:
          (json['activeChildId'] ?? childrenList.first.id).toString(),
      paymentHistory: payments,
      emailAlertsLog: alerts,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accountUid': accountUid,
      'registeredClientIpHash': registeredClientIpHash,
      'fullName': fullName,
      'emailOrPhone': emailOrPhone,
      'credentialSalt': credentialSalt,
      'pinSalt': pinSalt,
      'passwordHash': passwordHash,
      'pinHash': pinHash,
      'authProvider': authProvider,
      'warmEveningFilter': warmEveningFilter,
      'emailNotificationsEnabled': emailNotificationsEnabled,
      'dailySmartSuggestionsEnabled': dailySmartSuggestionsEnabled,
      'voiceAssistantEnabled': voiceAssistantEnabled,
      'subscriptionPlanId': subscriptionPlanId,
      'trialStartDate': trialStartDate.toIso8601String(),
      'subscriptionExpiryDate': subscriptionExpiryDate.toIso8601String(),
      'activeEntitlementReceiptId': activeEntitlementReceiptId,
      'entitlementSignature': entitlementSignature,
      'hasUsedFreeTrial': hasUsedFreeTrial,
      'failedPinAttempts': failedPinAttempts,
      'pinLockoutUntil': pinLockoutUntil?.toIso8601String(),
      'failedPasswordAttempts': failedPasswordAttempts,
      'passwordLockoutUntil': passwordLockoutUntil?.toIso8601String(),
      'children': children.map((c) => c.toJson()).toList(),
      'activeChildId': activeChildId,
      'paymentHistory': paymentHistory.map((p) => p.toJson()).toList(),
      'emailAlertsLog': emailAlertsLog.map((a) => a.toJson()).toList(),
    };
  }
}
