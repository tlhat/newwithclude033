import 'dart:convert';
import 'package:crypto/crypto.dart' as crypto;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:haneen_kids_vod/haneen_kids_exports.dart';

class BackendEntitlementResponse {
  final bool isVerifiedAndActive;
  final String lifecycleStatus; // 'active', 'expired', 'cancelled', 'refunded'
  final String authenticatedAccountEmail;
  final String planId;
  final DateTime? expiryDate;
  final String transactionId;
  final String webhookEventId;
  final String referenceCode;
  final int verifiedAmountEgp;
  final String currency;
  final bool webhookSignatureVerified;
  final String webhookSignature;
  final String backendEntitlementToken;
  final String errorMessage;

  const BackendEntitlementResponse({
    required this.isVerifiedAndActive,
    this.lifecycleStatus = 'expired',
    this.authenticatedAccountEmail = '',
    this.planId = 'trial_1day',
    this.expiryDate,
    this.transactionId = '',
    this.webhookEventId = '',
    this.referenceCode = '',
    this.verifiedAmountEgp = 0,
    this.currency = 'EGP',
    this.webhookSignatureVerified = false,
    this.webhookSignature = '',
    this.backendEntitlementToken = '',
    this.errorMessage = '',
  });
}

class SubscriptionEntitlementSecurityService {
  /// Injectable HTTP client for deterministic unit testing of Backend payment & entitlement endpoints.
  static http.Client? httpClientOverride;

  /// Registries of already-processed transaction IDs and webhook event IDs to prevent replay.
  static final Set<String> _processedTransactionIds = {};
  static final Set<String> _processedWebhookEventIds = {};

  /// Registries of Account UIDs and Client IP hashes that have already consumed the 7-Day Free Trial.
  static final Set<String> _consumedTrialAccountUids = {};
  static final Set<String> _consumedTrialClientIpHashes = {};

  static void resetProcessedTransactionsForTesting() {
    _processedTransactionIds.clear();
    _processedWebhookEventIds.clear();
    _consumedTrialAccountUids.clear();
    _consumedTrialClientIpHashes.clear();
  }

  /// Hashes a client IP address with SHA-256 so raw IPs are never stored in plaintext while preventing trial abuse.
  static String hashClientIp(String rawIp) {
    final String cleanIp = rawIp.trim().toLowerCase();
    if (cleanIp.isEmpty) return '';
    return crypto.sha256
        .convert(utf8.encode('trial_ip_bind_v40|$cleanIp'))
        .toString();
  }

  static void _hydrateTrialRegistries(SharedPreferences? prefs) {
    if (prefs == null) return;
    final List<String>? savedUids = prefs.getStringList('consumed_trial_uids_v40');
    if (savedUids != null) {
      _consumedTrialAccountUids.addAll(savedUids);
    }
    final List<String>? savedIps = prefs.getStringList('consumed_trial_ip_hashes_v40');
    if (savedIps != null) {
      _consumedTrialClientIpHashes.addAll(savedIps);
    }
  }

  /// Enforces strict 7-Day Free Trial eligibility bound to both the registered Database UID and Client IP.
  /// Prevents trial resets without an official account or creating multiple accounts from the same IP.
  static bool isTrialEligibleForUidAndIp({
    required String accountUid,
    required String clientIp,
    SharedPreferences? prefs,
  }) {
    _hydrateTrialRegistries(prefs);
    final String cleanUid = accountUid.trim();
    if (cleanUid.isEmpty) return false;
    if (_consumedTrialAccountUids.contains(cleanUid)) return false;

    final String ipHash = hashClientIp(clientIp);
    if (ipHash.isNotEmpty && _consumedTrialClientIpHashes.contains(ipHash)) {
      return false;
    }
    return true;
  }

  static Future<void> registerTrialActivationForUidAndIp({
    required String accountUid,
    required String clientIp,
    SharedPreferences? prefs,
  }) async {
    _hydrateTrialRegistries(prefs);
    final String cleanUid = accountUid.trim();
    if (cleanUid.isNotEmpty) {
      _consumedTrialAccountUids.add(cleanUid);
    }
    final String ipHash = hashClientIp(clientIp);
    if (ipHash.isNotEmpty) {
      _consumedTrialClientIpHashes.add(ipHash);
    }
    if (prefs != null) {
      await prefs.setStringList(
        'consumed_trial_uids_v40',
        _consumedTrialAccountUids.toList(),
      );
      await prefs.setStringList(
        'consumed_trial_ip_hashes_v40',
        _consumedTrialClientIpHashes.toList(),
      );
    }
  }

  /// Computes a local tamper-detection digest over cached account fields.
  /// IMPORTANT SECURITY INVARIANT:
  /// This local seal is used ONLY to detect unauthorized edits to SharedPreferences.
  /// It is NEVER sufficient to grant or activate a paid subscription; paid subscriptions
  /// require `account.isBackendConfirmedPaidEntitlement == true` (which is a private runtime
  /// field set exclusively via `applyVerifiedBackendEntitlement`).
  static String computeLocalCacheTamperSeal({
    required String emailOrPhone,
    required String planId,
    required String trialStartIso,
    required String expiryIso,
    required String activeReceiptId,
    required bool hasUsedFreeTrial,
  }) {
    final String canonical = [
      'local_tamper_seal_v34',
      emailOrPhone.trim().toLowerCase(),
      planId.trim(),
      trialStartIso.trim(),
      expiryIso.trim(),
      activeReceiptId.trim(),
      hasUsedFreeTrial ? '1' : '0',
    ].join('|');
    final List<int> digest =
        crypto.sha256.convert(utf8.encode(canonical)).bytes;
    return 'tamper_seal_v34\$${base64Url.encode(digest)}';
  }

  static bool verifyLocalCacheTamperSeal(ParentAccount account) {
    if (account.entitlementSignature.trim().isEmpty) return false;
    final String expectedSeal = computeLocalCacheTamperSeal(
      emailOrPhone: account.emailOrPhone,
      planId: account.subscriptionPlanId,
      trialStartIso: account.trialStartDate.toIso8601String(),
      expiryIso: account.subscriptionExpiryDate.toIso8601String(),
      activeReceiptId: account.activeEntitlementReceiptId,
      hasUsedFreeTrial: account.hasUsedFreeTrial,
    );
    if (!LocalCredentialSecurityService.constantTimeEquals(
        account.entitlementSignature, expectedSeal)) {
      return false;
    }

    if (account.subscriptionPlanId == 'free_forever') {
      return true;
    }

    if (account.subscriptionPlanId == 'trial_1day' ||
        account.subscriptionPlanId == 'trial_7days') {
      final int trialHours = account.subscriptionExpiryDate
          .difference(account.trialStartDate)
          .inHours;
      // Supports the 7-day comprehensive free trial (168 hours, up to 170h for clock skew)
      return trialHours >= 0 && trialHours <= 170;
    }

    if (!account.isBackendConfirmedPaidEntitlement ||
        account.backendEntitlementToken.trim().isEmpty ||
        account.activeEntitlementReceiptId.trim().isEmpty) {
      return false;
    }

    final int idx = account.paymentHistory
        .indexWhere((tx) => tx.id == account.activeEntitlementReceiptId);
    if (idx == -1) return false;
    final PaymentTransactionRecord receipt = account.paymentHistory[idx];
    if (!receipt.isVerified ||
        receipt.planId != account.subscriptionPlanId ||
        receipt.currency.toUpperCase() != 'EGP' ||
        !receipt.webhookSignatureVerified) {
      return false;
    }
    return true;
  }

  /// Verifies a payment exclusively on the authoritative Backend (`paymentVerifyApiUrl`).
  /// Authenticates the caller via `Authorization: Bearer <sessionAccessToken>` (never trusting
  /// a client-supplied email alone), validates Webhook signature, exact amount, EGP currency,
  /// unique `transactionId` and `webhookEventId`, and prevents cross-account IDOR.
  static Future<BackendEntitlementResponse> verifyPaymentOnBackend({
    required String paymentVerifyApiUrl,
    required String sessionAccessToken,
    required SubscriptionPlanModel plan,
    required EgyptianPaymentMethodInfo method,
    required String authenticatedAccountEmail,
    required String payerIdentifier,
    required String referenceCode,
    required String otpCode,
    required List<PaymentTransactionRecord> existingHistory,
  }) async {
    final String cleanApiUrl = paymentVerifyApiUrl.trim();
    if (cleanApiUrl.isEmpty ||
        !cleanApiUrl.toLowerCase().startsWith('https://')) {
      return const BackendEntitlementResponse(
        isVerifiedAndActive: false,
        errorMessage:
            '🔒 لا يُسمح للتطبيق بتفعيل اشتراك مدفوع محلياً؛ يجب ضبط رابط خادم التحقق الآمن (HTTPS Backend).',
      );
    }

    final String cleanBearer = sessionAccessToken.trim();
    if (cleanBearer.isEmpty) {
      return const BackendEntitlementResponse(
        isVerifiedAndActive: false,
        errorMessage:
            '🔒 رفض أمني: لا يوجد Access Token موثق للجلسة؛ لا يُسمح بتحديد الحساب بالبريد الإلكتروني وحده.',
      );
    }

    if (!AppNetworkPolicyGuard.canPerformOutboundNetworkRequest()) {
      return const BackendEntitlementResponse(
        isVerifiedAndActive: false,
        errorMessage:
            '🔒 تعذر الاتصال بخادم التحقق من الدفع لأن وضع عدم الاتصال مفعّل.',
      );
    }

    final String cleanRef = referenceCode.trim().toUpperCase();
    final String expectedEmail = authenticatedAccountEmail.trim().toLowerCase();
    final http.Client client = httpClientOverride ?? http.Client();
    final bool shouldClose = httpClientOverride == null;

    try {
      final response = await client
          .post(
            Uri.parse(cleanApiUrl),
            headers: {
              'Content-Type': 'application/json; charset=utf-8',
              'Authorization': 'Bearer $cleanBearer',
            },
            body: jsonEncode({
              'planId': plan.id,
              'expectedAmountEgp': plan.priceEgp,
              'expectedCurrency': 'EGP',
              'paymentMethod': method.id,
              'payerIdentifier': payerIdentifier.trim(),
              'referenceCode': cleanRef,
              'otpCode': otpCode.trim(),
            }),
          )
          .timeout(const Duration(seconds: 12));

      if (response.statusCode == 401 || response.statusCode == 403) {
        return const BackendEntitlementResponse(
          isVerifiedAndActive: false,
          errorMessage:
              '🔒 رفض الخادم رمز الجلسة (Access Token غير صالح أو غير مصرح له بهذا الحساب).',
        );
      }

      if (response.statusCode != 200 && response.statusCode != 201) {
        return BackendEntitlementResponse(
          isVerifiedAndActive: false,
          errorMessage:
              'رفض خادم الدفع الخلفي العملية (كود الاستجابة: ${response.statusCode}).',
        );
      }

      final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map) {
        return const BackendEntitlementResponse(
          isVerifiedAndActive: false,
          errorMessage: 'استجابة خادم الدفع غير صالحة.',
        );
      }

      final String tokenBoundEmail =
          (decoded['authenticatedEmail'] ?? '').toString().trim().toLowerCase();
      if (tokenBoundEmail.isEmpty || tokenBoundEmail != expectedEmail) {
        return const BackendEntitlementResponse(
          isVerifiedAndActive: false,
          errorMessage:
              '🔒 رفض أمني (IDOR Prevention): هوية الحساب المستخرجة من Access Token على الخادم لا تطابق الحساب الحالي.',
        );
      }

      final String lifecycle =
          (decoded['status'] ?? 'verified').toString().trim().toLowerCase();
      if (lifecycle == 'refunded' ||
          lifecycle == 'cancelled' ||
          lifecycle == 'expired') {
        return BackendEntitlementResponse(
          isVerifiedAndActive: false,
          lifecycleStatus: lifecycle,
          authenticatedAccountEmail: tokenBoundEmail,
          errorMessage: '🔒 حالة الاشتراك من الخادم: $lifecycle (غير فعال).',
        );
      }

      final bool paidConfirmed = decoded['paid'] == true ||
          decoded['verified'] == true ||
          lifecycle == 'verified' ||
          lifecycle == 'active';
      if (!paidConfirmed) {
        return BackendEntitlementResponse(
          isVerifiedAndActive: false,
          errorMessage: (decoded['message'] ??
                  'لم يؤكد الخادم تحصيل المبلغ الفعلي لهذه العملية.')
              .toString(),
        );
      }

      final bool webhookVerified = decoded['webhookVerified'] == true;
      final String webhookSig =
          (decoded['webhookSignature'] ?? '').toString().trim();
      final String webhookEventId =
          (decoded['webhookEventId'] ?? decoded['transactionId'] ?? '')
              .toString()
              .trim();
      if (!webhookVerified || webhookSig.isEmpty || webhookEventId.isEmpty) {
        return const BackendEntitlementResponse(
          isVerifiedAndActive: false,
          errorMessage:
              '🔒 رفض أمني: لم يتم التحقق من توقيع أو معرف Webhook بوابة الدفع على الخادم.',
        );
      }

      final int verifiedAmount =
          int.tryParse(decoded['amountEgp']?.toString() ?? '-1') ?? -1;
      if (verifiedAmount != plan.priceEgp) {
        return BackendEntitlementResponse(
          isVerifiedAndActive: false,
          errorMessage:
              '🔒 رفض أمني: المبلغ المؤكد في الخادم ($verifiedAmount) لا يطابق سعر الباقة (${plan.priceEgp} ج.م).',
        );
      }

      final String currency =
          (decoded['currency'] ?? '').toString().trim().toUpperCase();
      if (currency != 'EGP') {
        return BackendEntitlementResponse(
          isVerifiedAndActive: false,
          errorMessage:
              '🔒 رفض أمني: عملة العملية ($currency) غير مطابقة للعملة المعتمدة (EGP).',
        );
      }

      final String txId = (decoded['transactionId'] ?? '').toString().trim();
      if (txId.isEmpty) {
        return const BackendEntitlementResponse(
          isVerifiedAndActive: false,
          errorMessage:
              '🔒 رفض أمني: لم يُرجع الخادم معرف عملية (transactionId) موثقاً.',
        );
      }

      final bool duplicateWebhookOrTx = _processedWebhookEventIds
              .contains(webhookEventId.toLowerCase()) ||
          _processedTransactionIds.contains(txId.toLowerCase()) ||
          _processedTransactionIds.contains('ref_$cleanRef') ||
          existingHistory.any((tx) =>
              tx.isVerified &&
              (tx.id.toLowerCase() == txId.toLowerCase() ||
                  tx.referenceCode.toLowerCase() == cleanRef.toLowerCase()));
      if (duplicateWebhookOrTx) {
        return BackendEntitlementResponse(
          isVerifiedAndActive: false,
          errorMessage:
              '🔒 رفض أمني: تكرار Webhook ($webhookEventId) أو معرف العملية ($txId)؛ تم منع التفعيل المكرر.',
        );
      }

      final String entitlementToken =
          (decoded['entitlementToken'] ?? '').toString().trim();
      if (entitlementToken.isEmpty) {
        return const BackendEntitlementResponse(
          isVerifiedAndActive: false,
          errorMessage:
              '🔒 لم يُصدر الخادم رمز استحقاق (entitlementToken) صالحاً.',
        );
      }

      final DateTime parsedExpiry =
          DateTime.tryParse(decoded['expiryDate']?.toString() ?? '') ??
              DateTime.now().add(Duration(days: plan.durationDays));
      if (!parsedExpiry.isAfter(DateTime.now())) {
        return const BackendEntitlementResponse(
          isVerifiedAndActive: false,
          lifecycleStatus: 'expired',
          errorMessage: '🔒 تاريخ صلاحية الاشتراك الوارد من الخادم منتهٍ.',
        );
      }

      _processedWebhookEventIds.add(webhookEventId.toLowerCase());
      _processedTransactionIds.add(txId.toLowerCase());
      _processedTransactionIds.add('ref_$cleanRef');

      return BackendEntitlementResponse(
        isVerifiedAndActive: true,
        lifecycleStatus: 'active',
        authenticatedAccountEmail: tokenBoundEmail,
        planId: (decoded['planId'] ?? plan.id).toString(),
        expiryDate: parsedExpiry,
        transactionId: txId,
        webhookEventId: webhookEventId,
        referenceCode: cleanRef,
        verifiedAmountEgp: verifiedAmount,
        currency: currency,
        webhookSignatureVerified: true,
        webhookSignature: webhookSig,
        backendEntitlementToken: entitlementToken,
      );
    } catch (_) {
      return const BackendEntitlementResponse(
        isVerifiedAndActive: false,
        errorMessage:
            'تعذر الاتصال بخادم التحقق من الدفع؛ لم يتم تفعيل الاشتراك.',
      );
    } finally {
      if (shouldClose) {
        client.close();
      }
    }
  }

  static Future<BackendEntitlementResponse?> fetchSubscriptionStatusFromBackend({
    required String paymentVerifyApiUrl,
    required String sessionAccessToken,
    required String expectedAuthenticatedEmail,
  }) async {
    final String cleanApiUrl = paymentVerifyApiUrl.trim();
    final String cleanBearer = sessionAccessToken.trim();
    final String expectedEmail = expectedAuthenticatedEmail.trim().toLowerCase();
    if (cleanApiUrl.isEmpty ||
        cleanBearer.isEmpty ||
        expectedEmail.isEmpty ||
        !cleanApiUrl.toLowerCase().startsWith('https://') ||
        !AppNetworkPolicyGuard.canPerformOutboundNetworkRequest()) {
      return null;
    }

    final http.Client client = httpClientOverride ?? http.Client();
    final bool shouldClose = httpClientOverride == null;
    try {
      final Uri statusUri = Uri.parse('$cleanApiUrl/status');
      final response = await client.get(
        statusUri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $cleanBearer',
        },
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 401 || response.statusCode == 403) {
        return const BackendEntitlementResponse(
          isVerifiedAndActive: false,
          lifecycleStatus: 'unauthorized',
          errorMessage: '🔒 رمز الجلسة غير مخول للوصول إلى حالة الاشتراك.',
        );
      }

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is Map) {
          final String tokenEmail = (decoded['authenticatedEmail'] ?? '')
              .toString()
              .trim()
              .toLowerCase();
          if (tokenEmail.isEmpty || tokenEmail != expectedEmail) {
            return const BackendEntitlementResponse(
              isVerifiedAndActive: false,
              lifecycleStatus: 'idor_blocked',
              errorMessage:
                  '🔒 تم حظر محاولة قراءة اشتراك حساب آخر (IDOR Prevention).',
            );
          }

          final String statusStr =
              (decoded['status'] ?? (decoded['active'] == true ? 'active' : 'expired'))
                  .toString()
                  .trim()
                  .toLowerCase();
          final DateTime? expDate =
              DateTime.tryParse(decoded['expiryDate']?.toString() ?? '');
          final bool notExpired =
              expDate != null && expDate.isAfter(DateTime.now());
          final bool isActive = statusStr == 'active' &&
              decoded['active'] == true &&
              notExpired &&
              decoded['webhookVerified'] == true &&
              (decoded['currency'] ?? 'EGP').toString().toUpperCase() == 'EGP';

          return BackendEntitlementResponse(
            isVerifiedAndActive: isActive,
            lifecycleStatus: isActive ? 'active' : statusStr,
            authenticatedAccountEmail: tokenEmail,
            planId: (decoded['planId'] ?? 'trial_1day').toString(),
            expiryDate: expDate,
            transactionId: (decoded['transactionId'] ?? '').toString(),
            webhookEventId: (decoded['webhookEventId'] ?? '').toString(),
            referenceCode: (decoded['referenceCode'] ?? '').toString(),
            verifiedAmountEgp:
                int.tryParse(decoded['amountEgp']?.toString() ?? '0') ?? 0,
            currency:
                (decoded['currency'] ?? 'EGP').toString().toUpperCase(),
            webhookSignatureVerified: decoded['webhookVerified'] == true,
            webhookSignature: (decoded['webhookSignature'] ?? '').toString(),
            backendEntitlementToken:
                (decoded['entitlementToken'] ?? '').toString(),
          );
        }
      }
    } catch (_) {
    } finally {
      if (shouldClose) {
        client.close();
      }
    }
    return null;
  }
}
