import 'package:haneen_kids_vod/core/localization/tr.dart';
import 'package:flutter/material.dart';

class AccountSecurityNoticeWidget extends StatelessWidget {
  const AccountSecurityNoticeWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      tr('🔐 جميع بيانات العائلة ورمز الحماية الأبوي محفوظة بأمان تام.'),
      style: TextStyle(fontSize: 12, color: Colors.white70),
    );
  }
}
