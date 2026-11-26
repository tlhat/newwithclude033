import 'package:flutter/material.dart' hide Text;
import 'package:haneen_kids_vod/core/regional/dialect_text.dart';
import 'package:haneen_kids_vod/features/billing/billing_plans.dart';
import 'package:haneen_kids_vod/features/billing/billing_service.dart';

/// Plans screen. Only reachable from the parent area (behind the parent PIN).
class PlansScreen extends StatelessWidget {
  const PlansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final BillingService b = BillingService.instance;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('الاشتراك والباقات')),
        body: AnimatedBuilder(
          animation: b,
          builder: (context, _) {
            final String? active = b.activePlanId;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _card(
                  title: 'الخطة المجانية',
                  price: '٠ جنيه',
                  period: '',
                  features: kFreePlanFeatures,
                  current: active == null,
                ),
                for (final BillingPlan p in kBillingPlans)
                  _card(
                    title: p.title,
                    price: b.priceFor(p),
                    period: p.period,
                    badge: p.badge,
                    features: p.features,
                    current: active == p.id,
                    action: active == p.id
                        ? null
                        : ElevatedButton(
                            onPressed: b.buying || !b.storeAvailable
                                ? null
                                : () => b.buy(p.id),
                            child: const Text('اشترك'),
                          ),
                  ),
                if (b.message != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(b.message!, textAlign: TextAlign.center),
                  ),
                if (!b.storeAvailable)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                        'الشراء متاح فقط من النسخة المنشورة على Google Play.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12)),
                  ),
                TextButton(
                    onPressed: b.restore,
                    child: const Text('استرجاع مشترياتي')),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                      'الدفع والتجديد والإلغاء كلها عن طريق Google Play. تقدر تلغي في أي وقت من إعدادات الاشتراكات في Google Play.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11)),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _card({
    required String title,
    required String price,
    required String period,
    required List<String> features,
    bool current = false,
    String? badge,
    Widget? action,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
            color: current ? const Color(0xFF14B8A6) : Colors.transparent,
            width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(
                  child: Text(title,
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.bold))),
              if (current) const Text('خطتك الحالية'),
            ]),
            if (badge != null)
              Text(badge, style: const TextStyle(color: Color(0xFFFBBF24))),
            const SizedBox(height: 4),
            Text('$price $period',
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            for (final String f in features) Text('• $f'),
            if (action != null) ...[const SizedBox(height: 10), action],
          ],
        ),
      ),
    );
  }
}
