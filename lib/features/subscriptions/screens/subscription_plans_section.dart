import 'package:flutter/material.dart';
import 'package:haneen_kids_vod/haneen_kids_exports.dart';

class SubscriptionStatusBannerWidget extends StatelessWidget {
  final ParentAccount account;
  const SubscriptionStatusBannerWidget({super.key, required this.account});

  @override
  Widget build(BuildContext context) {
    return Text(
      account.subscriptionStatusLabel,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
    );
  }
}
