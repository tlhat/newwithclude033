# تسجيل بصمة SHA-1 لتسجيل الدخول بجوجل (خطوات ليك أنت، ما اتعمل أي شيء في حسابك)

المصادر:
- https://support.google.com/googleplay/android-developer/answer/9842756 (قسم Register with API providers)
- https://codelabs.developers.google.com/sign-in-with-google-android (عميل ويب + عميل أندرويد)
- https://support.google.com/cloud/answer/15549257

## الخطوات
1. افتح Google Cloud Console، اختر المشروع، وادخل APIs & Services > Credentials.
2. **عميل Android لكل بصمة** (Create credentials > OAuth client ID > Android):
   - Package name: `com.haneenkids.haneen_kids_vod`
   - SHA-1: واحدة من:
     a) بصمة APK الاختبار الحالي: تظهر في سجل البناء (سطر "certificate SHA-1 digest"): `63a88435548f06bcf23a2957b90f838f4189a372` (اكتبها في Console بصيغة أزواج بنقطتين: 63:A8:84:35:54:8F:06:...).
     b) بصمة **App signing key** من Play Console (بعد رفع أول AAB). من غيرها الدخول بجوجل مش هيشتغل في النسخة المنزّلة من المتجر.
     c) (اختياري) بصمة مفتاح الرفع لو بتختبر AAB موقّع بيه.
3. اعمل عميل **Web application** (للـ serverClientId) لو التطبيق بيطلبه. رقمه بيتحط وقت البناء كمتغير `GOOGLE_SERVER_CLIENT_ID` (--dart-define). ما نحطش أي رقم سري في الكود.
4. شاشة الموافقة (OAuth consent screen / Branding): الاسم، بريد الدعم، وروابط سياسة الخصوصية. بما إننا بنطلب النطاقات الأساسية (email, profile, openid) والـ appdata فقط، نشر التطبيق (In production) ضروري، وإلا الدخول بيشتغل لمستخدمين تجربة فقط. نطاق `drive.appdata` ممكن يحتاج مراجعة من Google.
5. بعد التسجيل ممكن ياخد دقائق لحد ما يتفعّل. جرّب الدخول من الـ APK ومن نسخة المتجر.

لو الدخول فشل برسالة عامة، السبب الأشهر هو بصمة ناقصة أو اسم حزمة غلط.
