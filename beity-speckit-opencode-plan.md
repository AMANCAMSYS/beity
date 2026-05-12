# خطة Spec Kit لمشروع بيتي داخل opencode

> الهدف من هذا الملف: تشغيل مشروع **بيتي** بمنهجية Spec-Driven Development داخل **opencode** عبر Specs صغيرة ومرتبة، بحيث لا يطلب الوكيل بناء التطبيق كاملًا دفعة واحدة، بل ينفّذ كل نطاق بعد توثيقه وتحليله وتقسيمه إلى مهام قابلة للاختبار.

---

## 0. ملخص المشروع

**بيتي** تطبيق لإدارة المنزل والمشتريات والمخزون والمصروفات والمهام بين شخص واحد أو عدة أعضاء داخل منزل/سكن/مكتب مشترك.

### المشكلة الأساسية

المستخدمون ينسون مشترياتهم، يشترون منتجات مكررة، لا يعرفون الموجود في المنزل، ويصعب عليهم التنسيق مع أفراد المنزل أو السكن في القوائم والمصاريف والمهام.

### الحل الأولي MVP

إطلاق نسخة قوية تبدأ بـ:

- تسجيل الدخول.
- إنشاء منزل/Workspace.
- دعوة أعضاء.
- إنشاء قوائم مشتريات مشتركة.
- إضافة وتعديل وشطب عناصر.
- Realtime بين الأعضاء.
- إشعارات أساسية.
- سجل نشاطات.
- وضع التسوق.

### التقنية المقترحة

- Frontend: Flutter
- State Management: Riverpod
- Routing: GoRouter
- Local Storage: Isar لاحقًا للـ Offline Mode
- Backend: Supabase
- Database: PostgreSQL
- Auth: Supabase Auth
- Realtime: Supabase Realtime
- Notifications: Firebase FCM
- Storage: Supabase Storage
- Server Logic: Supabase Edge Functions
- Analytics: PostHog لاحقًا

---

## 1. طريقة العمل داخل opencode مع Spec Kit

استخدم هذا التسلسل مع كل Spec:

```text
/speckit.specify
/speckit.clarify
/speckit.plan
/speckit.tasks
/speckit.analyze
/speckit.implement
```

> ملاحظة: إن كانت أوامر Spec Kit غير متاحة مباشرة داخل opencode، أنشئ أوامر مخصصة في `.opencode/commands/` أو استخدم نصوص الـ Prompts الموجودة في هذا الملف يدويًا داخل جلسة opencode.

---

## 2. إعداد opencode قبل التنفيذ

### 2.1 إنشاء AGENTS.md

شغّل داخل جذر المشروع:

```text
/init
```

ثم تأكد أن `AGENTS.md` يحتوي على قواعد المشروع التالية:

```markdown
# Beity Project Agent Rules

## Product Direction
Beity is a home management app focused first on shared shopping lists, then inventory, expenses, tasks, and AI suggestions.

## MVP Priority
Do not implement inventory, expenses, tasks, stores, OCR, payments, or AI before the core shared shopping-list MVP is stable.

## Tech Stack
- Flutter
- Riverpod
- GoRouter
- Supabase Auth
- Supabase PostgreSQL
- Supabase Realtime
- Firebase FCM
- Isar for offline support later

## Development Rules
- Use feature-first clean architecture.
- Keep features isolated under `lib/features/<feature_name>`.
- Every Supabase table must have RLS policies.
- Every write action must include `created_by` or `updated_by` where relevant.
- Never bypass home membership checks.
- Prefer small commits per Spec.
- Add tests for repositories, use cases, and critical UI flows.

## UX Rules
- The app must be fast for shopping mode.
- Add-item flow must be one of the fastest flows in the app.
- Empty states must explain what to do next.
- Arabic RTL must be supported from the beginning.
```

### 2.2 إنشاء هيكلة الأوامر الاختيارية في opencode

```bash
mkdir -p .opencode/commands
```

يمكن لاحقًا إنشاء أوامر مثل:

```text
.opencode/commands/beity-spec.md
.opencode/commands/beity-review.md
.opencode/commands/beity-db-check.md
```

---

## 3. تقسيم المشروع إلى Specs مرتبة

لا تنفّذ أكثر من Spec واحد في نفس الجلسة إلا إذا كان صغيرًا جدًا. الأفضل أن كل Spec ينتج فرع Git مستقلًا.

```text
spec-00-project-foundation
spec-01-auth-and-user-profile
spec-02-homes-and-members
spec-03-invitations-and-roles
spec-04-categories-and-units
spec-05-shopping-lists
spec-06-shopping-items
spec-07-realtime-sync
spec-08-activity-logs
spec-09-notifications
spec-10-shopping-mode
spec-11-offline-queue
spec-12-mvp-hardening-and-beta
spec-13-inventory-phase
spec-14-expenses-phase
spec-15-tasks-phase
spec-16-ai-phase
```

---

# SPEC 00 — Project Foundation

## الهدف

تأسيس مشروع Flutter نظيف، قابل للتوسع، ومجهز للتعامل مع Supabase وRiverpod وGoRouter وهيكلة Features.

## نطاق التنفيذ

- إنشاء مشروع Flutter.
- إعداد مجلدات المشروع.
- إعداد theme.
- إعداد routing.
- إعداد dependency injection إن لزم.
- إعداد Supabase client.
- إعداد بيئات dev/staging/prod.
- إعداد linting والتحليل.

## خارج النطاق

- لا تنفذ Auth UI.
- لا تنفذ قاعدة البيانات كاملة.
- لا تنفذ Realtime.

## Prompt لـ `/speckit.specify`

```text
/speckit.specify Build the foundation for Beity, a Flutter home-management app. The foundation must create a scalable feature-first architecture, app routing, theming, environment configuration, Supabase client initialization, and basic shared UI structure. The goal is to prepare the project for future specs without implementing business features yet. Support Arabic RTL from the beginning and keep the app structure clean, testable, and ready for Supabase-backed features.
```

## Prompt لـ `/speckit.plan`

```text
/speckit.plan Use Flutter with Riverpod for state management, GoRouter for navigation, Supabase Flutter for backend integration, feature-first clean architecture, and separate environment configuration for dev/staging/prod. Create folders for app, core, features, and shared. Add linting and basic smoke tests. Do not implement authentication screens or database business logic in this spec.
```

## معايير القبول

- التطبيق يعمل بشاشة بداية بسيطة.
- `lib/app`, `lib/core`, `lib/features`, `lib/shared` موجودة.
- GoRouter يعمل.
- Theme يدعم RTL.
- Supabase client قابل للتهيئة من env.
- `flutter analyze` ينجح.
- اختبار smoke واحد على الأقل ينجح.

---

# SPEC 01 — Auth and User Profile

## الهدف

تمكين المستخدم من التسجيل والدخول والخروج وإدارة بياناته الأساسية.

## نطاق التنفيذ

- تسجيل مستخدم بالبريد وكلمة المرور.
- تسجيل دخول.
- تسجيل خروج.
- إنشاء/قراءة سجل المستخدم في جدول `users`.
- شاشة ملف شخصي بسيطة.
- معالجة أخطاء Auth.

## الجداول

```sql
users (
  id uuid primary key,
  full_name text,
  email text unique,
  phone text,
  avatar_url text,
  created_at timestamp default now(),
  updated_at timestamp
)
```

## Prompt لـ `/speckit.specify`

```text
/speckit.specify Implement authentication and user profile for Beity. Users must be able to register, log in, log out, and view/update their basic profile. The app must create or sync a user profile record after successful authentication. Error messages must be friendly and support Arabic UI. This spec should not implement homes, invitations, shopping lists, or notifications.
```

## Prompt لـ `/speckit.plan`

```text
/speckit.plan Use Supabase Auth for email/password authentication. Use a users table linked to auth.users by UUID. Implement AuthRepository, AuthService, Riverpod providers, login/register screens, profile screen, and basic route guards with GoRouter. Add repository tests and widget tests for login form validation.
```

## معايير القبول

- المستخدم يستطيع التسجيل.
- المستخدم يستطيع الدخول والخروج.
- إنشاء سجل `users` بعد التسجيل.
- لا تظهر شاشات محمية قبل تسجيل الدخول.
- رسائل الخطأ مفهومة.

---

# SPEC 02 — Homes and Members

## الهدف

إنشاء مفهوم المنزل/Workspace وربط المستخدمين به كأعضاء.

## نطاق التنفيذ

- إنشاء منزل.
- عرض منازل المستخدم.
- اختيار المنزل الحالي.
- إضافة المالك كـ owner تلقائيًا.
- عرض أعضاء المنزل.

## الجداول

```sql
homes (
  id uuid primary key,
  name text not null,
  type text not null,
  owner_id uuid references users(id),
  default_currency text default 'TRY',
  created_at timestamp default now(),
  updated_at timestamp,
  deleted_at timestamp
)

home_members (
  id uuid primary key,
  home_id uuid references homes(id),
  user_id uuid references users(id),
  role text not null,
  status text default 'active',
  joined_at timestamp default now(),
  deleted_at timestamp
)
```

## Prompt لـ `/speckit.specify`

```text
/speckit.specify Implement homes and membership for Beity. A user can create a home workspace, automatically become its owner, see all homes they belong to, switch the active home, and view active members. Homes represent families, couples, shared houses, student housing, single users, or offices. Only authenticated users can access homes.
```

## Prompt لـ `/speckit.plan`

```text
/speckit.plan Use Supabase PostgreSQL tables homes and home_members with RLS. Implement HomeRepository, HomeService/use cases, Riverpod providers, create-home screen, home switcher, and members list. Enforce that users can read a home only if they are active members. Use soft delete fields but do not implement full deletion UI yet.
```

## معايير القبول

- المستخدم ينشئ منزلًا.
- المستخدم يصبح owner تلقائيًا.
- المستخدم يرى فقط المنازل التي ينتمي إليها.
- يمكن تبديل المنزل الحالي.
- RLS يمنع الوصول لمنازل غير عضو فيها.

---

# SPEC 03 — Invitations and Roles

## الهدف

دعوة أعضاء للمنزل وإدارة الأدوار الأساسية.

## نطاق التنفيذ

- دعوة عضو عبر البريد.
- إنشاء token للدعوة.
- قبول الدعوة.
- أدوار: owner/admin/member/viewer.
- صلاحيات أولية.

## الجداول

```sql
invitations (
  id uuid primary key,
  home_id uuid references homes(id),
  email text,
  phone text,
  role text default 'member',
  token text unique not null,
  status text default 'pending',
  invited_by uuid references users(id),
  expires_at timestamp,
  accepted_at timestamp,
  created_at timestamp default now()
)
```

## Prompt لـ `/speckit.specify`

```text
/speckit.specify Implement home invitations and basic roles for Beity. Owners and admins can invite people by email to join a home with a selected role. Invited users can accept a valid pending invitation and become active home members. The system must prevent unauthorized users from inviting members or changing protected ownership rules.
```

## Prompt لـ `/speckit.plan`

```text
/speckit.plan Use Supabase tables invitations and home_members. Add RLS and database constraints for invitation status and member roles. Implement invitation creation, invitation acceptance by token, role checks, and simple UI for invite member and pending invites. Do not send real email yet; display/copy invitation link or token for MVP.
```

## معايير القبول

- owner/admin يستطيعان إنشاء دعوة.
- member/viewer لا يستطيعان دعوة أعضاء.
- الدعوة pending تتحول إلى accepted عند القبول.
- يتم إنشاء home_member جديد.
- لا يمكن قبول دعوة منتهية أو ملغاة.

---

# SPEC 04 — Categories and Units

## الهدف

إضافة تصنيفات ووحدات قياس أساسية تدعم عناصر المشتريات والمخزون لاحقًا.

## نطاق التنفيذ

- تصنيفات افتراضية للمشتريات.
- تصنيفات مخصصة لكل منزل.
- وحدات قياس افتراضية.
- ربط التصنيف بنوعه.

## الجداول

```sql
categories (
  id uuid primary key,
  home_id uuid references homes(id),
  name text not null,
  type text not null,
  icon text,
  color text,
  sort_order int default 0,
  is_default boolean default false,
  created_by uuid references users(id),
  created_at timestamp default now(),
  updated_at timestamp,
  deleted_at timestamp
)

units (
  id uuid primary key,
  name text not null,
  symbol text,
  type text,
  is_default boolean default false,
  created_at timestamp default now()
)
```

## Prompt لـ `/speckit.specify`

```text
/speckit.specify Implement categories and units for Beity. The app needs default shopping categories and measurement units, plus home-specific custom categories. Shopping items must later be able to use these categories and units. Users should see default categories plus their current home's custom categories.
```

## Prompt لـ `/speckit.plan`

```text
/speckit.plan Use categories and units tables in Supabase. Allow home_id to be null for system defaults. Add seed data for common shopping categories and units. Implement repositories and providers to fetch categories by type and units. Add minimal management UI for custom categories only if it does not slow the MVP.
```

## معايير القبول

- التصنيفات الافتراضية تظهر لكل منزل.
- التصنيفات الخاصة تظهر فقط لأعضاء المنزل.
- الوحدات الافتراضية متاحة.
- RLS لا يسمح بتعديل تصنيفات منزل آخر.

---

# SPEC 05 — Shopping Lists

## الهدف

إنشاء وإدارة قوائم المشتريات داخل المنزل الحالي.

## نطاق التنفيذ

- إنشاء قائمة.
- عرض القوائم.
- تعديل عنوان القائمة ونوعها.
- أرشفة/حذف ناعم.
- حالات القائمة: active/completed/archived/cancelled.

## الجداول

```sql
shopping_lists (
  id uuid primary key,
  home_id uuid references homes(id),
  title text not null,
  type text,
  status text default 'active',
  created_by uuid references users(id),
  updated_by uuid references users(id),
  created_at timestamp default now(),
  updated_at timestamp,
  deleted_at timestamp
)
```

## Prompt لـ `/speckit.specify`

```text
/speckit.specify Implement shopping lists for Beity. Active members of a home can create and manage shopping lists inside the current home. Lists have a title, type, status, creator, updater, timestamps, and soft deletion. The UI must make the active list easy to access from the home dashboard.
```

## Prompt لـ `/speckit.plan`

```text
/speckit.plan Use Supabase shopping_lists with RLS based on home membership. Implement ShoppingListRepository, list use cases, Riverpod providers, list overview screen, create/edit list screen, and soft delete/archive actions. Add tests for permissions and list lifecycle.
```

## معايير القبول

- المستخدم العضو ينشئ قائمة داخل المنزل الحالي.
- تظهر القوائم الخاصة بالمنزل الحالي فقط.
- يمكن تعديل/أرشفة القائمة.
- viewer لا يعدّل ولا ينشئ.
- soft delete لا يحذف السجل فعليًا.

---

# SPEC 06 — Shopping Items

## الهدف

بناء قلب الـ MVP: عناصر قائمة المشتريات.

## نطاق التنفيذ

- إضافة عنصر.
- تعديل الاسم والكمية والوحدة والتصنيف والأولوية والملاحظة.
- شطب عنصر.
- إلغاء الشطب.
- حذف ناعم.
- تعيين عنصر لشخص.

## الجداول

```sql
products (
  id uuid primary key,
  home_id uuid references homes(id),
  name text not null,
  default_category_id uuid references categories(id),
  default_unit_id uuid references units(id),
  barcode text,
  image_url text,
  created_by uuid references users(id),
  created_at timestamp default now(),
  updated_at timestamp,
  deleted_at timestamp
)

shopping_items (
  id uuid primary key,
  list_id uuid references shopping_lists(id),
  product_id uuid references products(id),
  name text not null,
  quantity numeric(10,2) default 1,
  unit_id uuid references units(id),
  category_id uuid references categories(id),
  priority text default 'medium',
  note text,
  status text default 'pending',
  assigned_to uuid references users(id),
  created_by uuid references users(id),
  updated_by uuid references users(id),
  completed_by uuid references users(id),
  completed_at timestamp,
  created_at timestamp default now(),
  updated_at timestamp,
  deleted_at timestamp
)
```

## Prompt لـ `/speckit.specify`

```text
/speckit.specify Implement shopping items for Beity. Members can add, edit, complete, uncomplete, assign, and soft-delete items in a shopping list. Each item can have name, quantity, unit, category, priority, note, status, assigned member, creator, updater, completed_by, and completed_at. The add-item flow must be extremely fast for real shopping use.
```

## Prompt لـ `/speckit.plan`

```text
/speckit.plan Use shopping_items linked to shopping_lists, with RLS that checks membership through the parent list's home_id. Add optional products table for normalized recurring product names, but keep item creation possible without selecting an existing product. Implement item repository, providers, UI components, validation, and tests. Prioritize fast add/edit/check UX.
```

## معايير القبول

- إضافة عنصر تتم بسرعة من شاشة القائمة.
- يمكن شطب عنصر وتسجيل `completed_by` و`completed_at`.
- يمكن إلغاء الشطب.
- العناصر تظهر حسب القائمة فقط.
- RLS يحمي العناصر عبر علاقة القائمة بالمنزل.

---

# SPEC 07 — Realtime Sync

## الهدف

مزامنة القوائم والعناصر بين أعضاء المنزل لحظيًا.

## نطاق التنفيذ

- Realtime على shopping_lists.
- Realtime على shopping_items.
- تحديث الواجهة عند الإضافة/التعديل/الشطب.
- التعامل مع تضارب بسيط.

## Prompt لـ `/speckit.specify`

```text
/speckit.specify Implement realtime synchronization for Beity shopping lists and shopping items. When one member adds, updates, completes, or deletes a list/item, other active members viewing the same home should see the change without manual refresh. The UI must remain stable and avoid duplicate items.
```

## Prompt لـ `/speckit.plan`

```text
/speckit.plan Use Supabase Realtime channels for shopping_lists and shopping_items scoped to the current home/list. Integrate realtime events with Riverpod state. Add lifecycle handling for subscribe/unsubscribe, reconnect, optimistic updates where safe, and conflict handling based on updated_at. Add tests or simulation utilities for realtime event handling.
```

## معايير القبول

- عضو آخر يرى العنصر الجديد فورًا.
- شطب العنصر يظهر للأعضاء الآخرين.
- لا تتكرر العناصر بعد optimistic update.
- يتم إغلاق الاشتراكات عند تغيير المنزل أو الخروج من الشاشة.

---

# SPEC 08 — Activity Logs

## الهدف

إنشاء سجل نشاطات واضح: من أضاف؟ من عدّل؟ من شطب؟

## نطاق التنفيذ

- تسجيل أحداث أساسية.
- عرض آخر النشاطات.
- ربط النشاط بالمنزل والكيان.

## الجداول

```sql
activity_logs (
  id uuid primary key,
  home_id uuid references homes(id),
  user_id uuid references users(id),
  action text not null,
  entity_type text not null,
  entity_id uuid,
  entity_name text,
  metadata jsonb,
  created_at timestamp default now()
)
```

## Prompt لـ `/speckit.specify`

```text
/speckit.specify Implement activity logs for Beity. The system must record important home actions such as creating lists, adding items, updating items, completing items, inviting members, and joining homes. Members should be able to view recent activity for the current home.
```

## Prompt لـ `/speckit.plan`

```text
/speckit.plan Use activity_logs table with RLS by home membership. Add a reusable ActivityLogService that write operations can call. Store action, entity_type, entity_id, entity_name, metadata, and user_id. Implement recent activity UI and tests for log creation in key shopping flows.
```

## معايير القبول

- إضافة عنصر تسجل نشاطًا.
- شطب عنصر يسجل نشاطًا.
- إنشاء قائمة يسجل نشاطًا.
- الأعضاء يرون سجل منزلهم فقط.

---

# SPEC 09 — Notifications

## الهدف

إرسال وحفظ إشعارات أساسية للأعضاء.

## نطاق التنفيذ

- حفظ device token.
- تفضيلات إشعارات أساسية.
- إشعارات داخل التطبيق.
- FCM للأحداث المهمة لاحقًا/حسب الجاهزية.

## الجداول

```sql
notifications (
  id uuid primary key,
  user_id uuid references users(id),
  home_id uuid references homes(id),
  title text not null,
  body text,
  type text not null,
  entity_type text,
  entity_id uuid,
  is_read boolean default false,
  created_at timestamp default now()
)

device_tokens (
  id uuid primary key,
  user_id uuid references users(id),
  token text not null,
  platform text,
  device_name text,
  is_active boolean default true,
  created_at timestamp default now(),
  updated_at timestamp
)

notification_preferences (
  id uuid primary key,
  user_id uuid references users(id),
  home_id uuid references homes(id),
  item_added boolean default true,
  item_completed boolean default true,
  low_stock boolean default true,
  expiry_alert boolean default true,
  expense_added boolean default true,
  task_due boolean default true,
  created_at timestamp default now(),
  updated_at timestamp
)
```

## Prompt لـ `/speckit.specify`

```text
/speckit.specify Implement basic notifications for Beity. Users should receive in-app notifications for important home events such as member invitations, item added, item completed, and list completed. The app should store notification records, allow marking them as read, and prepare device token storage for push notifications.
```

## Prompt لـ `/speckit.plan`

```text
/speckit.plan Use notifications, device_tokens, and notification_preferences tables. Implement in-app notifications first. Add Firebase FCM token registration behind a service abstraction. Use Supabase Edge Functions for push sending only if credentials and setup are available; otherwise keep push integration prepared but not required for MVP completion.
```

## معايير القبول

- يتم إنشاء إشعار داخلي عند الأحداث المختارة.
- يمكن تعليم الإشعار كمقروء.
- المستخدم يرى إشعاراته فقط.
- token الجهاز يُحفظ عند توفر FCM.

---

# SPEC 10 — Shopping Mode

## الهدف

واجهة تسوق سريعة للاستخدام داخل المتجر.

## نطاق التنفيذ

- عرض عناصر القائمة بوضوح.
- تجميع حسب التصنيف.
- شطب سريع.
- بحث/فلترة.
- إبقاء العناصر المكتملة في أسفل القائمة أو إخفاؤها.

## Prompt لـ `/speckit.specify`

```text
/speckit.specify Implement Shopping Mode for Beity. Shopping Mode is a fast, distraction-free interface used inside stores. It must show pending items clearly, group them by category, support quick complete/uncomplete, search, and make completed items less prominent. It must work well on mobile and be optimized for one-handed use.
```

## Prompt لـ `/speckit.plan`

```text
/speckit.plan Build Shopping Mode as a dedicated route using existing shopping list and item providers. Add category grouping, sticky or clear sections if practical, quick check controls, search/filter, and responsive mobile-first UI. Reuse existing realtime and item update logic. Add widget tests for grouping and completion behavior.
```

## معايير القبول

- الدخول لوضع التسوق من القائمة النشطة.
- الشطب سريع وواضح.
- العناصر مرتبة حسب التصنيف.
- البحث يعمل.
- الواجهة مناسبة للاستخدام المستعجل.

---

# SPEC 11 — Offline Queue

## الهدف

تمكين استخدام القوائم داخل المتجر عند ضعف الإنترنت.

## نطاق التنفيذ

- قراءة آخر القوائم محليًا.
- حفظ عمليات الإضافة/الشطب في queue.
- مزامنة عند عودة الاتصال.
- منع فقدان العمليات.

## Prompt لـ `/speckit.specify`

```text
/speckit.specify Implement offline support for Beity shopping lists and shopping items. Users should be able to view the latest cached shopping list, add items, and complete/uncomplete items while offline. Changes must be queued locally and synchronized when connectivity returns, without losing user actions.
```

## Prompt لـ `/speckit.plan`

```text
/speckit.plan Use Isar or another local database abstraction for cached shopping lists/items and a sync_queue table/collection for pending mutations. Add connectivity monitoring, sync retry logic, conflict rules based on updated_at, and UI indicators for pending sync. Keep scope limited to shopping lists/items, not inventory or expenses.
```

## معايير القبول

- يمكن فتح آخر قائمة بدون اتصال.
- يمكن شطب عنصر بدون اتصال.
- تظهر حالة pending sync.
- تتم المزامنة عند عودة الاتصال.
- لا تتكرر العمليات بعد المزامنة.

---

# SPEC 12 — MVP Hardening and Beta

## الهدف

تجهيز النسخة التجريبية لاختبار 10–30 مستخدمًا.

## نطاق التنفيذ

- تحسين الأخطاء.
- مراقبة crash reporting.
- تحسين الأداء.
- Empty states.
- Onboarding بسيط.
- Seed data مناسب.
- سياسة خصوصية أولية.

## Prompt لـ `/speckit.specify`

```text
/speckit.specify Harden the Beity MVP for beta testing. The app should be stable enough for 10 to 30 real users to test shared shopping lists. Improve error handling, loading states, empty states, onboarding, performance, analytics hooks, and crash reporting. Do not add new major product modules.
```

## Prompt لـ `/speckit.plan`

```text
/speckit.plan Add Firebase Crashlytics, basic PostHog analytics events if available, consistent loading/error/empty states, onboarding screens, performance review for list rendering, and a beta checklist. Add regression tests for auth, home creation, list creation, item creation, completion, and realtime behavior.
```

## معايير القبول

- لا توجد أخطاء تحليل.
- أهم flows مغطاة باختبارات.
- رسائل الأخطاء واضحة.
- التطبيق قابل للتجربة من مستخدمين حقيقيين.

---

# SPEC 13 — Inventory Phase

## الهدف

إضافة المخزون بعد نجاح MVP.

## نطاق التنفيذ

- عناصر المخزون.
- أماكن التخزين.
- حركات المخزون.
- تنبيه نقص.
- تنبيه انتهاء صلاحية.
- تحويل الناقص إلى قائمة شراء.

## الجداول

```sql
storage_locations
inventory_items
inventory_movements
```

## Prompt لـ `/speckit.specify`

```text
/speckit.specify Add home inventory management to Beity after the shopping-list MVP. Members can track what exists at home, quantity, unit, category, storage location, expiry date, minimum quantity, and inventory movements. The system should alert for low stock and expiry and allow adding low-stock items to shopping lists.
```

## Prompt لـ `/speckit.plan`

```text
/speckit.plan Use inventory_items, storage_locations, and inventory_movements tables with RLS by home membership. Implement inventory repositories, screens, low-stock detection, expiry filtering, and movement history. Integrate with shopping items only through explicit user action, not automatic hidden changes.
```

## معايير القبول

- يمكن إضافة عنصر مخزون.
- يمكن تعديل الكمية.
- تسجل الحركة في inventory_movements.
- تظهر عناصر منخفضة المخزون.
- يمكن إضافة عنصر ناقص إلى قائمة شراء.

---

# SPEC 14 — Expenses Phase

## الهدف

إدارة المصاريف المشتركة وتقسيمها.

## نطاق التنفيذ

- إضافة مصروف.
- تحديد من دفع.
- تقسيم بالتساوي.
- تقسيم مخصص/نسبة لاحقًا.
- أرصدة بين الأعضاء.
- تسوية دين.

## الجداول

```sql
expenses
expense_shares
settlements
```

## Prompt لـ `/speckit.specify`

```text
/speckit.specify Add shared expenses to Beity for shared houses, students, families, and offices. Members can add an expense, select who paid, choose a category, split the amount among members, see unpaid shares, and record settlements. The system must make balances understandable and auditable.
```

## Prompt لـ `/speckit.plan`

```text
/speckit.plan Use expenses, expense_shares, and settlements tables. Start with equal split and manual settlement, then support custom/percentage split if feasible. Add ExpenseService for balance calculation. Ensure all expenses are scoped by home_id and protected by RLS. Add tests for split calculations and settlements.
```

## معايير القبول

- يمكن إضافة مصروف.
- يتم إنشاء shares للأعضاء.
- تظهر أرصدة من يدين لمن.
- يمكن تسجيل تسوية.
- الحسابات مختبرة.

---

# SPEC 15 — Tasks Phase

## الهدف

إدارة مهام المنزل المشتركة.

## نطاق التنفيذ

- إنشاء مهمة.
- تعيين عضو.
- موعد نهائي.
- أولوية.
- تكرار بسيط.
- تعليقات.
- إكمال المهمة.

## الجداول

```sql
tasks
task_comments
```

## Prompt لـ `/speckit.specify`

```text
/speckit.specify Add household tasks to Beity. Members can create tasks, assign them to members, set priority and due date, add comments, complete tasks, and optionally define simple recurrence rules. Tasks should support reminders later through the existing notification system.
```

## Prompt لـ `/speckit.plan`

```text
/speckit.plan Use tasks and task_comments tables with RLS by home membership. Implement task repository, task list screen, task detail screen, comments, completion, and basic recurrence field storage. Integrate due reminders with notifications only if notification infrastructure is already stable.
```

## معايير القبول

- يمكن إنشاء مهمة.
- يمكن تعيينها لشخص.
- يمكن إكمالها.
- يمكن إضافة تعليق.
- تظهر مهام المنزل الحالي فقط.

---

# SPEC 16 — AI Phase

## الهدف

إضافة ذكاء اصطناعي بعد وجود بيانات استخدام كافية.

## نطاق التنفيذ

- اقتراح منتجات متكررة.
- توقع نفاد المنتجات.
- تحليل المصروفات.
- إنشاء قوائم موسمية.
- قراءة الفواتير OCR لاحقًا.

## Prompt لـ `/speckit.specify`

```text
/speckit.specify Add AI-assisted features to Beity after the core modules are stable. AI should help users by suggesting recurring shopping items, predicting low stock, analyzing expenses, generating smart lists such as Ramadan/travel lists, and eventually extracting receipt items. AI must be optional, transparent, and privacy-aware.
```

## Prompt لـ `/speckit.plan`

```text
/speckit.plan Create an AIService abstraction. Start with deterministic suggestions from user history before calling external AI APIs. Add OpenAI API only behind Edge Functions, never directly from the mobile app. Do not send sensitive user data unless explicitly needed. Add user consent and clear explanation for AI suggestions.
```

## معايير القبول

- الاقتراحات لا تكسر تجربة المستخدم.
- AI اختياري.
- لا يوجد مفتاح API داخل التطبيق.
- يمكن للمستخدم قبول/رفض الاقتراح.
- يتم تسجيل مصدر الاقتراح بوضوح.

---

## 4. خطة الفروع Git المقترحة

```bash
git checkout -b spec-00-project-foundation
git checkout -b spec-01-auth-and-user-profile
git checkout -b spec-02-homes-and-members
git checkout -b spec-03-invitations-and-roles
git checkout -b spec-04-categories-and-units
git checkout -b spec-05-shopping-lists
git checkout -b spec-06-shopping-items
git checkout -b spec-07-realtime-sync
git checkout -b spec-08-activity-logs
git checkout -b spec-09-notifications
git checkout -b spec-10-shopping-mode
git checkout -b spec-11-offline-queue
git checkout -b spec-12-mvp-hardening-and-beta
```

---

## 5. Definition of Done لكل Spec

كل Spec لا يعتبر منتهيًا إلا إذا تحقق الآتي:

- تمت كتابة spec واضحة.
- تمت إزالة الغموض عبر clarify أو ملاحظات يدوية.
- تمت كتابة plan تقنية.
- تمت كتابة tasks قابلة للتنفيذ.
- تمت مراجعة analyze ولا توجد مخالفات خطيرة.
- تم التنفيذ.
- `flutter analyze` ناجح.
- الاختبارات الأساسية ناجحة.
- RLS موجود لأي جدول جديد.
- لا توجد بيانات بين منازل مختلفة تتسرب في الواجهة أو API.
- تم تحديث `AGENTS.md` أو docs إذا تغيرت القواعد.

---

## 6. قواعد قاعدة البيانات والأمان

### قاعدة RLS الأساسية

```text
المستخدم يستطيع قراءة أو تعديل البيانات فقط إذا كان عضوًا نشطًا في نفس home_id.
```

### للجداول التي لا تحتوي home_id مباشرة

مثال `shopping_items`:

```text
shopping_items -> shopping_lists -> homes -> home_members
```

### قيود مهمة

```sql
check (role in ('owner', 'admin', 'member', 'viewer'))
check (status in ('pending', 'in_progress', 'completed', 'cancelled'))
check (priority in ('low', 'medium', 'high', 'urgent'))
check (split_type in ('equal', 'percentage', 'custom', 'by_items'))
```

---

## 7. ترتيب تنفيذ قاعدة البيانات

```text
1. users
2. homes
3. home_members
4. invitations
5. categories
6. units
7. products
8. shopping_lists
9. shopping_items
10. activity_logs
11. notifications
12. device_tokens
13. notification_preferences
14. storage_locations
15. inventory_items
16. inventory_movements
17. expenses
18. expense_shares
19. settlements
20. tasks
21. task_comments
22. attachments
```

---

## 8. أوامر فحص متكررة بعد كل Spec

```bash
flutter pub get
flutter analyze
flutter test
```

إن كان المشروع يحتوي Supabase migrations:

```bash
supabase db lint
supabase test db
```

إن كان يستخدم توليد ملفات:

```bash
dart run build_runner build --delete-conflicting-outputs
```

---

## 9. أهم ما يجب عدم فعله مبكرًا

لا تطلب من opencode تنفيذ هذه الأشياء قبل إنهاء MVP:

- AI كامل.
- OCR للفواتير.
- الدفع الإلكتروني.
- مقارنة الأسعار.
- ربط المتاجر.
- مخزون متقدم قبل استقرار القوائم.
- مصروفات معقدة قبل تجربة قوائم المشتريات.
- لوحة Web للشركات.

---

## 10. أول جلسة opencode مقترحة

ابدأ بهذه الرسالة داخل opencode:

```text
We are building Beity, a Flutter + Supabase home-management app. Follow AGENTS.md strictly. Use Spec Kit workflow. Start only with SPEC 00 Project Foundation from docs/beity-speckit-opencode-plan.md. Do not implement auth, homes, shopping lists, inventory, expenses, tasks, or AI yet. First create the Spec Kit artifacts, then plan, tasks, analyze, and implement only the project foundation. Keep changes small and testable.
```

---

## 11. ثاني جلسة opencode بعد الدمج

```text
Continue Beity using Spec Kit workflow. Implement only SPEC 01 Auth and User Profile from docs/beity-speckit-opencode-plan.md. Respect the existing architecture from SPEC 00. Use Supabase Auth and users table. Add tests and route guards. Do not implement homes or shopping features yet.
```

---

## 12. تسلسل MVP المختصر

```text
Foundation
→ Auth
→ Homes
→ Members/Invitations
→ Categories/Units
→ Shopping Lists
→ Shopping Items
→ Realtime
→ Activity Logs
→ Notifications
→ Shopping Mode
→ Offline Queue
→ Beta Hardening
```

---

## 13. النتيجة المتوقعة

عند اتباع هذه الخطة، سيكون لديك مشروع مبني بمنهجية Spec-Driven Development، حيث كل جزء من تطبيق بيتي له:

- Spec واضحة.
- Plan تقنية.
- Tasks قابلة للتنفيذ.
- معايير قبول.
- حدود نطاق واضحة.
- حماية من تضخم المنتج مبكرًا.
- ترتيب مناسب لوكيل opencode حتى لا يخلط بين MVP والمراحل المستقبلية.
