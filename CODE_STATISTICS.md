# 📊 إحصائيات شاملة لمشروع ساوا (SAWA)

**التاريخ:** 2026-06-06  
**الإصدار:** v1.0.0+2003  
**Flutter SDK:** ^3.11.5

---

## 📈 ملخص عام

| المقياس | العدد |
|---------|:-----:|
| **إجمالي ملفات Dart** | 590 |
| **إجمالي أسطر Dart** | 114,682 |
| **ملفات Flutter (lib/)** | 475 |
| **ملفات الاختبارات (test/)** | 115 |
| **ملفات Edge Functions** | 10 |
| **ملفات SQL Migrations** | 11 |
| **ملفات التوثيق (docs/)** | 29 |

---

## 🎯 تقسيم الكود

```
Frontend (Flutter)     94,902 سطر (74.5%)
Tests                  19,780 سطر (15.5%)
Edge Functions          2,758 سطر (2.2%)
SQL Migrations          5,219 سطر (4.1%)
Documentation           9,400 سطر (3.7%)
─────────────────────────────────────────
المجموع               ~132,000 سطر
```

---

## 📱 Frontend — Flutter/Dart

### إجمالي الكود

| المجلد | الملفات | الأسطر |
|--------|:-------:|:------:|
| **lib/** (إجمالي) | 475 | 94,902 |
| **lib/features/** | 348 | 57,202 |
| **lib/core/** | 68 | 30,004 |
| **lib/shared/** | 19 | 1,731 |
| **lib/app/** | 13 | 1,379 |
| **مُولّد (generated)** | 4 | 17,026 |

---

### 📦 الأكواد حسب الوحدة (Features)

| الوحدة | الملفات | الأسطر | النسبة |
|--------|:-------:|:------:|:------:|
| 🛒 shopping_lists | 45 | 7,812 | 13.6% |
| 🤖 ai_suggestions | 33 | 7,559 | 13.2% |
| 💰 expenses | 32 | 5,878 | 10.2% |
| 📴 offline_queue | 30 | 6,311 | 11.0% |
| ✅ tasks | 30 | 3,938 | 6.9% |
| 📦 inventory | 24 | 4,004 | 7.0% |
| 📨 invitations | 24 | 2,869 | 5.0% |
| 🏠 homes | 23 | 3,380 | 5.9% |
| 📂 categories | 23 | 2,416 | 4.2% |
| 🛍️ shopping_mode | 22 | 3,069 | 5.4% |
| 🔔 notifications | 20 | 2,328 | 4.1% |
| 🏠 home (dashboard) | 14 | 2,971 | 5.2% |
| ⚙️ settings | 14 | 2,519 | 4.4% |
| 🔐 auth | 12 | 1,887 | 3.3% |
| 📋 activity_logs | 11 | 2,083 | 3.6% |
| 🎉 onboarding | 9 | 1,586 | 2.8% |
| 🧪 beta | 7 | 888 | 1.5% |
| **المجموع** | **348** | **57,202** | **100%** |

---

### 🔧 البنية التحتية (Core)

| المجلد | الملفات | الأسطر |
|--------|:-------:|:------:|
| **core/** (إجمالي) | 68 | 30,004 |
| 📊 local_database (Drift) | 19 | 20,037 |
| 🔧 services | 21 | 3,602 |
| 🚨 errors | 8 | 942 |
| 🌐 localization | 12 | ~4,500 |
| 📱 monitoring | 5 | ~500 |
| 📦 providers | 3 | ~400 |

---

### 🌐 الترجمات (i18n)

| اللغة | الملف | الأسطر | المفاتيح |
|-------|-------|:------:|:--------:|
| 🇸🇦 العربية | `ar.dart` | 1,436 | ~700 |
| 🇬🇧 الإنجليزية | `en.dart` | 1,469 | ~700 |
| 🇹🇷 التركية | `tr.dart` | 1,477 | ~700 |
| **المجموع** | — | **4,382** | **~2,100** |

---

### 📝 الكود المُولّد (Generated)

| الملف | الأسطر |
|-------|:------:|
| `app_database.g.dart` | 16,921 |
| أخريات `.g.dart` | ~105 |
| **المجموع** | **17,026** |

---

## 🧪 الاختبارات

### إجمالي الاختبارات

| النوع | الملفات | الأسطر |
|-------|:-------:|:------:|
| **test/** (إجمالي) | 115 | 19,780 |
| 🔬 Unit tests | — | 10,342 |
| 🖥️ Widget tests | — | 2,265 |
| 🔗 Integration tests | — | 1,743 |
| 📁 Feature tests | — | 4,746 |
| 🔒 Security tests | — | 429 |

### نتائج الاختبارات

```
✅ 526 ناجح
⏭️ 9 متخطّي
❌ 0 فاشل
```

### أكبر ملفات الاختبارات

| الملف | الأسطر |
|-------|:------:|
| `offline_queue_critical_test.dart` | 1,271 |
| `offline_aware_repository_test.dart` | 811 |
| `realtime_reconciliation_test.dart` | 562 |
| `realtime_sync_service_test.dart` | 566 |
| `concurrent_edit_test.dart` | 527 |
| `auth_provider_test.dart` | 457 |
| `smart_resume_sync_test.dart` | 440 |

---

## ⚙️ Backend — Supabase

### Edge Functions

| الدالة | الأسطر | الوظيفة |
|--------|:------:|---------|
| `send-notification` | 767 | إرسال إشعارات FCM |
| `generate-shopping-suggestions` | 744 | اقتراحات ذكية |
| `_shared` | 394 | كود مشترك |
| `broadcast-notification` | 306 | بث إشعارات |
| `update-notification-preferences` | 179 | تفضيلات الإشعارات |
| `submit-feedback` | 156 | ملاحظات المستخدمين |
| `get-notification-history` | 87 | سجل الإشعارات |
| `mark-notifications-read` | 74 | تحديد كمقروء |
| `cleanup-old-notifications` | 51 | تنظيف الإشعارات |
| **المجموع** | **2,758** | — |

---

### قاعدة البيانات (PostgreSQL)

| المقياس | العدد |
|---------|:-----:|
| **الجداول** | 26 |
| **الفهارس** | 35+ |
| **RLS Policies** | 100+ |
| **الدوال (Functions)** | 44 |
| **المُحفّزات (Triggers)** | 20+ |
| **الـ Migrations** | 11 ملف (5,219 سطر) |

#### الجداول الرئيسية

| الجدول | RLS | Policies | الوصف |
|--------|:---:|:--------:|-------|
| `users` | ✅ | 4 | المستخدمون |
| `homes` | ✅ | 4 | المنازل |
| `home_members` | ✅ | 4 | أعضاء المنزل |
| `invitations` | ✅ | 8 | الدعوات |
| `shopping_lists` | ✅ | 4 | قوائم التسوق |
| `shopping_items` | ✅ | 5 | عناصر التسوق |
| `categories` | ✅ | 4 | التصنيفات |
| `units` | ✅ | 4 | الوحدات |
| `products` | ✅ | 4 | المنتجات |
| `tasks` | ✅ | 4 | المهام |
| `expenses` | ✅ | 4 | المصروفات |
| `inventory_items` | ✅ | 4 | المخزون |
| `notifications` | ✅ | 2 | الإشعارات |
| `device_tokens` | ✅ | 2 | أجهزة المستخدمين |
| `activity_logs` | ✅ | 2 | سجل النشاط |
| `beta_feedback` | ✅ | 2 | ملاحظات البيتا |
| `sync_operations_log` | ✅ | 2 | سجل المزامنة |
| `rate_limit_log` | ✅ | 0 | حدود الطلبات |
| `item_templates` | ✅ | 4 | قوالب العناصر |
| `shopping_mode_sessions` | ✅ | 3 | جلسات التسوق |
| `task_comments` | ✅ | 4 | تعليقات المهام |
| `inventory_transactions` | ✅ | 2 | معاملات المخزون |
| `expense_splits` | ✅ | 4 | تقسيم المصروفات |
| `settlements` | ✅ | 2 | التسويات |
| `notification_preferences` | ✅ | 4 | تفضيلات الإشعارات |
| `role_permissions` | ✅ | 1 | صلاحيات الأدوار |

#### الدوال الأمنية (SECURITY DEFINER)

| الدالة | الوظيفة |
|--------|---------|
| `is_home_member(p_home_id)` | التحقق من عضوية المنزل |
| `is_not_viewer(p_home_id)` | التحقق من عدم كون المشاهد |
| `accept_invitation(token)` | قبول الدعوة |
| `create_invitation(...)` | إنشاء دعوة |
| `transfer_home_ownership(...)` | نقل ملكية المنزل |
| `handle_new_user()` | إعداد مستخدم جديد |
| `handle_new_home()` | إعداد منزل جديد |
| أخريات (44 دوال) | — |

---

## 📄 التوثيق

| المجلد | الملفات | الأسطر |
|--------|:-------:|:------:|
| `docs/audits/` | 7 | ~2,500 |
| `docs/beta/` | 5 | ~1,500 |
| `specs/` | 3 | ~500 |
| ملفات جذرية (`.md`) | 5 | ~1,500 |
| **المجموع** | **20** | **~6,000** |

### ملفات التوثيق الرئيسية

| الملف | الأسطر | المحتوى |
|-------|:------:|---------|
| `AUDIT_REPORT_2026-06-05.md` | 604 | تقرير التدقيق الشامل |
| `supabase-security-verification-2026-06-05.md` | ~200 | التحقق الأمني |
| `supabase-rls-matrix-2026-06-05.md` | ~300 | مصفوفة RLS |
| `shopping-mvp-reliability-2026-06-05.md` | ~150 | موثوقية التسوق |
| `notification-flow-2026-06-05.md` | ~415 | تدفق الإشعارات |
| `shopping-architecture-cleanup-2026-06-05.md` | ~200 | تنظيف المعمارية |
| `manual-test-plan.md` | ~200 | خطة اختبار البيتا |
| `store-readiness.md` | ~150 | جاهزية المتجر |
| `release-checklist.md` | ~100 | قائمة الإطلاق |
| `qa-checklist.md` | ~250 | قائمة ضمان الجودة |
| `plan.md` (specs) | 454 | خطة الاحتراف |

---

## 📁 أكبر الملفات (Top 15)

| # | الملف | الأسطر | ملاحظة |
|:-:|-------|:------:|--------|
| 1 | `app_database.g.dart` | 16,921 | مُولّد (Drift) |
| 2 | `offline_aware_shopping_repository.dart` | 2,181 | منطق sync معقد |
| 3 | `smart_item_resolver.dart` | 1,744 | AI suggestions |
| 4 | `tr.dart` | 1,477 | ترجمة تركية |
| 5 | `en.dart` | 1,469 | ترجمة إنجليزية |
| 6 | `ar.dart` | 1,436 | ترجمة عربية |
| 7 | `onboarding_screen.dart` | 969 | شاشة الإعداد |
| 8 | `ai_assistant_provider.dart` | 965 | AI provider |
| 9 | `ai_suggestions_screen.dart` | 847 | شاشة AI |
| 10 | `supabase_shopping_list_repository.dart` | 783 | Repository |
| 11 | `queue_action_executor.dart` | 771 | Offline queue |
| 12 | `sync_status_screen.dart` | 768 | شاشة المزامنة |
| 13 | `shopping_list_detail_screen.dart` | 739 | شاشة القائمة |
| 14 | `split_selector.dart` | 725 | تقسيم المصروفات |
| 15 | `realtime_table_handlers.dart` | 544 | Realtime handlers |

---

## 📊 إحصائيات مقارنة

| المقياس | SAWA | متوسط Flutter |
|---------|:----:|:-------------:|
| أسطر الكود | 94,902 | 30,000 |
| عدد الملفات | 475 | 150 |
| الترجمات | 3 لغات | 1-2 لغات |
| الاختبارات | 526 | 100-200 |
| Edge Functions | 10 | 3-5 |
| DB Tables | 26 | 10-15 |
| RLS Policies | 100+ | 20-30 |

---

## 🏗️ هيكل المشروع

```
Beity/
├── lib/                          # 94,902 سطر
│   ├── app/                      # 1,379 سطر
│   │   ├── config/
│   │   ├── router/               # 8 ملفات
│   │   └── theme/                # 3 ملفات
│   ├── core/                     # 30,004 سطر
│   │   ├── services/             # 21 ملف
│   │   ├── local_database/       # 19 ملف (Drift)
│   │   ├── errors/               # 8 ملفات
│   │   ├── localization/         # 12 ملف
│   │   ├── monitoring/           # 5 ملفات
│   │   └── providers/            # 3 ملفات
│   ├── features/                 # 57,202 سطر (17 وحدة)
│   │   ├── auth/                 # 1,887 سطر
│   │   ├── homes/                # 3,380 سطر
│   │   ├── shopping_lists/       # 7,812 سطر
│   │   ├── shopping_mode/        # 3,069 سطر
│   │   ├── categories/           # 2,416 سطر
│   │   ├── invitations/          # 2,869 سطر
│   │   ├── notifications/        # 2,328 سطر
│   │   ├── offline_queue/        # 6,311 سطر
│   │   ├── activity_logs/        # 2,083 سطر
│   │   ├── ai_suggestions/       # 7,559 سطر
│   │   ├── settings/             # 2,519 سطر
│   │   ├── tasks/                # 3,938 سطر
│   │   ├── expenses/             # 5,878 سطر
│   │   ├── inventory/            # 4,004 سطر
│   │   ├── onboarding/           # 1,586 سطر
│   │   ├── home/                 # 2,971 سطر
│   │   └── beta/                 # 888 سطر
│   └── shared/                   # 1,731 سطر
│       └── widgets/
│           └── design_system/
├── test/                         # 19,780 سطر
│   ├── unit/                     # 10,342 سطر
│   ├── widget/                   # 2,265 سطر
│   ├── integration/              # 1,743 سطر
│   ├── features/                 # 4,746 سطر
│   └── security/                 # 429 سطر
├── supabase/
│   ├── functions/                # 2,758 سطر (10 دوال)
│   │   ├── send-notification/
│   │   ├── generate-shopping-suggestions/
│   │   ├── broadcast-notification/
│   │   ├── submit-feedback/
│   │   └── ...
│   └── migrations/               # 5,219 سطر (11 ملف)
├── docs/                         # ~6,000 سطر
│   ├── audits/
│   └── beta/
└── specs/                        # ~500 سطر
```

---

## ✅ ملخص

| الفئة | الأسطر | النسبة |
|-------|:------:|:------:|
| 📱 Frontend (Flutter) | 94,902 | 74.5% |
| 🧪 Tests | 19,780 | 15.5% |
| ⚙️ Backend (Edge Functions) | 2,758 | 2.2% |
| 🗄️ Database (SQL) | 5,219 | 4.1% |
| 📄 Documentation | 9,400 | 3.7% |
| **المجموع** | **~132,000** | **100%** |

---

**مشروع ساوا يحتوي على أكثر من 132,000 سطر كود موزعة بين Frontend و Backend والاختبارات والتوثيق.** 📊
