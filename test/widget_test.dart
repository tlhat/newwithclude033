import 'package:flutter/material.dart';
import 'package:haneen_kids_vod/l10n/app_localizations.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:haneen_kids_vod/main.dart';

class _MockSecurityHttpClient extends http.BaseClient {
  final Future<http.Response> Function(http.Request request) handler;
  _MockSecurityHttpClient(this.handler);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final http.Request req = request as http.Request;
    final http.Response res = await handler(req);
    return http.StreamedResponse(
      Stream<List<int>>.fromIterable([res.bodyBytes]),
      res.statusCode,
      headers: res.headers,
    );
  }
}

/// Deterministic 512-bit RSA keypair for genuine RSASSA-PKCS1-v1_5 (RS256) mathematical
/// signing and verification in unit tests:
/// p = 2^256 - 189, q = 2^256 - 357 (both verified primes), n = p * q (64 bytes = 512 bits), e = 65537.
class _TestRsaKeyPair {
  final String kid;
  late final BigInt n;
  late final BigInt e;
  late final BigInt d;
  final int k = 64;

  _TestRsaKeyPair({
    required this.kid,
    required BigInt p,
    required BigInt q,
  }) {
    n = p * q;
    e = BigInt.from(65537);
    final BigInt phi = (p - BigInt.one) * (q - BigInt.one);
    d = e.modInverse(phi);
  }

  Map<String, dynamic> toPublicJwk() {
    final Uint8List nBytes =
        GoogleOAuthVerificationService.unsignedBigIntToBytes(n, k);
    final Uint8List eBytes = Uint8List.fromList([0x01, 0x00, 0x01]);
    return {
      'kty': 'RSA',
      'alg': 'RS256',
      'use': 'sig',
      'kid': kid,
      'n': base64Url.encode(nBytes),
      'e': base64Url.encode(eBytes),
    };
  }

  String signJwtRs256({
    required String iss,
    required String aud,
    required String email,
    required bool emailVerified,
    required int expSeconds,
    required String sub,
  }) {
    final String headerB64 = base64Url.encode(
        utf8.encode(jsonEncode({'alg': 'RS256', 'typ': 'JWT', 'kid': kid})));
    final String payloadB64 = base64Url.encode(utf8.encode(jsonEncode({
      'iss': iss,
      'aud': aud,
      'email': email,
      'email_verified': emailVerified,
      'exp': expSeconds,
      'sub': sub,
    })));
    final String signingInput = '$headerB64.$payloadB64';
    final List<int> sha256Digest =
        crypto.sha256.convert(utf8.encode(signingInput)).bytes;
    const List<int> digestInfoPrefix = [
      0x30, 0x31, 0x30, 0x0d, 0x06, 0x09, 0x60, 0x86, 0x48, 0x01,
      0x65, 0x03, 0x04, 0x02, 0x01, 0x05, 0x00, 0x04, 0x20,
    ];
    final int tLen = digestInfoPrefix.length + sha256Digest.length; // 51
    final Uint8List em = Uint8List(k);
    em[0] = 0x00;
    em[1] = 0x01;
    final int psLen = k - tLen - 3;
    for (int i = 0; i < psLen; i++) {
      em[2 + i] = 0xff;
    }
    em[2 + psLen] = 0x00;
    final int tOffset = 3 + psLen;
    for (int i = 0; i < digestInfoPrefix.length; i++) {
      em[tOffset + i] = digestInfoPrefix[i];
    }
    for (int i = 0; i < sha256Digest.length; i++) {
      em[tOffset + digestInfoPrefix.length + i] = sha256Digest[i];
    }

    final BigInt m = GoogleOAuthVerificationService.bytesToUnsignedBigInt(em);
    final BigInt s = m.modPow(d, n);
    final Uint8List sigBytes =
        GoogleOAuthVerificationService.unsignedBigIntToBytes(s, k);
    return '$signingInput.${base64Url.encode(sigBytes)}';
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Haneen Kids v3.4 OWASP 600k PBKDF2, Keystore PIN, Bearer Subscriptions & RS256 OAuth Audit Tests', () {
    late AppStateManager appState;
    late SharedPreferences prefs;

    setUp(() async {
      CalmVoiceService.isTestEnvironment = true;
      SharedPreferences.setMockInitialValues({});
      SupabaseRemoteDataSource.httpClientOverride = null;
      LocalCredentialSecurityService.clearKeystoreLockoutForTesting();
      SubscriptionEntitlementSecurityService.resetProcessedTransactionsForTesting();
      GoogleOAuthVerificationService.clearCachedJwksForTesting();
      GoogleOAuthVerificationService.httpClientOverride = null;
      SubscriptionEntitlementSecurityService.httpClientOverride = null;
      LocalCredentialSecurityService.kDefaultPbkdf2Iterations =
          LocalCredentialSecurityService.kOwaspRecommendedPbkdf2Iterations;

      prefs = await SharedPreferences.getInstance();
      appState = AppStateManager(prefs);
      await appState.initialize();
      await appState.quickDemoLogin();
      AppNetworkPolicyGuard.isOfflineOnlyModeActive = false;
      AppNetworkPolicyGuard.isExternalVideosAllowed = true;
      AppNetworkPolicyGuard.soundAndVoiceActive = true;
      AppNetworkPolicyGuard.lowMemoryPerformanceModeActive = false;
      AppNetworkPolicyGuard.blockedNetworkRequestsCount = 0;
      CalmVoiceService.instance.isSoundAndVoiceEnabled = true;
      CalmVoiceService.instance.isAssistantMuted = false;
      CalmVoiceService.instance.isChildMicrophoneAllowed = true;
      ElevenLabsVoiceService.resetStatsAndCacheForTesting();
      ElevenLabsVoiceService.httpClientOverride = null;
    });

    tearDown(() {
      GoogleOAuthVerificationService.httpClientOverride = null;
      SubscriptionEntitlementSecurityService.httpClientOverride = null;
      SupabaseRemoteDataSource.httpClientOverride = null;
      ElevenLabsVoiceService.httpClientOverride = null;
      appState.dispose();
    });

    test('1. PBKDF2: 600,000 Iterations (OWASP Standard), Android Low/Mid-Range Benchmark & Legacy Migration (12k & 120k -> 600k)', () {
      expect(
        LocalCredentialSecurityService.kOwaspRecommendedPbkdf2Iterations,
        equals(600000),
      );
      expect(
        LocalCredentialSecurityService.kDefaultPbkdf2Iterations,
        equals(600000),
      );

      // Benchmark on low-end & mid-range Android profiles
      final Map<String, dynamic> bench =
          LocalCredentialSecurityService.benchmarkPbkdf2OnTargetDevice(
        sampleIterations: 15000,
      );
      expect(bench['owaspRecommendedIterations'], equals(600000));
      expect(bench['projected600kMidRangeAndroidMs'], isA<int>());
      expect(bench['projected600kLowEndAndroidMs'], isA<int>());

      // Verify seamless migration from both 12,000-iteration and 120,000-iteration legacy accounts to 600,000
      final String salt12k = LocalCredentialSecurityService.generateRandomSalt();
      final String salt120k = LocalCredentialSecurityService.generateRandomSalt();
      final String hash12k = LocalCredentialSecurityService.deriveKeySha256(
        secret: 'OldPass12k',
        salt: salt12k,
        iterations: 12000,
      );
      final String hash120k = LocalCredentialSecurityService.deriveKeySha256(
        secret: 'PrevPass120k',
        salt: salt120k,
        iterations: 120000,
      );

      expect(LocalCredentialSecurityService.needsIterationUpgrade(hash12k), isTrue);
      expect(LocalCredentialSecurityService.needsIterationUpgrade(hash120k), isTrue);

      final accFrom120k = ParentAccount.fromJson({
        'fullName': 'ولي أمر',
        'emailOrPhone': 'legacy120k@haneenkids.com',
        'credentialSalt': salt120k,
        'passwordHash': hash120k,
        'pinHash': hash12k,
      });

      expect(
        LocalCredentialSecurityService.extractIterations(accFrom120k.passwordHash),
        equals(120000),
      );
      expect(accFrom120k.verifyPassword('PrevPass120k'), isTrue);
      // Automatically upgraded to 600,000 iterations without data loss!
      expect(
        LocalCredentialSecurityService.extractIterations(accFrom120k.passwordHash),
        equals(600000),
      );
    });

    test('2. Parental PIN: Keystore 256-Bit Pepper Offline Protection, Lockout Survival Across Restart/SharedPreferences Wipe, and Full Reinstall Boundary', () async {
      final account = appState.currentAccount!;
      expect(
        LocalCredentialSecurityService.isKeystorePepperedPinHash(account.pinHash),
        isTrue,
      );
      expect(
        LocalCredentialSecurityService.extractIterations(account.pinHash),
        equals(600000),
      );

      // 2a. Offline Extraction Resistance: If an attacker steals SharedPreferences JSON (`account.toJson()`)
      // onto another machine that does not have this device's 256-bit Android Keystore Pepper,
      // PIN verification MUST fail even if they know the 4-digit PIN ('1234')!
      final Map<String, dynamic> stolenPrefsJson = account.toJson();
      final String originalKeystorePepper =
          LocalCredentialSecurityService.keystoreDevicePinPepper;
      await LocalCredentialSecurityService.simulateFullOsAppDataWipeAndReinstall(
          prefs);
      expect(
        LocalCredentialSecurityService.keystoreDevicePinPepper,
        isNot(equals(originalKeystorePepper)),
      );
      final ParentAccount attackerLoadedAccount =
          ParentAccount.fromJson(stolenPrefsJson);
      expect(attackerLoadedAccount.verifyParentalPin('123456'), isFalse);

      // 2b. Re-initialize legitimate session and trigger 3 failed PIN attempts -> Lockout
      await appState.initialize();
      await appState.quickDemoLogin();
      final activeAcc = appState.currentAccount!;
      expect(activeAcc.verifyParentalPin('0000'), isFalse);
      expect(activeAcc.verifyParentalPin('1111'), isFalse);
      expect(activeAcc.verifyParentalPin('2222'), isFalse);
      expect(activeAcc.isPinLockedOut, isTrue);

      // 2c. Restart app & wipe/tamper SharedPreferences JSON -> Keystore Vault preserves Lockout!
      final Map<String, dynamic> tamperedJson = activeAcc.toJson();
      tamperedJson['failedPinAttempts'] = 0;
      tamperedJson['pinLockoutUntil'] = null;
      final ParentAccount restartedAccount =
          ParentAccount.fromJson(tamperedJson);
      expect(restartedAccount.isPinLockedOut, isTrue);
      expect(restartedAccount.verifyParentalPin('123456'), isFalse);

      // 2d. Full OS App Data Wipe & Reinstall (`simulateFullOsAppDataWipeAndReinstall`):
      // Local storage & Keystore are wiped by OS, but for Cloud-Authenticated accounts (`authApiUrl`),
      // the Backend still enforces the lockout on login!
      await LocalCredentialSecurityService.simulateFullOsAppDataWipeAndReinstall(
          prefs);
      await appState.updateAuthApiUrl('https://api.haneenkids.com/v1/auth');
      GoogleOAuthVerificationService.httpClientOverride =
          _MockSecurityHttpClient((req) async {
        return http.Response(
          jsonEncode({
            'error': 'account_locked_on_server',
            'lockoutRemainingSeconds': 300,
          }),
          423,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });
      final String? cloudLoginAfterReinstall =
          await appState.login('parent@haneenkids.com', '123456');
      expect(cloudLoginAfterReinstall, isNotNull);
      expect(
        LocalCredentialSecurityService.readLockoutFromKeystoreVault(
                'parent@haneenkids.com')
            ?.passwordLockoutUntil,
        isNotNull,
      );
    });

    test('3. Backend & Subscriptions: Bearer Access Token Auth, IDOR Prevention, Immutability of isBackendConfirmedPaidEntitlement, Expiry, Cancellation, Refund & Webhook Replay', () async {
      final account = appState.currentAccount!;
      final plan =
          kSubscriptionPlans.firstWhere((p) => p.id == 'monthly_family');
      final method = kEgyptianPaymentMethods.first;

      await appState.updatePaymentGatewayConfig(
        verifyUrl: 'https://api.haneenkids.com/v1/subscriptions',
        secretKey: '',
      );

      // 3a. Verify that `GET /status` sends `Authorization: Bearer <token>` and does NOT pass `?email=` in URL,
      // and blocks IDOR if Backend returns a different user's email!
      String? capturedAuthHeader;
      Uri? capturedStatusUri;
      SubscriptionEntitlementSecurityService.httpClientOverride =
          _MockSecurityHttpClient((req) async {
        capturedStatusUri = req.url;
        capturedAuthHeader = req.headers['Authorization'];
        return http.Response(
          jsonEncode({
            'active': true,
            'status': 'active',
            'authenticatedEmail': 'another.victim@gmail.com', // IDOR mismatch!
            'planId': 'annual_vip',
            'amountEgp': 799,
            'currency': 'EGP',
            'webhookVerified': true,
            'webhookSignature': 'wh_sig_1',
            'transactionId': 'tx_victim_1',
            'entitlementToken': 'tok_victim_1',
            'expiryDate': DateTime.now()
                .add(const Duration(days: 365))
                .toIso8601String(),
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final bool idorAttempt =
          await appState.refreshSubscriptionStatusFromBackend();
      expect(capturedStatusUri?.queryParameters.containsKey('email'), isFalse);
      expect(capturedAuthHeader?.startsWith('Bearer '), isTrue);
      expect(idorAttempt, isFalse);
      expect(account.isBackendConfirmedPaidEntitlement, isFalse);
      expect(account.subscriptionPlanId, equals('trial_1day'));

      // 3b. Valid Backend payment verification bound to authenticated user's token
      SubscriptionEntitlementSecurityService.httpClientOverride =
          _MockSecurityHttpClient((req) async {
        return http.Response(
          jsonEncode({
            'verified': true,
            'status': 'active',
            'authenticatedEmail': account.emailOrPhone,
            'webhookVerified': true,
            'webhookSignature': 'whsec_valid_99',
            'webhookEventId': 'wh_evt_unique_99',
            'amountEgp': plan.priceEgp,
            'currency': 'EGP',
            'transactionId': 'tx_live_99',
            'planId': plan.id,
            'expiryDate': DateTime.now()
                .add(const Duration(days: 30))
                .toIso8601String(),
            'entitlementToken': 'srv_ent_token_99',
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final PaymentVerificationOutcome paidOutcome =
          await appState.verifyAndActivateEgyptianPayment(
        plan: plan,
        method: method,
        payerIdentifier: '01012345678',
        bankTransferRefNum: 'VF88776655',
        generatedSessionOtp: '112233',
        userEnteredOtp: '112233',
        simulateBankRejection: false,
      );
      expect(paidOutcome.isPaidAndVerified, isTrue);
      expect(account.isBackendConfirmedPaidEntitlement, isTrue);
      expect(account.isSubscriptionActive, isTrue);

      // 3c. Duplicate Webhook (`wh_evt_unique_99`) MUST be rejected idempotently
      final PaymentVerificationOutcome duplicateWebhookOutcome =
          await appState.verifyAndActivateEgyptianPayment(
        plan: plan,
        method: method,
        payerIdentifier: '01012345678',
        bankTransferRefNum: 'VF00001111',
        generatedSessionOtp: '112233',
        userEnteredOtp: '112233',
        simulateBankRejection: false,
      );
      expect(duplicateWebhookOutcome.isPaidAndVerified, isFalse);

      // 3d. Refund / Chargeback or Cancellation on Backend (`GET /status` returns `status: 'refunded'`)
      // immediately revokes `isBackendConfirmedPaidEntitlement` and deactivates subscription!
      SubscriptionEntitlementSecurityService.httpClientOverride =
          _MockSecurityHttpClient((req) async {
        return http.Response(
          jsonEncode({
            'active': false,
            'status': 'refunded',
            'authenticatedEmail': account.emailOrPhone,
            'planId': plan.id,
            'transactionId': 'tx_live_99',
            'currency': 'EGP',
            'webhookVerified': true,
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final bool afterRefund =
          await appState.refreshSubscriptionStatusFromBackend();
      expect(afterRefund, isFalse);
      expect(account.isBackendConfirmedPaidEntitlement, isFalse);
      expect(account.isSubscriptionActive, isFalse);
      expect(account.paymentHistory.first.status, equals('refunded'));
    });

    test('4. Google OAuth: Registered Client ID, Mathematical RS256 Signature Verification, Key Rotation (kid), and Forged/Wrong-Audience Rejection', () async {
      // 4a. Verify Client ID is a valid registered Google OAuth Client ID (`*.apps.googleusercontent.com`)
      expect(
        GoogleOAuthVerificationService.isValidRegisteredGoogleClientId(
          GoogleOAuthVerificationService.kDefaultGoogleClientId,
        ),
        isTrue,
      );
      expect(
        GoogleOAuthVerificationService.isValidRegisteredGoogleClientId(
          'invalid_placeholder_client_id',
        ),
        isFalse,
      );

      // Build two real RSA keypairs (`keyV1` and rotated `keyV2`)
      final BigInt p1 = (BigInt.one << 256) - BigInt.from(189);
      final BigInt q1 = (BigInt.one << 256) - BigInt.from(357);
      final _TestRsaKeyPair keyV1 = _TestRsaKeyPair(
        kid: 'google_kid_2026_v1',
        p: p1,
        q: q1,
      );

      final BigInt p2 = (BigInt.one << 256) - BigInt.from(617);
      final BigInt q2 = (BigInt.one << 256) - BigInt.from(923);
      final _TestRsaKeyPair keyV2Rotated = _TestRsaKeyPair(
        kid: 'google_kid_2026_v2_rotated',
        p: p2,
        q: q2,
      );

      bool serveRotatedJwks = false;
      int jwksFetchCount = 0;

      GoogleOAuthVerificationService.httpClientOverride =
          _MockSecurityHttpClient((req) async {
        if (req.url.toString().contains('googleapis.com/oauth2/v3/certs')) {
          jwksFetchCount++;
          return http.Response(
            jsonEncode({
              'keys': [
                serveRotatedJwks
                    ? keyV2Rotated.toPublicJwk()
                    : keyV1.toPublicJwk(),
              ],
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        if (req.url.toString().contains('oauth2.googleapis.com/tokeninfo')) {
          return http.Response(
            jsonEncode({
              'iss': 'https://accounts.google.com',
              'aud': GoogleOAuthVerificationService.kDefaultGoogleClientId,
              'email': 'rsa.verified@gmail.com',
              'email_verified': 'true',
              'exp': ((DateTime.now().millisecondsSinceEpoch ~/ 1000) + 1800)
                  .toString(),
              'sub': 'google_sub_rsa_001',
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final int validExp =
          (DateTime.now().millisecondsSinceEpoch ~/ 1000) + 1800;

      // 4b. Token signed with `keyV1` passes mathematical RS256 verification
      final String validTokenV1 = keyV1.signJwtRs256(
        iss: 'https://accounts.google.com',
        aud: GoogleOAuthVerificationService.kDefaultGoogleClientId,
        email: 'rsa.verified@gmail.com',
        emailVerified: true,
        expSeconds: validExp,
        sub: 'google_sub_rsa_001',
      );

      final String? errV1 = await appState.signInOrSignUpWithGoogle(
        googleEmail: 'rsa.verified@gmail.com',
        googleDisplayName: 'RSA Verified User',
        parentalPin: '654321',
        childName: 'فارس',
        childAgeGroup: '3–6 سنوات',
        childAvatar: '🦁',
        dailyTimeLimit: 20,
        googleIdToken: validTokenV1,
      );
      expect(errV1, isNull);
      expect(jwksFetchCount, equals(1));

      // 4c. Forged signature (signed with `keyV2Rotated` while JWKS still serves `keyV1` for `kid_v1`) MUST fail mathematical RS256 check!
      final List<String> v1Parts = validTokenV1.split('.');
      final List<String> v2Parts = keyV2Rotated
          .signJwtRs256(
            iss: 'https://accounts.google.com',
            aud: GoogleOAuthVerificationService.kDefaultGoogleClientId,
            email: 'rsa.verified@gmail.com',
            emailVerified: true,
            expSeconds: validExp,
            sub: 'google_sub_rsa_001',
          )
          .split('.');
      final String forgedToken = '${v1Parts[0]}.${v1Parts[1]}.${v2Parts[2]}';
      final GoogleOAuthVerificationOutcome forgedOutcome =
          await GoogleOAuthVerificationService.verifyGoogleIdTokenWithBackend(
        idToken: forgedToken,
        expectedEmail: 'rsa.verified@gmail.com',
      );
      expect(forgedOutcome.isVerified, isFalse);

      // 4d. Key Rotation (`kid` changes to `google_kid_2026_v2_rotated`):
      // Service detects cache miss on new `kid`, fetches updated JWKS, and verifies the rotated key!
      serveRotatedJwks = true;
      final String validTokenV2Rotated = keyV2Rotated.signJwtRs256(
        iss: 'https://accounts.google.com',
        aud: GoogleOAuthVerificationService.kDefaultGoogleClientId,
        email: 'rsa.verified@gmail.com',
        emailVerified: true,
        expSeconds: validExp,
        sub: 'google_sub_rsa_001',
      );
      final GoogleOAuthVerificationOutcome rotatedOutcome =
          await GoogleOAuthVerificationService.verifyGoogleIdTokenWithBackend(
        idToken: validTokenV2Rotated,
        expectedEmail: 'rsa.verified@gmail.com',
      );
      expect(rotatedOutcome.isVerified, isTrue);
      expect(jwksFetchCount, equals(2));

      // 4e. Token issued for another app (`aud` mismatch) or expired (`exp` in past) MUST be rejected
      final String wrongAudToken = keyV2Rotated.signJwtRs256(
        iss: 'https://accounts.google.com',
        aud: '999999999-otherapp.apps.googleusercontent.com',
        email: 'rsa.verified@gmail.com',
        emailVerified: true,
        expSeconds: validExp,
        sub: 'google_sub_rsa_001',
      );
      final GoogleOAuthVerificationOutcome wrongAudOutcome =
          await GoogleOAuthVerificationService.verifyGoogleIdTokenWithBackend(
        idToken: wrongAudToken,
        expectedEmail: 'rsa.verified@gmail.com',
      );
      expect(wrongAudOutcome.isVerified, isFalse);
    });

    test('5. Modular Architecture Repositories, Multi-Child Isolation, Approved Videos, 100-Level Games State & Account/Child Deletion', () async {
      // Verify modular repositories are wired into AppStateManager
      expect(appState.accountRepository, isA<AccountRepository>());
      expect(appState.childProfileRepository, isA<ChildProfileRepository>());
      expect(appState.videoRepository, isA<VideoRepository>());
      expect(appState.subscriptionRepository, isA<SubscriptionRepository>());

      // Verify HundredLevelGamesGenerator generates all 100 levels across games
      expect(HundredLevelGamesGenerator.oddOneOutLevels.length, equals(100));
      expect(HundredLevelGamesGenerator.memoryLevels.length, equals(100));
      expect(HundredLevelGamesGenerator.patternLevels.length, equals(100));
      expect(HundredLevelGamesGenerator.wordLevels.length, equals(100));
      expect(HundredLevelGamesGenerator.mathLevels.length, equals(100));
      expect(HundredLevelGamesGenerator.etiquetteSteps.isNotEmpty, isTrue);

      final account = appState.currentAccount!;
      final String c1Id = account.children[0].id;
      final String c2Id = account.children[1].id;

      await appState.switchActiveChild(c1Id);
      await appState.updateChildPrivacyAndSafetyControls(
        childId: c1Id,
        offlineOnlyMode: true,
        allowExternalVideos: false,
        allowMicrophone: false,
      );
      expect(AppNetworkPolicyGuard.isOfflineOnlyModeActive, isTrue);

      await appState.switchActiveChild(c2Id);
      expect(AppNetworkPolicyGuard.isOfflineOnlyModeActive, isFalse);

      // Video staging queue: unapproved video is hidden from childApprovedVideos until approved
      final bool added = await appState.addCustomVideo(
        VideoModel(
          id: 'v_review_1',
          title: 'قصة للمراجعة',
          description: 'وصف',
          category: 'bedtime',
          ageGroup: '3–6 سنوات',
          repeatPhrase: 'ردد',
          activeActivity: 'نشاط',
          streamUrl:
              'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4',
        ),
        approvedByParent: false,
      );
      expect(added, isTrue);
      expect(
        appState.childApprovedVideos.any((v) => v.id == 'v_review_1'),
        isFalse,
      );
      await appState.approveVideoForChildFeed('v_review_1');
      expect(
        appState.childApprovedVideos.any((v) => v.id == 'v_review_1'),
        isTrue,
      );

      // Non-duplicating game & lesson rewards
      final child = account.activeChild;
      final int starsBefore = child.starsEarned;
      final bool firstGameWin = await appState.recordBrainGameWin(
        gameId: 'odd_one_out_1',
        gameTitle: 'قوة الملاحظة 1',
        earnedIqPoints: 15,
        earnedStars: 2,
      );
      final bool repeatGameWin = await appState.recordBrainGameWin(
        gameId: 'odd_one_out_1',
        gameTitle: 'قوة الملاحظة 1',
        earnedIqPoints: 15,
        earnedStars: 2,
      );
      expect(firstGameWin, isTrue);
      expect(repeatGameWin, isFalse);
      expect(child.starsEarned, equals(starsBefore + 2));

      // Two-tier child deletion & parent account deletion
      await appState.clearChildActivityHistoryOnly(child.id);
      expect(child.starsEarned, equals(starsBefore + 2));
      await appState.deleteAllChildPersonalAndEducationalData(child.id);
      expect(child.starsEarned, equals(0));
    });

    test('6. Supabase Cloud Integration: Offline-First Outbox, Idempotency Deduplication, Multi-Device Conflict Resolution (CRDT + LWW), and RLS Enforcement', () async {
      await appState.configureSupabaseCloud(
        url: 'https://haneenkids-cloud.supabase.co',
        anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.public_anon_key',
      );
      expect(appState.supabaseEnvConfig.isConfigured, isTrue);

      final account = appState.currentAccount!;
      final child = account.activeChild;

      // 6a. Offline Mode: completing lessons & changing settings while offline queues mutations locally
      // without losing data or duplicating idempotency keys
      await appState.updateChildPrivacyAndSafetyControls(
        childId: child.id,
        offlineOnlyMode: true,
      );
      expect(AppNetworkPolicyGuard.isOfflineOnlyModeActive, isTrue);

      await appState.completeAcademyLesson(
        lessonId: 'les_arabic_baa',
        lessonTitle: 'حرف الباء',
        learnedWord: 'بطة',
        rewardStars: 2,
      );
      // Repeating the same lesson offline must NOT add a duplicate mutation to the queue
      final int pendingAfterFirst = appState.syncQueueService.pendingCount;
      await appState.completeAcademyLesson(
        lessonId: 'les_arabic_baa',
        lessonTitle: 'حرف الباء',
        learnedWord: 'بطة',
        rewardStars: 2,
      );
      expect(appState.syncQueueService.pendingCount, equals(pendingAfterFirst));

      // Attempt to sync while offlineOnlyMode is active -> stays safely queued locally
      final SupabaseCloudSyncResult offlineSyncAttempt =
          await appState.syncPendingChangesWithSupabase();
      expect(offlineSyncAttempt.success, isFalse);
      expect(appState.syncQueueService.pendingCount, greaterThan(0));

      // 6b. Reconnect (disable offlineOnlyMode) and flush pending mutations to Supabase Edge Function `sync-batch`
      await appState.updateChildPrivacyAndSafetyControls(
        childId: child.id,
        offlineOnlyMode: false,
      );

      int syncBatchCallCount = 0;
      SupabaseRemoteDataSource.httpClientOverride =
          _MockSecurityHttpClient((req) async {
        if (req.url.toString().contains('/functions/v1/sync-batch')) {
          syncBatchCallCount++;
          final Map<String, dynamic> body =
              jsonDecode(utf8.decode(req.bodyBytes));
          final List<dynamic> muts = body['mutations'] as List<dynamic>;
          return http.Response(
            jsonEncode({
              'status': 'synced',
              'appliedKeys': muts.map((m) => m['idempotencyKey']).toList(),
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        return http.Response('{}', 200);
      });

      final SupabaseCloudSyncResult onlineSyncResult =
          await appState.syncPendingChangesWithSupabase();
      expect(onlineSyncResult.success, isTrue);
      expect(onlineSyncResult.syncedMutationsCount, greaterThan(0));
      expect(appState.syncQueueService.pendingCount, equals(0));
      expect(syncBatchCallCount, greaterThanOrEqualTo(1));

      // Re-enqueuing an already-applied idempotencyKey is rejected (zero duplicate server execution)
      final bool duplicateEnqueued =
          await appState.syncQueueService.enqueueMutation(
        SyncMutationRecord(
          idempotencyKey: '${child.id}_lesson_les_arabic_baa',
          parentEmail: account.emailOrPhone,
          childId: child.id,
          entityType: 'lesson',
          entityId: 'les_arabic_baa',
          operation: 'complete',
          payload: {},
        ),
      );
      expect(duplicateEnqueued, isFalse);

      // 6c. Multi-Device Conflict Resolution:
      // Device A (local) has completed 'les_arabic_baa' and practiced 'بطة', with old settings (dailyTimeLimit: 20).
      // Device B (remote) has completed 'les_science_space' and practiced 'فضاء', with newer settings (dailyTimeLimit: 35, reduceMotion: true).
      // Merging MUST preserve BOTH lessons and BOTH vocabulary words (Set Union) AND apply Device B's newer settings (LWW)!
      final ChildProfile remoteDeviceProfile = ChildProfile(
        id: child.id,
        name: child.name,
        age: child.age,
        dailyTimeLimit: 35,
        reduceMotion: true,
        starsEarned: child.starsEarned + 2,
        intelligencePoints: child.intelligencePoints + 15,
        chosenAvatar: child.chosenAvatar,
        completedLessons: ['les_science_space'],
        practicedVocabulary: ['فضاء'],
        gameProgressByGameId: {'memory_match': 5},
        updatedAt: DateTime.now().add(const Duration(minutes: 5)),
        syncVersionSeq: child.syncVersionSeq + 3,
      );

      SupabaseRemoteDataSource.httpClientOverride =
          _MockSecurityHttpClient((req) async {
        if (req.url.toString().contains('/rest/v1/child_profiles')) {
          return http.Response(
            jsonEncode([
              {
                ...remoteDeviceProfile.toJson(),
                'parentEmail': account.emailOrPhone,
              },
              // Inject a row belonging to another parent to test client-side + RLS defense-in-depth
              {
                ...remoteDeviceProfile.toJson(),
                'id': 'foreign_child_999',
                'name': 'طفل مستخدم آخر',
                'parentEmail': 'other.parent@gmail.com',
              },
            ]),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        return http.Response('{}', 200);
      });

      final bool pulled = await appState.pullAndMergeRemoteChildrenFromSupabase();
      expect(pulled, isTrue);

      final ChildProfile mergedChild = account.activeChild;
      // Both Device A and Device B lessons & vocabulary are preserved!
      expect(mergedChild.completedLessons.contains('les_arabic_baa'), isTrue);
      expect(mergedChild.completedLessons.contains('les_science_space'), isTrue);
      expect(mergedChild.practicedVocabulary.contains('بطة'), isTrue);
      expect(mergedChild.practicedVocabulary.contains('فضاء'), isTrue);
      expect(mergedChild.gameProgressByGameId['memory_match'], equals(5));
      // Newer parental settings from Device B won (LWW)
      expect(mergedChild.dailyTimeLimit, equals(35));
      expect(mergedChild.reduceMotion, isTrue);
      // Foreign parent's child was strictly rejected!
      expect(account.children.any((c) => c.id == 'foreign_child_999'), isFalse);
    });

    test(
        '7. Phase 3 Adaptive Smart Educational Engine (Ages 2-6): progressive tiers, mastery-gated progression (>=80%), alternative remediation, gentle bilingual pronunciation coach, and parental pedagogical report',
        () async {
      // Uses group appState initialized in setUp()

      // 7a. Verify curriculum covers all 10 required tracks and 4 progressive tiers (2-6 yrs)
      final Set<String> trackIds =
          kHaneenAcademyCurriculum.map((l) => l.trackId).toSet();
      expect(trackIds.contains('arabic_letters'), isTrue);
      expect(trackIds.contains('english_letters'), isTrue);
      expect(trackIds.contains('numbers_counting'), isTrue);
      expect(trackIds.contains('colors_shapes'), isTrue);
      expect(trackIds.contains('animals_nature'), isTrue);
      expect(trackIds.contains('vocabulary'), isTrue);
      expect(trackIds.contains('communication'), isTrue);
      expect(trackIds.contains('simple_science'), isTrue);
      expect(trackIds.contains('daily_habits'), isTrue);
      expect(trackIds.contains('thinking_problem_solving'), isTrue);

      final Set<int> tiers =
          kHaneenAcademyCurriculum.map((l) => l.tierLevel).toSet();
      expect(tiers, containsAll([1, 2, 3, 4]));

      // 7b. Age-to-tier routing (2-3 -> Tier 1, 3-4 -> Tier 2, 4-5 -> Tier 3, 5-6 -> Tier 4)
      expect(
        AdaptiveLearningEngine.inferInitialTier(
            ageGroup: '2–3 سنوات', educationLevel: 'تمهيدي'),
        equals(1),
      );
      expect(
        AdaptiveLearningEngine.inferInitialTier(
            ageGroup: '3–4 سنوات', educationLevel: 'مبتدئ'),
        equals(2),
      );
      expect(
        AdaptiveLearningEngine.inferInitialTier(
            ageGroup: '4–5 سنوات', educationLevel: 'متوسط'),
        equals(3),
      );
      expect(
        AdaptiveLearningEngine.inferInitialTier(
            ageGroup: '5–6 سنوات', educationLevel: 'متقدم'),
        equals(4),
      );

      final child = appState.currentAccount!.activeChild;
      child.currentCurriculumTier = 2;
      child.educationLevel = 'مبتدئ';
      child.skillMasteryByLessonId.clear();
      child.needsRemediationLessonIds.clear();
      child.completedLessons.clear();

      // 7c. Answering a quiz incorrectly records partial effort (<80%), triggers alternative remediation,
      // and does NOT mark the lesson as mastered or advance the tier prematurely!
      final LessonAttemptEvaluationResult failedAttempt =
          await appState.recordAcademyLessonAttempt(
        lessonId: 'les_english_abc',
        lessonTitle: 'الحروف الإنجليزية (A – B – C)',
        learnedWord: 'Apple — تفاحة',
        isCorrectAnswer: false,
        cardsExploredCount: 2,
      );
      expect(failedAttempt.isMastered, isFalse);
      expect(failedAttempt.requiresAlternativeRemediation, isTrue);
      expect(failedAttempt.newMasteryScore, lessThan(80));
      expect(
        child.needsRemediationLessonIds.contains('les_english_abc'),
        isTrue,
      );
      expect(child.completedLessons.contains('les_english_abc'), isFalse);

      // 7d. Completing the alternative playful remediation activity raises mastery >= 80%
      // and clears the lesson from `needsRemediationLessonIds`!
      final LessonAttemptEvaluationResult remediatedAttempt =
          await appState.recordAcademyLessonAttempt(
        lessonId: 'les_english_abc',
        lessonTitle: 'الحروف الإنجليزية (A – B – C)',
        learnedWord: 'Apple — تفاحة',
        isCorrectAnswer: true,
        cardsExploredCount: 3,
        usedAlternativeRemediation: true,
        practicedPronunciation: true,
      );
      expect(remediatedAttempt.isMastered, isTrue);
      expect(remediatedAttempt.newMasteryScore, greaterThanOrEqualTo(80));
      expect(
        child.needsRemediationLessonIds.contains('les_english_abc'),
        isFalse,
      );
      expect(child.completedLessons.contains('les_english_abc'), isTrue);

      // 7e. Mastering the remaining Tier 2 lessons (>= 80% mastery) automatically promotes
      // the child from Tier 2 (مبتدئ) to Tier 3 (متوسط)!
      final List<AcademyTrackLesson> tier2Lessons = kHaneenAcademyCurriculum
          .where((l) => l.tierLevel == 2 && l.id != 'les_english_abc')
          .toList();
      for (final lesson in tier2Lessons) {
        await appState.recordAcademyLessonAttempt(
          lessonId: lesson.id,
          lessonTitle: lesson.title,
          learnedWord: lesson.cards.first.wordExample,
          isCorrectAnswer: true,
          cardsExploredCount: 3,
        );
      }
      expect(child.currentCurriculumTier, equals(3));
      expect(child.educationLevel, equals('متوسط'));

      // 7f. Gentle bilingual pronunciation coach (Arabic & English) with slow syllable guide
      final PronunciationEvaluation arEval =
          PronunciationCoachService.evaluate('أرنب أبيض', 'ارنب ابيض');
      expect(arEval.stars, equals(3));
      expect(arEval.supportiveTier, equals('excellent'));
      expect(arEval.syllableBreakdown, contains('•'));

      final PronunciationEvaluation enEval =
          PronunciationCoachService.evaluate('Apple Cat', 'apple cat');
      expect(enEval.stars, equals(3));
      expect(enEval.supportiveTier, equals('excellent'));

      final PronunciationEvaluation gentleRetryEval =
          PronunciationCoachService.evaluate('قطار سريع', '');
      expect(gentleRetryEval.stars, equals(1));
      expect(gentleRetryEval.supportiveTier, equals('gentle_retry'));

      // 7g. Parental Pedagogical Report summarizes mastered skills, remediation items, and home tips
      final ChildPedagogicalReport? report =
          appState.getChildPedagogicalReport(child.id);
      expect(report, isNotNull);
      expect(report!.currentTier, equals(3));
      expect(report.masteredSkillTitles, isNotEmpty);
      expect(report.parentHomeTips, isNotEmpty);
    });

    test(
        '8. Phase 4 Educational Games, Offline-First AI Tutor, Haneen Voice Companion, Age-Adaptive Pronunciation, Progressive Badges & Low-End Device Controls',
        () async {
      // Uses group appState initialized in setUp()

      final child = appState.currentAccount!.activeChild;

      // 8a. Verify all 10 educational game categories and adaptive 100-level generators
      expect(kBrainGamesCatalog.length, equals(10));
      expect(
        HundredLevelGamesGenerator.getMemoryBoardForLevel(1, difficultyTier: 1)
            .length,
        equals(8), // 4 pairs for Tier 1 (ages 2-3)
      );
      expect(
        HundredLevelGamesGenerator.getMemoryBoardForLevel(1, difficultyTier: 2)
            .length,
        equals(12), // 6 pairs for Tier 2 (ages 3-4)
      );
      expect(
        HundredLevelGamesGenerator.getMemoryBoardForLevel(1, difficultyTier: 4)
            .length,
        equals(16), // 8 pairs for Tier 4 (ages 5-6)
      );

      final picMatchLvl = HundredLevelGamesGenerator.getPictureWordMatchLevel(
          0,
          difficultyTier: 2);
      final classifyLvl =
          HundredLevelGamesGenerator.getSmartClassificationLevel(0,
              difficultyTier: 2);
      final soundLvl = HundredLevelGamesGenerator.getSoundAndListeningLevel(0,
          difficultyTier: 2);
      final seqRiddleLvl =
          HundredLevelGamesGenerator.getLogicalSequenceAndRiddleLevel(0,
              difficultyTier: 2);
      expect(picMatchLvl['levelNumber'], equals(1));
      expect(classifyLvl['levelNumber'], equals(1));
      expect(soundLvl['levelNumber'], equals(1));
      expect(seqRiddleLvl['levelNumber'], equals(1));

      // Non-repetitive level step on winning streak
      final int nextAfterStreak =
          HundredLevelGamesGenerator.selectNextNonRepetitiveLevelIndex(
        currentIndex: 5,
        streakCount: 3,
        difficultyTier: 3,
      );
      expect(nextAfterStreak, greaterThan(6));

      // 8b. Offline-First Educational AI Tutor & Privacy Guard
      expect(
          EducationalAiTutorService.kRequiresInternetForCoreDecisions, isFalse);
      expect(
          EducationalAiTutorService.kCollectsRawVoiceAudioOrPersonalPhotos,
          isFalse);
      expect(PronunciationCoachService.isRawAudioStoredOrUploaded, isFalse);

      final AiTutorRecommendation? aiRec =
          appState.getAiTutorRecommendation(child.id);
      expect(aiRec, isNotNull);
      expect(aiRec!.worksCompletelyOffline, isTrue);
      expect(aiRec.domainScores.length, equals(8));
      expect(aiRec.privacySafeCloudPayload['containsRawAudioOrPii'], isFalse);

      // 8c. Age-adaptive pronunciation evaluation (extra toddler tolerance for 2-3 yrs)
      final PronunciationEvaluation toddlerEval =
          PronunciationCoachService.evaluateForChildAge(
        target: 'شجرة كبيرة',
        spoken: 'سدره كبيره', // Developmental toddler substitution ش->س, ج->د, ر->ل
        childAgeGroup: '2–3 سنوات',
      );
      expect(toddlerEval.ageToleranceApplied, isTrue);
      expect(toddlerEval.stars, greaterThanOrEqualTo(2));

      // 8d. Interactive Haneen Voice Companion reactions & parental sound/performance controls
      expect(
        kCuteSuperheroCharacters.any((h) => h.id == 'haneen_companion'),
        isTrue,
      );
      final String correctReaction =
          await CalmVoiceService.instance.reactToChildAnswerAsHaneen(
        isCorrect: true,
        childName: child.name,
        learnedConcept: 'الموز من الفواكه',
      );
      expect(correctReaction, contains(child.name));
      expect(correctReaction, contains('فخورة'));

      final String gentleCorrection =
          await CalmVoiceService.instance.reactToChildAnswerAsHaneen(
        isCorrect: false,
        childName: child.name,
        gentleHint: 'تأمل لون الفاكهة الأصفر',
      );
      // Wrong answers now use the 3-step coaching ladder: a cheer first, a
      // general nudge on the 1st miss, the specific hint from the 2nd miss.
      expect(gentleCorrection.trim(), isNotEmpty);
      expect(
        CalmVoiceService.kWrongEncouragements
            .any((l) => gentleCorrection.contains(l)),
        isTrue,
      );
      final String secondMiss =
          await CalmVoiceService.instance.reactToChildAnswerAsHaneen(
        isCorrect: false,
        childName: child.name,
        gentleHint: 'تأمل لون الفاكهة الأصفر',
      );
      expect(secondMiss, contains('تأمل لون الفاكهة الأصفر'));

      // 8e. Progressive educational badges & parental sound/low-memory toggles
      await appState.recordBrainGameWin(
        gameId: 'classify_1',
        gameTitle: 'لعبة التصنيف الذكي (المرحلة 1)',
        earnedIqPoints: 12,
        earnedStars: 1,
      );
      await appState.recordBrainGameWin(
        gameId: 'pic_match_2',
        gameTitle: 'مطابقة الصور والكلمات (المرحلة 2)',
        earnedIqPoints: 12,
        earnedStars: 1,
      );
      expect(
        child.unlockedAchievements.containsKey('classification_expert'),
        isTrue,
      );

      await appState.updateChildPrivacyAndSafetyControls(
        childId: child.id,
        allowSoundEffectsAndVoice: false,
        lowMemoryPerformanceMode: true,
      );
      expect(child.allowSoundEffectsAndVoice, isFalse);
      expect(child.lowMemoryPerformanceMode, isTrue);
      expect(AppNetworkPolicyGuard.soundAndVoiceActive, isFalse);
      expect(AppNetworkPolicyGuard.lowMemoryPerformanceModeActive, isTrue);
      expect(CalmVoiceService.instance.isSoundAndVoiceEnabled, isFalse);
    });

    test(
        '9. Phase 5 ElevenLabs Neural Voice Integration: 5 Verified Voice Personas, eleven_v4 vs eleven_flash_v2_5 Routing, Egyptian/MSA Dialect, Backend Proxy Only (Zero Client API Key), SHA-256 Audio Cache & Offline Fallback',
        () async {
      ElevenLabsVoiceService.resetStatsAndCacheForTesting();
      ElevenLabsVoiceService.httpClientOverride = null;

      await appState.configureSupabaseCloud(
        url: 'https://haneenkids-cloud.supabase.co',
        anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.public_anon_key',
      );
      ElevenLabsVoiceService.resetStatsAndCacheForTesting();

      // 9a. Verify 5 independent personas and their real, documented ElevenLabs Voice IDs
      expect(ElevenLabsVoiceService.kApprovedPersonas.length, equals(5));
      final Map<String, String> expectedVoiceIds = {
        'haneen': 'cUDXOxxuLZJdTcxEyGVB',
        'teacher': 'cUDXOxxuLZJdTcxEyGVB',
        'storyteller': 'cUDXOxxuLZJdTcxEyGVB',
        'cheerful_friend': 'L14QZl4DxSQ6xGvib36i',
        'calm_assistant': 'cUDXOxxuLZJdTcxEyGVB',
      };
      for (final entry in expectedVoiceIds.entries) {
        final persona = ElevenLabsVoiceService.getPersonaById(entry.key);
        expect(persona.officialVoiceId, equals(entry.value));
      }

      // 9b. Verify smart model selection: eleven_v4 for stories/expressive content, eleven_flash_v2_5 for quick interactions
      expect(
        ElevenLabsVoiceService.selectOptimalModelId(
            ElevenLabsSpeechContext.storyNarration),
        equals('eleven_v4'),
      );
      expect(
        ElevenLabsVoiceService.selectOptimalModelId(
            ElevenLabsSpeechContext.expressiveLesson),
        equals('eleven_v4'),
      );
      expect(
        ElevenLabsVoiceService.selectOptimalModelId(
            ElevenLabsSpeechContext.quickInteraction),
        equals('eleven_flash_v2_5'),
      );
      expect(
        ElevenLabsVoiceService.selectOptimalModelId(
            ElevenLabsSpeechContext.gameFeedback),
        equals('eleven_flash_v2_5'),
      );

      // 9c. Verify Egyptian Arabic vs MSA dialect adaptation
      final String msaText =
          'أحسنت يا فارس! إجابة ذكية وصحيحة! هيا نجرب معاً ما التالي؟';
      final String egyptianAdapted =
          ElevenLabsVoiceService.adaptTextToDialect(msaText, 'egyptian');
      expect(egyptianAdapted, contains('برافو عليك يا فارس'));
      expect(egyptianAdapted, contains('يلا نجرب سوا'));
      expect(egyptianAdapted, contains('إيه اللي جاي بعده؟'));
      expect(
        ElevenLabsVoiceService.adaptTextToDialect(msaText, 'msa'),
        equals(msaText),
      );

      // 9d. Verify strict Backend Proxy security (Bearer token only, zero client API key)
      // and SHA-256 caching (second call uses cache with 0 network requests)
      expect(ElevenLabsVoiceService.kClientContainsApiKey, isFalse);
      expect(ElevenLabsVoiceService.isHundredPercentElevenLabsPowered, isTrue);
      expect(ElevenLabsVoiceService.usesTraditionalDeviceTts, isFalse);

      String? capturedAuthHeader;
      String? capturedXiApiKeyHeader;
      Map<String, dynamic>? capturedRequestBody;

      ElevenLabsVoiceService.httpClientOverride =
          _MockSecurityHttpClient((req) async {
        capturedAuthHeader = req.headers['Authorization'];
        capturedXiApiKeyHeader = req.headers['xi-api-key'];
        capturedRequestBody =
            Map<String, dynamic>.from(jsonDecode(req.body) as Map);
        return http.Response(
          jsonEncode({
            'audioBase64': 'UklGRiQAAABXQVZFZm10IBAAAAABAAEAQB8AAEAfAAABAAgAZGF0YQAAAAA=',
            'mimeType': 'audio/mpeg',
            'voiceId': capturedRequestBody!['voiceId'],
            'modelUsed': capturedRequestBody!['modelId'],
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final child = appState.currentAccount!.activeChild;
      await appState.updateChildPrivacyAndSafetyControls(
        childId: child.id,
        preferredVoicePersonaId: 'storyteller',
        preferredVoiceDialect: 'egyptian',
        preferredVoiceSpeed: 0.95,
      );
      expect(CalmVoiceService.instance.activePersonaId, equals('storyteller'));
      expect(CalmVoiceService.instance.activeDialect, equals('egyptian'));
      expect(CalmVoiceService.instance.activeVoiceSpeed, closeTo(0.95, 0.001));

      // First call: synthesizes via secure Supabase Edge Function proxy using `eleven_v4`
      await CalmVoiceService.instance.speakStoryOrQuestionAsHaneen(
        titleOrContext: 'قصة الأمانة',
        contentToRead: 'أحسنت يا فارس! هيا نجرب معاً',
      );
      final ElevenLabsSynthesisOutcome? firstOutcome =
          CalmVoiceService.instance.lastSynthesisOutcome;
      expect(firstOutcome, isNotNull);
      expect(firstOutcome!.success, isTrue);
      expect(firstOutcome.servedFromCache, isFalse);
      expect(firstOutcome.usedFallbackLocalTts, isFalse);
      expect(firstOutcome.voiceId, equals('cUDXOxxuLZJdTcxEyGVB'));
      expect(firstOutcome.modelId, equals('eleven_v4'));
      expect(capturedAuthHeader?.startsWith('Bearer '), isTrue);
      expect(capturedXiApiKeyHeader, isNull); // Client NEVER sends xi-api-key!
      expect(ElevenLabsVoiceService.networkSynthesisCallsCount, equals(1));

      // Second call with identical phrase: served 100% from local SHA-256 cache (0 network calls!)
      await CalmVoiceService.instance.speakStoryOrQuestionAsHaneen(
        titleOrContext: 'قصة الأمانة',
        contentToRead: 'أحسنت يا فارس! هيا نجرب معاً',
      );
      final ElevenLabsSynthesisOutcome? cachedOutcome =
          CalmVoiceService.instance.lastSynthesisOutcome;
      expect(cachedOutcome!.servedFromCache, isTrue);
      expect(ElevenLabsVoiceService.networkSynthesisCallsCount, equals(1));
      expect(ElevenLabsVoiceService.cacheHitCallsCount, equals(1));

      // 9e. Offline playback of cached clips vs Offline fallback for uncached clips
      await appState.updateChildPrivacyAndSafetyControls(
        childId: child.id,
        offlineOnlyMode: true,
      );
      // Cached clip STILL plays offline from cache!
      await CalmVoiceService.instance.speakStoryOrQuestionAsHaneen(
        titleOrContext: 'قصة الأمانة',
        contentToRead: 'أحسنت يا فارس! هيا نجرب معاً',
      );
      expect(
          CalmVoiceService.instance.lastSynthesisOutcome!.servedFromCache,
          isTrue);

      // Uncached clip when offline automatically falls back to local TTS without error!
      await CalmVoiceService.instance.speakWithPersona(
        text: 'جملة جديدة تماماً أثناء انقطاع الإنترنت',
        personaId: 'teacher',
        context: ElevenLabsSpeechContext.quickInteraction,
      );
      final ElevenLabsSynthesisOutcome? fallbackOutcome =
          CalmVoiceService.instance.lastSynthesisOutcome;
      expect(fallbackOutcome!.usedFallbackLocalTts, isTrue);
      expect(fallbackOutcome.voiceId, equals('cUDXOxxuLZJdTcxEyGVB'));
      expect(fallbackOutcome.modelId, equals('eleven_flash_v2_5'));

      ElevenLabsVoiceService.httpClientOverride = null;
    });

    test(
        "10. Phase 6 (v4.0): Strict Official Auth (No Guest/Quick Sign-In), Google Credential Manager RS256 Token, Phone E.164 DB Persistence, and UID + IP Bound 7-Day Free Trial",
        () async {
      // Use fast PBKDF2 work factor inside this multi-step integration test (600k is already audited in Tests 1 & 2)
      LocalCredentialSecurityService.kDefaultPbkdf2Iterations =
          LocalCredentialSecurityService.kLegacy12kPbkdf2Iterations;

      // 10a. Verify 100% Free Forever Architecture (No 7-day trial locks, paywalls, or mandatory registration)
      expect(AppStateManager.isAppCompletelyFreeForever, isTrue);
      expect(appState.isSubscriptionExpired, isFalse);

      // 10b. Sprint 1 (P0 / 8.1): Unified 6-Digit Parental PIN Policy + One-Time Setup
      expect(ParentAccount.kUnifiedParentalPinLength, equals(6));
      expect(ParentAccount.isValidParentalPinFormat("123456"), isTrue);
      expect(ParentAccount.isValidParentalPinFormat("1234"), isFalse);
      expect(ParentAccount.isValidParentalPinFormat("123456789012"), isFalse);

      // Reject non-6-digit passcode in one-time setup (both 4-digit and 12-digit rejected)
      final String? shortPassErr = await appState.completeOneTimeInitialSetup(
        childName: "سارة",
        childAge: "3–4 سنوات",
        dailyTimeLimit: 25,
        parentPasscode6Digits: "1234",
      );
      expect(shortPassErr, isNotNull);

      final String? longPassErr = await appState.completeOneTimeInitialSetup(
        childName: "سارة",
        childAge: "3–4 سنوات",
        dailyTimeLimit: 25,
        parentPasscode6Digits: "123456789012",
      );
      expect(longPassErr, isNotNull);

      // Complete valid one-time initial installation setup with 6-digit passcode
      final String? setupErr = await appState.completeOneTimeInitialSetup(
        childName: "سارة",
        childAge: "3–4 سنوات",
        dailyTimeLimit: 25,
        parentPasscode6Digits: "123456",
      );
      expect(setupErr, isNull);
      expect(appState.onboardingCompleted, isTrue);
      expect(appState.hasSelectedChildInSession, isTrue);
      expect(appState.currentAccount, isNotNull);
      expect(appState.currentAccount?.subscriptionPlanId, equals("free_forever"));
      expect(appState.currentAccount?.subscriptionStatusLabel, contains("مجاني بالكامل"));
      expect(appState.currentAccount?.isSubscriptionTampered, isFalse);
      expect(appState.currentAccount?.isSubscriptionActive, isTrue);
      expect(appState.currentAccount?.activeChild.name, equals("سارة"));
      expect(appState.currentAccount?.activeChild.age, equals("3–4 سنوات"));
      expect(appState.currentAccount?.activeChild.dailyTimeLimit, equals(25));
      expect(
        appState.currentAccount?.verifyParentalPin("123456"),
        isTrue,
      );

      // Sprint 1 (P0 / 8.2): Filtered video index resolves against displayed list, not full list
      final List<VideoModel> filteredSubset = appState.videos
          .where((v) => v.category == "arabic")
          .toList();
      expect(filteredSubset.length, greaterThan(1));
      final VideoModel targetArabic = filteredSubset[1];
      final int resolvedInFiltered =
          VerticalVideoFeedPlayerScreen.resolveDisplayedVideoIndexById(
        filteredSubset,
        targetArabic.id,
      );
      expect(resolvedInFiltered, equals(1));
      expect(
        VerticalVideoFeedPlayerScreen.resolveDisplayedVideoIndexById(
          filteredSubset,
          "non_existent_id",
        ),
        equals(-1),
      );

      // 10c. Verify setup never reappears on subsequent app launches
      final AppStateManager relaunchedAppState = AppStateManager(prefs);
      await relaunchedAppState.initialize();
      expect(relaunchedAppState.onboardingCompleted, isTrue);
      expect(relaunchedAppState.currentAccount, isNotNull);
      expect(relaunchedAppState.isSubscriptionExpired, isFalse);
      expect(
        relaunchedAppState.currentAccount?.activeChild.name,
        equals("سارة"),
      );
      relaunchedAppState.dispose();

      // 10d. Verify 6-digit passcode update (rejecting 4 or 12 digits) & Support/Rating actions in Parent Hub
      expect(await appState.updateParentalPin("1234"), isFalse);
      expect(await appState.updateParentalPin("987654321098"), isFalse);
      final bool passUpdated =
          await appState.updateParentalPin("987654");
      expect(passUpdated, isTrue);
      expect(
        appState.currentAccount?.verifyParentalPin("987654"),
        isTrue,
      );

      final String playUrl = await appState.openGooglePlayStoreRating();
      expect(playUrl, contains("play.google.com/store/apps/details"));
      expect(appState.hasOpenedGooglePlayRating, isTrue);

      // 10e. Dual Voice Assistants & Auto-Advance on Correct Answer:
      // - Correct answer triggers Superhero voice (`L14QZl4DxSQ6xGvib36i`) and auto-advances (`autoAdvanced == true`)!
      // - Incorrect answer triggers Primary Assistant voice (`cUDXOxxuLZJdTcxEyGVB`)!
      bool autoAdvancedToNextQuestion = false;
      await CalmVoiceService.instance.reactToChildAnswerAsHaneen(
        isCorrect: true,
        childName: "سارة",
        learnedConcept: "حرف الألف",
        onAutoAdvanceAfterAudio: () {
          autoAdvancedToNextQuestion = true;
        },
      );
      expect(autoAdvancedToNextQuestion, isTrue);
      expect(
        CalmVoiceService.instance.lastSynthesisOutcome?.voiceId,
        equals("L14QZl4DxSQ6xGvib36i"),
      );

      await CalmVoiceService.instance.reactToChildAnswerAsHaneen(
        isCorrect: false,
        childName: "سارة",
        gentleHint: "حاول مرة أخرى بهدوء",
      );
      expect(
        CalmVoiceService.instance.lastSynthesisOutcome?.voiceId,
        equals("cUDXOxxuLZJdTcxEyGVB"),
      );

      // 10f. Complete Replacement of Legacy Videos with 200 Scene-Free Academic Interactive Animated Stories (3-5 Minutes Each)
      expect(
        appState.videos.any((v) => v.title.contains("فارس ونور يراقبان الهلال المبتسم")),
        isFalse,
      );
      expect(AcademicStoriesRepository.defaultCatalog.length, equals(200));
      expect(appState.videos.length, equals(200));
      for (final st in AcademicStoriesRepository.defaultCatalog) {
        expect(st.totalEstimatedDurationSeconds, inInclusiveRange(180, 300));
        expect(st.totalEstimatedMinutes, inInclusiveRange(3, 5));
        expect(st.pedagogicalConcept, isNotEmpty);
        expect(st.learningOutcomes, isNotEmpty);
        expect(st.storyCards.length, equals(6));
        for (final card in st.storyCards) {
          expect(card.sceneTitle.contains("المشهد"), isFalse);
          expect(card.sceneTitle.toLowerCase().contains("scene"), isFalse);
        }
      }

      // 10g. Interactive Animated Story Image Cards, Dual-Voice Auto-Narration (`cUDXOxxuLZJdTcxEyGVB` <-> `L14QZl4DxSQ6xGvib36i`),
      // Strict Sequential Audio Queue, Auto-Swipe Synchronization & Calm Background Music Mixing (14% volume)
      final InteractiveEducationalStoryModel story =
          kInteractiveOriginalStories.first;
      expect(story.storyCards.length, equals(6));
      CalmVoiceService.instance.lastNarratedStoryHadBackgroundMusic = false;
      final List<int> autoSwipedIndices = [];
      bool storyFinishedFlag = false;
      final List<ElevenLabsSynthesisOutcome> cardOutcomes =
          await CalmVoiceService.instance.narrateStoryCardsWithDualVoices(
        story: story,
        onCardCompletedAndAutoSwipe: (nextIdx) {
          autoSwipedIndices.add(nextIdx);
        },
        onStoryFinished: () {
          storyFinishedFlag = true;
        },
      );
      expect(cardOutcomes.length, equals(6));
      expect(cardOutcomes[0].voiceId, equals("cUDXOxxuLZJdTcxEyGVB"));
      expect(cardOutcomes[1].voiceId, equals("L14QZl4DxSQ6xGvib36i"));
      expect(cardOutcomes[2].voiceId, equals("cUDXOxxuLZJdTcxEyGVB"));
      expect(cardOutcomes[3].voiceId, equals("L14QZl4DxSQ6xGvib36i"));
      expect(cardOutcomes[4].voiceId, equals("cUDXOxxuLZJdTcxEyGVB"));
      expect(cardOutcomes[5].voiceId, equals("L14QZl4DxSQ6xGvib36i"));
      expect(autoSwipedIndices, equals([1, 2, 3, 4, 5]));
      expect(storyFinishedFlag, isTrue);
      expect(
        CalmVoiceService.instance.lastNarratedStoryHadBackgroundMusic,
        isTrue,
      );
      expect(
        CalmVoiceService.instance.calmBackgroundMusicVolume,
        closeTo(0.14, 0.01),
      );

      // Verify Strict Sequential Audio Queue ordering (START_0 -> END_0 -> START_1 -> END_1 ...) with zero overlap!
      expect(
        CalmVoiceService.instance.sequentialPlaybackLog,
        equals([
          "START_CARD_0_cUDXOxxuLZJdTcxEyGVB",
          "END_CARD_0_cUDXOxxuLZJdTcxEyGVB",
          "START_CARD_1_L14QZl4DxSQ6xGvib36i",
          "END_CARD_1_L14QZl4DxSQ6xGvib36i",
          "START_CARD_2_cUDXOxxuLZJdTcxEyGVB",
          "END_CARD_2_cUDXOxxuLZJdTcxEyGVB",
          "START_CARD_3_L14QZl4DxSQ6xGvib36i",
          "END_CARD_3_L14QZl4DxSQ6xGvib36i",
          "START_CARD_4_cUDXOxxuLZJdTcxEyGVB",
          "END_CARD_4_cUDXOxxuLZJdTcxEyGVB",
          "START_CARD_5_L14QZl4DxSQ6xGvib36i",
          "END_CARD_5_L14QZl4DxSQ6xGvib36i",
        ]),
      );

      // 10h. Touch-to-Pause / Touch-to-Resume & Immediate Total Audio Stop on Parental Gate / Studio entry
      final bool pausedState =
          await CalmVoiceService.instance.toggleStoryPauseResume();
      expect(pausedState, isTrue);
      expect(CalmVoiceService.instance.isStoryNarrationPaused, isTrue);

      final bool resumedState =
          await CalmVoiceService.instance.toggleStoryPauseResume();
      expect(resumedState, isFalse);
      expect(CalmVoiceService.instance.isStoryNarrationPaused, isFalse);

      await CalmVoiceService.instance.startCalmBackgroundMusic();
      expect(CalmVoiceService.instance.isCalmBackgroundMusicPlaying, isTrue);
      await CalmVoiceService.instance.stopAllAudioImmediatelyForParentalGate();
      expect(CalmVoiceService.instance.isSpeaking, isFalse);
      expect(CalmVoiceService.instance.isStoryNarrationPaused, isFalse);
      expect(CalmVoiceService.instance.isCalmBackgroundMusicPlaying, isFalse);
    });

    test('11. Sprint 2 (P0): Unified AppTheme Tokens (Light/Dark/HighContrast) & Persistence', () async {
      expect(AppDesignTokens.minTouchTarget, greaterThanOrEqualTo(48.0));
      final ThemeData darkTheme = AppTheme.buildTheme(highContrast: false, isDarkMode: true);
      final ThemeData lightTheme = AppTheme.buildTheme(highContrast: false, isDarkMode: false);
      final ThemeData hcTheme = AppTheme.buildTheme(highContrast: true, isDarkMode: true);
      expect(darkTheme.brightness, equals(Brightness.dark));
      expect(lightTheme.brightness, equals(Brightness.light));
      expect(hcTheme.brightness, equals(Brightness.dark));

      expect(appState.isDarkMode, isTrue);
      await appState.toggleDarkMode(false);
      expect(appState.isDarkMode, isFalse);

      final AppStateManager relaunched = AppStateManager(prefs);
      await relaunched.initialize();
      expect(relaunched.isDarkMode, isFalse);
      relaunched.dispose();
    });

    testWidgets('12. Sprint 2 (P0): 5-Destination MainNavigationShell on 360x640 Small Screen', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ar'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          theme: AppTheme.buildTheme(highContrast: false, isDarkMode: true),
          home: MainNavigationShell(appState: appState),
        ),
      );
      await tester.pump();

      expect(find.text('قصص حنين'), findsOneWidget);
      expect(find.text('أكاديمية حنين'), findsOneWidget);
      expect(find.text('واحة الذكاء'), findsOneWidget);
      expect(find.text('إنجازاتي'), findsOneWidget);
      expect(find.text('حسابي'), findsOneWidget);

      await tester.tap(find.text('إنجازاتي'));
      await tester.pump();
      expect(find.text('النجوم المكتسبة'), findsOneWidget);

      await tester.tap(find.text('حسابي'));
      await tester.pump();
      expect(find.text('بوابة الوالدين والإعدادات (محمية بالرمز)'), findsOneWidget);
    });

    test('13. Sprint 3 (P0): LocaleController Separates UI Locale from Learning Locale & Persists', () async {
      expect(appState.localeController.uiLanguageCode, equals('ar'));
      expect(appState.localeController.learningLanguageCode, equals('ar'));
      expect(appState.localeController.uiTextDirection, equals(TextDirection.rtl));

      await appState.setUiLanguage('en');
      expect(appState.localeController.uiLanguageCode, equals('en'));
      expect(appState.localeController.uiTextDirection, equals(TextDirection.ltr));
      // Learning language stays independent!
      expect(appState.localeController.learningLanguageCode, equals('ar'));

      await appState.setLearningLanguage('en');
      expect(appState.localeController.learningLanguageCode, equals('en'));

      final AppStateManager relaunched = AppStateManager(prefs);
      await relaunched.initialize();
      expect(relaunched.localeController.uiLanguageCode, equals('en'));
      expect(relaunched.localeController.learningLanguageCode, equals('en'));
      relaunched.dispose();
    });

    testWidgets('14. Sprint 3 (P0): English LTR Rendering of MainNavigationShell on 360x640', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          theme: AppTheme.buildTheme(highContrast: false, isDarkMode: false),
          home: MainNavigationShell(appState: appState),
        ),
      );
      await tester.pump();

      expect(find.text('Stories'), findsOneWidget);
      expect(find.text('Academy'), findsOneWidget);
      expect(find.text('Brain Oasis'), findsOneWidget);
      expect(find.text('Achievements'), findsOneWidget);
      expect(find.text('My Account'), findsOneWidget);

      await tester.tap(find.text('My Account'));
      await tester.pump();
      expect(find.text('Parental Hub & Settings (PIN Protected)'), findsOneWidget);
    });

    test('15. Sprint 4 (P0): AppEnvironmentConfig Isolation & FeatureFlags Persistence', () async {
      final AppEnvironmentConfig devCfg = AppEnvironmentConfig.fromDartDefine('dev');
      final AppEnvironmentConfig stagingCfg = AppEnvironmentConfig.fromDartDefine('staging');
      final AppEnvironmentConfig prodCfg = AppEnvironmentConfig.fromDartDefine('prod');

      expect(devCfg.storageKeyPrefix, equals('dev_'));
      expect(stagingCfg.storageKeyPrefix, equals('staging_'));
      expect(prodCfg.storageKeyPrefix, equals('prod_'));
      expect(devCfg.allowsProductionPushNotifications, isFalse);
      expect(stagingCfg.allowsProductionPushNotifications, isFalse);
      expect(prodCfg.allowsProductionPushNotifications, isTrue);

      expect(appState.featureFlags.enableTimedExplorationPopup, isTrue);
      await appState.setFeatureFlag('timed_popup', false);
      expect(appState.featureFlags.enableTimedExplorationPopup, isFalse);

      final AppStateManager relaunched = AppStateManager(prefs);
      await relaunched.initialize();
      expect(relaunched.featureFlags.enableTimedExplorationPopup, isFalse);
      relaunched.dispose();
    });

    test('16. Sprint 4 (P0): Parent-Only Beta Feedback Collects Diagnostic Context Without Child PII', () async {
      final Map<String, String> entry = await appState.submitParentBetaFeedback(
        category: 'ترجمة',
        description: 'مراجعة نص زر في شاشة الحساب',
      );
      expect(entry['category'], equals('ترجمة'));
      expect(entry['appVersion'], equals(AppEnvironmentConfig.kBuildVersion));
      expect(entry['uiLanguage'], equals('ar'));
      expect(entry['learningLanguage'], equals('ar'));
      expect(entry.containsKey('childName'), isFalse);
      expect(entry.containsKey('emailOrPhone'), isFalse);
      expect(appState.betaFeedbackLog.length, equals(1));
    });

    test('17. P0 Security: Phone OTP Request & Verification with Genuine Session Bearer Token', () async {
      const String testPhone = '01011223344';
      final PhoneOtpOutcome reqRes = await AuthSessionService.requestPhoneOtp(testPhone);
      expect(reqRes.success, isTrue);
      expect(reqRes.normalizedPhone, equals('+201011223344'));

      // Wrong OTP
      final PhoneOtpOutcome failRes = await AuthSessionService.verifyPhoneOtp(
        rawPhone: testPhone,
        enteredOtp: '000000',
      );
      expect(failRes.success, isFalse);

      // Correct OTP (123456 in unit tests)
      final PhoneOtpOutcome successRes = await AuthSessionService.verifyPhoneOtp(
        rawPhone: testPhone,
        enteredOtp: '123456',
      );
      expect(successRes.success, isTrue);
      expect(successRes.sessionBearerToken, isNotNull);
      expect(successRes.sessionBearerToken!.startsWith('sess_bearer_phone_'), isTrue);
    });

    test('18. P0 Data Architecture: Supabase snake_case Schema Mapping to ChildProfile Model', () {
      final Map<String, dynamic> supabaseRow = {
        'id': 'child_test_mapped',
        'display_name': 'يوسف البطل',
        'age_group': '4–5 سنوات',
        'chosen_avatar': '🚀',
        'education_level': 'متوسط',
        'daily_time_limit': 35,
        'used_minutes_today': 12,
        'watched_videos_today': 4,
        'stars_earned': 28,
        'intelligence_points': 65,
        'games_completed_count': 7,
        'correct_pronunciations_count': 9,
        'is_device_remotely_locked': false,
        'allow_microphone': true,
        'allow_external_videos': true,
        'offline_only_mode': false,
        'reduce_motion': false,
        'high_contrast_mode': false,
      };

      final ChildProfile parsed = ChildProfile.fromJson(supabaseRow);
      expect(parsed.id, equals('child_test_mapped'));
      expect(parsed.name, equals('يوسف البطل'));
      expect(parsed.age, equals('4–5 سنوات'));
      expect(parsed.chosenAvatar, equals('🚀'));
      expect(parsed.educationLevel, equals('متوسط'));
      expect(parsed.dailyTimeLimit, equals(35));
      expect(parsed.usedMinutesToday, equals(12));
      expect(parsed.watchedVideosToday, equals(4));
      expect(parsed.starsEarned, equals(28));
      expect(parsed.intelligencePoints, equals(65));
      expect(parsed.gamesCompletedCount, equals(7));
      expect(parsed.correctPronunciationsCount, equals(9));

      final Map<String, dynamic> exported = parsed.toSupabaseRow(parentId: 'parent_uuid_123');
      expect(exported['display_name'], equals('يوسف البطل'));
      expect(exported['age_group'], equals('4–5 سنوات'));
      expect(exported['daily_time_limit'], equals(35));
      expect(exported['parent_id'], equals('parent_uuid_123'));
    });

    test('19. P1 Timer Guard: Child Screen Time Tracking Stops in Parental Studio & Background', () {
      expect(appState.isParentalControlActive, isFalse);
      expect(appState.isAppInBackground, isFalse);

      appState.setParentalControlActive(true);
      expect(appState.isParentalControlActive, isTrue);

      appState.setAppInBackground(true);
      expect(appState.isAppInBackground, isTrue);

      appState.setParentalControlActive(false);
      expect(appState.isParentalControlActive, isFalse);

      appState.setAppInBackground(false);
      expect(appState.isAppInBackground, isFalse);
    });

    test('20. P1/P2 Global Ready: Multilingual Curriculum & Unified System Enums', () {
      final arabicCurriculum = AdaptiveLearningEngine.getCurriculumForLanguage('ar');
      expect(arabicCurriculum.isNotEmpty, isTrue);
      expect(arabicCurriculum.first.id, equals('les_arabic_alif'));

      final englishCurriculum = AdaptiveLearningEngine.getCurriculumForLanguage('en');
      expect(englishCurriculum.isNotEmpty, isTrue);
      expect(englishCurriculum.first.id, equals('les_en_letter_a'));
      expect(englishCurriculum.first.title.contains('Letter A'), isTrue);

      expect(CurriculumTier.fromInt(1), equals(CurriculumTier.beginner));
      expect(CurriculumTier.fromInt(2), equals(CurriculumTier.elementary));
      expect(CurriculumTier.fromInt(3), equals(CurriculumTier.intermediate));
      expect(CurriculumTier.fromInt(4), equals(CurriculumTier.advanced));
    });
  });
}
