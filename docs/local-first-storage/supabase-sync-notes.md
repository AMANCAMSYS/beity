# Supabase Sync Notes

هذه الوثيقة تحدد تعديلات Supabase المطلوبة حتى تعمل قاعدة الهاتف المحلية بدون استهلاك غير ضروري لموارد Supabase.

## قواعد عامة

- كل جدول exposed في schema `public` يجب أن يبقى عليه RLS.
- لا يتم تجاوز home membership checks في أي RPC أو policy.
- كل write يجب أن يكتب `created_by` أو `updated_by` حسب الحالة.
- كل soft delete يجب أن يضع `deleted_at`, `updated_at`, و`updated_by`.
- لا تعتمد RLS على `user_metadata` لأنه قابل للتعديل من المستخدم.

## تعديل `get_tables_last_update`

المشكلة: إذا كانت الدالة تحسب `MAX(updated_at)` مع شرط `deleted_at IS NULL` فلن يعرف الجهاز أن هناك حذفاً حدث.

المطلوب:

- إزالة شرط `deleted_at IS NULL` من حسابات `MAX(updated_at)` للجداول التي تستخدم soft delete.
- إبقاء home membership check في بداية الدالة.
- إرجاع timestamps لكل الجداول المهمة، حتى لو كانت القيمة `1970-01-01`.

الجداول التي يجب تضمينها تدريجياً:

- Phase 1: `homes`, `home_members`, `shopping_lists`, `shopping_items`, `item_templates`, `categories`, `units`, `activity_logs`, `shopping_mode_sessions`
- Phase 2: `notifications`, `notification_preferences`, `invitations`, `tasks`, `task_comments`
- Phase 3: `inventory_items`, `inventory_transactions`, `expenses`, `expense_splits`, `settlements`, `products`

## Delta Queries

كل repository remote يحتاج method واضح:

- `getUpdatedShoppingLists(homeId, since)`
- `getUpdatedShoppingItems(homeId, since)`
- `getUpdatedCategories(homeId, since)`
- `getUpdatedActivityLogs(homeId, since)`

قواعد delta:

- استخدم `updated_at > since`.
- لا تستبعد `deleted_at`.
- استخدم pagination إذا زادت النتائج.
- بعد نجاح الصفحة الأخيرة، حدث `local_sync_cursors`.

## Indexes مطلوبة في Supabase

راجع وجود هذه الفهارس أو أضفها:

- `shopping_lists(home_id, updated_at desc)`
- `shopping_items(home_id, updated_at desc)`
- `categories(home_id, updated_at desc)`
- `item_templates(home_id, updated_at desc)`
- `home_members(user_id, home_id)` مع filter active إن أمكن
- `home_members(home_id, updated_at desc)`
- `activity_logs(home_id, created_at desc)`
- `shopping_mode_sessions(home_id, updated_at desc)`
- `notifications(user_id, is_read, created_at desc)`
- `tasks(home_id, updated_at desc)`
- `inventory_items(home_id, updated_at desc)`
- `expenses(home_id, updated_at desc)`

## Realtime

الجداول المنشورة في Supabase Realtime يجب أن تشمل كل ما يهم العرض المحلي:

- Phase 1: `homes`, `home_members`, `shopping_lists`, `shopping_items`, `item_templates`, `categories`, `units`, `activity_logs`, `shopping_mode_sessions`
- Phase 2: `notifications`, `invitations`, `tasks`, `task_comments`

عند وصول event:

- لا تحدث UI state مباشرة.
- اكتب event في SQLite.
- اترك Drift streams تحدث الواجهة.

## Idempotency

استخدم `idempotency_key` في `local_pending_mutations` محلياً، واربطه بسجل server-side عند الحاجة في `sync_operations_log` حتى لا تتكرر العمليات عند retry.

العمليات الحساسة:

- إنشاء قائمة.
- إنشاء عنصر.
- تغيير حالة شراء عنصر.
- حذف عنصر.
- عمليات RPC مثل `set_shopping_item_purchase_state`.

## Membership Revocation

عند اكتشاف أن المستخدم لم يعد عضواً في home:

1. أوقف Realtime لهذا المنزل.
2. احذف cursors الخاصة بالمنزل.
3. احذف كل بيانات `home_id` محلياً.
4. ألغ mutations المعلقة لهذا المنزل أو علمها `cancelled`.
5. إذا كان المنزل هو النشط، اختر أحدث منزل صالح أو امسح active home.

## Security Checklist

- RLS enabled على كل جدول exposed.
- policies تستخدم `to authenticated`.
- لا يوجد `service_role` في Flutter.
- لا تعتمد policies على `raw_user_meta_data`.
- `UPDATE` policies لديها SELECT policy مناسب.
- أي security definer RPC يثبت `search_path`.
- كل RPC يتحقق من عضوية المنزل.

