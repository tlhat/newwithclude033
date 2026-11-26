# إنشاء مفتاح الرفع الجديد (upload key) وتجهيز النشر، خطوة بخطوة

مهم: مفتاح التوقيع الحالي وكلمة سره ظاهرين في المستودع العام. **ما ترفعش أي AAB موقّع بيه على Play**. لأن أول AAB بترفعه على Play (مع Play App Signing) بيتحول مفتاحه لمفتاح الرفع. لازم أول ملف يتوقّع بمفتاح جديد عملته أنت ومحدش شافه.
المصدر: https://support.google.com/googleplay/android-developer/answer/9842756

## الخطوة 1: اعمل المفتاح على جهازك (كمبيوتر)
محتاج Java (أو Android Studio، وفيه keytool). افتح Terminal أو PowerShell واكتب (غيّر المسار لو عايز):

    keytool -genkeypair -v -keystore haneen-upload.jks -storetype PKCS12 -alias haneen -keyalg RSA -keysize 2048 -validity 10000 -dname "CN=Haneen Kids, O=Haneen Kids, C=EG"

- هيسألك عن كلمة سر. اختار كلمة سر طويلة (16 حرف أو أكتر) **واكتبها في مكان آمن**. اكتب نفس الكلمة لو سأل عن كلمة سر المفتاح.
- الاسم المستعار (alias) لازم يفضل `haneen` لأن الـ workflow بيستخدمه. وكلمة سر الملف وكلمة سر المفتاح لازم تكون **نفس الكلمة** (الـ workflow بيستخدم كلمة واحدة للاتنين).
- احفظ ملف haneen-upload.jks في مكانين (فلاشة وحساب تخزين خاص). لو ضاع، Google تقدر تعمل reset لمفتاح الرفع، بس الأفضل متضيعوش.
- متبعتش الملف ولا الكلمة لأي حد، ولا في شات، ولا في GitHub كملف.

## الخطوة 2: حوّل الملف لنص (base64)
- Windows PowerShell:

      [Convert]::ToBase64String([IO.File]::ReadAllBytes("haneen-upload.jks")) | Set-Clipboard

  (بينسخ النص للحافظة.)
- Mac/Linux:

      base64 -i haneen-upload.jks | tr -d '\n' | pbcopy      (على لينكس: base64 -w0 haneen-upload.jks)

## الخطوة 3: ضيف سرّين في GitHub
1. افتح https://github.com/tlhat/newwithclude033/settings/secrets/actions
2. اضغط **New repository secret**:
   - Name: `HANEEN_KEYSTORE_B64`، Secret: الصق النص من الحافظة. Add secret.
   - Name: `HANEEN_KEYSTORE_PASSWORD`، Secret: كلمة السر. Add secret.
   (الأسماء موجودة بالفعل لو أضفتها قبل كده. اضغط Update واستبدل القيم.)

## الخطوة 4: قولي (للمساعد) وأنا أعمل الباقي
بعد ما تضيف السرين:
1. أشيل كلمة سر المفتاح القديم المكتوبة في build.yaml وملفات ci/ من الـ workflow.
2. أشغّل Build مع build_aab وأتأكد إن الـ AAB موقّع بالمفتاح الجديد (SHA-1 هيتغير ويطلع في السجل، ومش هيبدأ بـ 63a88435).
3. أسلّمك لينك الـ AAB (Artifact): GitHub > Actions > آخر تشغيل > Artifacts > haneen-kids-release-aab (بيتحمل ملف zip، فُكّه تلاقي app-release.aab).

ملحوظة: تغيير المفتاح معناه إن APK الاختبار الجديد بيتوقّع بتوقيع مختلف: لازم تشيل النسخة القديمة من الموبايل قبل ما تسطّب الجديدة.

## الخطوة 5: على Play Console (إنت بس، بعد عمل الحساب)
1. Create app. الاسم: واحة اللعب والتعلم. اللغة العربية. تطبيق مش لعبة (أو لعبة حسب اختيارك). مجاني.
2. Test and release > Setup > App signing: خلّيها الخيار الافتراضي (Google-managed key).
3. Testing > Closed testing > Create new release > ارفع app-release.aab. (راجع CLOSED_TESTING.md.)
4. بعد الرفع: Test and release > Setup > App signing > انسخ **SHA-1** لـ "App signing key certificate" وابعتها لي أو سجّلها في Google Cloud (راجع OAUTH_SHA1.md).
