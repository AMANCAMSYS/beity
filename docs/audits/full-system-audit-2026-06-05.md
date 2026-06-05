# تقرير الفحص الشامل - تطبيق SAWA (Beity)

**تاريخ الفحص:** 05 يونيو 2026
**نوع الفحص:** يدوي شامل (Code Review)

---

## معلومات عامة

| البند | القيمة |
|-------|--------|
| اسم التطبيق | SAWA |
| الإصدار | 1.0.0+2003 |
| Dart SDK | ^3.11.5 |
| عدد ملفات Dart في `lib/` | 466 |
| عدد ملفات الاختبارات | 102 + 5 تكاملية |
| عدد Features | 17 |
| عدد Migrationات | 11 |
| عدد Edge Functions | 8 |
| عدد المواصفات (Specs) | 16 |
| اللغات المدعومة | ar_SA, en_US, tr_TR |

---

## البنية المعمارية

التبعية تتبع نمط **feature-first clean architecture** بشكل جيد:
- كل Feature تحت `lib/features/<name>` مع طبقات `data/`, `domain/`, `presentation/`
- استخدام **Riverpod** لإدارة الحالة
- استخدام **GoRouter** للتوجيه
- استخدام **Supabase** كـ backend
- استخدام **Drift (SQLite)** لتخزين محلي offline-first
- استخدام **Firebase FCM** للإشعارات و **Crashlytics** للمراقبة

---

## المشاكل الحرجة (Critical)

### 1. ثغرة أمنية في قاعدة البيانات

```sql
GRANT ALL ON TABLE "public"."beta_feedback" TO "anon";
GRANT ALL ON TABLE "public"."sync_operations_log" TO "anon";
```

هاتان الجدولتان ممنوحة بالكامل لدور `anon` بشكل خاطئ. يجب إلغاء هذا التصريح فوراً.

### 2. دالة `auto_archive_completed_tasks` مكشوفة

هذه الدالة SECURITY DEFINER وتقوم بأرشفة المهام المكتملة في **جميع المنازل** بدون التحقق من عضوية المستخدم. أي مستخدم مسجل يمكنه استدعاؤها. يجب تقييدها بـ `service_role` فقط.

### 3. عدم وجود سياسة DELETE على `products`

جدول `products` لا يحتوي على سياسات UPDATE أو DELETE.这意味着 المنتجات لا يمكن تعديلها أو حذفها عبر العميل.

---

## المشاكل عالية الأولوية (High Priority)

### 4. حقول `created_by` / `updated_by` مفقودة

違反 قاعدة المشروع: "Every write action must include `created_by` or `updated_by` where relevant"

| الجدول | `created_by` | `updated_by` | متوافق؟ |
|--------|-------------|-------------|---------|
| `homes` | ❌ | ❌ | ❌ |
| `expense_splits` | ❌ | ❌ | ❌ |
| `notification_preferences` | ❌ | ❌ | ❌ |
| `categories` | ✅ | ❌ | جزئي |
| `task_comments` | ✅ | ❌ | جزئي |
| `products` | ✅ | ❌ | جزئي |
| `notifications` | ❌ | ✅ (أُضيفت متأخرة) | جزئي |

### 5. `authStateProvider` غير مستخدم في `AuthNotifier`

تيار `authStateProvider` معرّف لكن `AuthNotifier` لا يشترك فيه.这意味着 تغييرات الجلسة الخارجية (انتهاء الصلاحية، سحب من جهاز آخر) لا تنعكس تلقائياً في حالة المصادقة.

**الملف:** `lib/features/auth/presentation/providers/auth_provider.dart`

### 6. عدم وجود حل لتعارضات التعديل المتزامنة offline

إذا قام مستخدمان بتعديل نفس العنصر أثناء عدم الاتصال، آخر عملية مزامنة تفوز بدون أي إشعار بالتعارض أو استراتيجية دمج.

---

## المشاكل متوسطة الأولوية (Medium Priority)

### 7. استخدام `StateNotifier` (Legacy Riverpod API)

16 provider يستخدمون `StateNotifierProvider` من `flutter_riverpod/legacy.dart`. النهج الحديث هو `AsyncNotifier`.

### 8. اقتران شديد في `AuthNotifier`

يقوم يدوياً بإبطال 24 provider مختلف عند تسجيل الخروج (`_invalidateAllState()`). يجب استخدام `ProviderObserver` أو نهج مركزي لإدارة دورة حياة التطبيق.

**الملف:** `lib/features/auth/presentation/providers/auth_provider.dart:79-105`

### 9. رسائل عربية مترجمة في Repository

رسائل الخطأ في `AuthRepository` مكتوبة بالعربي مباشرة بدلاً من استخدام مفاتيح الترجمة. هذا يكسر دعم i18n.

**الملف:** `lib/features/auth/data/repositories/auth_repository.dart`

### 10. `OfflineAwareShoppingRepository` بحجم 2161 سطر

هذا الكلاس يتعامل مع كل منطق offline-aware للقوائم والعناصر. يجب تقسيمه إلى كلاسات منفصلة (`OfflineAwareShoppingListRepository` و `OfflineAwareShoppingItemRepository`).

### 11. `catch (_) {}` صامت في أكثر من 20 مكان

الأخطاء تبتلع بدون تسجيل في `OfflineAwareShoppingRepository`، مما يجعل تشخيص المشاكل في الإنتاج مستحيلاً.

### 12. التحقق من كلمة المرور ضعيف

التحقق من كلمة المرور يقتصر على طول >= 8 أحرف فقط. لا يوجد تحقق من أحرف كبيرة أو أرقام أو رموز خاصة.

**الملف:** `lib/core/utils/auth_error_messages.dart`

### 13. تعبير Email regex بسيط

التعبير `^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$` لا يقبل `user+tag@example.com` ويقصي TLDs الحديثة مثل `.technology`.

---

## المشاكل منخفضة الأولوية (Low Priority)

### 14. كود ميت (Dead Code)

- `User` entity في `domain/entities/user.dart` - غير مستخدم نهائياً
- 4 ملفات Isar محذوفة (`// DELETED`) لا تزال موجودة في `shopping_lists/data/`
- 3 widgets غير مستخدمة في home feature:
  - `RecentListsWidget` (`recent_lists_widget.dart`)
  - `ActiveListCard` (`active_list_card.dart`)
  - `QuickAddItemSheet` (`quick_add_item_sheet.dart`)
- 3 widgets غير مستخدمة في shopping_lists:
  - `ConnectionStatusWidget`
  - `ItemUpdatedToast`
  - `ListDetailCategorySection`

### 15. تكرار كود

| الدالة/المتغير | الأماكن المكررة |
|----------------|----------------|
| `_getIconData` | `shopping_list_tile.dart`, `home_active_list_card.dart` |
| `_getProgressColor` | `shopping_list_tile.dart`, `active_list_card.dart`, `home_active_list_card.dart` |
| `_sentinel` | `shopping_item.dart`, `shopping_list.dart`, `shopping_item_model.dart`, `shopping_list_model.dart` |
| Notification token refresh | `auth_provider.dart` signIn + signInWithGoogle |

### 16. نصوص عربية مترجمة في Widgets (بدون i18n)

- `quick_add_item_sheet.dart`: الوحدات (`كيلو`, `جرام`, `لتر`) والفئات (`خضروات`, `فواكه`, `لحوم`) مترجمة بالعربي
- `home_selector_dropdown.dart:56`: `'%d أعضاء'` مترجم
- `home_dashboard_snapshot_updater.dart:155-168`: نصوص النشاط (`أضاف`, `اشترى`, `أنشأ`, `انضم`) مخزنة في Snapshot
- `active_list_card.dart:67,98-99`: `'عنصر'`, `'متبقية'`, `'تم شراؤها'`

### 17. استخدام `e.toString()` في UI

يتم عرض تفاصيل الخطأ التقنية للمستخدم في بعض الأماكن بدلاً من رسائل مترجمة.

**الأماكن:**
- `home_screen.dart:272`
- `app_drawer.dart:251`
- `home_screen.dart:626-654`

### 18. عدم اتساق في استخدام Design System

بعض الأماكن تستخدم `SawaCard`/`SawaButton`/`SawaEmptyState` بينما أجزاء أخرى تستخدم Material widgets مباشرة (`Card`, `ElevatedButton`, `OutlinedButton`).

### 19. مشكلة Dark Mode

`quick_add_item_sheet.dart` يستخدم `Colors.white` مباشرة بدلاً من ألوان الثيم.

### 20. `firstWhere` بدون null-safety

`home_header_sliver.dart:72` يستخدم `firstWhere` بدون قيمة افتراضية. يجب استخدام `firstWhereOrNull` مع قيمة بديلة.

---

## البنية التحتية الإيجابية

### نقاط القوة

#### المعالجة
- نظام معالجة أخطاء من 6 طبقات: `AppException` → `Result` → `SupabaseErrorMapper` → `ErrorHandler` → `ErrorFormatter` → UI Components
- `ErrorBoundary` يلتقط الأخطاء غير المتوقعة ويعرض شاشة خطأ مع زر إعادة المحاولة
- `SawaErrorWidget` كـ `ErrorWidget.builder` عالمي

#### التخزين والمزامنة
- نمط local-first مع offline queue و `MutationsDao`
- نظام مزامنة domain-parallel مع throttling لكل domain
- نمط snapshot caching للعرض الفوري (WhatsApp-like startup)
- `SyncCoordinator` مع smart resume بناءً على الوقت المنقضي:
  - <30s: مزامنة التسوق فقط
  - 30s-5min: مزامنة التسوق فقط
  - 5min-60min: المنازل + الأعضاء + التسوق
  - >=60min: مزامنة كاملة

#### قاعدة البيانات
- 40+ index لتحسين الأداء (delta sync indexes, partial indexes)
- RLS policies على معظم الجداول مع `is_home_member()` و `is_not_viewer()`
- 14 جدول في Realtime publication
- Soft deletes على معظم الجداول
- 30+ trigger للأمان والتدقيق

#### Edge Functions
- محمية بـ JWT و membership checks
- PII stripping في AI suggestions
- Rate limiting في edge function الذكاء الاصطناعي (10/دقيقة)
- FCM v1 API مع معالجة tokens غير صالحة تلقائياً

#### UX
- دعم RTL من البداية مع خط Cairo
- 3 لغات مدعومة (عربي، إنجليزي، تركي)
- 1000+ مفتاح ترجمة
- Accessibility semantics على العناصر الرئيسية
- Haptic feedback مع التحكم بالإعدادات
- Action debouncing لمنع النقرات المزدوجة

#### التصميم
- Design System متكامل: `SawaButton`, `SawaCard`, `SawaDialog`, `SawaSnackBar`, `SawaEmptyState`, `SawaLoadingState`, `SawaErrorState`, `SawaTextField`, `SawaFilterChips`, `SawaStatusChip`, `SawaSkeletonList`, `SawaSectionHeader`, `SawaBottomSheet`

---

## ملاحظات على الاختبارات

### التغطية الحالية

| النوع | عدد الملفات | ملاحظات |
|-------|------------|---------|
| Unit tests | 55 | تغطية جيدة لـ core services |
| Widget tests | 8 | محدودة |
| Feature tests | 34 | بعضها scaffold فقط |
| Integration tests | 5 | جيدة (offline sync, shopping journey, session interruption, concurrent edits, reconnection) |

### المشاكل

- **Auth**: 4 اختبارات فقط (signOut, signUp email confirmation, getCurrentUser null, authStateChanges)
- **لا اختبارات لـ**: signIn, signInWithGoogle, updateProfile, uploadAvatar
- اختبار `logout_cleanup_test.dart` يستخدم mocks مصنوعة يدوياً ولا يختبر الكود الفعلي
- لا توجد اختبارات لـ error handling paths في معظم Features

---

## ملخص التوصيات

### 🔴 حرجة (يجب إصلاحها فوراً)

1. إلغاء `GRANT ALL` على `beta_feedback` و `sync_operations_log` لدور `anon`
2. تقييد `auto_archive_completed_tasks` بـ `service_role`
3. إضافة سياسات UPDATE/DELETE على `products`

### 🟠 عالية الأولوية

4. إضافة `created_by`/`updated_by` على `homes`, `expense_splits`, `notification_preferences`
5. ربط `AuthNotifier` بـ `authStateProvider`
6. إضافة نظام اكتشاف تعارضات offline

### 🟡 متوسطة الأولوية

7. ترقية Riverpod من `StateNotifier` إلى `AsyncNotifier`
8. فصل `OfflineAwareShoppingRepository` إلى كلاسات أصغر
9. استبدال `catch (_) {}` بتسجيل أخطاء
10. تحسين التحقق من كلمة المرور و Email regex
11. إصلاح الاقتران الشديد في `_invalidateAllState()`
12. نقل النصوص المترجمة من Repository إلى نظام i18n

### 🟢 منخفضة الأولوية

13. حذف الكود الميت (Dead Code)
14. استخراج الدوال المكررة إلى shared utilities
15. نقل النصوص العربية المترجمة في Widgets إلى نظام i18n
16. توحيد استخدام Design System
17. إصلاح مشكلة Dark Mode في `quick_add_item_sheet.dart`
18. استبدال `e.toString()` برسائل مترجمة في UI
19. تحسين تغطية الاختبارات للميزات الحرجة

---

## إحصائيات سريعة

```
إجمالي المشاكل المكتشفة: ~45
├── حرجة:        3
├── عالية:        3
├── متوسطة:      6
├── منخفضة:      8
└── نقاط قوة:    15+

الملفات المتأثرة بشكل رئيسي:
├── auth_provider.dart
├── auth_repository.dart
├── OfflineAwareShoppingRepository (2161 سطر)
├── home_screen.dart (716 سطر)
├── supabase migrations (11 ملف)
└── edge functions (8 ملف)
```
