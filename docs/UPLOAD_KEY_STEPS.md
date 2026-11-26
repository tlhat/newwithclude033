# مفتاح الرفع (upload key) لـ Play: اتعمل، ومفيش حاجة تعملها على جهازك

المصدر: https://support.google.com/googleplay/android-developer/answer/9842756

## الحالة
- اتولّد مفتاح رفع جديد (PKCS12، alias: haneen) وانحفظ **كأسرار GitHub فقط**: `HANEEN_UPLOAD_KEYSTORE_B64` و `HANEEN_UPLOAD_KEYSTORE_PASSWORD`. ما اتكتب في المستودع ولا في ملف ولا في Artifact.
- الأسرار في GitHub **ما بتتقراش تاني** (حتى لحاب المستودع). مفيش نسخة منه عند حد. لو ضاع أو اتمسح: Play Console > Test and release > Setup > App signing > Request upload key reset (Google بتسمح بكده).
- مفتاح التوقيع القديم (SHA-1 يبدأ بـ 63a88435) فضل بس لتوقيع APK الاختبار. **ما ترفعش على Play أي ملف موقّع بيه.**
- SHA-1 لمفتاح الرفع: BF:1C:07:2C:D6:26:4B:05:35:A3:D1:12:ED:85:00:11:00:85:9F:03

## بناء الـ AAB
GitHub > Actions > Build Android APK > Run workflow:
- build_aab = تشغيل
- sign_with_upload_key = تشغيل (الافتراضي)
بعد ما ينتهي: افتح التشغيل > Artifacts > haneen-kids-release-aab (zip، فكّه، جواه app-release.aab). ده الملف اللي بيترفع على Play.

## على Play Console (إنت بس)
1. Create app: الاسم، اللغة العربية، مجاني.
2. Test and release > Setup > App signing: سيبها على الخيار الافتراضي (Google-managed key).
3. Testing > Closed testing > Create new release > ارفع app-release.aab (راجع CLOSED_TESTING.md).
4. بعد الرفع: Setup > App signing > انسخ SHA-1 لـ "App signing key certificate" وسجّلها في Google Cloud (راجع OAUTH_SHA1.md).

## بعد أول رفع ناجح
- يتشال من build.yaml وملفات ci/ كلمة سر المفتاح القديم (بنعملها إحنا).
- ملحوظة: الـ APK الموقّع بالمفتاح القديم مش بيتثبّت فوق نسخة المتجر والعكس. شيل النسخة القديمة قبل ما تجرب.
