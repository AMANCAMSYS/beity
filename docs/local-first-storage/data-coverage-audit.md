# Full Local Data Coverage Audit

آخر تحديث: 2026-06-03

## الخلاصة

لا، لم يتم نقل كل البيانات التي يطلبها التطبيق إلى قاعدة البيانات المحلية بعد. الموجود حالياً في Drift/SQLite يغطي نواة الـ MVP: المنازل، الأعضاء، قوائم التسوق، عناصر التسوق، قوالب العناصر، التصنيفات، الوحدات، سجلات النشاط، جلسات وضع التسوق، مؤشرات المزامنة، والعمليات المعلقة.

لكن ما زالت هناك مسارات خارج نواة التسوق تقرأ من Supabase مباشرة أو تحفظ snapshots في `SharedPreferences`. المطلوب ليس "كاش مؤقت لكل شيء"، بل قاعدة محلية دائمة لكل بيانات العرض التي يحتاجها المستخدم، مع إبقاء الجداول التقنية أو الحساسة server-only عندما يكون ذلك صحيحاً.

## طريقة الفحص

تمت مراجعة:

- جداول Drift الحالية في `lib/core/local_database/app_database.dart`.
- كل استدعاءات Supabase عبر `.from(...)`, `.rpc(...)`, و`.select(...)` داخل `lib/core` و`lib/features`.
- local data sources التي ما زالت تستخدم `SharedPreferences`.
- مخطط Supabase الحالي في `supabase/migrations/20260601182913_remote_schema.sql`.

## قاعدة القرار

| نوع البيانات | القرار المحلي |
|---|---|
| تظهر في واجهة المستخدم أو يحتاجها المستخدم بدون إنترنت | جدول Drift دائم + DAO + repository local-first |
| عملية كتابة يمكن أن تحدث بدون إنترنت | Drift row محلي + `local_pending_mutations` |
| إعداد بسيط للجهاز مثل اللغة والثيم وonboarding | `SharedPreferences` مقبول |
| token أو سجل تقني لا يفيد العرض | لا يحفظ كجدول عرض محلي |
| نتيجة مشتقة من عدة جداول | تشتق من Drift أو تحفظ snapshot محلي واضح قابل للحذف |

## مصفوفة التغطية الحالية

| المجال | جداول Supabase | الحالة الحالية | المطلوب |
|---|---|---|---|
| الحساب والملف الشخصي | `users` | `local_users` مربوط بـ `AuthRepositoryImpl` للكتابة والقراءة offline، وprofile/invitations تقرأ منه، وmigration v2 ينقل مفاتيح profile القديمة | تنظيف مفاتيح SharedPreferences legacy لاحقاً بعد إصدار مستقر |
| المنازل | `homes` | Drift موجود ومربوط بمسارات أساسية | إكمال delta لكل read path وليس فقط شاشة homes |
| أعضاء المنازل | `home_members` | Drift موجود ومربوط جزئياً | ربط roles/invitations/member screens بالقراءة المحلية عند الإمكان |
| صلاحيات الأدوار | `role_permissions` | cache محدود في `local_store_meta`، والقراءة تبدأ محلياً بعد أول تحميل ناجح | إضافة TTL أو global cursor لاحقاً إذا أصبحت تتغير كثيراً |
| قوائم التسوق | `shopping_lists` | Local-first فعلياً في المسارات الأساسية | إكمال أي read path مساعد ما زال يستدعي remote بلا حاجة |
| عناصر التسوق | `shopping_items` | Local-first فعلياً في المسارات الأساسية | إكمال suggestions/shopping mode/recovery من Drift أولاً |
| قوالب العناصر | `item_templates` | جدول Drift موجود، لكن بعض مسارات الاقتراحات ما زالت remote-first | جعل الاقتراحات تقرأ Drift أولاً ثم delta عند الحاجة |
| التصنيفات | `categories` | Drift-first للقراءة والكتابة، وcreate/update/delete تدخل outbox عند انقطاع الشبكة | إكمال اختبارات repository/outbox المخصصة للتصنيفات |
| الوحدات | `units` | Drift-first للقراءة والـ streams و`getUnitById`، وautocomplete يستخدم الوحدات المحلية، والكتابة تحدث Drift بعد نجاح السيرفر | حسم scope للوحدات العامة قبل تفعيل outbox offline كامل |
| سجل النشاط | `activity_logs` | Drift-first للـ streams والـ filters، وRealtime يكتب Drift | إضافة outbox اختياري إذا أردنا تسجيل النشاط أثناء offline writes العامة |
| وضع التسوق | `shopping_mode_sessions` | DAO + repository/recovery local-first، وRealtime يكتب Drift، وstart/end يدخلان outbox عند انقطاع الشبكة | إضافة اختبارات lifecycle offline على SQLite حقيقي |
| الإشعارات | `notifications` | Drift-first: `local_notifications` + `NotificationsDao` + `LocalFirstNotificationRepository` | Realtime يكتب Drift، mark read local-first + outbox |
| تفضيلات الإشعارات | `notification_preferences` | Drift-first: `local_notification_preferences` + `NotificationPreferencesDao` + `LocalFirstNotificationRepository` | default يُنشأ محلياً، update local-first + outbox |
| الدعوات | `invitations` | Drift-first: `local_invitations` + `InvitationsDao` + `LocalFirstInvitationRepository` | Drift أولاً، remote refresh يكتب Drift، decline/cancel local-first + outbox، accept online-only (RPC) |
| المهام | `tasks`, `task_comments` | SharedPreferences cache + remote-first | مؤجل حسب MVP، لكن يجب نقله إلى Drift عند فتح Phase tasks |
| المصروفات | `expenses`, `expense_splits`, `settlements` | SharedPreferences cache + remote-first | مؤجل حسب MVP، ثم Drift tables + local-first writes |
| المخزون | `inventory_items`, `inventory_transactions` | SharedPreferences cache + remote-first | مؤجل حسب MVP، ثم Drift tables + local-first writes |
| المنتجات | `products` | غير مغطى محلياً | يؤجل إلى inventory/AI، مع جدول محلي عند تفعيل البحث/الاقتراح |
| لوحة المنزل | dashboard snapshot | snapshot انتقل إلى `local_store_meta` في Drift مع ذاكرة داخلية للقراءة الفورية | يفضل لاحقاً اشتقاقه بالكامل من Drift بدون snapshot إذا صار ذلك أبسط |
| أجهزة الإشعارات | `device_tokens` | server write فقط | لا تحفظ كجدول عرض؛ token الحالي فقط في meta إن احتجنا |
| سجل idempotency | `sync_operations_log` | server-side | لا يحفظ محلياً؛ يقابله `local_pending_mutations` |
| rate limits | `rate_limit_log` | server-side | لا يحفظ محلياً |
| beta feedback | `beta_feedback` | remote write | pending write-only في outbox عند انقطاع الإنترنت |
| اقتراحات AI | Edge Functions/AI | remote/transient | لا تكون source of truth؛ يمكن حفظ history اختياري فقط |

## فجوات SharedPreferences التي يجب إزالتها

هذه المسارات يجب ألا تبقى كبيانات عرض طويلة الأجل في `SharedPreferences`:

- `*_cached_profile` و`last_logged_in_user_id` للملف الشخصي.
- `cached_activity_logs_*` و`cached_actors_*`.
- `cached_home_invitations_*` و`cached_user_invitations_*`. ✅ تم نقلها إلى `local_invitations` في migration v2.
- `cached_tasks_*` و`cached_tasks_stream_*`.
- `cached_expenses_*` و`cached_expenses_stream_*`.
- `cached_inventory_*` و`cached_inventory_stream_*`.
- `cached_home_dashboard_snapshot_*` أزيل من المسار الجديد، ويبقى فقط كمفتاح legacy يمكن تنظيفه.

تبقى `SharedPreferences` فقط للإعدادات الصغيرة مثل اللغة، الثيم، onboarding، آخر شاشة مفتوحة، وfeature flags المحلية.

## ترتيب التنفيذ الصحيح

### أولوية 1: إغلاق فجوات MVP

هذه لا تخالف MVP ويجب تنفيذها قبل التوسع:

1. تنظيف مفاتيح `SharedPreferences` القديمة للملف الشخصي بعد إصدار مستقر يؤكد نجاح migration v2.
2. إضافة اختبارات SQLite حقيقية لـ `shopping_mode_sessions` بعد توفر `libsqlite3.so` أو تشغيل integration tests على جهاز.
3. جعل أي path جديد في shopping يستخدم `item_templates` و`units` من Drift أولاً.
4. إزالة مفاتيح SharedPreferences القديمة بعد اكتمال migration.
5. إكمال اختبارات التصنيفات local-first، واتخاذ قرار مستقل للوحدات العامة إذا كانت الشاشة تسمح بتعديلها بدون إنترنت.
6. جعل dashboard يعتمد على Drift بدلاً من snapshot في SharedPreferences.

### أولوية 2: بيانات عالمية صغيرة ومهمة

هذه تستهلك Supabase بلا داع إذا بقيت remote-first:

1. `notifications`.
2. `notification_preferences`.
3. `invitations`.
4. `role_permissions` لديها cache محدود الآن؛ المتبقي فقط TTL أو global cursor عند الحاجة.

### أولوية 3: ميزات مؤجلة حسب AGENTS.md

لا تنفذ قبل ثبات shared shopping-list MVP، لكن عندما تفتح مراحلها يجب أن تبدأ Drift-first من أول يوم:

1. `tasks` و`task_comments`.
2. `expenses`, `expense_splits`, `settlements`.
3. `inventory_items`, `inventory_transactions`, `products`.

## شروط قبول عامة

- أي شاشة تعرض بيانات يجب أن تعرض أولاً من Drift بدون انتظار الشبكة.
- كل repository جديد يملك local DAO قبل remote repository.
- كل write يظهر فوراً محلياً ثم يدخل outbox إذا تعذر رفعه.
- كل جدول قابل للمزامنة يملك cursor في `local_sync_cursors`.
- كل delta pull يستخدم pagination ويشمل soft-deleted rows إذا كان الجدول يدعم `deleted_at`.
- كل Realtime payload للجداول المفعلة في Phase 15 يكتب Drift ولا يحدث الواجهة مباشرة.
- حذف بيانات منزل أو مستخدم يحذف كل الجداول المرتبطة به، بما فيها الجداول المضافة لاحقاً.
- لا يتم حذف البيانات المحلية عند تسجيل الخروج العادي.
