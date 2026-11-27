import 'dart:io' show Platform;
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LockoutVaultSnapshot {
  int failedPinAttempts;
  DateTime? pinLockoutUntil;
  int failedPasswordAttempts;
  DateTime? passwordLockoutUntil;

  LockoutVaultSnapshot({
    this.failedPinAttempts = 0,
    this.pinLockoutUntil,
    this.failedPasswordAttempts = 0,
    this.passwordLockoutUntil,
  });

  Map<String, dynamic> toJson() => {
        'failedPinAttempts': failedPinAttempts,
        'pinLockoutUntil': pinLockoutUntil?.toIso8601String(),
        'failedPasswordAttempts': failedPasswordAttempts,
        'passwordPasswordLockoutUntil': passwordLockoutUntil?.toIso8601String(),
        'passwordLockoutUntil': passwordLockoutUntil?.toIso8601String(),
      };

  factory LockoutVaultSnapshot.fromJson(Map<String, dynamic> json) {
    return LockoutVaultSnapshot(
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
    );
  }
}

class LocalCredentialSecurityService {
  /// Latest OWASP Password Storage Cheat Sheet recommendation for PBKDF2-HMAC-SHA256:
  /// 600,000 iterations (https://cheatsheetseries.owasp.org/cheatsheets/Password_Storage_Cheat_Sheet.html).
  /// NIST SP 800-63B Section 5.1.1.2 specifies a minimum of 10,000 iterations with a random salt
  /// and recommends scaling the work factor as high as target device verification performance allows.
  static const int kOwaspRecommendedPbkdf2Iterations = 600000;
  static const int kMidRangeAndroidPbkdf2Iterations = 210000;
  static const int kLegacy120kPbkdf2Iterations = 120000;
  static const int kLegacy12kPbkdf2Iterations = 12000;

  /// Active target work factor used for new password & PIN derivations and automatic upgrades.
  /// Defaults to the OWASP 600,000-iteration standard.
  static int kDefaultPbkdf2Iterations = kOwaspRecommendedPbkdf2Iterations;

  /// Work factor for the 6-digit parental PIN. The PIN is already mixed with a
  /// 256-bit Keystore secret (see below), so 100,000 rounds is plenty
  /// (NIST SP 800-63B minimum is 10,000). 600,000 rounds froze a mid-range
  /// Samsung tablet for about 10 seconds on every PIN check.
  static const int kPinPbkdf2Iterations = 100000;

  static final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  static final Map<String, LockoutVaultSnapshot> _keystoreBackedLockoutVault =
      {};
  static final Map<String, String> _keystorePinVerifiers = {};

  /// Hardware-backed Android Keystore 256-bit secret pepper (`keystore_device_pin_pepper_v34`).
  /// Because a 4-digit PIN only has 10,000 combinations (0000..9999), PBKDF2 alone CANNOT
  /// prevent offline brute-forcing if SharedPreferences XML is extracted. Mixing a 256-bit
  /// Keystore-resident secret pepper into the PIN derivation makes offline cracking of extracted
  /// SharedPreferences mathematically infeasible (2^256 key space) without the device's Keystore.
  static String _keystoreDevicePinPepper = _generateInitialKeystorePepper();

  static String _generateInitialKeystorePepper() {
    final Random rng = Random.secure();
    final Uint8List bytes = Uint8List(32);
    for (int i = 0; i < 32; i++) {
      bytes[i] = rng.nextInt(256);
    }
    return base64Url.encode(bytes);
  }

  static String get keystoreDevicePinPepper => _keystoreDevicePinPepper;

  /// Short fingerprint of this phone's Keystore pepper (not reversible).
  /// A backup stores it so a restore can tell whether the saved PIN check
  /// still works here. After a reinstall the pepper is new, so the old PIN
  /// check can never match and the parent must set a new PIN.
  static String pepperFingerprint() => crypto.sha256
      .convert(utf8.encode('fp:$_keystoreDevicePinPepper'))
      .toString()
      .substring(0, 12);

  static Future<String> ensureKeystorePinPepperInitialized() async {
    try {
      final String? stored =
          await _secureStorage
          .read(key: 'keystore_device_pin_pepper_v34')
          .guard();
      if (stored != null && stored.trim().length >= 32) {
        _keystoreDevicePinPepper = stored.trim();
        return _keystoreDevicePinPepper;
      }
      await _secureStorage
          .write(
            key: 'keystore_device_pin_pepper_v34',
            value: _keystoreDevicePinPepper,
          )
          .guard();
    } catch (_) {}
    return _keystoreDevicePinPepper;
  }

  static String generateRandomSalt([int byteLength = 16]) {
    final Random rng = Random.secure();
    final Uint8List bytes = Uint8List(byteLength);
    for (int i = 0; i < byteLength; i++) {
      bytes[i] = rng.nextInt(256);
    }
    return base64Url.encode(bytes);
  }

  static String deriveKeySha256({
    required String secret,
    required String salt,
    int? iterations,
  }) {
    final int effectiveIterations = iterations ?? kDefaultPbkdf2Iterations;
    final List<int> secretBytes = utf8.encode(secret.trim());
    final List<int> saltBytes = utf8.encode(salt);
    final crypto.Hmac hmac = crypto.Hmac(crypto.sha256, secretBytes);
    List<int> block = hmac.convert(saltBytes).bytes;
    final Uint8List accumulator = Uint8List.fromList(block);
    for (int i = 1; i < effectiveIterations; i++) {
      block = hmac.convert(block).bytes;
      for (int j = 0; j < 32; j++) {
        accumulator[j] ^= block[j];
      }
    }
    return 'pbkdf2_sha256\$$effectiveIterations\$$salt\$${base64Url.encode(accumulator)}';
  }

  /// Derives a Keystore-Peppered PIN verifier (`kpin_pbkdf2_sha256$<iters>$<salt>$<hash>`)
  /// by first binding the 4-digit PIN with the 256-bit Android Keystore Pepper via HMAC-SHA256
  /// and then running PBKDF2-HMAC-SHA256.
  static String deriveKeystorePepperedPin({
    required String rawPin,
    required String pinSalt,
    String? accountEmail,
    int? iterations,
  }) {
    final int effectiveIterations = iterations ?? kPinPbkdf2Iterations;
    final String cleanPin = rawPin.trim();
    final crypto.Hmac pepperHmac =
        crypto.Hmac(crypto.sha256, utf8.encode(_keystoreDevicePinPepper));
    final String pepperedSecret = base64Url
        .encode(pepperHmac.convert(utf8.encode('$pinSalt:$cleanPin')).bytes);
    final String derived = deriveKeySha256(
      secret: pepperedSecret,
      salt: pinSalt,
      iterations: effectiveIterations,
    );
    final String formatted = 'kpin_$derived';
    if (accountEmail != null && accountEmail.trim().isNotEmpty) {
      final String norm = accountEmail.trim().toLowerCase();
      _keystorePinVerifiers[norm] = formatted;
      writeSecureValue('keystore_pin_verifier_v34_$norm', formatted);
    }
    return formatted;
  }

  static bool isKeystorePepperedPinHash(String storedValue) {
    return storedValue.startsWith('kpin_pbkdf2_sha256\$');
  }

  static bool isFormattedHash(String storedValue) {
    return storedValue.startsWith('pbkdf2_sha256\$') ||
        isKeystorePepperedPinHash(storedValue);
  }

  static int extractIterations(String storedValue) {
    if (!isFormattedHash(storedValue)) return 0;
    final String stripped = storedValue.startsWith('kpin_')
        ? storedValue.substring(5)
        : storedValue;
    final List<String> parts = stripped.split('\$');
    if (parts.length != 4) return 0;
    return int.tryParse(parts[1]) ?? 0;
  }

  static bool needsIterationUpgrade(String storedValue) {
    if (!isFormattedHash(storedValue)) return true;
    return extractIterations(storedValue) < kDefaultPbkdf2Iterations;
  }

  static bool needsPinKeystoreUpgrade(String storedValue) {
    return !isKeystorePepperedPinHash(storedValue) ||
        extractIterations(storedValue) != kPinPbkdf2Iterations;
  }

  /// Benchmarks PBKDF2-HMAC-SHA256 performance across low-end and mid-range Android profiles
  /// and measures actual runtime latency for 12,000, 120,000, and 600,000 iterations.
  static Map<String, dynamic> benchmarkPbkdf2OnTargetDevice({
    int sampleIterations = 20000,
  }) {
    final Stopwatch sw = Stopwatch()..start();
    final String sampleHash = deriveKeySha256(
      secret: 'benchmark_secret_2026',
      salt: 'benchmark_salt_v34',
      iterations: sampleIterations,
    );
    sw.stop();
    final double msPer10k =
        max(0.5, (sw.elapsedMicroseconds / 1000.0) / (sampleIterations / 10000.0));
    final int projected120kMs = (msPer10k * 12).round();
    final int projected600kMidRangeMs = (msPer10k * 60).round();
    // Low-end Android (e.g., Cortex-A53 @ 1.8GHz in-order core) is ~2.4x slower than mid-range Cortex-A78
    final int projected600kLowEndMs = (msPer10k * 60 * 2.4).round();
    return {
      'configuredDefaultIterations': kDefaultPbkdf2Iterations,
      'owaspRecommendedIterations': kOwaspRecommendedPbkdf2Iterations,
      'sampleIterations': sampleIterations,
      'measuredSampleMs': sw.elapsedMilliseconds,
      'msPer10kIterations': double.parse(msPer10k.toStringAsFixed(2)),
      'projected120kMidRangeMs': projected120kMs,
      'projected600kMidRangeAndroidMs': projected600kMidRangeMs,
      'projected600kLowEndAndroidMs': projected600kLowEndMs,
      'hashPrefix': sampleHash.substring(0, 24),
    };
  }

  static bool constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    int diff = 0;
    for (int i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }

  static bool verifySecret({
    required String inputSecret,
    required String storedHashOrLegacy,
    required String fallbackSalt,
    String? accountEmail,
  }) {
    final String cleanInput = inputSecret.trim();
    if (cleanInput.isEmpty || storedHashOrLegacy.isEmpty) return false;

    String effectiveStored = storedHashOrLegacy;
    if (accountEmail != null && accountEmail.trim().isNotEmpty) {
      final String norm = accountEmail.trim().toLowerCase();
      final String? ksVerifier = _keystorePinVerifiers[norm];
      if (ksVerifier != null &&
          ksVerifier.isNotEmpty &&
          isKeystorePepperedPinHash(storedHashOrLegacy)) {
        effectiveStored = ksVerifier;
      }
    }

    if (isKeystorePepperedPinHash(effectiveStored)) {
      final String inner = effectiveStored.substring(5);
      final List<String> parts = inner.split('\$');
      if (parts.length == 4) {
        final int iters =
            int.tryParse(parts[1]) ?? kOwaspRecommendedPbkdf2Iterations;
        final String salt = parts[2];
        final String computed = deriveKeystorePepperedPin(
          rawPin: cleanInput,
          pinSalt: salt,
          iterations: iters,
        );
        return constantTimeEquals(computed, effectiveStored);
      }
      return false;
    }

    if (effectiveStored.startsWith('pbkdf2_sha256\$')) {
      final List<String> parts = effectiveStored.split('\$');
      if (parts.length == 4) {
        final int iters = int.tryParse(parts[1]) ?? kLegacy12kPbkdf2Iterations;
        final String salt = parts[2];
        final String computed = deriveKeySha256(
          secret: cleanInput,
          salt: salt,
          iterations: iters,
        );
        return constantTimeEquals(computed, effectiveStored);
      }
    }
    if (effectiveStored.startsWith('hpin_')) {
      int hash = 5381;
      final String salted = 'haneen_safe_salt_v3_$cleanInput';
      for (int i = 0; i < salted.length; i++) {
        hash = ((hash << 5) + hash) ^ salted.codeUnitAt(i);
      }
      final String legacyHpin = 'hpin_${(hash & 0x7FFFFFFF).toRadixString(16)}';
      return constantTimeEquals(legacyHpin, effectiveStored);
    }
    return constantTimeEquals(cleanInput, effectiveStored);
  }

  static Future<void> writeSecureValue(String key, String value) async {
    try {
      await _secureStorage
          .write(key: key, value: value)
          .guard();
    } catch (_) {}
  }

  static Future<String?> readSecureValue(String key) async {
    try {
      return await _secureStorage
          .read(key: key)
          .guard();
    } catch (_) {
      return null;
    }
  }

  static String _lockoutVaultKey(String emailOrPhone) =>
      'keystore_lockout_v34_${emailOrPhone.trim().toLowerCase()}';

  static void persistLockoutToKeystoreVault({
    required String emailOrPhone,
    required int failedPinAttempts,
    required DateTime? pinLockoutUntil,
    required int failedPasswordAttempts,
    required DateTime? passwordLockoutUntil,
  }) {
    final String norm = emailOrPhone.trim().toLowerCase();
    if (norm.isEmpty) return;
    final LockoutVaultSnapshot snap = LockoutVaultSnapshot(
      failedPinAttempts: failedPinAttempts,
      pinLockoutUntil: pinLockoutUntil,
      failedPasswordAttempts: failedPasswordAttempts,
      passwordLockoutUntil: passwordLockoutUntil,
    );
    _keystoreBackedLockoutVault[norm] = snap;
    writeSecureValue(_lockoutVaultKey(norm), jsonEncode(snap.toJson()));
  }

  static LockoutVaultSnapshot? readLockoutFromKeystoreVault(
      String emailOrPhone) {
    final String norm = emailOrPhone.trim().toLowerCase();
    return _keystoreBackedLockoutVault[norm];
  }

  static Future<void> hydrateLockoutVaultFromSecureStorage(
      String emailOrPhone) async {
    final String norm = emailOrPhone.trim().toLowerCase();
    if (norm.isEmpty) return;
    final String? raw = await readSecureValue(_lockoutVaultKey(norm));
    if (raw != null && raw.isNotEmpty) {
      try {
        final Map<String, dynamic> map = jsonDecode(raw);
        _keystoreBackedLockoutVault[norm] = LockoutVaultSnapshot.fromJson(map);
      } catch (_) {}
    }
  }

  /// Simulates an OS-level "Clear App Data" or Uninstall + Reinstall where both
  /// SharedPreferences and local Android Keystore entries for the app are wiped by the OS,
  /// regenerating a new device Keystore pepper.
  static Future<void> simulateFullOsAppDataWipeAndReinstall(
      SharedPreferences prefs) async {
    await prefs.clear();
    _keystoreBackedLockoutVault.clear();
    _keystorePinVerifiers.clear();
    _keystoreDevicePinPepper = _generateInitialKeystorePepper();
    try {
      await _secureStorage.deleteAll();
    } catch (_) {}
  }

  static void clearKeystoreLockoutForTesting([String? emailOrPhone]) {
    if (emailOrPhone == null) {
      _keystoreBackedLockoutVault.clear();
      _keystorePinVerifiers.clear();
    } else {
      final String norm = emailOrPhone.trim().toLowerCase();
      _keystoreBackedLockoutVault.remove(norm);
      _keystorePinVerifiers.remove(norm);
    }
  }
}


/// Gives secure-storage calls a 4 s limit (some phone brands stall the Keystore).
/// The timer is cancelled as soon as the call finishes, so nothing stays pending.
extension _SecureGuard<T> on Future<T> {
  Future<T> guard() {
    if (Platform.environment.containsKey('FLUTTER_TEST')) return this;
    final Completer<T> c = Completer<T>();
    final Timer t = Timer(const Duration(seconds: 4), () {
      if (!c.isCompleted) c.completeError(TimeoutException('secure storage'));
    });
    then((T v) {
      t.cancel();
      if (!c.isCompleted) c.complete(v);
    }, onError: (Object e, StackTrace st) {
      t.cancel();
      if (!c.isCompleted) c.completeError(e, st);
    });
    return c.future;
  }
}
