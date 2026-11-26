/// Dialect packs the app knows. Gulf is listed but has no recordings yet, so
/// it is not offered until its voice pack exists.
enum DialectId { msaSimple, egyptian, gulf }

extension DialectIdInfo on DialectId {
  String get key => name;
  String get nameAr => switch (this) {
        DialectId.msaSimple => 'فصحى مبسطة',
        DialectId.egyptian => 'مصري',
        DialectId.gulf => 'خليجي',
      };

  /// Gulf voice clips are not recorded yet.
  bool get available => this != DialectId.gulf;

  static DialectId? fromKey(String? k) {
    for (final d in DialectId.values) {
      if (d.name == k) return d;
    }
    return null;
  }
}

/// One file of settings per country: default dialect, currency, content notes,
/// holidays and example names. Adding a country is one more entry here.
class CountryConfig {
  final String code; // ISO 3166-1 alpha-2, upper case
  final String nameAr;
  final DialectId defaultDialect;
  final String currency;
  final List<String> holidays;
  final List<String> exampleNames;
  final bool weekendFriSat;

  const CountryConfig({
    required this.code,
    required this.nameAr,
    required this.defaultDialect,
    required this.currency,
    this.holidays = const [],
    this.exampleNames = const [],
    this.weekendFriSat = false,
  });
}

class Countries {
  static const CountryConfig egypt = CountryConfig(
    code: 'EG', nameAr: 'مصر', defaultDialect: DialectId.egyptian,
    currency: 'EGP',
    holidays: ['شم النسيم', 'عيد الفطر', 'عيد الأضحى', 'المولد النبوي'],
    exampleNames: ['أحمد', 'مريم', 'يوسف', 'ليلى'],
  );
  static const CountryConfig saudi = CountryConfig(
    code: 'SA', nameAr: 'السعودية', defaultDialect: DialectId.msaSimple,
    currency: 'SAR',
    holidays: ['اليوم الوطني', 'يوم التأسيس', 'عيد الفطر', 'عيد الأضحى'],
    exampleNames: ['فيصل', 'نورة', 'سلطان', 'لينا'], weekendFriSat: true,
  );
  static const CountryConfig uae = CountryConfig(
    code: 'AE', nameAr: 'الإمارات', defaultDialect: DialectId.msaSimple,
    currency: 'AED',
    holidays: ['اليوم الوطني', 'عيد الفطر', 'عيد الأضحى'],
    exampleNames: ['خالد', 'مريم', 'حمدان', 'شما'],
  );
  static const CountryConfig qatar = CountryConfig(
    code: 'QA', nameAr: 'قطر', defaultDialect: DialectId.msaSimple,
    currency: 'QAR',
    holidays: ['اليوم الوطني', 'عيد الفطر', 'عيد الأضحى'],
    exampleNames: ['جاسم', 'نوف', 'حمد', 'مها'], weekendFriSat: true,
  );
  static const CountryConfig kuwait = CountryConfig(
    code: 'KW', nameAr: 'الكويت', defaultDialect: DialectId.msaSimple,
    currency: 'KWD',
    holidays: ['اليوم الوطني', 'يوم التحرير', 'عيد الفطر', 'عيد الأضحى'],
    exampleNames: ['فهد', 'دانة', 'بدر', 'جود'], weekendFriSat: true,
  );
  static const CountryConfig bahrain = CountryConfig(
    code: 'BH', nameAr: 'البحرين', defaultDialect: DialectId.msaSimple,
    currency: 'BHD',
    holidays: ['اليوم الوطني', 'عيد الفطر', 'عيد الأضحى'],
    exampleNames: ['علي', 'زينب', 'محمد', 'فاطمة'], weekendFriSat: true,
  );
  static const CountryConfig oman = CountryConfig(
    code: 'OM', nameAr: 'عُمان', defaultDialect: DialectId.msaSimple,
    currency: 'OMR',
    holidays: ['اليوم الوطني', 'عيد الفطر', 'عيد الأضحى'],
    exampleNames: ['سالم', 'أسماء', 'حمد', 'مزنة'],
  );

  /// Any other country: simplified standard Arabic and USD pricing.
  static const CountryConfig other = CountryConfig(
    code: 'XX', nameAr: 'دولة أخرى', defaultDialect: DialectId.msaSimple,
    currency: 'USD',
    holidays: ['عيد الفطر', 'عيد الأضحى'],
    exampleNames: ['أحمد', 'مريم', 'يوسف', 'ليلى'],
  );

  static const List<CountryConfig> all = [
    egypt, saudi, uae, qatar, kuwait, bahrain, oman, other,
  ];

  static CountryConfig byCode(String? code) {
    final c = (code ?? '').trim().toUpperCase();
    for (final k in all) {
      if (k.code == c) return k;
    }
    return other;
  }
}
