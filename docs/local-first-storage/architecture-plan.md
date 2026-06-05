# Local-First Storage Architecture Plan

## ملخص

الوضع الحالي في SAWA يعتمد على `SharedPreferences` لحفظ snapshots من البيانات مثل shopping lists, items, homes, categories. هذا يعطي تحميل سريع أحياناً، لكنه ليس قاعدة بيانات محلية حقيقية. النتيجة أن التطبيق ما زال يحتاج إلى سحب بيانات كثيرة من Supabase، ويصعب التعامل مع الحالات الفارغة، التعارضات، الحذف، والفهرسة.

الحل المقترح هو بناء طبقة Local-first عامة باستخدام Drift/SQLite:

1. الواجهة تقرأ دائماً من SQLite أولاً.
2. أي تعديل يكتب محلياً فوراً.
3. التعديل يُرفع إلى Supabase مباشرة إذا الجهاز متصل، أو يدخل `local_pending_mutations` إذا الجهاز غير متصل.
4. المزامنة تسحب delta فقط حسب `updated_at`.
5. Supabase Realtime يكتب التغييرات الواردة في SQLite، وليس في `SharedPreferences`.
6. Drift streams تحدث الواجهة تلقائياً بعد أي تغيير محلي أو remote.

## المشاكل الحالية

- `SharedPreferences` يخزن JSON strings، ولا يدعم queries أو indexes.
- الكاش الفارغ لا يمكن تمييزه دائماً عن "لم تتم المزامنة بعد".
- `getServerLastUpdates` يقلل الطلبات، لكنه لا يكفي وحده لبناء تجربة offline-first.
- بعض sync checks تستبعد الصفوف المحذوفة soft-delete، وهذا قد يمنع وصول الحذف للأجهزة.
- تنظيف بيانات منزل أو مستخدم يعتمد على حذف مفاتيح كثيرة يدوياً.
- offline queue منفصلة عن بيانات العرض، وهذا يزيد تعقيد الدمج.

## المبادئ

- Local DB هي مصدر العرض الأول.
- Supabase هو مصدر المشاركة بين الأجهزة والمصدر النهائي بعد نجاح المزامنة.
- كل query محلية يجب أن تكون scoped بـ `user_id` أو `home_id`.
- لا يتم حذف البيانات المحلية تلقائياً عند تسجيل الخروج العادي.
- لا يتم سحب جدول كامل إذا كان يمكن سحب delta.
- كل جدول مهم يجب أن يملك cursor محلي.
- كل write action يجب أن يحافظ على `created_by` أو `updated_by` عندما ينطبق ذلك.
- لا يتم تجاوز home membership checks؛ Supabase RLS يبقى خط الدفاع الرئيسي عند المزامنة.

## مصدر الحقيقة

| الحالة | مصدر العرض | مصدر التحقق |
|---|---|---|
| فتح التطبيق | SQLite | لا يوجد طلب ضروري قبل أول شاشة |
| تصفح قوائم التسوق | SQLite | Realtime + periodic delta sync |
| إضافة عنصر | SQLite أولاً | Supabase عند الاتصال |
| تعديل أو حذف | SQLite أولاً | Supabase عند الاتصال |
| إزالة عضوية منزل | Supabase | حذف محلي مؤكد بعد sync |
| تبديل مستخدم | SQLite scoped by user | Supabase session |

## مراحل التنفيذ

### Phase 1: Core MVP

هذه المرحلة ضرورية فوراً لأنها تؤثر على فتح التطبيق والتسوق:

- `users`
- `homes`
- `home_members`
- `shopping_lists`
- `shopping_items`
- `item_templates`
- `categories`
- `units`
- `activity_logs`
- `shopping_mode_sessions`
- `local_sync_cursors`
- `local_pending_mutations`
- `local_store_meta`

### Phase 2: ميزات موجودة لكنها ليست قلب التسوق

تضاف بعد استقرار Phase 1:

- `notifications`
- `notification_preferences`
- `invitations`
- `tasks`
- `task_comments`

### Phase 3: ميزات ما بعد MVP

لا يتم تنفيذها قبل استقرار shopping MVP، لكن يجب أن تكون مدعومة معمارياً:

- `inventory_items`
- `inventory_transactions`
- `expenses`
- `expense_splits`
- `settlements`
- `products`

### Server-only أو limited-local

هذه الجداول لا تُحفظ كاملة مثل بيانات العرض:

- `device_tokens`: حفظ token الحالي فقط محلياً إن لزم.
- `rate_limit_log`: server-only.
- `sync_operations_log`: server-only، ويقابله محلياً `local_pending_mutations`.
- `beta_feedback`: pending write-only عند انقطاع الإنترنت.
- `role_permissions`: cache محدود ونادر التحديث.
- `ai_suggestions`: transient، ولا تُحفظ إلا لو أضيف history اختياري.

## دورة القراءة

1. الشاشة تطلب stream من DAO المحلي.
2. DAO يرجع البيانات فوراً من SQLite.
3. Sync coordinator يقرر هل نحتاج delta sync.
4. عند وصول delta، يتم upsert/delete محلياً.
5. Drift stream يعيد بناء الواجهة.

## دورة الكتابة

1. المستخدم يضيف أو يعدل أو يحذف.
2. repository يكتب في SQLite داخل transaction.
3. يتم تحديث `local_state` إلى `pending_create`, `pending_update`, أو `pending_delete`.
4. يتم إنشاء صف في `local_pending_mutations`.
5. إذا الاتصال متاح، sync worker يرفع العملية إلى Supabase.
6. عند نجاح الرفع:
   - تحديث الصف المحلي بنسخة السيرفر.
   - تغيير `local_state` إلى `synced`.
   - حذف mutation أو تعليمها `completed`.
7. عند الفشل:
   - زيادة `retry_count`.
   - حفظ `last_error`.
   - جدولة `next_retry_at`.

## Delta Sync

لكل جدول قابل للمزامنة، يوجد cursor في `local_sync_cursors`:

- `home_id`
- `table_name`
- `last_server_updated_at`
- `initial_sync_done`
- `last_success_at`
- `last_error`

قواعد السحب:

- إذا `initial_sync_done = false`: اسحب الصفحة الأولى من الجدول.
- إذا `initial_sync_done = true`: اسحب فقط `updated_at > last_server_updated_at`.
- يجب تضمين الصفوف ذات `deleted_at != null` حتى تصل عمليات الحذف.
- لا تستخدم "cache empty" وحدها كسبب للسحب؛ استخدم `initial_sync_done`.

## Realtime

Supabase Realtime يبقى مفيداً لتقليل polling. عند وصول payload:

- `INSERT`: upsert في SQLite.
- `UPDATE`: upsert إذا `deleted_at == null`، أو soft delete محلياً إذا `deleted_at != null`.
- `DELETE`: حذف محلي أو soft delete حسب الجدول.

لا يتم تحديث Riverpod providers مباشرة من payload. المصدر المحلي هو الذي يحدث الواجهة.

## سياسة حذف البيانات

| الحدث | السلوك المطلوب |
|---|---|
| تسجيل خروج عادي | لا تحذف البيانات المحلية. امسح session/auth فقط. |
| تسجيل خروج مع حذف بيانات الجهاز | احذف بيانات المستخدم الحالي وكل homes المرتبطة به وكل pending mutations. |
| حذف بيانات منزل من الإعدادات | احذف كل صفوف `home_id` من SQLite. |
| مغادرة منزل أو إزالة عضوية | بعد تأكيد Supabase، احذف بيانات ذلك المنزل محلياً. |
| حذف الحساب | نفذ العملية في Supabase ثم احذف بيانات المستخدم محلياً بالكامل. |
| تبديل مستخدم | لا تعرض بيانات المستخدم السابق. كل query يجب أن تكون scoped. |
| مسح الكاش فقط | احذف snapshots/temp/search فقط، ولا تحذف بيانات الجداول الأساسية. |

## إعدادات مطلوبة في التطبيق

أضف في شاشة الإعدادات قسم "البيانات المحلية":

- حجم البيانات المحلية.
- آخر مزامنة ناجحة.
- عدد العمليات المعلقة.
- زر "مزامنة الآن".
- زر "حذف بيانات هذا المنزل من الجهاز".
- زر "حذف كل بيانات هذا الحساب من الجهاز".
- خيار عند تسجيل الخروج: "الاحتفاظ بالبيانات على هذا الجهاز" أو "حذف بيانات هذا الجهاز".

## معايير النجاح

- فتح التطبيق يعرض البيانات من الهاتف قبل أي طلب شبكة.
- إضافة عنصر بدون إنترنت تظهر فوراً وتبقى بعد إغلاق التطبيق.
- عند عودة الإنترنت تتم المزامنة بدون تكرار.
- حذف عنصر من جهاز آخر يصل للجهاز الحالي.
- تسجيل الخروج لا يحذف البيانات إلا إذا اختار المستخدم ذلك.
- لا تظهر بيانات مستخدم سابق بعد تبديل الحساب.
- لا يتم استدعاء Supabase لجداول لم تتغير.

## مراجع تقنية

- Drift: https://pub.dev/packages/drift
- Drift setup: https://drift.simonbinder.eu/setup/
- Drift stream queries: https://drift.simonbinder.eu/dart_api/streams/
- Drift migrations: https://drift.simonbinder.eu/migrations/
- Supabase Realtime: https://supabase.com/docs/guides/realtime/postgres-changes
- Supabase RLS: https://supabase.com/docs/guides/auth/auth-deep-dive/auth-row-level-security

