import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

/// Who signed in with Google, plus the headers needed to call Google Drive
/// for this user.
class GoogleIdentity {
  final String email;
  final String displayName;
  final String id;
  final Map<String, String> authHeaders;
  const GoogleIdentity({
    required this.email,
    required this.displayName,
    required this.id,
    required this.authHeaders,
  });
}

/// An error whose message is safe to show to a parent, in Arabic.
class GoogleAccountException implements Exception {
  final String messageAr;
  const GoogleAccountException(this.messageAr);
  @override
  String toString() => messageAr;
}

/// Thin wrapper so tests can replace the real Google sign-in.
abstract class GoogleSignInGateway {
  Future<GoogleIdentity?> signIn();
  Future<void> signOut();
}

class RealGoogleSignInGateway implements GoogleSignInGateway {
  /// Optional. Only needed if you later want a server to verify an ID token.
  /// Build with: --dart-define=GOOGLE_SERVER_CLIENT_ID=xxxx.apps.googleusercontent.com
  static const String _serverClientId =
      String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');

  late final GoogleSignIn _gs = GoogleSignIn(
    scopes: const <String>[
      'email',
      GoogleAccountService.kDriveAppDataScope,
    ],
    serverClientId: _serverClientId.isEmpty ? null : _serverClientId,
  );

  @override
  Future<GoogleIdentity?> signIn() async {
    try {
      final GoogleSignInAccount? acc = await _gs.signIn();
      if (acc == null) return null; // the parent closed the Google window
      final Map<String, String> headers = await acc.authHeaders;
      return GoogleIdentity(
        email: acc.email,
        displayName: acc.displayName ?? acc.email,
        id: acc.id,
        authHeaders: headers,
      );
    } on PlatformException catch (e) {
      final String code = e.code;
      final String msg = '${e.message ?? ''}';
      if (code == 'network_error') {
        throw const GoogleAccountException(
            'مفيش إنترنت دلوقتي. وصّل بالنت وجرّب تاني.');
      }
      if (code == 'sign_in_canceled') return null;
      if (msg.contains('10') || code == 'sign_in_failed') {
        throw const GoogleAccountException(
            'إعداد دخول جوجل في التطبيق لسه مش مكتمل (بصمة SHA-1 أو رقم العميل). راجع خطوات الإعداد.');
      }
      throw GoogleAccountException('تعذّر الدخول بجوجل ($code).');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _gs.signOut();
    } catch (_) {}
  }
}

/// Google sign-in plus a private backup file in the user's own Google Drive
/// "app data" folder. No Firebase and no server of ours: the file is hidden
/// from the Drive app and only this app can read it.
class GoogleAccountService {
  GoogleAccountService({GoogleSignInGateway? gateway, http.Client? client})
      : gateway = gateway ?? RealGoogleSignInGateway(),
        _client = client;

  /// Replace in tests.
  static GoogleAccountService instance = GoogleAccountService();

  static const String kDriveAppDataScope =
      'https://www.googleapis.com/auth/drive.appdata';
  static const String kBackupFileName = 'haneen_kids_backup_v1.json';

  final GoogleSignInGateway gateway;
  final http.Client? _client;

  Future<GoogleIdentity?> signIn() => gateway.signIn();
  Future<void> signOut() => gateway.signOut();

  Map<String, String> _h(GoogleIdentity id, [Map<String, String>? extra]) =>
      {...id.authHeaders, ...?extra};

  Future<http.Response> _send(
      Future<http.Response> Function(http.Client c) call) async {
    final http.Client c = _client ?? http.Client();
    try {
      final http.Response r = await call(c).timeout(const Duration(seconds: 30));
      if (r.statusCode == 401 || r.statusCode == 403) {
        throw const GoogleAccountException(
            'جوجل رفضت الوصول للنسخة الاحتياطية. تأكد إن Google Drive API مفعّل في المشروع وإن الشاشة مرفوعة (In production).');
      }
      return r;
    } on GoogleAccountException {
      rethrow;
    } catch (_) {
      throw const GoogleAccountException(
          'مفيش اتصال بالإنترنت أو جوجل مش بترد. جرّب تاني.');
    } finally {
      if (_client == null) c.close();
    }
  }

  Future<String?> _findBackupFileId(GoogleIdentity id) async {
    final Uri url = Uri.https('www.googleapis.com', '/drive/v3/files', {
      'spaces': 'appDataFolder',
      'q': "name='$kBackupFileName' and trashed=false",
      'fields': 'files(id,modifiedTime)',
      'orderBy': 'modifiedTime desc',
      'pageSize': '1',
    });
    final http.Response r = await _send((c) => c.get(url, headers: _h(id)));
    if (r.statusCode != 200) {
      throw const GoogleAccountException('تعذّر قراءة النسخة الاحتياطية من جوجل.');
    }
    final Map<String, dynamic> body =
        jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
    final List files = (body['files'] as List?) ?? const [];
    if (files.isEmpty) return null;
    return (files.first as Map)['id'] as String?;
  }

  /// Returns the saved backup text, or null when this Google account has none.
  Future<String?> downloadBackup(GoogleIdentity id) async {
    final String? fileId = await _findBackupFileId(id);
    if (fileId == null) return null;
    final Uri url = Uri.https(
        'www.googleapis.com', '/drive/v3/files/$fileId', {'alt': 'media'});
    final http.Response r = await _send((c) => c.get(url, headers: _h(id)));
    if (r.statusCode != 200) {
      throw const GoogleAccountException('تعذّر تنزيل النسخة الاحتياطية.');
    }
    return utf8.decode(r.bodyBytes);
  }

  /// Creates or overwrites the single backup file.
  Future<void> uploadBackup(GoogleIdentity id, String json) async {
    final String? fileId = await _findBackupFileId(id);
    final List<int> bytes = utf8.encode(json);
    http.Response r;
    if (fileId == null) {
      const String boundary = 'haneen_backup_boundary';
      final String meta = jsonEncode({
        'name': kBackupFileName,
        'parents': ['appDataFolder'],
        'mimeType': 'application/json',
      });
      final String body = '--$boundary\r\n'
          'Content-Type: application/json; charset=UTF-8\r\n\r\n$meta\r\n'
          '--$boundary\r\n'
          'Content-Type: application/json; charset=UTF-8\r\n\r\n$json\r\n'
          '--$boundary--';
      final Uri url = Uri.https('www.googleapis.com', '/upload/drive/v3/files',
          {'uploadType': 'multipart'});
      r = await _send((c) => c.post(url,
          headers: _h(id,
              {'Content-Type': 'multipart/related; boundary=$boundary'}),
          body: utf8.encode(body)));
    } else {
      final Uri url = Uri.https(
          'www.googleapis.com',
          '/upload/drive/v3/files/$fileId',
          {'uploadType': 'media'});
      r = await _send((c) => c.patch(url,
          headers: _h(id, {'Content-Type': 'application/json; charset=UTF-8'}),
          body: bytes));
    }
    if (r.statusCode != 200) {
      throw const GoogleAccountException('تعذّر حفظ النسخة الاحتياطية على جوجل.');
    }
  }
}
