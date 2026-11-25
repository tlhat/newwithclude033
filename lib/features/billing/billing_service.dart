import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:haneen_kids_vod/features/billing/billing_plans.dart';

/// Subscriptions through Google Play Billing only. No server, no card data in
/// the app: Google handles payment, renewal and cancellation.
///
/// Entitlement is kept on the phone. Play is asked about the active
/// subscriptions at every launch (restorePurchases); each answer renews a
/// 3-day local grace window, so an expired or cancelled subscription stops
/// counting after the window and a short offline period does not lock anyone out.
/// (A server check with the Play Developer API is the stronger option later.)
class BillingService extends ChangeNotifier {
  BillingService._();
  static final BillingService instance = BillingService._();

  static const String _kPlan = 'billing_plan_id';
  static const String _kUntil = 'billing_valid_until_ms';
  static const Duration _grace = Duration(days: 3);

  SharedPreferences? _prefs;
  InAppPurchase? _iap;
  StreamSubscription<List<PurchaseDetails>>? _sub;

  bool storeAvailable = false;
  bool loading = false;
  bool buying = false;
  String? message;
  final Map<String, ProductDetails> products = <String, ProductDetails>{};

  /// The active plan id, or null (free plan).
  String? get activePlanId {
    final SharedPreferences? p = _prefs;
    if (p == null) return null;
    final String? id = p.getString(_kPlan);
    final int until = p.getInt(_kUntil) ?? 0;
    if (id == null || DateTime.now().millisecondsSinceEpoch > until) return null;
    return id;
  }

  bool get isSubscribed => activePlanId != null;

  /// Child profiles allowed: 3 on the family plan, 1 otherwise.
  int get maxChildProfiles {
    final String? id = activePlanId;
    for (final BillingPlan p in kBillingPlans) {
      if (p.id == id) return p.maxChildren;
    }
    return 1;
  }

  String priceFor(BillingPlan plan) =>
      products[plan.id]?.price ?? plan.fallbackPrice;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
    if (kIsWeb || !Platform.isAndroid) return;
    if (Platform.environment.containsKey('FLUTTER_TEST')) return;
    try {
      _iap = InAppPurchase.instance;
      storeAvailable = await _iap!.isAvailable();
      _sub ??= _iap!.purchaseStream.listen(
        _onPurchases,
        onError: (Object e) {
          message = 'حصلت مشكلة في الاتصال بـ Google Play.';
          buying = false;
          notifyListeners();
        },
      );
      if (storeAvailable) {
        await loadProducts();
        await _iap!.restorePurchases();
      }
    } catch (_) {
      storeAvailable = false;
    }
    notifyListeners();
  }

  Future<void> loadProducts() async {
    final InAppPurchase? iap = _iap;
    if (iap == null) return;
    loading = true;
    notifyListeners();
    try {
      final ProductDetailsResponse r =
          await iap.queryProductDetails(kBillingProductIds);
      products
        ..clear()
        ..addEntries(r.productDetails.map((d) => MapEntry(d.id, d)));
      if (products.isEmpty) {
        message = 'الباقات لسه مش متاحة على Google Play.';
      }
    } catch (_) {
      message = 'تعذر تحميل الباقات من Google Play.';
    }
    loading = false;
    notifyListeners();
  }

  Future<void> buy(String planId) async {
    final ProductDetails? d = products[planId];
    final InAppPurchase? iap = _iap;
    if (d == null || iap == null) {
      message = 'الباقة مش متاحة حاليًا على Google Play.';
      notifyListeners();
      return;
    }
    buying = true;
    message = null;
    notifyListeners();
    try {
      await iap.buyNonConsumable(purchaseParam: PurchaseParam(productDetails: d));
    } catch (_) {
      buying = false;
      message = 'تعذر بدء الشراء.';
      notifyListeners();
    }
  }

  Future<void> restore() async {
    final InAppPurchase? iap = _iap;
    if (iap == null) return;
    message = null;
    try {
      await iap.restorePurchases();
    } catch (_) {
      message = 'تعذر استرجاع المشتريات.';
      notifyListeners();
    }
  }

  Future<void> _onPurchases(List<PurchaseDetails> list) async {
    for (final PurchaseDetails p in list) {
      switch (p.status) {
        case PurchaseStatus.pending:
          message = 'العملية قيد المعالجة عند Google Play.';
          break;
        case PurchaseStatus.error:
          buying = false;
          message = 'العملية ما تمتش.';
          break;
        case PurchaseStatus.canceled:
          buying = false;
          message = 'اتلغت العملية.';
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          if (kBillingProductIds.contains(p.productID)) {
            await _prefs?.setString(_kPlan, p.productID);
            await _prefs?.setInt(_kUntil,
                DateTime.now().add(_grace).millisecondsSinceEpoch);
            buying = false;
            message = 'الاشتراك شغال. شكرًا لك 💛';
          }
          break;
      }
      if (p.pendingCompletePurchase) {
        try {
          await _iap?.completePurchase(p);
        } catch (_) {}
      }
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
