# تطبيق حنين كيدز (Haneen Kids v3.6) — المنصة التعليمية السحابية الآمنة (Flutter + Supabase + PostgreSQL)

## ١. نظرة عامة على البنية المعمارية (v3.6)
تم تطوير تطبيق **حنين كيدز** ليعمل ببنية **Offline-First Cloud Architecture** تجمع بين:
- **واجهة Flutter المعيارية (`lib/app`, `lib/core`, `lib/data`, `lib/features`, `lib/shared`)** مع الحفاظ الكامل على جميع الشاشات والألعاب والميزات.
- **قاعدة بيانات سحابية PostgreSQL عبر Supabase (`supabase/migrations/`)** مع تفعيل وإجبار سياسات أمان الصفوف (`ENABLE & FORCE ROW LEVEL SECURITY`) على جميع الجداول الـ 9.
- **محرك مزامنة تلقائي يعمل دون إنترنت (`OfflineSyncQueueService` & `ChildSyncConflictResolver`)** يحفظ التقدم المحلي في طابور مزامنة غير قابل للتكرار (`idempotencyKey`) ويدمج التقدم التعليمي بين الأجهزة المتعددة دون فقدان أي نجمة أو درس.
- **تحقق خادمي حصري من الاشتراكات (`supabase/functions/subscription-status` & `payment-webhook-receiver`)** يمنع تفعيل أي باقة مدفوعة من داخل التطبيق.

## ٢. هيكل ملفات Supabase والخادم السحابي
- `supabase/config.toml`: إعدادات مشروع Supabase المحلي والسحابي.
- `supabase/migrations/20261030000001_initial_schema.sql`: إنشاء الجداول الـ 9 (`parent_accounts`, `child_profiles`, `child_educational_progress`, `child_activity_logs`, `child_favorites`, `parent_videos`, `subscriptions`, `payment_transactions`, `sync_mutation_ledger`) مع علاقات `ON DELETE CASCADE` وتقليل البيانات الشخصية للأطفال (Data Minimization).
- `supabase/migrations/20261030000002_rls_policies_and_rpc.sql`: سياسات `RLS` الصارمة (`auth.uid() = parent_id`) التي تمنع أي مستخدم من الوصول لبيانات مستخدم آخر، وتقصر جدولَي `subscriptions` و`payment_transactions` على القراءة فقط (`SELECT`) للعملاء، مع دوال الخادم (`rpc_clear_child_activity_history_only`, `rpc_delete_all_child_data`, `rpc_delete_parent_account_cascade`).
- `supabase/tests/rls_security_test.sql`: اختبارات التحقق من تفعيل `FORCE ROW LEVEL SECURITY` ومنع الكتابة المباشرة على جداول الاشتراكات.
- `supabase/functions/subscription-status/index.ts`: دالة Edge Function تستخرج هوية الأب من `Bearer JWT` وتتحقق من صلاحية الاشتراك.
- `supabase/functions/payment-webhook-receiver/index.ts`: دالة Edge Function جاهزة لاستقبال Webhooks بوابات الدفع مستقبلاً (التحقق من توقيع `HMAC-SHA256`، العملة `EGP`، المبلغ، ومنع التكرار).
- `supabase/functions/sync-batch/index.ts`: دالة Edge Function لمزامنة طابور العمليات غير المتصلة مع سجل عدم التكرار (`sync_mutation_ledger`).
- `.env.example`: ملف إعدادات تجريبي خالٍ تماماً من أي مفاتيح سرية.

## ٣. خطوات التشغيل والربط مع Supabase
1. **تطبيق قاعدة البيانات وسياسات RLS:**
   ```bash
   supabase link --project-ref <your-project-ref>
   supabase db push
   ```
2. **نشر دوال Edge Functions:**
   ```bash
   supabase functions deploy subscription-status
   supabase functions deploy payment-webhook-receiver
   supabase functions deploy sync-batch
   ```
3. **تشغيل تطبيق Flutter أو بناء APK Release بتمرير الإعدادات العامة:**
   ```bash
   flutter pub get
   flutter analyze
   flutter test
   flutter build apk --release \
     --dart-define=SUPABASE_URL=https://<your-project-ref>.supabase.co \
     --dart-define=SUPABASE_ANON_KEY=<your-public-anon-key>
   ```
