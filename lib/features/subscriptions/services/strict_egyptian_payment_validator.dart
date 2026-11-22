
class StrictEgyptianPaymentValidator {
  static String? validateWalletPrefix(String methodId, String phone) {
    final cleaned = phone.replaceAll(RegExp(r'\s+|-'), '');
    if (!RegExp(r'^\d{11}$').hasMatch(cleaned)) {
      return 'رقم المحفظة يجب أن يتكون من ١١ رقماً بالضبط (مثال: 01012345678).';
    }
    if (methodId == 'vodafone_cash' && !cleaned.startsWith('010')) {
      return 'رقم محفظة فودافون كاش يجب أن يبدأ بـ 010.';
    }
    if (methodId == 'orange_cash' && !cleaned.startsWith('012')) {
      return 'رقم محفظة أورنج كاش يجب أن يبدأ بـ 012.';
    }
    if (methodId == 'etisalat_cash' && !cleaned.startsWith('011')) {
      return 'رقم محفظة اتصالات كاش (e& money) يجب أن يبدأ بـ 011.';
    }
    return null;
  }

  static String? validateInstaPayIdentifier(String input) {
    final cleaned = input.trim();
    if (cleaned.isEmpty) {
      return 'يرجى إدخال عنوان الدفع اللحظي (IPA مثل name@instapay) أو رقم الهاتف البنكي (١١ رقماً).';
    }
    final bool isIpa = cleaned.contains('@') && cleaned.length >= 6;
    final bool isPhone =
        RegExp(r'^01[0125]\d{8}$').hasMatch(cleaned.replaceAll(' ', ''));
    if (!isIpa && !isPhone) {
      return 'صيغة إنستا باي غير صحيحة: أدخل عنوان IPA يحتوي على @ أو رقم هاتف مصري مكون من ١١ رقماً.';
    }
    return null;
  }

  static bool checkLuhnCardNumber(String cardNumber) {
    final cleaned = cardNumber.replaceAll(RegExp(r'\D'), '');
    if (cleaned.length != 16) return false;
    int sum = 0;
    bool alternate = false;
    for (int i = cleaned.length - 1; i >= 0; i--) {
      int n = int.parse(cleaned[i]);
      if (alternate) {
        n *= 2;
        if (n > 9) n -= 9;
      }
      sum += n;
      alternate = !alternate;
    }
    return sum % 10 == 0;
  }

  static String? validateBankCard({
    required String cardNumber,
    required String expiry,
    required String cvv,
    required String cardHolderName,
  }) {
    if (cardHolderName.trim().length < 4) {
      return 'يرجى إدخال اسم حامل البطاقة ثلاثياً أو ثنائياً كما هو مطبوع على البطاقة.';
    }
    final cleanedNum = cardNumber.replaceAll(RegExp(r'\D'), '');
    if (cleanedNum.length != 16) {
      return 'رقم البطاقة البنكية (فيزا / ماستركارد / ميزة) يجب أن يتكون من ١٦ رقماً.';
    }
    if (!checkLuhnCardNumber(cleanedNum)) {
      return 'رقم البطاقة البنكية غير صالح (فشل التحقق الرقمي Luhn Check). تأكد من الأرقام الصحيحة.';
    }
    final expMatch = RegExp(r'^(\d{2})\/(\d{2})$').firstMatch(expiry.trim());
    if (expMatch == null) {
      return 'تاريخ انتهاء البطاقة يجب أن يكون بصيغة MM/YY (مثال: 08/28).';
    }
    final int month = int.tryParse(expMatch.group(1)!) ?? 0;
    final int year = 2000 + (int.tryParse(expMatch.group(2)!) ?? 0);
    if (month < 1 || month > 12) {
      return 'شهر انتهاء البطاقة غير صحيح (يجب أن يكون بين 01 و 12).';
    }
    final now = DateTime.now();
    if (year < now.year || (year == now.year && month < now.month)) {
      return 'هذه البطاقة منتهية الصلاحية ولا يمكن الخصم منها.';
    }
    if (!RegExp(r'^\d{3,4}$').hasMatch(cvv.trim())) {
      return 'رمز الأمان الخلفي (CVV) يجب أن يتكون من ٣ أو ٤ أرقام.';
    }
    return null;
  }
}
