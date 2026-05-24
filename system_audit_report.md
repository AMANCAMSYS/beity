# Beity Full-Stack Audit Report

تاريخ التدقيق: 2026-05-24  
النطاق: Flutter/Riverpod/GoRouter + Supabase PostgreSQL/Auth/Realtime/Edge Functions  
الحالة العامة: التطبيق غني وظيفيا، لكن توجد عدة نقاط حرجة في التفويض، المزامنة بدون اتصال، وتطابق المخطط بين Flutter وSupabase. هذه النقاط يجب علاجها قبل أي Beta عامة أو تفعيل AI/Notifications على بيئة إنتاج.

## ملخص تنفيذي

تمت مراجعة ملفات Flutter الأساسية، providers، repositories، خدمات realtime/notifications/offline، Edge Functions، ومهاجرات Supabase/RLS. لم أتمكن من تشغيل `flutter analyze` أو `dart` أو `supabase` CLI لأن الأدوات غير متوفرة في البيئة الحالية، لذلك هذا التقرير مبني على قراءة الكود والمخطط.

الأولوية القصوى:

| الشدة | العدد | الخلاصة |
| --- | ---: | --- |
| Critical | 7 | Edge Functions بلا تحقق JWT كاف، RPCs تكشف بيانات مالية، سياسات invitations تسمح بتجاوز RPC، offline queue مكسورة، sign out لا يمسح بيانات المستخدم الفعلي، AI function مكشوفة، وظائف notifications غير متطابقة مع المخطط. |
| High | 18 | سياسات RLS لا تتحقق من عضوية active في عدة ميزات، Realtime providers غير autoDispose، Tasks تستدعي RPCs غير موجودة، Role repository يكتب أعمدة غير موجودة، Shopping audit logs تنسب التعديل للمستخدم الخطأ، وحدات units قابلة للإدارة في الواجهة لكن RLS يمنعها. |
| Medium | 20+ | نقص فهارس مهمة، معالجة أخطاء غير موحدة، cache invalidation غير مكتمل، قيود cross-home ناقصة، UI flows لا تعرض دائما optimistic/offline state. |

## القيود والمنهجية

- تمت قراءة `specs/016-ai-phase/plan.md`، `pubspec.yaml`، `lib/main.dart`، إعدادات البيئة، ملفات features، ومهاجرات Supabase.
- تمت مراجعة `supabase/migrations/20260524100350_remote_schema.sql` والمهاجرات اللاحقة الخاصة بالدعوات.
- تمت مراجعة Edge Functions تحت `supabase/functions`.
- لم يتم تشغيل اختبارات أو analyzer بسبب عدم توفر `flutter`/`dart`/`supabase` في PATH.

## 1. Database & Backend Audit

### 1.1 ثغرات RLS/RPC حرجة

#### CRITICAL-DB-01: RPCs المالية تكشف أرصدة وأعضاء أي بيت لمن يعرف `home_id`

الأدلة:

- `calculate_home_balances(p_home_id uuid)` معرفة كـ `SECURITY DEFINER` دون تحقق `auth.uid()` أو عضوية البيت، ودون `SET search_path`.
- `has_unsettled_balances(p_home_id, p_user_id)` تستدعي نفس الحسابات دون تحقق ملكية/عضوية.
- تم منح `GRANT ALL` لهذه الدوال إلى `anon` و`authenticated`.

الأثر:

- أي مستخدم مصادق، وربما anonymous حسب إعدادات API، يستطيع استدعاء RPC ومعرفة UUIDs وأرصدة أعضاء أي بيت إذا حصل على `home_id`.
- هذا تسريب خصوصية مالي مباشر ويخالف قاعدة "Never bypass home membership checks".

الإصلاح الفوري المقترح:

```sql
begin;

revoke all on function public.calculate_home_balances(uuid) from anon, authenticated;
revoke all on function public.has_unsettled_balances(uuid, uuid) from anon, authenticated;

create or replace function public.calculate_home_balances(p_home_id uuid)
returns table(user_id uuid, balance numeric)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if auth.uid() is null then
    raise exception 'Authentication required';
  end if;

  if not exists (
    select 1
    from public.home_members hm
    where hm.home_id = p_home_id
      and hm.user_id = auth.uid()
      and hm.status = 'active'
      and hm.deleted_at is null
  ) then
    raise exception 'Access denied';
  end if;

  return query
  with paid as (
    select e.paid_by as member_id, coalesce(sum(e.amount), 0)::numeric as amount
    from public.expenses e
    where e.home_id = p_home_id
      and e.deleted_at is null
    group by e.paid_by
  ),
  owed as (
    select es.member_id, coalesce(sum(es.amount), 0)::numeric as amount
    from public.expense_splits es
    join public.expenses e on e.id = es.expense_id
    where e.home_id = p_home_id
      and e.deleted_at is null
    group by es.member_id
  )
  select hm.user_id,
         coalesce(paid.amount, 0) - coalesce(owed.amount, 0) as balance
  from public.home_members hm
  left join paid on paid.member_id = hm.user_id
  left join owed on owed.member_id = hm.user_id
  where hm.home_id = p_home_id
    and hm.status = 'active'
    and hm.deleted_at is null;
end;
$$;

create or replace function public.has_unsettled_balances(
  p_home_id uuid,
  p_user_id uuid
)
returns boolean
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if auth.uid() is null then
    raise exception 'Authentication required';
  end if;

  if not exists (
    select 1
    from public.home_members hm
    where hm.home_id = p_home_id
      and hm.user_id = auth.uid()
      and hm.status = 'active'
      and hm.deleted_at is null
  ) then
    raise exception 'Access denied';
  end if;

  if auth.uid() <> p_user_id and not exists (
    select 1
    from public.home_members hm
    where hm.home_id = p_home_id
      and hm.user_id = auth.uid()
      and hm.role in ('owner', 'admin')
      and hm.status = 'active'
      and hm.deleted_at is null
  ) then
    raise exception 'Access denied';
  end if;

  return exists (
    select 1
    from public.calculate_home_balances(p_home_id) b
    where b.user_id = p_user_id
      and b.balance <> 0
  );
end;
$$;

grant execute on function public.calculate_home_balances(uuid) to authenticated;
grant execute on function public.has_unsettled_balances(uuid, uuid) to authenticated;

commit;
```

#### CRITICAL-DB-02: قبول الدعوات يمكن تجاوزه بتحديث مباشر على جدول `invitations`

الأدلة:

- توجد RPC `accept_invitation(invitation_token text)`.
- توجد أيضا سياسات update مباشرة على `invitations` تسمح للمدعو بتغيير صف الدعوة عندما يطابق البريد، مع `WITH CHECK` ضعيف يركز على `status` أو `email` فقط.
- السياسات لا تثبت أن الصف كان `pending` قبل التحديث، ولا تمنع تغيير أعمدة حساسة مثل `home_id`, `role`, `token`, `accepted_at`.

الأثر:

- يمكن لعميل خبيث وضع الدعوة بحالة `accepted` دون إدخال صف `home_members`.
- يمكن إنتاج حالة بيانات غير متسقة أو نشاطات خاطئة.
- إذا سمحت صلاحيات update بكتابة أعمدة إضافية، يمكن تغيير دلالة الدعوة نفسها.

الإصلاح الفوري المقترح:

```sql
begin;

drop policy if exists "Invited users can update their invitations" on public.invitations;
drop policy if exists "Users can update their own pending invitations" on public.invitations;

create policy "Invited users can cancel only their pending invitations"
on public.invitations
for update
to authenticated
using (
  lower(email) = lower((auth.jwt() ->> 'email'))
  and status = 'pending'
  and expires_at > now()
)
with check (
  lower(email) = lower((auth.jwt() ->> 'email'))
  and status = 'cancelled'
);

revoke all on function public.accept_invitation(text) from anon, authenticated;

create or replace function public.accept_invitation(invitation_token text)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_invitation public.invitations%rowtype;
  v_user_email text;
begin
  if auth.uid() is null then
    raise exception 'Authentication required';
  end if;

  v_user_email := auth.jwt() ->> 'email';

  select *
  into v_invitation
  from public.invitations
  where token = invitation_token
    and status = 'pending'
    and expires_at > now()
  for update;

  if not found then
    raise exception 'Invalid or expired invitation';
  end if;

  if lower(v_invitation.email) <> lower(v_user_email) then
    raise exception 'Invitation email does not match authenticated user';
  end if;

  insert into public.home_members (
    home_id, user_id, role, status, joined_at, created_by
  )
  values (
    v_invitation.home_id,
    auth.uid(),
    v_invitation.role,
    'active',
    now(),
    v_invitation.created_by
  )
  on conflict (home_id, user_id)
  do update set
    role = excluded.role,
    status = 'active',
    deleted_at = null,
    joined_at = now();

  update public.invitations
  set status = 'accepted',
      accepted_at = now()
  where id = v_invitation.id;

  return jsonb_build_object(
    'home_id', v_invitation.home_id,
    'role', v_invitation.role,
    'status', 'accepted'
  );
end;
$$;

grant execute on function public.accept_invitation(text) to authenticated;

commit;
```

#### CRITICAL-BE-01: Edge Function `send-notification` تستخدم service role دون تحقق هوية أو عضوية

الأدلة:

- `supabase/functions/send-notification/index.ts` ينشئ service-role client ويتعامل مع payload مباشرة.
- لا يوجد تحقق صريح من `Authorization: Bearer <jwt>`.
- الدالة تستعلم جداول لا تطابق المخطط الحالي مثل `profiles`.

الأثر:

- أي مستدعي قادر على الوصول للدالة يمكنه إطلاق إشعارات باسم أي بيت إذا عرف IDs.
- استخدام service role يتجاوز RLS، لذلك يجب أن يكون التحقق داخل الدالة صارما.
- الدالة غالبا تفشل حاليا بسبب عدم وجود `profiles` وتباين `notification_preferences`.

الإصلاح الفوري المقترح:

```ts
async function requireUser(req: Request, supabaseAdmin: SupabaseClient) {
  const authHeader = req.headers.get('Authorization') ?? '';
  const token = authHeader.replace(/^Bearer\s+/i, '');

  if (!token) {
    throw new Response(JSON.stringify({ error: 'Missing authorization token' }), { status: 401 });
  }

  const { data, error } = await supabaseAdmin.auth.getUser(token);
  if (error || !data.user) {
    throw new Response(JSON.stringify({ error: 'Invalid authorization token' }), { status: 401 });
  }

  return data.user;
}

async function requireActiveHomeMember(
  supabaseAdmin: SupabaseClient,
  homeId: string,
  userId: string,
) {
  const { data, error } = await supabaseAdmin
    .from('home_members')
    .select('role')
    .eq('home_id', homeId)
    .eq('user_id', userId)
    .eq('status', 'active')
    .is('deleted_at', null)
    .maybeSingle();

  if (error || !data) {
    throw new Response(JSON.stringify({ error: 'Access denied' }), { status: 403 });
  }
}
```

يجب استدعاء الدالتين في بداية handler قبل أي قراءة/كتابة أو إرسال FCM، واستبدال `profiles` بجدول `users`، وتحديث منطق `notification_preferences` ليتوافق مع الأعمدة الفعلية: `item_added`, `item_completed`, `low_stock`, `expiry_alert`, `expense_added`, `task_due`.

#### CRITICAL-BE-02: Edge Function `generate-shopping-suggestions` مكشوفة وتستهلك مزود AI دون تحقق

الأدلة:

- الدالة تقبل الطلب وتقرأ `DEEPSEEK_API_KEY` وتستدعي DeepSeek API دون تحقق JWT داخل الكود.
- الخطة في `specs/016-ai-phase/plan.md` تشترط auth عبر JWT، وعدم وجود مفاتيح AI في العميل، والحدود الآمنة.
- تنظيف PII يطبق على `prompt` فقط، بينما السياق المرسل يمكن أن يحتوي أسماء عناصر/ملاحظات حساسة.

الأثر:

- يمكن استهلاك quota/cost الخاص بالمشروع عبر استدعاءات غير مصرح بها إذا لم تكن الدالة محمية على مستوى gateway.
- لا يوجد تحقق عضوية للبيت/القائمة عند إرسال سياق من التطبيق.

الإصلاح الفوري المقترح:

```ts
const authHeader = req.headers.get('Authorization') ?? '';
const token = authHeader.replace(/^Bearer\s+/i, '');

if (!token) {
  return new Response(JSON.stringify({ error: 'Missing authorization token' }), { status: 401 });
}

const { data: userData, error: userError } = await supabaseAdmin.auth.getUser(token);
if (userError || !userData.user) {
  return new Response(JSON.stringify({ error: 'Invalid authorization token' }), { status: 401 });
}

if (homeId) {
  const { data: member } = await supabaseAdmin
    .from('home_members')
    .select('id')
    .eq('home_id', homeId)
    .eq('user_id', userData.user.id)
    .eq('status', 'active')
    .is('deleted_at', null)
    .maybeSingle();

  if (!member) {
    return new Response(JSON.stringify({ error: 'Access denied' }), { status: 403 });
  }
}
```

كما يجب تطبيق فلترة PII على جميع عناصر السياق وليس `prompt` فقط، وإضافة rate limiting أو daily quota لكل مستخدم.

### 1.2 RLS High-Risk Findings

#### HIGH-DB-01: سياسات كثيرة تتحقق من وجود عضوية فقط دون `status='active'` و`deleted_at is null`

الجداول المتأثرة تشمل:

- `expenses`
- `settlements`
- `inventory_items`
- `inventory_transactions`
- `item_templates`
- `shopping_mode_sessions`

الأثر:

- عضو soft-deleted أو inactive يمكن أن يبقى قادرا على القراءة/الكتابة إذا ظل صف `home_members` موجودا.

الإصلاح:

- توحيد كل سياسات العضوية لتستخدم شرطا واحدا:

```sql
exists (
  select 1
  from public.home_members hm
  where hm.home_id = <table>.home_id
    and hm.user_id = auth.uid()
    and hm.status = 'active'
    and hm.deleted_at is null
)
```

#### HIGH-DB-02: سياسات update على `shopping_lists` و`shopping_items` لا تلزم `updated_by`

الأدلة:

- سياسات update تعمل بـ `USING` فقط ولا تفرض `WITH CHECK`.
- Flutter update/delete/mark purchased لا يرسل `updated_by`.
- trigger النشاط يستخدم `COALESCE(NEW.updated_by, NEW.created_by)`، لذلك قد ينسب التعديل للمنشئ بدلا من المعدل.

الأثر:

- سجل النشاط غير موثوق.
- يمكن لعميل خبيث تغيير أعمدة ownership/audit إذا لم تكن محمية.

الإصلاح:

```sql
drop policy if exists "Home members can update items" on public.shopping_items;
create policy "Home members can update items"
on public.shopping_items
for update
to authenticated
using (
  exists (
    select 1 from public.shopping_lists sl
    join public.home_members hm on hm.home_id = sl.home_id
    where sl.id = shopping_items.list_id
      and hm.user_id = auth.uid()
      and hm.status = 'active'
      and hm.deleted_at is null
  )
)
with check (
  updated_by = auth.uid()
  and exists (
    select 1 from public.shopping_lists sl
    join public.home_members hm on hm.home_id = sl.home_id
    where sl.id = shopping_items.list_id
      and hm.user_id = auth.uid()
      and hm.status = 'active'
      and hm.deleted_at is null
  )
);
```

طبق نفس المبدأ على `shopping_lists`.

#### HIGH-DB-03: `home_members` تسمح بإضافة أعضاء مباشرة وتجاوز الدعوات

الأدلة:

- توجد policy تسمح للـ owner/admin بإدخال أعضاء في `home_members`.
- المنتج يعتمد على invitations/roles كمسار عضوية رسمي.

الأثر:

- يمكن تجاوز invitation lifecycle، إشعارات، وسجل النشاط.

الإصلاح:

- اجعل إضافة الأعضاء المباشرة عبر RPC آمنة فقط أو قيدها على service role.
- اجعل العميل يقبل الدعوة عبر `accept_invitation` فقط.

#### HIGH-DB-04: `units` قابلة للإنشاء/التعديل/الحذف في Flutter لكن RLS يسمح SELECT فقط

الأدلة:

- `SupabaseUnitRepository` يحتوي create/update/delete.
- migration تحتوي سياسة select فقط لـ `units`.

الأثر:

- شاشة إدارة الوحدات ستفشل في الإنتاج برسائل RLS/permission.

الإصلاح:

- إما جعل units read-only في التطبيق، أو إضافة نموذج ownership واضح (`home_id`, `created_by`) وسياسات RLS مناسبة.

### 1.3 RPC/Triggers

#### HIGH-DB-05: عدة دوال `SECURITY DEFINER` بلا `SET search_path`

الدوال المتأثرة تشمل دوال مالية، تسجيل نشاط، إشعارات، وبعض triggers. عدم تحديد search_path مع security definer يفتح باب hijacking إذا امتلك مستخدم صلاحيات create في schema متاح.

الإصلاح:

```sql
alter function public.some_function(...) set search_path = public, pg_temp;
```

ويفضل إعادة تعريف الدوال مع schema-qualified table names.

#### HIGH-DB-06: grants عامة جدا للدوال والجداول

الأدلة:

- وجود `GRANT ALL ON FUNCTION ... TO anon/authenticated/service_role`.
- وجود default privileges تمنح كل الدوال المستقبلية إلى `anon`.

الأثر:

- أي RPC جديد يصبح مكشوفا تلقائيا.

الإصلاح:

```sql
alter default privileges for role postgres in schema public
revoke all on functions from anon;

revoke all on all functions in schema public from anon;
grant usage on schema public to anon, authenticated;
```

ثم امنح `execute` فقط للدوال العامة المطلوبة.

### 1.4 Constraints & Foreign Keys

#### HIGH-DB-07: قيود cross-home ناقصة

أمثلة:

- `inventory_transactions.inventory_item_id` لا يضمن أن العنصر من نفس `home_id`.
- `shopping_mode_sessions.shopping_list_id` لا يضمن أن القائمة من نفس `home_id`.
- `shopping_items.category_id/unit_id/product_id` لا يضمن نفس البيت أو default scope.
- `expenses.paid_by`, `expense_splits.member_id`, `settlements.from_member/to_member`, `tasks.assigned_to/completed_by` لا تضمن active home membership.

الأثر:

- يمكن إدخال بيانات متقاطعة بين بيوت مختلفة إذا مرّت RLS.
- التقارير والإشعارات قد تظهر بيانات خاطئة.

الإصلاح:

- أضف triggers constraint-style للتحقق من membership/same-home، أو استخدم composite FKs حيث يمكن.

#### MEDIUM-DB-01: حذف البيت hard-delete قد يتعطل بسبب علاقات بلا cascade

أمثلة:

- `tasks.home_id` بلا `ON DELETE CASCADE`.
- `task_comments.task_id` بلا `ON DELETE CASCADE`.
- `homes.owner_id` قد يمنع حذف مستخدم مالك.

إذا كان النظام يعتمد soft delete فقط فهذا مقبول مؤقتا، لكن يجب توثيقه وإضافة cleanup jobs.

#### HIGH-DB-08: unique index للمخزون لا يمنع التكرار النشط

الأدلة:

- `uq_inventory_items_home_name_unit` على `(home_id, name, unit_id, deleted_at)`.
- في PostgreSQL، قيم `NULL` ليست متساوية، لذلك يمكن إدخال أكثر من عنصر نشط بنفس الاسم والوحدة.

الإصلاح:

```sql
drop index if exists public.uq_inventory_items_home_name_unit;

create unique index uq_inventory_items_active_home_name_unit
on public.inventory_items (home_id, lower(name), unit_id)
where deleted_at is null;
```

### 1.5 Indexes & Performance

فهارس ينصح بإضافتها قبل Beta:

```sql
create index if not exists idx_home_members_active_user_home
on public.home_members (user_id, home_id)
where status = 'active' and deleted_at is null;

create index if not exists idx_shopping_lists_home_active
on public.shopping_lists (home_id, updated_at desc)
where deleted_at is null;

create index if not exists idx_shopping_items_list_active
on public.shopping_items (list_id, updated_at desc)
where deleted_at is null;

create index if not exists idx_invitations_email_status
on public.invitations (lower(email), status, expires_at);

create index if not exists idx_invitations_home_status
on public.invitations (home_id, status, created_at desc);

create index if not exists idx_notifications_user_unread_created
on public.notifications (user_id, is_read, created_at desc);

create index if not exists idx_products_home
on public.products (home_id)
where deleted_at is null;
```

## 2. Frontend-Backend Integration Audit

### 2.1 Critical Integration Findings

#### CRITICAL-FE-01: Sign out لا يمسح بيانات المستخدم المحلي الفعلي

الأدلة:

- `AuthNotifier.signOut()` يستدعي `_repo.signOut()` أولا، ثم `clearQueue()` و`clearAllUserData()`.
- `HomeLocalDataSource` و`SharedPreferencesQueueDataSource` يبنيان key من `Supabase.instance.client.auth.currentUser?.id ?? 'anonymous'`.

الأثر:

- بعد sign out يصبح `currentUser` فارغا، فيتم مسح مفاتيح `anonymous` بدلا من مفاتيح المستخدم السابق.
- تبقى queue وactive home وبيانات homes محليا بعد تسجيل الخروج.

الإصلاح الفوري المقترح:

```dart
Future<void> signOut() async {
  final userId = _repo.currentUser?.id;
  final fcmToken = await _getCurrentFcmToken();

  state = const AuthState.loading();
  try {
    if (userId != null && fcmToken != null) {
      await _deviceTokenRepository.removeDeviceToken(fcmToken);
    }

    if (userId != null) {
      await _queueDataSource.clearQueueForUser(userId);
      await _homeLocalDataSource.clearAllUserDataForUser(userId);
    }

    await _repo.signOut();

    _ref.invalidate(currentUserProvider);
    _ref.invalidate(userProfileProvider);
    _ref.invalidate(authStateProvider);
    state = const AuthState.unauthenticated();
  } catch (e) {
    state = AuthState.error(_mapSignOutError(e));
  }
}
```

ويضاف في data sources:

```dart
Future<void> clearQueueForUser(String userId) async {
  await _prefs.remove('offline_queue_$userId');
}

Future<void> clearAllUserDataForUser(String userId) async {
  await _prefs.remove('homes_$userId');
  await _prefs.remove('active_home_id_$userId');
}
```

#### CRITICAL-FE-02: Offline queue لا تتم مزامنتها بسبب `homeId` خاطئ واسم جدول خاطئ

الأدلة:

- `OfflineAwareShoppingRepository.addItem()` يضع `homeId: listId`.
- update/delete/mark purchased تضع `homeId: itemId`.
- `SyncQueueUseCase.executeAction` يستخدم `client.from(entry.entityType.name)`، والقيم هي `shoppingItem`/`shoppingList` بينما الجداول هي `shopping_items`/`shopping_lists`.

الأثر:

- `getEntriesByHome(activeHomeId)` لن يجد العمليات المؤجلة.
- عند sync سيحاول الكتابة إلى جدول غير موجود باسم `shoppingItem`.
- offline mode سيبدو أنه عمل، لكنه لا يرفع التغييرات فعليا.

الإصلاح الفوري المقترح:

```dart
extension EntityTypeTable on EntityType {
  String get tableName => switch (this) {
        EntityType.shoppingItem => 'shopping_items',
        EntityType.shoppingList => 'shopping_lists',
        EntityType.home => 'homes',
        EntityType.invitation => 'invitations',
      };
}

Future<void> executeAction(QueueEntry entry) async {
  final table = entry.entityType.tableName;
  final query = client.from(table);

  switch (entry.actionType) {
    case QueueActionType.create:
      await query.insert(entry.payload);
      return;
    case QueueActionType.update:
      await query.update(entry.payload).eq('id', entry.entityId);
      return;
    case QueueActionType.delete:
      await query.update({
        'deleted_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', entry.entityId);
      return;
    case QueueActionType.markPurchased:
      await query.update({
        'status': 'completed',
        'completed_at': DateTime.now().toIso8601String(),
        'completed_by': client.auth.currentUser!.id,
        'updated_by': client.auth.currentUser!.id,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', entry.entityId);
      return;
  }
}
```

كما يجب تمرير `homeId` الحقيقي إلى عمليات `OfflineAwareShoppingRepository` أو جلبه من القائمة/العنصر قبل enqueue.

### 2.2 Repository Schema Mismatches

#### HIGH-FE-01: Role repository يكتب عمود `updated_at` غير موجود في `home_members`

الأدلة:

- `SupabaseRoleRepository.changeMemberRole()` و`transferOwnership()` يرسلان `updated_at`.
- مخطط `home_members` يحتوي `joined_at`, `deleted_at`, `created_at`, ولا يظهر `updated_at`.

الأثر:

- تغيير الدور ونقل الملكية سيفشلان بـ PostgREST column error.

الإصلاح:

- أضف `updated_at` إلى الجدول trigger/update policies، أو احذف الحقل من update payload.
- الأفضل إضافة `updated_at` و`updated_by` لأن الدور حساس.

#### HIGH-FE-02: removeMember يستخدم `delete()` رغم أن النظام يستخدم soft delete

الأثر:

- قد يفشل بسبب عدم وجود DELETE policy.
- حتى لو نجح لن يعمل trigger النشاط المبني على `deleted_at`.

الإصلاح:

```dart
await _client
    .from('home_members')
    .update({
      'status': 'inactive',
      'deleted_at': DateTime.now().toIso8601String(),
      'updated_by': currentUser.id,
    })
    .eq('home_id', homeId)
    .eq('user_id', userId);
```

#### HIGH-FE-03: Tasks تستدعي RPCs غير موجودة ولا تضبط `completed_at`

الأدلة:

- `TaskRemoteDataSource` يستدعي `create_next_recurring_task` و`archive_old_completed_tasks`.
- migration يحتوي `auto_archive_completed_tasks` فقط.
- `completeTask()` يغير `status` إلى `completed` دون `completed_by` أو `completed_at`.

الأثر:

- recurring/archive flows تفشل.
- auto-archive لن يجد `completed_at` للتاسكات المكتملة من التطبيق.

الإصلاح:

```dart
await client
    .from('tasks')
    .update({
      'status': 'completed',
      'completed_by': client.auth.currentUser!.id,
      'completed_at': DateTime.now().toIso8601String(),
    })
    .eq('id', taskId);
```

وتوحيد أسماء RPCs بين التطبيق والمهاجرات.

#### HIGH-FE-04: Shopping list update يستخدم `description` لتحديث عمود `type`

الأدلة:

- `updateShoppingList()` يبني payload فيه `'type': description`.
- جدول shopping_lists يملك `type` لا `description`.

الأثر:

- أي تعديل وصف من الواجهة قد يفسد نوع القائمة.

الإصلاح:

- إن كان مطلوبا وصف، أضف عمود `description`.
- وإلا احذف mapping واستخدم `type` فقط من enum واضح.

#### HIGH-FE-05: أسعار عناصر التسوق تظهر في UI لكنها لا تحفظ في DB

الأدلة:

- `ShoppingItemModel` يحتوي `price/currency`.
- `shopping_items` في DB لا يحتوي `price/currency`.
- repository يتجاهل السعر ويعيد `price: null`.

الأثر:

- إجماليات القائمة ستكون صفرية أو غير موثوقة.

الإصلاح:

- إما إزالة السعر من MVP UI أو إضافة أعمدة `estimated_price`, `currency` مع RLS وmigrations.

#### HIGH-FE-06: Invitations repository لا يتحقق من أن المدعو عضو موجود فعلا

الأدلة:

- `sendInvitation()` يبحث في `home_members` بـ `user_id = currentUser.id` بدلا من user id المرتبط ببريد المدعو، والنتيجة `existingMember` غير مستخدمة.
- token مولد من timestamp/microseconds وليس عشوائيا كفاية.

الأثر:

- يمكن إرسال دعوات لأعضاء موجودين.
- token قابل للتخمين نسبيا.

الإصلاح:

- أضف RPC `create_invitation` يتحقق server-side من الدور، البريد، العضوية الحالية، وينشئ token عبر `gen_random_uuid()` أو `gen_random_bytes()`.

### 2.3 Error Handling

المشكلة العامة:

- Repositories كثيرة لا تلتقط `PostgrestException`, `AuthException`, `StorageException` ولا تحولها إلى رسائل domain-friendly.
- بعض الأماكن تعرض `e.toString()` للمستخدم.
- Notification preferences تخفي الأخطاء وتعيد defaults، ما يجعل فشل الحفظ صامتا.

المطلوب:

- إضافة mapper مركزي:

```dart
String mapSupabaseError(Object error) {
  if (error is AuthException) return mapAuthError(error);
  if (error is PostgrestException) return mapPostgrestError(error);
  return 'حدث خطأ غير متوقع. حاول مرة أخرى.';
}
```

- في repositories: أعد throw كـ domain exception أو `Result<T>`.

## 3. Realtime & Memory Leaks

### HIGH-RT-01: StreamProvider families غير `autoDispose`

الأدلة:

- `shoppingItemsProvider`, `shoppingListsProvider`, `presenceProvider` وغيرهم معرفون كـ `StreamProvider.family` بدون autoDispose.
- Supabase `.stream()` يبقى مرتبطا طالما provider cached.

الأثر:

- عند التنقل بين بيوت/قوائم كثيرة يمكن أن تبقى subscriptions حية.

الإصلاح:

```dart
final shoppingItemsProvider =
    StreamProvider.autoDispose.family<List<ShoppingItem>, String>((ref, listId) {
  final repo = ref.watch(shoppingListRepositoryProvider);
  return repo.watchShoppingItems(listId);
});
```

### HIGH-RT-02: Presence channel في shopping mode قد يتراكم

الأدلة:

- الشاشة تستدعي `_joinPresence`.
- `presenceProvider` يفتح watch مستقل.
- عند dispose يتم `leavePresence` فقط، وليس unsubscribe channel.

الإصلاح:

```dart
final presenceProvider =
    StreamProvider.autoDispose.family<List<UserPresence>, String>((ref, listId) {
  final service = ref.watch(realtimeServiceProvider);
  final channelName = 'presence:$listId';
  ref.onDispose(() => service.unsubscribeChannel(channelName));
  return service.watchPresence(listId);
});
```

### MEDIUM-RT-01: `watchListActivity` يفلتر list activity على العميل

الأثر:

- كل نشاطات البيت تصل للعميل ثم يتم فلترتها، ما يزيد load وbandwidth.

الإصلاح:

- أضف `entity_type/entity_id` للأحداث بشكل ثابت واستعلم/اشترك عليها server-side بفلتر أدق.

## 4. Riverpod State Management Audit

### HIGH-RP-01: Cache invalidation بعد تبديل البيت غير مكتمل

الأدلة:

- `HomesNotifier.switchHome()` يحفظ active home فقط ولا يبطل `activeHomeIdProvider` أو providers المعتمدة.
- بعض الشاشات تفعل invalidate يدويا، لكن هذا يجعل السلوك غير موحد.

الأثر:

- يمكن أن تبقى قوائم/دعوات/نشاطات من البيت السابق حتى إعادة بناء الشاشة.

الإصلاح:

```dart
Future<void> switchHome(String homeId) async {
  await _repo.setActiveHome(homeId);
  ref.invalidate(activeHomeIdProvider);
  ref.invalidate(shoppingListsProvider);
  ref.invalidate(categoriesProvider);
  ref.invalidate(unitsProvider);
  ref.invalidate(invitationsProvider);
}
```

### MEDIUM-RP-01: بعض FutureBuilders داخل UI تتجاوز providers

مثال:

- `HomeScreen._buildRecentActivity()` يستعلم Supabase مباشرة داخل UI.

الأثر:

- إعادة استعلام غير ضرورية عند rebuild.
- صعوبة الاختبار وعدم توحيد handling/loading/error.

الإصلاح:

- نقل الاستعلام إلى repository/provider مخصص.

### MEDIUM-RP-02: Feature flags لا تمنع deep links لكل الميزات

الأدلة:

- GoRouter يحرس AI route فقط.
- Inventory/Expenses/Tasks routes تبقى قابلة للوصول عبر deep link حتى لو flag false.

الإصلاح:

- تطبيق route guard عام لكل feature.

## 5. UI/UX & Edge Cases Audit

### 5.1 Offline Handling

المشاكل:

- offline queue مكسورة كما سبق.
- optimistic offline item لا يظهر بالضرورة في `watchShoppingItems` لأن stream من remote فقط.
- `QueueActionExecutor` قديم ويستخدم أعمدة غير موجودة: `is_purchased`, `purchased_at`, `purchased_by`, `notes`.

المطلوب:

- دمج remote stream مع local pending entries داخل provider.
- توحيد payload schema snake_case مع DB.
- اختبار end-to-end: add/update/mark/delete offline ثم reconnect.

### 5.2 Sign Out Flow

المشاكل:

- local cleanup بعد signOut يمسح `anonymous`.
- `main.dart` يستمع auth signedOut ثم يستدعي `signOut()` مرة أخرى؛ هذا قابل لحالات race.

المطلوب:

- جعل `AuthNotifier.signOut()` idempotent.
- إضافة method `clearForUser(userId)`.
- بعد logout: invalidate كل providers الحساسة، clear queue/local homes، ثم route إلى login.

### 5.3 Empty & Loading States

الوضع العام:

- توجد empty states في ميزات عديدة.
- بعض errors لا تتحول إلى رسائل مفهومة، خصوصا RLS/schema errors.

المطلوب:

- لا تعرض raw exception للمستخدم.
- أضف empty state عملي لكل شاشة: الدعوات، القوائم، العناصر، tasks، expenses، inventory، notifications.
- في shopping mode، اجعل add-item أسرع flow مع input focused وoffline optimistic feedback.

### 5.4 Arabic RTL

الإيجابيات:

- `MaterialApp.router` مضبوط على Arabic RTL.

ملاحظات:

- يجب اختبار كل الشاشات التي تستخدم Row/leading/trailing وأيقونات direction.
- تجنب hard-coded English strings في AI/notifications/errors.

## 6. Module-by-Module Findings

### Auth & Profile

- Sign out local cleanup critical.
- رسائل Auth errors غير موحدة وتحتوي نصا غريبا في sign-up.
- لا يوجد ضمان واضح لمسح كل providers المرتبطة بالمستخدم بعد logout.

### Homes & Members

- RLS للعضوية يحتاج active/deleted في كل الميزات.
- home member role changes تكتب أعمدة غير موجودة.
- remove member يجب أن يكون soft delete.
- يجب حماية owner invariants في DB: لا حذف آخر owner ولا demote نفسه دون transfer.

### Invitations & Roles

- Direct update policies على invitations خطرة.
- `accept_invitation` يحتاج search_path/revoke/grant مضبوط.
- token generation في Flutter ضعيف؛ يجب نقله للسيرفر.
- إرسال دعوة لعضو موجود غير ممنوع server-side.

### Categories & Units

- categories تبدو أقرب للتكامل مع home/default.
- units فيها mismatch: UI/repo create/update/delete مقابل RLS read-only وغياب ownership.

### Shopping Lists & Items

- updated_by لا يرسل في update/delete/mark purchased.
- `description -> type` خطأ.
- price/currency غير مخزنين.
- offline repository يرجع placeholders عند انقطاع الإنترنت.
- RLS يجب أن يمنع تغيير created_by/home_id/list_id عبر update غير مصرح.

### Realtime Sync

- providers يجب أن تكون autoDispose.
- presence channel cleanup غير مكتمل.
- activity stream يفلتر كثيرا على العميل.

### Activity Logs

- triggers موجودة، لكن attribution قد يكون خاطئا بسبب عدم إرسال `updated_by`.
- direct hard delete أو عمليات لا تمر عبر soft delete قد لا تسجل النشاط المتوقع.

### Notifications

- Edge Function `send-notification` حرجة: auth/membership/schema mismatch.
- `update-notification-preferences` لا يطابق جدول `notification_preferences`.
- Flutter repository يخفي بعض فشل preferences.
- `_getPlatform()` يعيد `flutter` لمنصات غير مدعومة بينما DB check يسمح `android/ios/web` فقط.

### Shopping Mode

- presence cleanup.
- session policies يجب أن تتحقق من active membership وأن `shopping_list_id` يتبع نفس home.
- offline mode يحتاج دمج pending actions في UI.

### Offline Queue

- homeId خاطئ.
- table name خاطئ.
- payload قديم في executor.
- clear queue بعد logout يمسح user wrong key.

### Inventory

- duplicate active items غير ممنوع DB بسبب unique nullable index.
- transaction/item same-home غير مفروض.
- RLS لا يتحقق دائما من active/deleted membership.

### Expenses

- RPC balance leak critical.
- paid_by/splits/settlements لا تضمن active membership.
- بعض casts قد تفشل عند numeric/null.
- RLS يحتاج active/deleted checks.

### Tasks

- RPCs غير موجودة.
- completeTask لا يضبط completed_at/by.
- recurring task flow غير موثوق حتى تتطابق DB functions.
- RLS يحتاج owner/admin/member semantics أدق حسب الدور.

### AI Phase

- Edge Function مكشوفة بلا JWT check.
- الخطة تقول Gemini، الكود يستخدم DeepSeek؛ يجب توثيق القرار أو تعديل الخطة.
- shopping suggestions في `AiAssistantScreen` تعرض add icons لكن لا تضيف shopping suggestions فعليا؛ `_buildFAB` يدعم recipe ingredients فقط.
- يجب إضافة rate limit وquota وaudit log لطلبات AI.

### Beta Feedback

- `submit-feedback` يكتب إلى `beta_feedback`، لكن لا يوجد جدول ظاهر في migrations.
- الدالة ستفشل حتى تضاف migration وسياسات RLS/service handling.

## 7. خطة علاج مقترحة

### خلال 24 ساعة

1. إغلاق Edge Functions الحرجة بإضافة JWT + membership checks أو تعطيلها مؤقتا.
2. إصلاح/revoke RPCs المالية.
3. إغلاق direct invitation accept عبر RLS، وجعل acceptance عبر RPC آمن فقط.
4. إصلاح sign-out cleanup وoffline queue table/homeId.
5. تعطيل AI feature flag في الإنتاج حتى تكتمل الحماية والquota.

### قبل Beta

1. توحيد membership predicates في كل RLS.
2. إضافة `updated_by` في عمليات shopping وتثبيته في policies.
3. إصلاح schema mismatches: tasks RPCs، role repository، units، notifications functions، feedback table.
4. تحويل realtime family providers إلى autoDispose وتنظيف channels.
5. إضافة الفهارس المقترحة.
6. إضافة tests حقيقية للـ RLS وoffline sync.

### بعد Beta

1. تحسين cross-home constraints.
2. إضافة monitoring لمعدلات Edge Functions وAI.
3. إضافة DB advisor/performance regression checks في CI.
4. توثيق soft-delete lifecycle وجداول cleanup.

## 8. اختبارات مطلوبة

### RLS/Supabase

- مستخدم غير عضو لا يستطيع قراءة/تعديل أي home-scoped table.
- عضو inactive/deleted لا يستطيع القراءة/الكتابة.
- accepted invitation عبر direct table update تفشل.
- accept_invitation يضيف home_members مرة واحدة idempotently.
- calculate_home_balances تفشل لغير الأعضاء وتنجح للعضو.
- owner/admin لا يستطيع حذف آخر owner.

### Flutter Repositories

- signOut يمسح queue/local homes للمستخدم السابق.
- offline add/update/delete/markPurchased تتحول إلى payload صحيح وجداول صحيحة.
- shopping update يرسل updated_by.
- tasks complete يرسل completed_by/completed_at.
- role change لا يرسل أعمدة غير موجودة.

### Realtime/Riverpod

- مغادرة شاشة shopping mode تلغي presence subscription.
- تبديل البيت يبطل providers الحساسة.
- فتح وإغلاق عدة قوائم لا يترك channels مفتوحة.

### Edge Functions

- no token -> 401.
- invalid token -> 401.
- valid token but not home member -> 403.
- valid member -> success.
- notifications تستخدم جدول `users` وschema الصحيح لـ preferences.

## 9. قائمة تحقق قصيرة للإصدار القادم

- [ ] لا توجد Edge Function تستخدم service role قبل تحقق JWT/authorization.
- [ ] لا توجد `SECURITY DEFINER` public RPC دون `SET search_path` وتحقق عضوية.
- [ ] لا توجد policy home-scoped دون active/deleted membership check.
- [ ] offline queue تعمل end-to-end.
- [ ] sign out يمسح بيانات المستخدم السابق.
- [ ] كل update مهم يرسل `updated_by`.
- [ ] كل StreamProvider.family realtime إما autoDispose أو له lifecycle واضح.
- [ ] analyzer/tests/DB RLS tests تعمل في CI.

