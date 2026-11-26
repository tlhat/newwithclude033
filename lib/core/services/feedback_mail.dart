import 'package:flutter/services.dart';

/// Where feedback and complaints go. Kept in code only: it is never shown on
/// screen. The button opens the phone's mail app with this address filled in.
class FeedbackMail {
  static const String _to = 'tlhatmaher1893@gmail.com';
  static const MethodChannel _ch = MethodChannel('haneen/mail');

  /// Opens the mail app. Returns false when no mail app could open.
  static Future<bool> compose({String subject = 'ملاحظات على حنين كيدز'}) async {
    try {
      final ok = await _ch.invokeMethod<bool>('compose', {
        'to': _to,
        'subject': subject,
        'body': 'اكتب ملاحظتك أو شكواك هنا:\n\n',
      });
      return ok ?? false;
    } catch (_) {
      return false;
    }
  }
}
