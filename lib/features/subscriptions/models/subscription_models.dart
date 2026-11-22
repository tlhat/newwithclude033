import 'package:flutter/material.dart';

class SubscriptionPlanModel {
  final String id;
  final String title;
  final String badge;
  final String subtitle;
  final int priceEgp;
  final int originalPriceEgp;
  final int durationDays;
  final List<String> features;
  final Color accentColor;
  final bool isPopular;

  const SubscriptionPlanModel({
    required this.id,
    required this.title,
    required this.badge,
    required this.subtitle,
    required this.priceEgp,
    required this.originalPriceEgp,
    required this.durationDays,
    required this.features,
    required this.accentColor,
    this.isPopular = false,
  });
}

const List<SubscriptionPlanModel> kSubscriptionPlans = [
  SubscriptionPlanModel(
    id: 'trial_1day',
    title: 'التجربة المجانية الشاملة (٧ أيام)',
    badge: 'مجاني لمدة ٧ أيام كاملة 🎁',
    subtitle: 'استكشف جميع القصص والميزات الصوتية الذكية مجاناً لمدة ٧ أيام شاملة',
    priceEgp: 0,
    originalPriceEgp: 0,
    durationDays: 7,
    features: [
      'فتح جميع القصص الهادئة والأكاديمية لمدة ٧ أيام كاملة (١٦٨ ساعة)',
      'تجربة المصحح الصوتي الذكي في نافذة «ردد معي»',
      'تجربة المساعد الصوتي الذكي للطفل (رفيق حنين ElevenLabs)',
      'تقارير وتنبيهات البريد الإلكتروني للوالدين',
    ],
    accentColor: Color(0xFF38BDF8),
  ),
  SubscriptionPlanModel(
    id: 'weekly_flex',
    title: 'باقة الأسبوع المرنة',
    badge: 'مرونة عالية ⚡',
    subtitle: 'مثالية للإجازات الأسبوعية والتجربة السريعة بدون التزام طويل',
    priceEgp: 45,
    originalPriceEgp: 65,
    durationDays: 7,
    features: [
      'مشاهدة غير محدودة لجميع الأقسام لمدة ٧ أيام',
      'تفعيل كامل للمساعد الصوتي وتصحيح النطق العربي',
      'إضافة حتى ٣ ملفات أطفال مستقلة',
      'تقارير يومية واقتراحات تربوية على إيميل الوالدين',
    ],
    accentColor: Color(0xFF14B8A6),
  ),
  SubscriptionPlanModel(
    id: 'monthly_family',
    title: 'الباقة الشهرية الذكية',
    badge: 'الأكثر اختياراً في مصر ⭐',
    subtitle: 'الخيار المفضل للعائلات لمتابعة يومية هادئة وتطوير النطق والسلوك',
    priceEgp: 120,
    originalPriceEgp: 180,
    durationDays: 30,
    isPopular: true,
    features: [
      'فتح كافة القصص والتحديثات السحابية طوال الشهر',
      'إضافة حتى ٥ ملفات أطفال مع تقارير أداء مفصلة',
      'المساعد الذكي الصوتي التفاعلي وتصحيح مخارج الحروف',
      'تنبيهات بريدية ذكية واقتراحات مخصصة لكل طفل',
      'أولوية الدعم الفني وإمكانية الإلغاء في أي وقت',
    ],
    accentColor: Color(0xFFF59E0B),
  ),
  SubscriptionPlanModel(
    id: 'quarterly_plus',
    title: 'باقة الـ ٣ شهور التوفيرية',
    badge: 'وفّر ٣٥٪ 💎',
    subtitle: 'خطة فصلية متكاملة لبناء عادات القراءة والنطق الفصيح والهدوء',
    priceEgp: 280,
    originalPriceEgp: 430,
    durationDays: 90,
    features: [
      'جميع مميزات الباقة الشهرية لمدة ٩٠ يوماً كاملة',
      'برامج نطق وفصاحة متدرجة مع المساعد الصوتي',
      'تقارير شهرية وأسبوعية شاملة عبر الإيميل للوالدين',
      'إمكانية تخصيص مكتبة قصص خاصة لكل طفل',
    ],
    accentColor: Color(0xFFA855F7),
  ),
  SubscriptionPlanModel(
    id: 'annual_vip',
    title: 'باقة العائلة السنوية VIP',
    badge: 'أفضل قيمة — وفّر ٥٥٪ 👑',
    subtitle: 'استثمار تربوي كامل لعام كامل من القصص الهادئة والأنشطة الواقعية',
    priceEgp: 799,
    originalPriceEgp: 1800,
    durationDays: 365,
    features: [
      'اشتراك كامل لمدة ٣٦٥ يوماً لكل أطفال العائلة بلا حدود',
      'تفعيل دائم للمساعد الذكي الصوتي ومصحح النطق العربي',
      'تنبيهات فورية على الإيميل واقتراحات تربوية ذكية يومية',
      'وصول مبكر لجميع السلاسل والقصص التربوية الجديدة',
      'هدية شهر إضافي مجاني عند التجديد',
    ],
    accentColor: Color(0xFFEC4899),
  ),
];

class EgyptianPaymentMethodInfo {
  final String id;
  final String nameAr;
  final String subtitleAr;
  final String badgeText;
  final Color brandColor;
  final IconData icon;
  final String merchantAccountNumber;

  const EgyptianPaymentMethodInfo({
    required this.id,
    required this.nameAr,
    required this.subtitleAr,
    required this.badgeText,
    required this.brandColor,
    required this.icon,
    required this.merchantAccountNumber,
  });
}

const List<EgyptianPaymentMethodInfo> kEgyptianPaymentMethods = [
  EgyptianPaymentMethodInfo(
    id: 'vodafone_cash',
    nameAr: 'فودافون كاش (Vodafone Cash)',
    subtitleAr: 'الدفع الفوري عبر محفظة فودافون كاش (*9*7#)',
    badgeText: 'الأسرع في مصر',
    brandColor: Color(0xFFE60000),
    icon: Icons.phone_android_rounded,
    merchantAccountNumber: '0100-888-9922',
  ),
  EgyptianPaymentMethodInfo(
    id: 'instapay',
    nameAr: 'إنستا باي (InstaPay Egypt)',
    subtitleAr: 'تحويل لحظي عبر عنوان الدفع IPA أو رقم الهاتف البنكي',
    badgeText: 'تحويل لحظي مجاني',
    brandColor: Color(0xFF7C3AED),
    icon: Icons.account_balance_rounded,
    merchantAccountNumber: 'haneenkids@instapay',
  ),
  EgyptianPaymentMethodInfo(
    id: 'orange_cash',
    nameAr: 'أورنج كاش (Orange Cash)',
    subtitleAr: 'الدفع السريع عبر محفظة أورنج كاش (#7115#)',
    badgeText: 'محفظة أورنج',
    brandColor: Color(0xFFFF7900),
    icon: Icons.smartphone_rounded,
    merchantAccountNumber: '0122-555-7744',
  ),
  EgyptianPaymentMethodInfo(
    id: 'etisalat_cash',
    nameAr: 'اتصالات كاش (e& money / Etisalat Cash)',
    subtitleAr: 'الدفع المباشر عبر محفظة اتصالات كاش (*777#)',
    badgeText: 'محفظة e& money',
    brandColor: Color(0xFF10B981),
    icon: Icons.mobile_friendly_rounded,
    merchantAccountNumber: '0111-333-8855',
  ),
  EgyptianPaymentMethodInfo(
    id: 'visa_mastercard',
    nameAr: 'بطاقة بنكية (فيزا / ماستركارد / ميزة)',
    subtitleAr: 'دفع آمن بالبطاقات البنكية المصرية وبطاقات ميزة الوطنية',
    badgeText: 'Visa / Meeza',
    brandColor: Color(0xFF2563EB),
    icon: Icons.credit_card_rounded,
    merchantAccountNumber: 'بوابة الدفع الإلكتروني المؤمنة 3D-Secure',
  ),
];

class PaymentTransactionRecord {
  final String id;
  final String planId;
  final String planTitle;
  final int amountEgp;
  final String currency;
  final String paymentMethodId;
  final String paymentMethodName;
  final String payerIdentifier;
  final String referenceCode;
  final String status;
  final String failureReason;
  final DateTime createdAt;
  final bool webhookSignatureVerified;
  final String receiptSignature;

  PaymentTransactionRecord({
    required this.id,
    required this.planId,
    required this.planTitle,
    required this.amountEgp,
    this.currency = 'EGP',
    required this.paymentMethodId,
    required this.paymentMethodName,
    required this.payerIdentifier,
    required this.referenceCode,
    this.status = 'failed',
    this.failureReason = '',
    required this.createdAt,
    this.webhookSignatureVerified = false,
    this.receiptSignature = '',
  });

  bool get isVerified =>
      status == 'verified' &&
      webhookSignatureVerified &&
      currency.toUpperCase() == 'EGP' &&
      receiptSignature.trim().isNotEmpty;

  factory PaymentTransactionRecord.fromJson(Map<String, dynamic> json) {
    return PaymentTransactionRecord(
      id: (json['id'] ?? '').toString(),
      planId: (json['planId'] ?? '').toString(),
      planTitle: (json['planTitle'] ?? '').toString(),
      amountEgp: int.tryParse(json['amountEgp']?.toString() ?? '0') ?? 0,
      currency: (json['currency'] ?? 'EGP').toString(),
      paymentMethodId: (json['paymentMethodId'] ?? '').toString(),
      paymentMethodName: (json['paymentMethodName'] ?? '').toString(),
      payerIdentifier: (json['payerIdentifier'] ?? '').toString(),
      referenceCode: (json['referenceCode'] ?? '').toString(),
      status: (json['status'] ?? 'failed').toString(),
      failureReason: (json['failureReason'] ?? '').toString(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      webhookSignatureVerified: json['webhookSignatureVerified'] == true,
      receiptSignature: (json['receiptSignature'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'planId': planId,
      'planTitle': planTitle,
      'amountEgp': amountEgp,
      'currency': currency,
      'paymentMethodId': paymentMethodId,
      'paymentMethodName': paymentMethodName,
      'payerIdentifier': payerIdentifier,
      'referenceCode': referenceCode,
      'status': status,
      'failureReason': failureReason,
      'createdAt': createdAt.toIso8601String(),
      'webhookSignatureVerified': webhookSignatureVerified,
      'receiptSignature': receiptSignature,
    };
  }
}

class PaymentVerificationOutcome {
  final bool isPaidAndVerified;
  final String message;
  final PaymentTransactionRecord? transaction;

  const PaymentVerificationOutcome({
    required this.isPaidAndVerified,
    required this.message,
    this.transaction,
  });
}
