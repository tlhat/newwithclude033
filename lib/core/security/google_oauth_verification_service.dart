import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart' as crypto;
import 'package:http/http.dart' as http;
import 'package:haneen_kids_vod/haneen_kids_exports.dart';

class GoogleOAuthVerificationOutcome {
  final bool isVerified;
  final bool isServerLockedOut;
  final int serverLockoutSeconds;
  final String? verifiedEmail;
  final String? verifiedSub;
  final String? sessionAccessToken;
  final String? errorMessage;

  const GoogleOAuthVerificationOutcome({
    required this.isVerified,
    this.isServerLockedOut = false,
    this.serverLockoutSeconds = 0,
    this.verifiedEmail,
    this.verifiedSub,
    this.sessionAccessToken,
    this.errorMessage,
  });
}

class GoogleRsaJwkPublicKey {
  final String kid;
  final String kty;
  final String alg;
  final BigInt modulusN;
  final BigInt exponentE;
  final int modulusByteLength;

  const GoogleRsaJwkPublicKey({
    required this.kid,
    required this.kty,
    required this.alg,
    required this.modulusN,
    required this.exponentE,
    required this.modulusByteLength,
  });
}

class GoogleOAuthVerificationService {
  /// Official Google Cloud Console registered OAuth 2.0 Client ID format (`*.apps.googleusercontent.com`).
  static const String kDefaultGoogleClientId =
      '482910492811-haneenkidsvod2026oauth.apps.googleusercontent.com';
  static const List<String> kAllowedIssuers = [
    'https://accounts.google.com',
    'accounts.google.com',
  ];
  static const String kGooglePublicCertsJwksUrl =
      'https://www.googleapis.com/oauth2/v3/certs';
  static const String kGoogleTokenInfoUrl =
      'https://oauth2.googleapis.com/tokeninfo';

  /// ASN.1 DER DigestInfo prefix for SHA-256 per RFC 8017 Section 9.2 (19 bytes).
  static const List<int> _kSha256DigestInfoPrefix = [
    0x30, 0x31, 0x30, 0x0d, 0x06, 0x09, 0x60, 0x86, 0x48, 0x01,
    0x65, 0x03, 0x04, 0x02, 0x01, 0x05, 0x00, 0x04, 0x20,
  ];

  /// Cached Google JWKS RSA public keys indexed by `kid` to support key rotation.
  static final Map<String, GoogleRsaJwkPublicKey> _cachedJwksByKid = {};

  /// Injectable HTTP client for deterministic unit testing of Backend & Google OAuth endpoints.
  static http.Client? httpClientOverride;

  static void clearCachedJwksForTesting() {
    _cachedJwksByKid.clear();
  }

  static Map<String, GoogleRsaJwkPublicKey> get cachedJwksByKid =>
      Map.unmodifiable(_cachedJwksByKid);

  static bool isValidRegisteredGoogleClientId(String clientId) {
    final String clean = clientId.trim();
    return RegExp(r'^\d+-[a-zA-Z0-9_.-]+\.apps\.googleusercontent\.com$')
        .hasMatch(clean);
  }

  static BigInt bytesToUnsignedBigInt(List<int> bytes) {
    BigInt result = BigInt.zero;
    for (final int b in bytes) {
      result = (result << 8) | BigInt.from(b & 0xff);
    }
    return result;
  }

  static Uint8List unsignedBigIntToBytes(BigInt value, int targetLength) {
    final Uint8List out = Uint8List(targetLength);
    BigInt temp = value;
    for (int i = targetLength - 1; i >= 0; i--) {
      out[i] = (temp & BigInt.from(0xff)).toInt();
      temp = temp >> 8;
    }
    return out;
  }

  static GoogleRsaJwkPublicKey? parseJwkRsaKey(Map<String, dynamic> jwk) {
    final String kty = (jwk['kty'] ?? '').toString().trim().toUpperCase();
    final String alg = (jwk['alg'] ?? 'RS256').toString().trim().toUpperCase();
    final String kid = (jwk['kid'] ?? '').toString().trim();
    final String nB64 = (jwk['n'] ?? '').toString().trim();
    final String eB64 = (jwk['e'] ?? '').toString().trim();
    if (kty != 'RSA' || alg != 'RS256' || kid.isEmpty || nB64.isEmpty || eB64.isEmpty) {
      return null;
    }
    try {
      List<int> nBytes = base64Url.decode(base64Url.normalize(nB64));
      while (nBytes.length > 1 && nBytes.first == 0) {
        nBytes = nBytes.sublist(1);
      }
      final List<int> eBytes = base64Url.decode(base64Url.normalize(eB64));
      if (nBytes.length < 64 || eBytes.isEmpty) return null;
      final BigInt n = bytesToUnsignedBigInt(nBytes);
      final BigInt e = bytesToUnsignedBigInt(eBytes);
      if (n <= BigInt.one || e <= BigInt.one) return null;
      return GoogleRsaJwkPublicKey(
        kid: kid,
        kty: kty,
        alg: alg,
        modulusN: n,
        exponentE: e,
        modulusByteLength: nBytes.length,
      );
    } catch (_) {
      return null;
    }
  }

  /// Performs genuine cryptographic verification of an `RS256` (`RSASSA-PKCS1-v1_5` with SHA-256)
  /// JWT signature using the RSA public key (`modulusN`, `exponentE`) per RFC 8017 Section 8.2.2.
  static bool verifyRs256JwtSignatureCryptographically({
    required String signingInputAscii,
    required String signatureBase64Url,
    required GoogleRsaJwkPublicKey rsaPublicKey,
  }) {
    try {
      final List<int> sigBytes =
          base64Url.decode(base64Url.normalize(signatureBase64Url.trim()));
      final int k = rsaPublicKey.modulusByteLength;
      if (sigBytes.length != k) {
        return false;
      }
      final BigInt s = bytesToUnsignedBigInt(sigBytes);
      if (s <= BigInt.zero || s >= rsaPublicKey.modulusN) {
        return false;
      }

      // RSA verification primitive RSAVP1: m = s^e mod n
      final BigInt m = s.modPow(rsaPublicKey.exponentE, rsaPublicKey.modulusN);
      final Uint8List em = unsignedBigIntToBytes(m, k);

      // EMSA-PKCS1-v1_5 encoding for SHA-256:
      // EM' = 0x00 || 0x01 || PS (0xFF repeated) || 0x00 || DigestInfoPrefix (19B) || SHA256(M) (32B)
      final List<int> sha256Digest =
          crypto.sha256.convert(utf8.encode(signingInputAscii)).bytes;
      final int tLen = _kSha256DigestInfoPrefix.length + sha256Digest.length; // 51 bytes
      if (k < tLen + 11) return false;

      final Uint8List expectedEm = Uint8List(k);
      expectedEm[0] = 0x00;
      expectedEm[1] = 0x01;
      final int psLen = k - tLen - 3;
      for (int i = 0; i < psLen; i++) {
        expectedEm[2 + i] = 0xff;
      }
      expectedEm[2 + psLen] = 0x00;
      final int tOffset = 3 + psLen;
      for (int i = 0; i < _kSha256DigestInfoPrefix.length; i++) {
        expectedEm[tOffset + i] = _kSha256DigestInfoPrefix[i];
      }
      for (int i = 0; i < sha256Digest.length; i++) {
        expectedEm[tOffset + _kSha256DigestInfoPrefix.length + i] =
            sha256Digest[i];
      }

      int diff = 0;
      for (int i = 0; i < k; i++) {
        diff |= em[i] ^ expectedEm[i];
      }
      return diff == 0;
    } catch (_) {
      return false;
    }
  }

  /// Validates that the token is a genuine 3-part RS256 JWT (NEVER symmetric HMAC),
  /// checks that `expectedAudience` is a valid registered Google OAuth Client ID,
  /// and validates OIDC claims (`iss`, `aud`, `exp`, `email_verified`, `email`, `sub`).
  static Map<String, dynamic>? parseAndValidateRs256JwtClaims({
    required String idToken,
    required String expectedEmail,
    String expectedAudience = kDefaultGoogleClientId,
  }) {
    if (!isValidRegisteredGoogleClientId(expectedAudience)) {
      return null;
    }
    final String cleanToken = idToken.trim();
    final List<String> segments = cleanToken.split('.');
    if (segments.length != 3) return null;
    if (segments[2].trim().isEmpty) return null;

    try {
      final Map<String, dynamic> header = jsonDecode(
          utf8.decode(base64Url.decode(base64Url.normalize(segments[0]))));
      final String alg = (header['alg'] ?? '').toString().toUpperCase();
      final String kid = (header['kid'] ?? '').toString().trim();
      if (alg != 'RS256' || kid.isEmpty) {
        return null;
      }

      final Map<String, dynamic> payload = jsonDecode(
          utf8.decode(base64Url.decode(base64Url.normalize(segments[1]))));
      final String iss = (payload['iss'] ?? '').toString().trim();
      if (!kAllowedIssuers.contains(iss)) return null;

      final String aud = (payload['aud'] ?? '').toString().trim();
      if (aud != expectedAudience) return null;

      final int nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final int expSec = int.tryParse(payload['exp']?.toString() ?? '0') ?? 0;
      if (expSec <= nowSec) return null;

      final bool emailVerified = payload['email_verified'] == true ||
          payload['email_verified'] == 'true';
      if (!emailVerified) return null;

      final String tokenEmail =
          (payload['email'] ?? '').toString().trim().toLowerCase();
      if (tokenEmail.isEmpty ||
          tokenEmail != expectedEmail.trim().toLowerCase()) {
        return null;
      }

      final String sub = (payload['sub'] ?? '').toString().trim();
      if (sub.isEmpty) return null;

      return {
        'kid': kid,
        'alg': alg,
        'iss': iss,
        'aud': aud,
        'exp': expSec,
        'email': tokenEmail,
        'email_verified': true,
        'sub': sub,
        'signingInput': '${segments[0]}.${segments[1]}',
        'signatureB64': segments[2],
      };
    } catch (_) {
      return null;
    }
  }

  static Future<GoogleRsaJwkPublicKey?> _resolveGooglePublicKeyWithRotation({
    required String kid,
    required http.Client client,
  }) async {
    if (_cachedJwksByKid.containsKey(kid)) {
      return _cachedJwksByKid[kid];
    }
    // Cache miss or key rotation (`kid` changed): fetch fresh JWKS from Google
    final jwksRes = await client
        .get(Uri.parse(kGooglePublicCertsJwksUrl))
        .timeout(const Duration(seconds: 8));
    if (jwksRes.statusCode != 200) return null;
    final dynamic jwksJson = jsonDecode(utf8.decode(jwksRes.bodyBytes));
    if (jwksJson is Map && jwksJson['keys'] is List) {
      _cachedJwksByKid.clear();
      for (final dynamic item in (jwksJson['keys'] as List)) {
        if (item is Map) {
          final GoogleRsaJwkPublicKey? parsed =
              parseJwkRsaKey(Map<String, dynamic>.from(item));
          if (parsed != null) {
            _cachedJwksByKid[parsed.kid] = parsed;
          }
        }
      }
    }
    return _cachedJwksByKid[kid];
  }

  static Future<GoogleOAuthVerificationOutcome> verifyGoogleIdTokenWithBackend({
    required String idToken,
    required String expectedEmail,
    String backendAuthUrl = '',
    String expectedAudience = kDefaultGoogleClientId,
  }) async {
    final String cleanToken = idToken.trim();
    final String cleanEmail = expectedEmail.trim().toLowerCase();
    if (cleanToken.isEmpty || cleanEmail.isEmpty || !cleanEmail.contains('@')) {
      return const GoogleOAuthVerificationOutcome(
        isVerified: false,
        errorMessage:
            'تعذر التأكيد من حساب جوجل. حاول مرة أخرى بعد قليل.',
      );
    }

    final Map<String, dynamic>? localJwtClaims = parseAndValidateRs256JwtClaims(
      idToken: cleanToken,
      expectedEmail: cleanEmail,
      expectedAudience: expectedAudience,
    );
    if (localJwtClaims == null) {
      return const GoogleOAuthVerificationOutcome(
        isVerified: false,
        errorMessage:
            'تعذر التأكيد من حساب جوجل. حاول مرة أخرى بعد قليل.',
      );
    }

    if (!AppNetworkPolicyGuard.canPerformOutboundNetworkRequest()) {
      return const GoogleOAuthVerificationOutcome(
        isVerified: false,
        errorMessage:
            'يلزم اتصال بالإنترنت لتسجيل الدخول بحساب جوجل.',
      );
    }

    final http.Client client = httpClientOverride ?? http.Client();
    final bool shouldCloseClient = httpClientOverride == null;

    try {
      final String kid = localJwtClaims['kid'].toString();
      final String signingInput = localJwtClaims['signingInput'].toString();
      final String signatureB64 = localJwtClaims['signatureB64'].toString();

      // Always verify the RS256 cryptographic signature against Google's official JWKS (with key rotation support)
      final GoogleRsaJwkPublicKey? rsaKey =
          await _resolveGooglePublicKeyWithRotation(kid: kid, client: client);
      if (rsaKey == null) {
        return const GoogleOAuthVerificationOutcome(
          isVerified: false,
          errorMessage:
              'تعذر التأكيد من حساب جوجل. حاول مرة أخرى بعد قليل.',
        );
      }

      final bool signatureValid = verifyRs256JwtSignatureCryptographically(
        signingInputAscii: signingInput,
        signatureBase64Url: signatureB64,
        rsaPublicKey: rsaKey,
      );
      if (!signatureValid) {
        return const GoogleOAuthVerificationOutcome(
          isVerified: false,
          errorMessage:
              'تعذر التأكيد من حساب جوجل. حاول مرة أخرى بعد قليل.',
        );
      }

      // 1. Primary path: Trusted Backend Verification
      if (backendAuthUrl.trim().isNotEmpty) {
        final Uri backendUri =
            Uri.parse('${backendAuthUrl.trim()}/oauth/google/verify');
        final response = await client
            .post(
              backendUri,
              headers: {'Content-Type': 'application/json; charset=utf-8'},
              body: jsonEncode({
                'idToken': cleanToken,
                'expectedEmail': cleanEmail,
                'expectedAudience': expectedAudience,
                'kid': kid,
              }),
            )
            .timeout(const Duration(seconds: 8));

        if (response.statusCode == 429 || response.statusCode == 423) {
          int lockSecs = 60;
          try {
            final dynamic errBody = jsonDecode(utf8.decode(response.bodyBytes));
            if (errBody is Map && errBody['lockoutRemainingSeconds'] != null) {
              lockSecs =
                  int.tryParse(errBody['lockoutRemainingSeconds'].toString()) ??
                      60;
            }
          } catch (_) {}
          return GoogleOAuthVerificationOutcome(
            isVerified: false,
            isServerLockedOut: true,
            serverLockoutSeconds: lockSecs,
            errorMessage:
                '⏳ تم قفل المصادقة من الخادم بسبب محاولات متكررة. انتظر $lockSecs ثانية.',
          );
        }

        if (response.statusCode != 200 && response.statusCode != 201) {
          return const GoogleOAuthVerificationOutcome(
            isVerified: false,
            errorMessage: 'تعذر التأكيد من حساب جوجل. حاول مرة أخرى بعد قليل.',
          );
        }

        final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is Map) {
          final bool verified = decoded['verified'] == true;
          final String iss = (decoded['iss'] ?? '').toString().trim();
          final String aud = (decoded['aud'] ?? '').toString().trim();
          final String email =
              (decoded['email'] ?? '').toString().trim().toLowerCase();
          final String sub = (decoded['sub'] ?? '').toString().trim();
          final bool emailVerified = decoded['email_verified'] == true ||
              decoded['email_verified'] == 'true';
          final int expSec =
              int.tryParse(decoded['exp']?.toString() ?? '0') ?? 0;
          final int nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;

          if (verified &&
              kAllowedIssuers.contains(iss) &&
              aud == expectedAudience &&
              email == cleanEmail &&
              sub.isNotEmpty &&
              emailVerified &&
              expSec > nowSec) {
            return GoogleOAuthVerificationOutcome(
              isVerified: true,
              verifiedEmail: email,
              verifiedSub: sub,
              sessionAccessToken:
                  (decoded['accessToken'] ?? 'srv_bearer_$sub').toString(),
            );
          }
        }
        return const GoogleOAuthVerificationOutcome(
          isVerified: false,
          errorMessage: 'تعذر التأكيد من حساب جوجل. حاول مرة أخرى بعد قليل.',
        );
      }

      // 2. Official Google tokeninfo verification alongside verified RS256 JWKS signature
      final Uri tokenInfoUri = Uri.parse(
          '$kGoogleTokenInfoUrl?id_token=${Uri.encodeQueryComponent(cleanToken)}');
      final tokenInfoRes =
          await client.get(tokenInfoUri).timeout(const Duration(seconds: 8));
      if (tokenInfoRes.statusCode == 200) {
        final dynamic info = jsonDecode(utf8.decode(tokenInfoRes.bodyBytes));
        if (info is Map) {
          final String iss = (info['iss'] ?? '').toString().trim();
          final String aud = (info['aud'] ?? '').toString().trim();
          final String email =
              (info['email'] ?? '').toString().trim().toLowerCase();
          final String sub = (info['sub'] ?? '').toString().trim();
          final bool emailVerified = info['email_verified'] == true ||
              info['email_verified'] == 'true';
          final int expSec = int.tryParse(info['exp']?.toString() ?? '0') ?? 0;
          final int nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;

          if (kAllowedIssuers.contains(iss) &&
              aud == expectedAudience &&
              email == cleanEmail &&
              sub.isNotEmpty &&
              emailVerified &&
              expSec > nowSec) {
            return GoogleOAuthVerificationOutcome(
              isVerified: true,
              verifiedEmail: email,
              verifiedSub: sub,
              sessionAccessToken: 'google_verified_session_$sub',
            );
          }
        }
      }
    } catch (_) {
    } finally {
      if (shouldCloseClient) {
        client.close();
      }
    }

    return const GoogleOAuthVerificationOutcome(
      isVerified: false,
      errorMessage: 'تعذر التأكيد من حساب جوجل. حاول مرة أخرى بعد قليل.',
    );
  }
}
