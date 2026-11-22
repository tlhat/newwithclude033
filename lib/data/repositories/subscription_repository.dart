import 'package:haneen_kids_vod/haneen_kids_exports.dart';

class SubscriptionRepository {
  final SupabaseRemoteDataSource? remoteDataSource;

  const SubscriptionRepository({this.remoteDataSource});

  String _resolveStatusEndpoint(String paymentVerifyApiUrl) {
    if (paymentVerifyApiUrl.trim().isNotEmpty) {
      return paymentVerifyApiUrl.trim();
    }
    final cfg = remoteDataSource?.config;
    if (cfg != null && cfg.isConfigured) {
      return cfg.edgeFunctionUri('subscription-status').toString();
    }
    return '';
  }

  Future<BackendEntitlementResponse?> fetchStatus({
    required String paymentVerifyApiUrl,
    required String sessionAccessToken,
    required String expectedAuthenticatedEmail,
  }) {
    final String effectiveUrl = _resolveStatusEndpoint(paymentVerifyApiUrl);
    return SubscriptionEntitlementSecurityService
        .fetchSubscriptionStatusFromBackend(
      paymentVerifyApiUrl: effectiveUrl,
      sessionAccessToken: sessionAccessToken,
      expectedAuthenticatedEmail: expectedAuthenticatedEmail,
    );
  }

  Future<BackendEntitlementResponse> verifyPayment({
    required String paymentVerifyApiUrl,
    required String sessionAccessToken,
    required SubscriptionPlanModel plan,
    required EgyptianPaymentMethodInfo method,
    required String authenticatedAccountEmail,
    required String payerIdentifier,
    required String referenceCode,
    required String otpCode,
    required List<PaymentTransactionRecord> existingHistory,
  }) {
    return SubscriptionEntitlementSecurityService.verifyPaymentOnBackend(
      paymentVerifyApiUrl: paymentVerifyApiUrl,
      sessionAccessToken: sessionAccessToken,
      plan: plan,
      method: method,
      authenticatedAccountEmail: authenticatedAccountEmail,
      payerIdentifier: payerIdentifier,
      referenceCode: referenceCode,
      otpCode: otpCode,
      existingHistory: existingHistory,
    );
  }
}
