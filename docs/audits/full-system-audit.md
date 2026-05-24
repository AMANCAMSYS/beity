# تقرير التدقيق الشامل للنظام - تطبيق بيتي

> **تاريخ التدقيق**: 2026-05-14
> **الإصدار**: v0.2.0-preview
> **المدقق**: Antigravity AI
> **الحالة**: تدقيق أمني وبنيوي شامل قبل مرحلة البيتا العامة

---

## الملخص التنفيذي

تم إجراء تدقيق شامل لتطبيق "بيتي" المبني باستخدام Flutter + Supabase. يغطي التقرير: الأمان (RLS)، عزل الجلسات، سلامة البيانات، الملاحة، Null Safety، المنطق التجاري، والتدفقات غير المكتملة.

### نتائج التدقيق حسب الخطورة

| الخطورة | العدد | الحالة |
|---------|-------|--------|
| 🔴 حرجة | 3 | تتطلب إصلاح فوري |
| 🟠 عالية | 5 | تتطلب إصلاح قبل البيتا العامة |
| 🟡 متوسطة | 6 | يُنصح بإصلاحها |
| 🔵 منخفضة | 4 | تحسينات مستقبلية |

---

## 1. التدقيق الأمني (RLS وقاعدة البيانات)

### 1.1 🟠 عالية: عدم تطابق هيكل جدول `notification_preferences`

**الوصف**: هيكل جدول `notification_preferences` في ملف الهجرة SQL يختلف جذرياً عن النموذج في Flutter:

- **قاعدة البيانات** (الهجرة): أعمدة `user_id`, `category` (enum: shopping_list/home_activity/invitation), `enabled`
- **Flutter** (النموذج): أعمدة `user_id`, `home_id`, `item_added`, `item_completed`, `low_stock`, `expiry_alert`, `expense_added`, `task_due`

**الملفات المتأثرة**:
- `supabase/migrations/20260513_add_notifications.sql` (سطر 28-37)
- `lib/features/notifications/data/models/notification_preference_model.dart`
- `lib/features/notifications/data/repositories/supabase_notification_repository.dart` (سطر 93-154)

**الأثر**: استعلامات التفضيلات ستفشل لعدم وجود أعمدة `home_id`, `item_added` إلخ في الجدول الفعلي. المستودع يلتقط الخطأ ويعيد قيم افتراضية (سطر 119-134)، مما يعني أن تغييرات المستخدم لن تُحفظ أبداً.

**التوصية**: إنشاء هجرة جديدة لتحديث هيكل الجدول ليتطابق مع النموذج.

---

### 1.2 ✅ سياسات RLS للجداول الأساسية: سليمة

تم فحص سياسات RLS لجميع الجداول:

| الجدول | SELECT | INSERT | UPDATE | DELETE | ملاحظات |
|--------|--------|--------|--------|--------|---------|
| `inventory_items` | ✅ | ✅ | ✅ | ✅ | فحص `home_members` + `created_by`/`updated_by` |
| `inventory_transactions` | ✅ | ✅ | - | - | فحص `home_members` + `changed_by` |
| `tasks` | ✅ | ✅ | ✅ | ❌ | لا توجد سياسة DELETE |
| `task_comments` | ✅ | ✅ | ✅ | ✅ | المالك فقط يعدل/يحذف |
| `shopping_mode_sessions` | ✅ | ✅ | ✅ | - | فحص `user_id = auth.uid()` |
| `notifications` | ✅ | ✅ | ✅ | ✅ | `user_id = auth.uid()` |
| `notification_preferences` | ✅ | ✅ | ✅ | - | `user_id = auth.uid()` |

### 1.3 🟡 متوسطة: جدول `tasks` لا يملك سياسة DELETE

**الملف**: `supabase/migrations/20260513_add_tasks_tables.sql`

**الوصف**: لا توجد سياسة RLS لعملية DELETE. الكود يستخدم soft-delete عبر UPDATE، لكن غياب السياسة يمثل ثغرة معمارية.

**التوصية**: إضافة سياسة DELETE مماثلة لسياسة UPDATE.

### 1.4 🟡 متوسطة: دوال RPC بصلاحيات `SECURITY DEFINER`

**الوصف**: الدوال `create_next_recurring_task()` و `archive_old_completed_tasks()` تعمل بصلاحيات المالك ولا تتحقق من أن المستدعي عضو في المنزل.

**التوصية**: إضافة فحص `auth.uid()` داخل الدوال للتحقق من عضوية المنزل.

---

## 2. عزل الجلسات والحسابات

### 2.1 ✅ تسجيل الخروج: سليم

تم فحص `AuthNotifier.signOut()` في `auth_provider.dart`:
- يستدعي `Supabase.instance.client.auth.signOut()` ✅
- يبطل (invalidate) جميع الـ providers الحساسة ✅
- يمسح `HomeLocalDataSource` ✅
- يبطل `realtimeServiceProvider` و `offlineQueueProvider` ✅

### 2.2 ✅ عزل البيانات المحلية: سليم

`HomeLocalDataSource` يستخدم `_userKey` مبني على `currentUser?.id` كبادئة، مما يمنع تسريب بيانات بين حسابات مختلفة على نفس الجهاز.

---

## 3. الملاحة والتوجيه (Router)

### 3.1 ✅ `getEffectiveHomeId`: سليم

الدالة في `app_router.dart` (سطر 48-66) تتعامل مع جميع حالات الـ fallback بشكل صحيح.

### 3.2 🟡 متوسطة: `state.extra as dynamic` بدون تحقق

**الملف**: `app_router.dart` (سطر 282)

```dart
final log = state.extra as dynamic;
```

**الأثر**: إذا تم الوصول لهذا المسار بدون `extra` سيكون `log = null` وقد يتسبب بانهيار.

### 3.3 🟡 متوسطة: مسار المهام بـ `homeId` فارغ

**الملف**: `app_drawer.dart` (سطر 139, 147)

```dart
context.push('/home/${homeId ?? ""}/tasks');
```

**الوصف**: إذا كان `homeId` فارغاً، سيُنتج مسار `/home//tasks` مما قد يتسبب بخطأ 404.

**التوصية**: إضافة null check مسبق كما في زر "إدارة الأعضاء".

---

## 4. سلامة البيانات والمنطق التجاري

### 4.1 🔴 حرجة: قائمة الانتظار دون اتصال غير مربوطة

**الوصف**: يوجد نظامان منفصلان:

1. **النظام الأول** (`lib/features/offline_queue/`): بنية كاملة مع `QueueEntry`, `SharedPreferencesQueueDataSource`, `EnqueueActionUseCase` - **غير مربوط** بأي مستودع.

2. **النظام الثاني** (`realtime_providers.dart`): `OfflineQueueNotifier` بسيط يعمل في الذاكرة فقط - يفقد البيانات عند إغلاق التطبيق.

**الأثر**: لا يوجد دعم حقيقي للعمل دون اتصال. أي عملية بدون إنترنت ستفشل أو تُفقد.

**التوصية**: ربط `OfflineAwareShoppingRepository` وإزالة النظام المكرر.

### 4.2 🔴 حرجة: استعلام مباشر لـ Supabase من واجهة المستخدم

**الملف**: `home_screen.dart` (سطر 518-525)

```dart
future: Supabase.instance.client
    .from('activity_logs')
    .select()
    .eq('home_id', homeId)
    .order('created_at', ascending: false)
    .limit(5)
```

**المشاكل**:
- لا يستفيد من التحديث اللحظي (Realtime)
- يُعاد تنفيذه عند كل rebuild
- يخالف البنية المعمارية (Clean Architecture)
- لا يُبطل عند تبديل المنزل النشط

**التوصية**: إنشاء `activityLogsProvider` في طبقة providers.

### 4.3 🟠 عالية: خطأ محتمل في حساب إجمالي المصروفات

**الملف**: `expense_remote_datasource.dart` (سطر 209-210)

```dart
return (response as List)
    .fold<int>(0, (sum, json) => sum + (json['converted_amount'] as int));
```

**الوصف**: يستخدم `as int` مباشرةً. إذا كانت القيمة `null` أو `double`، سينهار التطبيق.

**التوصية**: استخدام `(json['converted_amount'] as num?)?.toInt() ?? 0`.

### 4.4 🟠 عالية: حذف المصروف لا يحذف التقسيمات

**الملف**: `expense_remote_datasource.dart` (سطر 130-144)

**الوصف**: `deleteExpense` يعمل soft-delete فقط لكن لا يحذف `expense_splits`. الأرصدة المحسوبة قد تتضمن تقسيمات من مصروفات محذوفة.

**التوصية**: التحقق من أن `calculate_home_balances` تستثني المصروفات ذات `status = 'cancelled'`.

---

## 5. Null Safety ومعالجة الأخطاء

### 5.1 🟠 عالية: استثناءات مبتلعة (Swallowed Exceptions)

| الملف | السطر | النمط |
|-------|-------|-------|
| `realtime_providers.dart` | 44 | `catch (_) { continue; }` - فقدان بيانات صامت |
| `realtime_service.dart` | 237, 250, 292, 336 | `catch (_) {}` |
| `auth_provider.dart` | 85, 91 | `catch (_) {}` |

**الأثر الأخطر**: في `realtime_providers.dart` فشل مزامنة عنصر يُتجاهل بـ `continue`، مما يعني فقدان بيانات صامت.

**التوصية**: إضافة `debugPrint` logging على الأقل.

### 5.2 ✅ استخدام `.first` و `.single`: آمن

جميع استخدامات `.first` مسبوقة بفحص `isNotEmpty`. استخدامات `.single()` هي بعد `.insert().select().single()` في Supabase وهذا النمط القياسي.

### 5.3 ✅ Type casts في نماذج البيانات: آمنة

`ExpenseModel.fromJson` يستخدم `as String? ?? ''` و `as num?` بشكل آمن. النمط الوحيد الخطر هو `getExpenseTotal` (موثق في 4.3).

---

## 6. التدفقات غير المكتملة

### 6.1 🔴 حرجة: نظاما Offline Queue متعارضان

كما ذُكر في 4.1. يجب توحيدهما.

### 6.2 🟠 عالية: فلاتر المصروفات غير مكتملة

الفلترة بالتصنيف والعضو موجودة في `ExpenseRemoteDataSource.getExpenses()` لكن لا يوجد UI يربطها.

### 6.3 🔵 منخفضة: عدم وجود اختبارات

لم يُعثر على أي ملفات اختبار. يُنصح بإضافة اختبارات لـ:
- `SplitExpense.calculateEqualSplits`
- `AuthNotifier.signOut`
- نماذج البيانات (`fromJson`/`toJson`)

---

## 7. أعلام الميزات (Feature Flags)

**الملف**: `lib/core/config/feature_flags.dart`

```dart
static const bool enableInventory = true;
static const bool enableExpenses = true;
static const bool enableTasks = true;
static const bool enableAi = false;
```

**الملاحظات**:
- ✅ الأعلام مستخدمة بشكل صحيح في `app_drawer.dart`
- ✅ AI معطل كما هو متوقع
- 🔵 لا توجد feature flags على مستوى الـ Router (المسارات متاحة حتى لو كان العلم معطلاً)

---

## 8. ملخص التوصيات حسب الأولوية

### المرحلة 1: قبل أي إصدار (حرجة)

| # | المشكلة | الإصلاح |
|---|---------|---------|
| 1 | Offline Queue غير مربوط | ربط `OfflineAwareShoppingRepository` |
| 2 | استعلام Supabase مباشر في HomeScreen | إنشاء `activityLogsProvider` |
| 3 | نظاما offline queue متعارضان | توحيد واستخدام النظام القائم على SharedPreferences |

### المرحلة 2: قبل البيتا العامة (عالية)

| # | المشكلة | الإصلاح |
|---|---------|---------|
| 4 | تطابق هيكل `notification_preferences` | إنشاء هجرة جديدة أو تحديث النموذج |
| 5 | `as int` في حساب الإجمالي | استخدام `as num?` مع `?.toInt()` |
| 6 | حذف المصروف لا يحذف التقسيمات | فحص دالة RPC أو إضافة حذف cascade |
| 7 | استثناءات مبتلعة | إضافة logging |
| 8 | فلاتر المصروفات غير مكتملة | ربط UI بالفلاتر الموجودة |

### المرحلة 3: تحسينات (متوسطة/منخفضة)

| # | المشكلة | الإصلاح |
|---|---------|---------|
| 9 | جدول tasks بدون سياسة DELETE | إضافة سياسة RLS |
| 10 | مسار المهام بـ homeId فارغ | إضافة null check |
| 11 | `state.extra as dynamic` بدون تحقق | إضافة type check |
| 12 | SECURITY DEFINER بدون فحص عضوية | إضافة auth check |
| 13 | Feature flags غير مطبقة على Router | إضافة route guards |
| 14 | عدم وجود اختبارات | إضافة unit tests |

---

## 9. النقاط الإيجابية

- ✅ بنية Clean Architecture متسقة ومنظمة
- ✅ RLS مطبق على جميع الجداول مع فحص `home_members`
- ✅ عزل بيانات المستخدمين المحليين عبر `_userKey`
- ✅ تسجيل الخروج يبطل جميع الـ providers
- ✅ نماذج البيانات تستخدم `as String?` (null-safe)
- ✅ Realtime و Presence يعملان بشكل صحيح
- ✅ دعم RTL العربية شامل
- ✅ Feature Flags مطبقة في القائمة الجانبية
- ✅ Soft-delete مطبق في جميع الجداول الحساسة
- ✅ `created_by`/`updated_by` موجودة في جميع العمليات الكتابية

---

> **الخلاصة**: النظام في حالة جيدة بشكل عام للـ Internal Beta. المشاكل الحرجة الثلاث (Offline Queue، الاستعلام المباشر، تعارض الأنظمة) يجب حلها قبل البيتا العامة. سياسات RLS سليمة وعزل الجلسات يعمل بشكل صحيح.
