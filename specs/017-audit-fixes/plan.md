# خطة إصلاحات التدقيق الشامل – SAWA v1.0.0+2003

**التاريخ:** 2026-06-05  
**الأولوية:** عالية  
**الجدول الزمني المقدر:** 3-4 أسابيع

---

## 📋 ملخص التنفيذ

| المرحلة | الوصف | الأولوية | الجهد المقدر |
|---------|-------|:--------:|:------------:|
| 1 | حذف الكود الميت | 🔴 حرجة | يوم واحد |
| 2 | إعادة بناء ErrorFormatter | 🔴 حرجة | 2-3 أيام |
| 3 | ترحيل StateNotifier → Notifier | 🟡 عالية | أسبوع |
| 4 | تقسيم الملفات الكبيرة | 🟡 عالية | أسبوع |
| 5 | تحسين تغطية الاختبارات | 🟢 متوسطة | أسبوع |

---

## المرحلة 1: حذف الكود الميت (Quick Wins)

### 1.1 حذف `isar_service.dart`
- **الملف:** `lib/core/services/isar_service.dart`
- **السبب:** يحتوي فقط على `// DELETED` — لا قيمة له
- **الإجراء:** حذف الملف بالكامل
- **التحقق:** التأكد من عدم وجود أي import له

### 1.2 حذف `result.dart`
- **الملف:** `lib/core/error/result.dart`
- **السبب:** 76 سطر، لا يوجد أي import في المشروع
- **الإجراء:** حذف الملف بالكامل
- **التحقق:** التأكد من عدم وجود أي reference له

---

## المرحلة 2: إعادة بناء ErrorFormatter

### المشكلة
- 58 شرط `if` + 59 استدعاء `.contains()`
- 205 سطر في method واحد `formatWithL10n`
- String matching بطيء وصعب الصيانة

### الحل المقترح
تحويل الـ if/contains chain إلى `Map<String, String>` lookup:

```dart
// بدلاً من 38 if/contains blocks
static final _errorMappings = <String, String>{
  'network': 'error_network',
  'timeout': 'error_timeout',
  'connection': 'error_connection',
  // ... etc
};

static String formatWithL10n(dynamic error, String Function(String) translate) {
  final errorStr = error.toString().toLowerCase();
  
  // Check type-based errors first
  if (error is SocketException) return translate('error_network');
  if (error is TimeoutException) return translate('error_timeout');
  
  // Map-based lookup for string patterns
  for (final entry in _errorMappings.entries) {
    if (errorStr.contains(entry.key)) {
      return translate(entry.value);
    }
  }
  
  return translate('error_unknown');
}
```

### الفوائد
- سهولة الصيانة (إضافة خطأ جديد = سطر واحد)
- أداء أفضل (Map lookup vs sequential scanning)
- قابلية الاختبار (يمكن اختبار الـ map بشكل مستقل)

---

## المرحلة 3: ترحيل StateNotifier → Notifier

### الملفات المتأثرة (15 ملف)

| الأولوية | الملف | الفئة |
|:--------:|-------|-------|
| 1 | `auth/presentation/providers/auth_provider.dart` | AuthNotifier |
| 1 | `homes/presentation/providers/homes_provider.dart` | HomesNotifier |
| 1 | `core/services/sync_coordinator.dart` | SyncCoordinator |
| 2 | `shopping_mode/presentation/providers/shopping_mode_provider.dart` | ShoppingModeNotifier |
| 2 | `categories/presentation/providers/categories_provider.dart` | CategoryNotifier |
| 2 | `categories/presentation/providers/units_provider.dart` | UnitNotifier |
| 2 | `invitations/presentation/providers/invitations_provider.dart` | InvitationNotifier |
| 2 | `invitations/presentation/providers/roles_provider.dart` | RoleNotifier |
| 3 | `settings/presentation/providers/app_settings_provider.dart` | AppSettingsNotifier |
| 3 | `tasks/presentation/providers/task_filter_providers.dart` | TaskFilterNotifier |
| 3 | `activity_logs/presentation/providers/activity_logs_provider.dart` | ActivityFilterNotifier |
| 3 | `onboarding/presentation/providers/app_tour_controller.dart` | AppTourController |
| 3 | `ai_suggestions/presentation/providers/ai_assistant_provider.dart` | AiAssistantNotifier |
| 3 | `ai_suggestions/presentation/providers/ai_suggestions_provider.dart` | AiSuggestionsNotifier |
| 3 | `core/services/initial_data_hydration_service.dart` | InitialDataHydrationService |

### نمط الترحيل

```dart
// BEFORE (Legacy)
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authRepositoryProvider));
});

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._repository) : super(const AuthState.initial());
}

// AFTER (Modern)
final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState.initial();
}
```

### ملاحظات مهمة
- الترحيل يجب أن يكون **تدريجي** (ملف واحد في كل مرة)
- يجب اختبار كل ملف بعد الترحيل
- بعض الـ Notifiers قد تحتاج `Ref` access عبر `ref.read()` بدلاً من constructor injection

---

## المرحلة 4: تقسيم الملفات الكبيرة

### 4.1 `shopping_list_detail_screen.dart` (948 سطر)

**الهيكل المقترح:**
```
shopping_list_detail/
├── shopping_list_detail_screen.dart (200 سطر - shell فقط)
├── widgets/
│   ├── shopping_list_header.dart (100 سطر)
│   ├── shopping_item_tile.dart (150 سطر)
│   ├── shopping_item_actions.dart (100 سطر)
│   ├── shopping_list_stats.dart (80 سطر)
│   └── shopping_list_fab.dart (60 سطر)
├── dialogs/
│   ├── add_item_dialog.dart (120 سطر)
│   └── edit_item_dialog.dart (120 سطر)
└── helpers/
    └── shopping_list_helpers.dart (50 سطر)
```

### 4.2 `shopping_mode_screen.dart` (769 سطر)

**الهيكل المقترح:**
```
shopping_mode/
├── shopping_mode_screen.dart (200 سطر - shell فقط)
├── widgets/
│   ├── shopping_mode_header.dart (80 سطر)
│   ├── shopping_mode_item_card.dart (120 سطر)
│   ├── shopping_mode_progress.dart (80 سطر)
│   ├── shopping_mode_category_filter.dart (80 سطر)
│   └── shopping_mode_quick_add.dart (100 سطر)
├── dialogs/
│   ├── partial_purchase_dialog.dart (80 سطر)
│   └── shopping_guide_dialog.dart (60 سطر)
└── services/
    └── shopping_mode_session_service.dart (80 سطر)
```

### 4.3 `notification_service.dart` (776 سطر)

**الهيكل المقترح:**
```
core/services/
├── notification_service.dart (200 سطر - core فقط)
├── notification/
│   ├── notification_initialization.dart (100 سطر)
│   ├── notification_handling.dart (150 سطر)
│   ├── notification_navigation.dart (100 سطر)
│   ├── notification_preferences.dart (80 سطر)
│   └── notification_cleanup.dart (80 سطر)
```

### 4.4 `realtime_sync_service.dart` (798 سطر)

**الهيكل المقترح:**
```
core/services/
├── realtime_sync_service.dart (200 سطر - core فقط)
├── realtime/
│   ├── realtime_channel_manager.dart (100 سطر)
│   ├── realtime_event_handler.dart (150 سطر)
│   ├── realtime_table_handlers.dart (200 سطر)
│   └── realtime_debounce.dart (80 سطر)
```

### 4.5 `app_tour_controller.dart` (596 سطر)

**الهيكل المقترح:**
```
onboarding/presentation/providers/
├── app_tour_controller.dart (200 سطر - core فقط)
├── app_tour/
│   ├── app_tour_steps.dart (100 سطر)
│   ├── app_tour_animations.dart (100 سطر)
│   └── app_tour_overlay.dart (100 سطر)
```

---

## المرحلة 5: تحسين تغطية الاختبارات

### 5.1 Widget Tests المطلوبة

| الأولوية | الشاشة | الملف |
|:--------:|--------|-------|
| 1 | Shopping List Detail | `test/widget/features/shopping/shopping_list_detail_screen_test.dart` |
| 1 | Shopping Mode | `test/widget/features/shopping_mode/shopping_mode_screen_test.dart` |
| 2 | Onboarding | `test/widget/features/onboarding/welcome_onboarding_screen_test.dart` |
| 2 | Auth Login | `test/widget/features/auth/login_screen_test.dart` |
| 2 | Auth Signup | `test/widget/features/auth/signup_screen_test.dart` |
| 3 | Notifications | `test/widget/features/notifications/notifications_screen_test.dart` |
| 3 | Activity Logs | `test/widget/features/activity_logs/activity_logs_screen_test.dart` |

### 5.2 Unit Tests المطلوبة

| الأولوية | الوحدة | الملف |
|:--------:|--------|-------|
| 1 | SyncCoordinator | `test/unit/core/sync_coordinator_test.dart` |
| 1 | RealtimeSyncService | `test/unit/core/realtime_sync_service_test.dart` |
| 2 | ErrorFormatter | `test/unit/core/error_formatter_test.dart` |
| 2 | NotificationService | `test/unit/core/notification_service_test.dart` |
| 3 | AppTourController | `test/unit/features/onboarding/app_tour_controller_test.dart` |

---

## 📅 الجدول الزمني المقترح

```
الأسبوع 1:
├── اليوم 1-2: المرحلة 1 (حذف الكود الميت)
├── اليوم 3-5: المرحلة 2 (إعادة بناء ErrorFormatter)

الأسبوع 2:
├── اليوم 1-5: المرحلة 3 (ترحيل StateNotifier - الجزء الأول)
│   ├── Auth, Homes, SyncCoordinator (أولوية عالية)
│   └── Shopping, Categories, Invitations (أولوية متوسطة)

الأسبوع 3:
├── اليوم 1-3: المرحلة 3 (ترحيل StateNotifier - الجزء الثاني)
│   └── Settings, Tasks, Activity Logs, AI, Onboarding
├── اليوم 4-5: المرحلة 4 (تقسيم الملفات الكبيرة - البداية)

الأسبوع 4:
├── اليوم 1-3: المرحلة 4 (تقسيم الملفات الكبيرة - الاستكمال)
├── اليوم 4-5: المرحلة 5 (إضافة الاختبارات)
```

---

## ✅ معايير القبول

- [ ] لا يوجد أي ملف يحتوي على `// DELETED` أو كود ميت
- [ ] ErrorFormatter يستخدم Map-based lookup بدلاً من if/contains chain
- [ ] جميع الـ Notifiers تستخدم `Notifier`/`AsyncNotifier` بدلاً من `StateNotifier`
- [ ] لا يوجد ملف أكبر من 400 سطر
- [ ] تغطية الاختبارات > 70% للـ presentation layer
- [ ] جميع الاختبارات الحالية تمر بنجاح
- [ ] لا يوجد regressions في الوظائف الموجودة

---

## ⚠️ المخاطر المحتملة

1. **ترحيل StateNotifier** قد يسبب breaking changes في providers أخرى تعتمد عليه
2. **تقسيم الملفات الكبيرة** قد يتطلب تعديل imports في ملفات أخرى
3. **إعادة بناء ErrorFormatter** قد تؤثر على معالجة الأخطاء الموجودة
4. **إضافة الاختبارات** قد تكشف bugs موجودة لم يتم اكتشافها سابقاً

---

## 🔄 خطة الطوارئ

- إذا تسبب ترحيل StateNotifier في regressions → التراجع واستخدام approach أكثر تحفظاً
- إذا كان تقسيم الملفات معقداً → استخدام `part/part of` بدلاً من ملفات منفصلة
- إذا فشلت الاختبارات → إصلاحها أولاً قبل المتابعة
