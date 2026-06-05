# ملخص نظام واجهة المستخدم - تطبيق سوا

> تاريخ التقرير: 2026-05-13
> الإصدار: v0.2.0-preview (معاينة داخلية شاملة)
> الأداة: تدقيق يدوي شامل للكود

---

## 1. ملخص عام للنظام

### ما هو تطبيق سوا؟

سوا هو تطبيق Flutter + Supabase لإدارة المنزل المشترك، يركز بشكل أساسي على **قوائم التسوق المشتركة** بين أفراد المنزل. يستهدف التطبيق العائلات والشركاء والسكن المشترك.

### الهدف الأساسي (MVP)

تم تصميم MVP حول تجربة واحدة مركزية: **إنشاء قائمة تسوق → إضافة منتجات → التسوق معاً في الوقت الفعلي → تتبع النشاطات**.

### الميزات الأساسية (Core MVP)

| الميزة | الحالة | الوصف |
|--------|--------|-------|
| المصادقة (Auth) | مكتملة | تسجيل دخول/خروج/ملف شخصي |
| المنازل (Homes) | مكتملة | إنشاء وإدارة منازل |
| الأعضاء والدعوات | مكتملة | دعوة أعضاء وأدوار |
| قوائم التسوق | مكتملة | إنشاء وتعديل وأرشفة القوائم |
| عناصر التسوق | مكتملة | إضافة/تعديل/حذف/شراء العناصر |
| وضع التسوق | مكتملة | وضع خاص للتسوق في المتجر |
| المزامنة اللحظية | مكتملة | Realtime عبر Supabase |
| سجل النشاطات | مكتملة | تتبع جميع العمليات |
| الإشعارات | مكتملة | إشعارات داخل التطبيق |
| التصنيفات والوحدات | مكتملة | إدارة التصنيفات ووحدات القياس |

### الميزات المبكرة / المؤجلة

| الميزة | الحالة | ملاحظات |
|--------|--------|---------|
| قائمة الانتظار دون اتصال | مكتمل لكن **غير مُفعَّل** | الكود موجود لكن غير مربوط بالـ Providers |
| المخزون (Inventory) | **مُفعَّل** | `enableInventory: true` |
| المصروفات (Expenses) | **مُفعَّل** (تجريبي) | مسارات مسجلة، شاشات متاحة |
| المهام (Tasks) | **مُفعَّل** | `enableTasks: true` |
| الذكاء الاصطناعي | مؤجل | مخفي مع تسمية "قريبًا" |

---

## 2. خريطة التنقل (Navigation Map)

### المسارات المسجلة في GoRouter (36 مسار)

#### المصادقة والملف الشخصي

| المسار | الشاشة | الملف | الوصول | المعاملات | من | إلى |
|--------|--------|-------|--------|-----------|-----|-----|
| `/login` | `LoginScreen` | `lib/features/auth/presentation/screens/login_screen.dart` | غير مصادق | لا يوجد | `/register` | `/` |
| `/register` | `RegisterScreen` | `lib/features/auth/presentation/screens/register_screen.dart` | غير مصادق | لا يوجد | `/login` | `/` |
| `/profile` | `ProfileScreen` | `lib/features/auth/presentation/screens/profile_screen.dart` | مصادق | لا يوجد | Drawer/Home | back |

#### المنازل

| المسار | الشاشة | الملف | المعاملات | من | إلى |
|--------|--------|-------|-----------|-----|-----|
| `/` | `HomeScreen` | `lib/features/home/presentation/screens/home_screen.dart` | لا يوجد | أي مكان | شاشات فرعية |
| `/homes` | `HomesListScreen` | `lib/features/homes/presentation/screens/homes_list_screen.dart` | لا يوجد | Drawer | `/homes/create` |
| `/homes/create` | `CreateHomeScreen` | `lib/features/homes/presentation/screens/create_home_screen.dart` | لا يوجد | HomesList | `/` |
| `/homes/:id/members` | `HomeMembersScreen` | `lib/features/homes/presentation/screens/home_members_screen.dart` | `homeId` | Drawer | `/homes/:id/invitations/send` |
| `/onboarding` | `OnboardingScreen` | `lib/features/homes/presentation/screens/onboarding_screen.dart` | لا يوجد | Redirect | `/homes/create` |

#### الدعوات

| المسار | الشاشة | المعاملات | من | إلى |
|--------|--------|-----------|-----|-----|
| `/invitations` | `InvitationsListScreen` | لا يوجد | Drawer | قبول/رفض |
| `/homes/:id/invitations` | `InvitationsListScreen` | `homeId` | Members | قبول/رفض |
| `/homes/:id/invitations/send` | `SendInvitationScreen` | `homeId`, `homeName` | Members | back |
| `/homes/:id/roles` | `ManageRolesScreen` | `homeId`, `homeName` | Members | تغيير أدوار |

#### التصنيفات والوحدات

| المسار | الشاشة | المعاملات | من | إلى |
|--------|--------|-----------|-----|-----|
| `/categories` | `CategoriesListScreen` | لا يوجد | Drawer | `/categories/create` |
| `/categories/create` | `CreateCategoryScreen` | `homeId` | Categories | back |
| `/units` | `UnitsListScreen` | لا يوجد | Drawer | `/units/create` |
| `/units/create` | `CreateUnitScreen` | لا يوجد | Units | back |

#### قوائم التسوق

| المسار | الشاشة | المعاملات | من | إلى |
|--------|--------|-----------|-----|-----|
| `/shopping-lists` | `ShoppingListsScreen` | `homeId` (extra) | Home | `/shopping-lists/create`, `/shopping-list/:id` |
| `/shopping-lists/create` | `CreateShoppingListScreen` | `homeId` (extra) | Lists | `/shopping-list/:id` |
| `/shopping-list/:id` | `ShoppingListDetailScreen` | `listId` | Lists | add-item, edit-item, summary, shopping-mode |
| `/shopping-list/:id/add-item` | `AddItemScreen` | `listId` | Detail | back |
| `/shopping-list/:id/edit-item/:itemId` | `EditItemScreen` | `listId`, `itemId` | Detail | back |
| `/shopping-list/:id/summary` | `ListSummaryScreen` | `listId` | Detail | back |
| `/shopping-list/:id/quick-add` | `QuickAddScreen` | `listId`, `homeId` | Detail | back |

#### وضع التسوق

| المسار | الشاشة | المعاملات | من | إلى |
|--------|--------|-----------|-----|-----|
| `/shopping-list/:id/shopping-mode` | `ShoppingModeScreen` | `listId`, `homeId`, `listName` | Detail/Home | exit summary |

#### سجل النشاطات

| المسار | الشاشة | المعاملات | من | إلى |
|--------|--------|-----------|-----|-----|
| `/activity` | `ActivityFeedScreen` | `homeId` (extra) | Drawer/Home | تفاصيل |
| `/shopping-list/:id/activity` | `ListActivityScreen` | `homeId`, `listId`, `listName` | Detail | back |
| `/activity/:id` | `ActivityDetailScreen` | `ActivityLogModel` (extra) | Feed | back |

#### الإشعارات

| المسار | الشاشة | المعاملات | من | إلى |
|--------|--------|-----------|-----|-----|
| `/notifications` | `NotificationCenterScreen` | لا يوجد | AppBar | back |
| `/notifications/preferences` | `NotificationPreferencesScreen` | لا يوجد | Drawer | back |

#### المخزون

| المسار | الشاشة | المعاملات | من | إلى |
|--------|--------|-----------|-----|-----|
| `/inventory` | `InventoryScreen` | `homeId` (extra) | Drawer | add, detail |
| `/inventory/add` | `AddInventoryItemScreen` | `homeId` (extra) | Inventory | back |
| `/inventory/:id` | `InventoryItemDetailScreen` | `itemId`, `homeId` | Inventory | edit, delete |
| `/inventory/:id/edit` | `EditInventoryItemScreen` | `itemId`, `homeId` | Detail | back |

#### المهام

| المسار | الشاشة | المعاملات | من | إلى |
|--------|--------|-----------|-----|-----|
| `/home/:id/tasks` | `TaskListScreen` | `homeId` | Drawer/Home | add, detail, archived |
| `/home/:id/tasks/add` | `AddTaskScreen` | `homeId` | Tasks | back |
| `/home/:id/tasks/archived` | `ArchivedTasksScreen` | `homeId` | Tasks | detail |
| `/home/:id/tasks/:taskId` | `TaskDetailScreen` | `taskId`, `homeId` | Tasks | edit (inline) |

#### المصروفات

| المسار | الشاشة | المعاملات | من | إلى |
|--------|--------|-----------|-----|-----|
| `/expenses` | `ExpenseListScreen` | `homeId` (extra) | Drawer/Home | add, detail, summary, balances |
| `/expenses/add` | `AddExpenseScreen` | `homeId` (extra) | List | back |
| `/expenses/:id` | `ExpenseDetailScreen` | `expenseId` | List | back |
| `/expenses/summary` | `ExpenseSummaryScreen` | `homeId` (extra) | List | back |
| `/expenses/balances` | `BalancesScreen` | `homeId` (extra) | List | back |

### شاشات موجودة بدون مسارات مسجلة (يتيمة)

لا توجد شاشات يتيمة حالياً. جميع الشاشات لها مسارات مسجلة.

---

## 3. القائمة السفلية (Bottom Navigation)

الشاشة الرئيسية `HomeScreen` تستخدم `BottomNavigationBar` مع 5 تبويبات:

| التبويب | النص العربي | الأيقونة | الهدف | المحتوى الرئيسي | جاهز MVP؟ |
|---------|------------|----------|-------|-----------------|-----------|
| 0 | الرئيسية | `Icons.home` | `_buildHomeContent()` | تحية، اختيار المنزل، إجراءات سريعة، القائمة النشطة، آخر النشاطات | جيد |
| 1 | القوائم | `Icons.list_alt` | `_buildShoppingListsTab()` | جميع قوائم التسوق + FAB لإنشاء قائمة | جيد |
| 2 | التسوق | `Icons.shopping_cart` | `_buildShoppingTab()` | عرض القوائم للدخول لوضع التسوق | يحتاج تحسين |
| 3 | النشاط | `Icons.history` | `_buildActivityTab()` | آخر 50 نشاط (FutureBuilder مباشر) | يحتاج تحسين |
| 4 | الإعدادات | `Icons.settings` | `_buildSettingsTab()` | الملف الشخصي، المنازل، التصنيفات، الوحدات، المهام، الإشعارات، تسجيل الخروج | جيد |

### ملاحظات على التبويبات

- **تبويب "الرئيسية"**: يركز على القائمة النشطة وإجراءات سريعة (إضافة عنصر، وضع التسوق)
- **تبويب "التسوق"**: يعرض القوائم للدخول لوضع التسوق
- **تبويب "النشاط"**: يستخدم `FutureBuilder` مع استعلام Supabase مباشر بدلاً من Riverpod Provider - عدم اتساق معماري
- **تبويب "الإعدادات"**: يحتوي على الملف الشخصي، المنازل، التصنيفات، الوحدات، إعدادات الإشعارات، تسجيل الخروج. المهام تظهر فقط عند تفعيل `enableTasks`

---

## 4. قائمة الجانبي (Drawer Menu)

ملف: `lib/features/home/presentation/widgets/app_drawer.dart`

### الرئيسية
| # | النص | الأيقونة | الوجهة | الغرض |
|---|------|----------|--------|-------|
| 1 | الرئيسية | `Icons.home` | `/` | العودة للرئيسية |
| 2 | قوائم المشتريات | `Icons.list_alt` | `/shopping-lists` | عرض القوائم |
| 3 | وضع التسوق | `Icons.shopping_bag_outlined` | `/` | دخول وضع التسوق |
| 4 | النشاطات | `Icons.history` | `/activity` | عرض النشاطات |

### إدارة المنزل
| # | النص | الأيقونة | الوجهة | الغرض |
|---|------|----------|--------|-------|
| 5 | إدارة المنازل | `Icons.home_outlined` | `/homes` | إدارة المنازل |
| 6 | إدارة الأعضاء | `Icons.group` | `/homes/:id/members` | إدارة أعضاء المنزل |
| 7 | الدعوات | `Icons.mail` | `/homes/:id/invitations` | عرض دعوات المنزل |
| 8 | إدارة الأدوار | `Icons.admin_panel_settings` | `/homes/:id/roles` | إدارة أدوار الأعضاء |

### المحتوى
| # | النص | الأيقونة | الوجهة | الغرض |
|---|------|----------|--------|-------|
| 9 | التصنيفات | `Icons.category` | `/categories` | إدارة التصنيفات |
| 10 | وحدات القياس | `Icons.straighten` | `/units` | إدارة الوحدات |

### مزايا المنزل
| # | النص | الأيقونة | الوجهة | الغرض | ملاحظات |
|---|------|----------|--------|-------|---------|
| 11 | المخزون | `Icons.inventory_2` | `/inventory` | إدارة المخزون | يظهر فقط عند `enableInventory` |
| 12 | المصروفات | `Icons.receipt_long` | `/expenses` | تتبع المصروفات | يظهر فقط عند `enableExpenses`، badge "تجريبي" |
| 13 | المهام | `Icons.task_alt` | `/home/:id/tasks` | إدارة المهام | يظهر فقط عند `enableTasks` |
| 14 | المساعد الذكي | `Icons.auto_awesome` | معطّل | - | معطّل مع تسمية "قريبًا" |

### الإشعارات
| # | النص | الأيقونة | الوجهة | الغرض |
|---|------|----------|--------|-------|
| 15 | مركز الإشعارات | `Icons.notifications_active` | `/notifications` | عرض الإشعارات |
| 16 | إعدادات الإشعارات | `Icons.notifications` | `/notifications/preferences` | تفضيلات الإشعارات |

### الحساب
| # | النص | الأيقونة | الوجهة | الغرض |
|---|------|----------|--------|-------|
| 17 | الملف الشخصي | `Icons.person` | `/profile` | عرض الملف الشخصي |
| 18 | إرسال ملاحظات | `Icons.feedback_outlined` | FeedbackBottomSheet | ملاحظات بيتا |
| 19 | تسجيل الخروج | `Icons.logout` | `/login` | تسجيل خروج |

### ملاحظات مهمة على القائمة الجانبية

- **منظمة بأقسام**: الرئيسية، إدارة المنزل، المحتوى، مزايا المنزل، الإشعارات، الحساب
- **المصروفات**: تظهر مع badge "تجريبي" فقط عند `enableExpenses: true`
- **المهام والمخزون**: تظهر فقط عند تفعيل أعلام الميزات (`FeatureFlags`)
- **الذكاء الاصطناعي**: معطّل مع تسمية "قريبًا" ولا يمكن النقر عليه
- **القائمة موجودة في**: `HomeScreen`, `InventoryScreen`, `TaskListScreen`, `HomeMembersScreen`, `ArchivedTasksScreen`

---

## 5. جميع الصفحات (Screens Inventory)

### 5.1 شاشة تسجيل الدخول (LoginScreen)

- **الملف**: `lib/features/auth/presentation/screens/login_screen.dart`
- **الغرض**: تسجيل الدخول بالبريد الإلكتروني وكلمة المرور
- **الهدف الرئيسي**: المصادقة
- **البيانات المعروضة**: شعار "سوا"، حقول الإدخال
- **الـ Providers**: `authNotifierProvider`
- **حالة التحميل**: CircularProgressIndicator على الزر
- **حالة فارغة**: لا تنطبق
- **حالة الخطأ**: SnackBar أحمر مع رسائل عربية
- **بدون اتصال**: لا يوجد
- **المزامنة اللحظية**: لا يوجد
- **RTL**: نعم - حقل البريد الإلكتروني LTR، الباقي RTL
- **تقييم الجودة**: جيد

### 5.2 شاشة إنشاء الحساب (RegisterScreen)

- **الملف**: `lib/features/auth/presentation/screens/register_screen.dart`
- **الغرض**: إنشاء حساب جديد
- **الحقول**: الاسم الكامل، البريد الإلكتروني، كلمة المرور، تأكيد كلمة المرور
- **التحقق**: regex للبريد، 8 أحرف لكلمة المرور، تطابق كلمة المرور
- **RTL**: نعم
- **تقييم الجودة**: جيد

### 5.3 الشاشة الرئيسية (HomeScreen)

- **الملف**: `lib/features/home/presentation/screens/home_screen.dart` (1068 سطر)
- **الغرض**: الشاشة الرئيسية - مركز التطبيق
- **الهدف**: عرض نظرة عامة على المنزل والوصول السريع
- **البيانات**: تحية، قائمة منزل نشطة، إجراءات سريعة، قوائم تسوق، نشاطات
- **الـ Providers**: `hasHomesProvider`, `userHomesProvider`, `activeHomeIdProvider`, `shoppingListsProvider`, `shoppingItemsProvider`
- **حالة التحميل**: CircularProgressIndicator
- **حالة فارغة**: "لا توجد قوائم مشتريات" + زر إنشاء
- **حالة الخطأ**: "خطأ في تحميل المنازل" + إعادة المحاولة
- **المزامنة اللحظية**: لا بشكل مباشر (عبر Providers)
- **RTL**: نعم
- **تقييم الجودة**: يحتاج تحسين - الشاشة مزدحمة

### 5.4 شاشة الملف الشخصي (ProfileScreen)

- **الملف**: `lib/features/auth/presentation/screens/profile_screen.dart`
- **الغرض**: عرض وتعديل الملف الشخصي
- **الوضعان**: عرض (قراءة فقط) وتعديل
- **الحقول**: الاسم الكامل، رقم الهاتف (اختياري)
- **RTL**: نعم
- **تقييم الجودة**: جيد

### 5.5 شاشة قائمة المنازل (HomesListScreen)

- **الملف**: `lib/features/homes/presentation/screens/homes_list_screen.dart`
- **الغرض**: عرض وإدارة المنازل
- **حالة فارغة**: "لا توجد منازل" + "أنشئ منزلك الأول لتبدأ"
- **RTL**: نعم
- **تقييم الجودة**: جيد

### 5.6 شاشة إنشاء منزل (CreateHomeScreen)

- **الملف**: `lib/features/homes/presentation/screens/create_home_screen.dart`
- **الغرض**: إنشاء منزل جديد
- **الحقول**: اسم المنزل (مطلوب)، نوع المنزل (ChoiceChip)
- **RTL**: نعم
- **تقييم الجودة**: جيد

### 5.7 شاشة Onboarding (OnboardingScreen)

- **الملف**: `lib/features/homes/presentation/screens/onboarding_screen.dart`
- **الغرض**: شاشة ترحيب للمستخدم الجديد
- **الخيارات**: إنشاء منزل جديد، الانضمام لمنزل
- **ملاحظة**: زر "الانضمام بالرمز" هو stub غير مكتمل
- **RTL**: نعم
- **تقييم الجودة**: جزئي - الانضمام بالرمز غير مفعل

### 5.8 شاشة أعضاء المنزل (HomeMembersScreen)

- **الملف**: `lib/features/homes/presentation/screens/home_members_screen.dart`
- **الغرض**: عرض أعضاء المنزل والدعوات المعلقة
- **القائمة الجانبية**: نعم (AppDrawer)
- **حالة فارغة**: "لا يوجد أعضاء" + "دعوة عضو"
- **RTL**: نعم
- **تقييم الجودة**: جيد

### 5.9 شاشة الدعوات (InvitationsListScreen)

- **الملف**: `lib/features/invitations/presentation/screens/invitations_list_screen.dart`
- **الغرض**: عرض الدعوات (مستخدم أو منزل)
- **الحالات**: معلقة، مقبولة، منتهية، ملغاة
- **RTL**: نعم
- **تقييم الجودة**: جيد

### 5.10 شاشة إرسال دعوة (SendInvitationScreen)

- **الملف**: `lib/features/invitations/presentation/screens/send_invitation_screen.dart`
- **الغرض**: إرسال دعوة لعضو جديد
- **الحقول**: البريد الإلكتروني (مطلوب)، الدور (مطلوب)
- **RTL**: نعم
- **تقييم الجودة**: جيد

### 5.11 شاشة إدارة الأدوار (ManageRolesScreen)

- **الملف**: `lib/features/invitations/presentation/screens/manage_roles_screen.dart`
- **الغرض**: تغيير أدوار الأعضاء
- **RTL**: نعم
- **تقييم الجودة**: جيد

### 5.12 شاشة التصنيفات (CategoriesListScreen)

- **الملف**: `lib/features/categories/presentation/screens/categories_list_screen.dart`
- **الغرض**: عرض وإدارة التصنيفات
- **الفلاتر**: الكل، تسوق، مخزون، مصروفات
- **RTL**: نعم
- **تقييم الجودة**: جيد

### 5.13 شاشة إنشاء تصنيف (CreateCategoryScreen)

- **الملف**: `lib/features/categories/presentation/screens/create_category_screen.dart`
- **الغرض**: إنشاء تصنيف جديد
- **الحقول**: اسم التصنيف، النوع، الأيقونة (اختياري)، اللون (اختياري)
- **RTL**: نعم
- **تقييم الجودة**: جيد

### 5.14 شاشة وحدات القياس (UnitsListScreen)

- **الملف**: `lib/features/categories/presentation/screens/units_list_screen.dart`
- **الغرض**: عرض وإدارة وحدات القياس
- **الفلاتر**: الكل، وزن، حجم، عدد، طول
- **RTL**: نعم
- **تقييم الجودة**: جيد

### 5.15 شاشة قوائم التسوق (ShoppingListsScreen)

- **الملف**: `lib/features/shopping_lists/presentation/screens/shopping_lists_screen.dart`
- **الغرض**: عرض قوائم التسوق (نشطة ومؤرشفة)
- **التبويبات**: النشطة، المؤرشفة
- **RTL**: نعم
- **تقييم الجودة**: جيد

### 5.16 شاشة إنشاء قائمة تسوق (CreateShoppingListScreen)

- **الملف**: `lib/features/shopping_lists/presentation/screens/create_shopping_list_screen.dart`
- **الغرض**: إنشاء قائمة تسوق جديدة
- **الحقول**: أيقونة (اختيار من 18)، اسم القائمة، الوصف (اختياري)
- **ملاحظة**: الوصف لا يُمرر للاستخدام - bug
- **RTL**: نعم
- **تقييم الجودة**: جزئي - الوصف لا يُحفظ

### 5.17 شاشة تفاصيل قائمة التسوق (ShoppingListDetailScreen)

- **الملف**: `lib/features/shopping_lists/presentation/screens/shopping_list_detail_screen.dart`
- **الغرض**: عرض وإدارة عناصر القائمة
- **الميزات**: إضافة/تعديل/حذف/شراء العناصر، فلترة بالتصنيف، مزامنة لحظية
- **RTL**: نعم
- **تقييم الجودة**: جيد - هذه أهم شاشة في التطبيق

### 5.18 شاشة إضافة منتج (AddItemScreen)

- **الملف**: `lib/features/shopping_lists/presentation/screens/add_item_screen.dart`
- **الغرض**: إضافة منتج لقائمة التسوق
- **الحقول**: اسم المنتج (مطلوب)، الكمية، الوحدة، السعر، التصنيف، ملاحظات
- **الميزات**: اقتراحات تلقائية، كشف التكرار
- **RTL**: نعم
- **تقييم الجودة**: جيد جداً

### 5.19 شاشة تعديل منتج (EditItemScreen)

- **الملف**: `lib/features/shopping_lists/presentation/screens/edit_item_screen.dart`
- **الغرض**: تعديل منتج موجود
- **RTL**: نعم
- **تقييم الجودة**: جيد

### 5.20 شاشة ملخص القائمة (ListSummaryScreen)

- **الملف**: `lib/features/shopping_lists/presentation/screens/list_summary_screen.dart`
- **الغرض**: عرض ملخص القائمة (للشراء / تم شراؤها)
- **RTL**: نعم
- **تقييم الجودة**: جيد

### 5.21 شاشة الإضافة السريعة (QuickAddScreen)

- **الملف**: `lib/features/shopping_lists/presentation/screens/quick_add_screen.dart`
- **الغرض**: إضافة سريعة من منتجات محفوظة سابقاً
- **RTL**: نعم
- **تقييم الجودة**: جيد

### 5.22 شاشة وضع التسوق (ShoppingModeScreen)

- **الملف**: `lib/features/shopping_mode/presentation/screens/shopping_mode_screen.dart`
- **الغرض**: وضع خاص للتسوق في المتجر
- **الميزات**: تجميع بالتصنيف، بحث، إضافة سريعة، شريط تقدم
- **问题**: شريط التقدم بالإنجليزية "X of Y"
- **RTL**: جزئي
- **تقييم الجودة**: جيد مع مشاكل ترجمة

### 5.23 شاشة سجل النشاطات (ActivityFeedScreen)

- **الملف**: `lib/features/activity_logs/presentation/screens/activity_feed_screen.dart`
- **الغرض**: عرض سجل نشاطات المنزل
- **RTL**: نعم
- **تقييم الجودة**: جيد

### 5.24 شاشة نشاطات القائمة (ListActivityScreen)

- **الملف**: `lib/features/activity_logs/presentation/screens/list_activity_screen.dart`
- **الغرض**: نشاطات متعلقة بقائمة معينة
- **RTL**: نعم
- **تقييم الجودة**: جيد

### 5.25 شاشة تفاصيل النشاط (ActivityDetailScreen)

- **الملف**: `lib/features/activity_logs/presentation/screens/activity_detail_screen.dart`
- **الغرض**: تفاصيل نشاط محدد
- **ملاحظة**: StatelessWidget بدون Riverpod - عدم اتساق
- **RTL**: نعم
- **تقييم الجودة**: جيد

### 5.26 شاشة مركز الإشعارات (NotificationCenterScreen)

- **الملف**: `lib/features/notifications/presentation/screens/notification_center_screen.dart`
- **الغرض**: عرض الإشعارات
- **问题**: وقت النشاط بالإنجليزية ("Just now", "Xm ago")
- **RTL**: جزئي
- **تقييم الجودة**: جزئي - مشكلة ترجمة الوقت

### 5.27 شاشة إعدادات الإشعارات (NotificationPreferencesScreen)

- **الملف**: `lib/features/notifications/presentation/screens/notification_preferences_screen.dart`
- **الغرض**: إدارة تفضيلات الإشعارات
- **RTL**: نعم
- **تقييم الجودة**: جيد

### 5.28 شاشة المخزون (InventoryScreen)

- **الملف**: `lib/features/inventory/presentation/screens/inventory_screen.dart`
- **الغرض**: عرض وإدارة المخزون
- **القائمة الجانبية**: نعم (AppDrawer)
- **RTL**: نعم
- **تقييم الجودة**: جيد

### 5.29 شاشة إضافة منتج مخزون (AddInventoryItemScreen)

- **الملف**: `lib/features/inventory/presentation/screens/add_inventory_item_screen.dart`
- **الغرض**: إضافة منتج للمخزون
- **RTL**: نعم
- **تقييم الجودة**: جيد

### 5.30 شاشة تفاصيل منتج المخزون (InventoryItemDetailScreen)

- **الملف**: `lib/features/inventory/presentation/screens/inventory_item_detail_screen.dart`
- **الغرض**: عرض تفاصيل منتج المخزون
- **RTL**: نعم
- **تقييم الجودة**: جيد

### 5.31 شاشة تعديل منتج المخزون (EditInventoryItemScreen)

- **الملف**: `lib/features/inventory/presentation/screens/edit_inventory_item_screen.dart`
- **الغرض**: تعديل منتج مخزون
- **RTL**: نعم
- **تقييم الجودة**: جيد

### 5.32 شاشة قائمة المهام (TaskListScreen)

- **الملف**: `lib/features/tasks/presentation/screens/task_list_screen.dart`
- **الغرض**: عرض المهام
- **التبويبات**: مهامي، كل المهام
- **الفرز**: تاريخ الاستحقاق، تاريخ الإنشاء
- **القائمة الجانبية**: نعم (AppDrawer)
- **RTL**: نعم
- **تقييم الجودة**: جيد

### 5.33 شاشة إضافة مهمة (AddTaskScreen)

- **الملف**: `lib/features/tasks/presentation/screens/add_task_screen.dart`
- **الغرض**: إضافة مهمة جديدة
- **الحقول**: العنوان، الوصف، تاريخ الاستحقاق، المسند إليه، التكرار
- **RTL**: نعم
- **تقييم الجودة**: جيد

### 5.34 شاشة تفاصيل المهمة (TaskDetailScreen)

- **الملف**: `lib/features/tasks/presentation/screens/task_detail_screen.dart`
- **الغرض**: عرض وتعديل تفاصيل المهمة
- **الوضعان**: عرض وتعديل (inline)
- **RTL**: نعم
- **تقييم الجودة**: جيد

### 5.35 شاشة المهام المؤرشفة (ArchivedTasksScreen)

- **الملف**: `lib/features/tasks/presentation/screens/archived_tasks_screen.dart`
- **الغرض**: عرض المهام المؤرشفة
- **القائمة الجانبية**: نعم (AppDrawer)
- **RTL**: نعم
- **تقييم الجودة**: جيد

### 5.36 شاشات المصروفات

| الشاشة | الملف | الغرض | المسار |
|--------|-------|-------|--------|
| `ExpenseListScreen` | `lib/features/expenses/presentation/screens/expense_list_screen.dart` | قائمة المصروفات | `/expenses` |
| `AddExpenseScreen` | `lib/features/expenses/presentation/screens/add_expense_screen.dart` | إضافة مصروف | `/expenses/add` |
| `ExpenseDetailScreen` | `lib/features/expenses/presentation/screens/expense_detail_screen.dart` | تفاصيل مصروف | `/expenses/:id` |
| `ExpenseSummaryScreen` | `lib/features/expenses/presentation/screens/expense_summary_screen.dart` | ملخص المصروفات | `/expenses/summary` |
| `BalancesScreen` | `lib/features/expenses/presentation/screens/balances_screen.dart` | الأرصدة | `/expenses/balances` |

---

## 6. الأزرار (Buttons Inventory)

### أزرار المصادقة

| الزر | الشاشة | النوع | الإجراء | تأكيد؟ | معالجة خطأ | واضح؟ |
|------|--------|-------|---------|--------|------------|-------|
| تسجيل الدخول | LoginScreen | primary | مصادقة | لا | SnackBar أحمر | نعم |
| إنشاء حساب | RegisterScreen | primary | تسجيل | لا | SnackBar أحمر | نعم |
| حفظ (الملف الشخصي) | ProfileScreen | primary | تحديث الملف | لا | SnackBar أحمر | نعم |
| إلغاء (الملف الشخصي) | ProfileScreen | secondary | إلغاء التعديل | لا | - | نعم |

### أزرار المنازل

| الزر | الشاشة | النوع | الإجراء | تأكيد؟ |
|------|--------|-------|---------|--------|
| إنشاء المنزل | CreateHomeScreen | primary | إنشاء منزل | لا |
| إنشاء منزل جديد | OnboardingScreen | primary | الذهاب لإنشاء منزل | لا |
| الانضمام إلى منزل | OnboardingScreen | secondary | فتح حوار الانضمام | لا |

### أزرار قوائم التسوق

| الزر | الشاشة | النوع | الإجراء | تأكيد؟ |
|------|--------|-------|---------|--------|
| + (FAB) | ShoppingListsScreen | FAB | إنشاء قائمة | لا |
| إنشاء القائمة | CreateShoppingListScreen | primary | إنشاء | لا |
| إضافة منتج (FAB) | ShoppingListDetailScreen | FAB | إضافة منتج | لا |
| حفظ | AddItemScreen | primary | إضافة المنتج | لا (إلا عند تكرار) |
| حفظ التعديلات | EditItemScreen | primary | حفظ | لا |
| وضع التسوق | ActiveListCard | secondary | دخول وضع التسوق | لا |
| افتح القائمة | ActiveListCard | secondary | فتح القائمة | لا |
| شراء (checkbox) | ShoppingItemTileWidget | icon | تبديل حالة الشراء | لا |
| حذف (swipe) | ShoppingItemTileWidget | destructive | حذف المنتج | نعم (dialog) |
| إعادة تسمية | ShoppingListCardWidget | popup | إعادة تسمية | لا |
| أرشفة | ShoppingListCardWidget | popup | أرشفة القائمة | لا |
| حذف | ShoppingListCardWidget | popup | حذف القائمة | نعم (dialog) |

### أزرار وضع التسوق

| الزر | الشاشة | النوع | الإجراء |
|------|--------|-------|---------|
| شراء دائري | ShoppingItemCard | icon | تبديل حالة الشراء |
| + إضافة سريعة | ShoppingModeScreen | FAB | فتح نافذة إضافة |
| إنهاء التسوق | ShoppingModeScreen | icon (AppBar) | عرض ملخص الخروج |
| العودة إلى القائمة | ShoppingExitSummary | primary | الخروج من وضع التسوق |

### أزرار المهام

| الزر | الشاشة | النوع | الإجراء | تأكيد؟ |
|------|--------|-------|---------|--------|
| + (FAB) | TaskListScreen | FAB | إضافة مهمة | لا |
| حفظ | AddTaskScreen | primary | إنشاء مهمة | لا |
| حفظ | TaskDetailScreen (edit) | primary | حفظ التعديل | لا |
| إلغاء | TaskDetailScreen (edit) | secondary | إلغاء التعديل | لا |
| حذف | TaskDetailScreen | popup | حذف المهمة | نعم (dialog) |
| إكمال (checkbox) | TaskCard | icon | تبديل الإكمال | لا |

### أزرار المخزون

| الزر | الشاشة | النوع | الإجراء | تأكيد؟ |
|------|--------|-------|---------|--------|
| + (FAB) | InventoryScreen | FAB | إضافة منتج | لا |
| إضافة إلى المخزون | AddInventoryItemScreen | primary | إضافة | لا |
| حفظ التعديلات | EditInventoryItemScreen | primary | حفظ | لا |
| +/- (كمية) | InventoryItemTile | icon | تعديل الكمية | لا |
| حذف (swipe) | InventoryItemTile | destructive | حذف | نعم (dialog) |

### أزرار عامة

| الزر | الشاشة | النوع | الإجراء |
|------|--------|-------|---------|
| إعادة المحاولة | عدة شاشات | secondary | إعادة تحميل |
| تسجيل الخروج | Drawer/Settings | destructive | تسجيل خروج |
| إرسال الملاحظات | FeedbackBottomSheet | primary | إرسال ملاحظات |
| تحديد الكل كمقروء | NotificationCenter | text | تحديد الكل |
| إرسال الدعوة | SendInvitationScreen | primary | إرسال دعوة |

---

## 7. الكروت (Cards Inventory)

### بطاقة القائمة النشطة (ActiveListCard)

- **الشاشة**: الرئيسية (تبويب الرئيسية)
- **الغرض**: عرض القائمة النشطة حالياً مع التقدم
- **البيانات**: اسم القائمة، عدد العناصر، المتبقية، تم شراؤها، نسبة التقدم
- **الإجراءات**: افتح القائمة، وضع التسوق
- **حالة فارغة**: لا تعرض (الشاشة الرئيسية تعرض بدلاً منها زر إنشاء)
- **تصميم**: جيد

### بطاقة قائمة التسوق (ShoppingListCardWidget)

- **الشاشة**: قوائم التسوق
- **الغرض**: عرض قائمة تسوق واحدة
- **البيانات**: اسم، وصف، أيقونة، تاريخ، حالة الأرشفة
- **الإجراءات**: onTap، PopupMenu (إعادة تسمية، أرشفة، حذف)
- **تصميم**: جيد

### بطاقة عنصر التسوق (ShoppingItemTileWidget)

- **الشاشة**: تفاصيل قائمة التسوق
- **الغرض**: عرض عنصر تسوق واحد
- **البيانات**: اسم، كمية + وحدة، ملاحظات، حالة الشراء، سعر
- **الإجراءات**: onTap، checkbox شراء، swipe لتعديل/حذف
- **مؤشر المزامنة**: PendingSyncIndicator
- **تصميم**: جيد جداً

### بطاقة المنزل (HomeCardWidget)

- **الشاشة**: قائمة المنازل
- **الغرض**: عرض منزل واحد
- **البيانات**: اسم، نوع، أيقونة، badge "نشط"
- **الإجراءات**: onTap
- **تصميم**: جيد

### بطاقة العضو (MemberCardWidget)

- **الشاشة**: أعضاء المنزل
- **الغرض**: عرض عضو واحد
- **البيانات**: اسم، دور، تاريخ الانضمام
- **الإجراءات**: لا (معلوماتي فقط)
- **تصميم**: جيد

### بطاقة الدعوة (InvitationCardWidget)

- **الشاشة**: الدعوات
- **الغرض**: عرض دعوة واحدة
- **البيانات**: بريد، دور، حالة (معلقة/مقبولة/منتهية/ملغاة)
- **الإجراءات**: قبول، رفض، إلغاء (حسب الدور والحالة)
- **تصميم**: جيد

### بطاقة الإشعار (NotificationTileWidget)

- **الشاشة**: مركز الإشعارات
- **الغرض**: عرض إشعار واحد
- **البيانات**: أيقونة، عنوان، نص، وقت، مؤشر غير مقروء
- **問題**: الوقت بالإنجليزية
- **تصميم**: جزئي

### بطاقة النشاط (ActivityLogTileWidget)

- **الشاشة**: سجل النشاطات
- **الغرض**: عرض نشاط واحد
- **البيانات**: اسم الفاعل، وصف الإجراء، وقت (عربي)، أيقونة ملونة
- **تصميم**: جيد

### بطاقة التصنيف (CategoryCardWidget)

- **الشاشة**: التصنيفات
- **الغرض**: عرض تصنيف واحد
- **البيانات**: اسم، أيقونة، نوع، لون
- **الإجراءات**: حذف (للمخصصات فقط)
- **ملاحظة**: زر التعديل stub (فارغ)
- **تصميم**: جيد

### بطاقة الوحدة (UnitCardWidget)

- **الشاشة**: وحدات القياس
- **الغرض**: عرض وحدة واحدة
- **البيانات**: اسم، رمز، نوع
- **الإجراءات**: حذف (للمخصصات فقط)
- **ملاحظة**: زر التعديل stub (فارغ)
- **تصميم**: جيد

### بطاقة المهمة (TaskCard)

- **الشاشة**: قائمة المهام
- **الغرض**: عرض مهمة واحدة
- **البيانات**: عنوان، وصف، مسند إليه، تاريخ استحقاق، تكرار
- **الإجراءات**: onTap، checkbox إكمال
- **الألوان**: أحمر (متأخرة)، برتقالي (اليوم)، رمادي (مستقبل)
- **تصميم**: جيد

### بطاقة المصروف (ExpenseCard)

- **الشاشة**: قائمة المصروفات (بدون مسار)
- **الغرض**: عرض مصروف واحد
- **البيانات**: وصف، تاريخ، مبلغ، حالة إلغاء
- **تصميم**: جيد

### بطاقة الرصيد (BalanceCard)

- **الشاشة**: الأرصدة (بدون مسار)
- **الغرض**: عرض علاقة دين بين عضوين
- **البيانات**: المدين، الدائن، المبلغ
- **تصميم**: جيد

---

## 8. النماذج (Forms Inventory)

### نموذج تسجيل الدخول

- **الملف**: `lib/features/auth/presentation/screens/login_screen.dart`
- **الحقول**: البريد الإلكتروني (مطلوب)، كلمة المرور (مطلوب)
- **التحقق**: regex للبريد، فراغ لكلمة المرور
- **زر الإرسال**: تسجيل الدخول
- **زر الإلغاء**: لا يوجد (رابط لتسجيل)
- **معالجة الخطأ**: SnackBar أحمر
- **نجاح**: الذهاب للرئيسية

### نموذج إنشاء الحساب

- **الملف**: `lib/features/auth/presentation/screens/register_screen.dart`
- **الحقول**: الاسم (مطلوب)، البريد (مطلوب)، كلمة المرور (مطلوب)، التأكيد (مطلوب)
- **التحقق**: regex، 8 أحرف، تطابق
- **زر الإرسال**: إنشاء حساب
- **نجاح**: الذهاب للرئيسية

### نموذج إنشاء منزل

- **الملف**: `lib/features/homes/presentation/screens/create_home_screen.dart`
- **الحقول**: اسم المنزل (مطلوب، max 100)، نوع المنزل (ChoiceChip)
- **زر الإرسال**: إنشاء المنزل
- **نجاح**: الذهاب للرئيسية

### نموذج إرسال دعوة

- **الملف**: `lib/features/invitations/presentation/screens/send_invitation_screen.dart`
- **الحقول**: البريد الإلكتروني (مطلوب)، الدور (مطلوب)
- **زر الإرسال**: إرسال الدعوة
- **نجاح**: SnackBar + back

### نموذج إنشاء قائمة تسوق

- **الملف**: `lib/features/shopping_lists/presentation/screens/create_shopping_list_screen.dart`
- **الحقول**: أيقونة (اختيار من 18)، اسم القائمة (مطلوب)
- **問題**: الوصف لا يُمرر للاستخدام
- **زر الإرسال**: إنشاء القائمة
- **نجاح**: الذهاب للقائمة

### نموذج إضافة منتج

- **الملف**: `lib/features/shopping_lists/presentation/screens/add_item_screen.dart`
- **الحقول**: اسم المنتج (مطلوب + اقتراحات)، الكمية (مطلوب)، الوحدة، السعر، التصنيف، ملاحظات
- **التحقق**: اسم فارغ، كمية > 0
- **الميزات**: اقتراحات تلقائية، كشف تكرار
- **زر الإرسال**: إضافة المنتج
- **نجاح**: back

### نموذج تعديل منتج

- **الملف**: `lib/features/shopping_lists/presentation/screens/edit_item_screen.dart`
- **الحقول**: نفس نموذج الإضافة
- **زر الإرسال**: حفظ التعديلات

### نموذج إنشاء تصنيف

- **الملف**: `lib/features/categories/presentation/screens/create_category_screen.dart`
- **الحقول**: اسم (مطلوب)، نوع (مطلوب)، أيقونة (اختياري)، لون (اختياري)

### نموذج إنشاء وحدة

- **الملف**: `lib/features/categories/presentation/screens/create_unit_screen.dart`
- **الحقول**: اسم (مطلوب)، رمز (مطلوب)، نوع (مطلوب)

### نموذج إضافة منتج مخزون

- **الملف**: `lib/features/inventory/presentation/screens/add_inventory_item_screen.dart`
- **الحقول**: اسم (مطلوب)، كمية (مطلوب)، تصنيف (اختياري)، وحدة (اختياري)، حد أدنى (اختياري)، ملاحظات (اختياري)

### نموذج إضافة مهمة

- **الملف**: `lib/features/tasks/presentation/screens/add_task_screen.dart`
- **الحقول**: عنوان (مطلوب، max 200)، وصف (اختياري، max 2000)، تاريخ استحقاق (اختياري)، مسند إليه (اختياري)، تكرار (اختياري)

### نموذج إضافة مصروف

- **الملف**: `lib/features/expenses/presentation/screens/add_expense_screen.dart`
- **الحقول**: مبلغ (مطلوب)، وصف (مطلوب)، تاريخ (افتراضي: اليوم)
- **TODO**: محدد التصنيف، محدد عنصر القائمة

### نموذج تسوية دين (SettlementForm)

- **الملف**: `lib/features/expenses/presentation/widgets/settlement_form.dart`
- **الحقول**: مبلغ (مطلوب)، طريقة الدفع (مطلوب)، تاريخ (افتراضي: اليوم)

### الحوارات (Dialogs)

| الحوار | الشاشة | الغرض |
|--------|--------|-------|
| الانضمام بالرمز | OnboardingScreen | stub غير مكتمل |
| إعادة تسمية القائمة | ShoppingListsScreen | تعديل اسم القائمة |
| حذف القائمة | ShoppingListsScreen | تأكيد الحذف |
| منتج مكرر | AddItemScreen | تأكيد إضافة مكرر |
| حذف منتج المخزون | InventoryItemDetailScreen | تأكيد الحذف |
| حذف مصروف | ExpenseDetailScreen | تأكيد الحذف |
| فلترة المصروفات | ExpenseListScreen | فلترة بالتاريخ |
| حذف مهمة | TaskDetailScreen | تأكيد الحذف |
| ترحيب بيتا | BetaWelcomeDialog | شرح التطبيق |
| استبيان الرضا | SatisfactionSurveyDialog | تقييم 1-5 |

### الأوراق السفلية (Bottom Sheets)

| الورق | الشاشة | الغرض |
|--------|--------|-------|
| FeedbackBottomSheet | Drawer | إرسال ملاحظات |
| QuickAddItemSheet | HomeScreen | إضافة عنصر سريع |

---

## 9. حالات النظام (UI States)

### المصادقة

| الحالة | التنفيذ | النص العربي |
|--------|---------|------------|
| تحميل | CircularProgressIndicator على الزر | - |
| خطأ | SnackBar أحمر | "حدث خطأ، يرجى المحاولة مرة أخرى" |
| نجاح | تنقل للرئيسية | - |
| فارغة | لا تنطبق | - |

### المنازل

| الحالة | التنفيذ | النص العربي |
|--------|---------|------------|
| تحميل | CircularProgressIndicator | - |
| فارغة | أيقونة + نص + زر | "لا توجد منازل" / "أنشئ منزلك الأول لتبدأ" |
| خطأ | أيقونة + نص + زر إعادة المحاولة | "خطأ في تحميل المنازل" |

### قوائم التسوق

| الحالة | التنفيذ | النص العربي |
|--------|---------|------------|
| تحميل | CircularProgressIndicator | - |
| فارغة | أيقونة + نص + زر | "لا توجد قوائم" / "أنشئ قائمتك الأولى" |
| خطأ | أيقونة + نص + زر إعادة المحاولة | رسائل خطأ عربية |

### عناصر التسوق

| الحالة | التنفيذ | النص العربي |
|--------|---------|------------|
| تحميل | CircularProgressIndicator | - |
| فارغة | أيقونة + نص | "القائمة فارغة" / "اضغط على + لإضافة منتجات" |
| خطأ | SnackBar | رسائل خطأ |

### وضع التسوق

| الحالة | التنفيذ | النص العربي |
|--------|---------|------------|
| تحميل | CircularProgressIndicator | - |
| فارغة | أيقونة + نص | "لا توجد عناصر" |
| اتصال | ConnectionStatusWidget | "غير متصل" / "جارٍ المزامنة..." |
| حضور | PresenceIndicatorWidget | "المتواجدون:" |

### سجل النشاطات

| الحالة | التنفيذ | النص العربي |
|--------|---------|------------|
| تحميل | CircularProgressIndicator | - |
| فارغة | أيقونة + نص | "لا توجد نشاطات" / "لا توجد نشاطات بعد" |

### الإشعارات

| الحالة | التنفيذ | النص العربي |
|--------|---------|------------|
| تحميل | CircularProgressIndicator | - |
| فارغة | أيقونة + نص | "لا توجد إشعارات بعد" / "ستظهر هنا الإشعارات عندما يقوم أحد بإضافة عناصر أو دعوتك" |

### المهام

| الحالة | التنفيذ | النص العربي |
|--------|---------|------------|
| تحميل | CircularProgressIndicator | - |
| فارغة | أيقونة + نص | "لا توجد مهام" / "اضغط على + لإضافة مهمة جديدة" |
| خطأ | أيقونة + نص + زر إعادة المحاولة | "خطأ" |

### المخزون

| الحالة | التنفيذ | النص العربي |
|--------|---------|------------|
| تحميل | CircularProgressIndicator | - |
| فارغة | أيقونة + نص | "المخزون فارغ" / "أضف المنتجات التي لديك في المنزل لتتبعها بسهولة" |

### الملف الشخصي

| الحالة | التنفيذ | النص العربي |
|--------|---------|------------|
| تحميل | CircularProgressIndicator | - |
| نجاح | SnackBar أخضر | "تم تحديث الملف الشخصي بنجاح" |
| خطأ | SnackBar أحمر | "فشل تحديث الملف الشخصي" |

---

## 10. تجربة الصفحة الرئيسية (Home Screen Analysis)

### التخطيط الحالي

الشاشة الرئيسية مقسمة إلى 5 تبويبات عبر BottomNavigationBar. تبويب "الرئيسية" (index 0) هو الأكثر تعقيداً ويحتوي على:

1. **رأس SliverAppBar**: تحية (صباح الخير/مساء الخير)، dropdown اختيار المنزل، أيقونة الإشعارات، أيقونة الملف الشخصي
2. **إجراءات سريعة**: 3 بطاقات (إضافة عنصر، المهام، وضع التسوق)
3. **القائمة النشطة**: بطاقة تقدم مع إحصائيات
4. **قوائم المشتريات**: قسم مع "عرض الكل"
5. **آخر النشاطات**: آخر 5 نشاطات

### تحليل العناصر

| العنصر | موجود؟ | ملاحظات |
|--------|--------|---------|
| رأس مع تحية | نعم | صباح/مساء الخير |
| اختيار المنزل | نعم | HomeSelectorDropdown |
| جرس الإشعارات | نعم | NotificationBadgeWidget |
| الملف الشخصي | نعم | أيقونة شخص |
| إجراءات سريعة | نعم | 3 بطاقات |
| القائمة النشطة | نعم | ActiveListCard |
| قوائم حديثة | نعم | RecentListsWidget |
| آخر نشاطات | نعم | RecentActivityWidget |
| شريط بحث | لا | غير موجود |
| إحصائيات منزل | لا | غير موجود |
| تذكيرات/مهام | لا | غير موجود |

### هل الصفحة بسيطة أم مزدحمة؟

**مزدحمة نوعاً ما**. تبويب "الرئيسية" يحتوي على الكثير من العناصر:
- رأس + 3 إجراءات سريعة + بطاقة قائمة نشطة + قسم قوائم + قسم نشاطات
- هذا كثير للمستخدم الجديد

### هل تطابق هدف MVP؟

**جزئياً**. الشاشة تركز على قوائم التسوق (صحيح) لكنها تحاول عرض الكثير في آن واحد.

### تحسينات مقترحة

1. تبسيط الرأس: إزالة SliverAppBar المعقد واستخدام AppBar بسيط
2. دمج الإجراءات السريعة في مكان واحد
3. إضافة شريط بحث سريع
4. تقليل عدد الأقسام المعروضة في آن واحد

---

## 11. تحليل تدفق التسوق (Shopping Flow Analysis)

### إنشاء قائمة

1. من تبويب "القوائم" → FAB "+" → شاشة إنشاء قائمة
2. اختيار أيقونة → كتابة اسم → "إنشاء القائمة"
3. **問題**: الوصف لا يُحفظ (bug)

### إضافة منتجات

1. من تفاصيل القائمة → FAB "+" → شاشة إضافة منتج
2. أو من الرئيسية → "إضافة عنصر" → QuickAddItemSheet
3. **الميزات**: اقتراحات تلقائية، كشف التكرار
4. **التقييم**: جيد جداً - سريع وسهل

### تعديل منتجات

1. من تفاصيل القائمة → onTap على العنصر → شاشة تعديل
2. أو swipe يسار/يمين
3. **التقييم**: جيد

### تحديد كمشترى

1. checkbox على العنصر → تحويل مباشر
2. أو في وضع التسوق → النقر على الدائرة
3. **التقييم**: ممتاز - سريع جداً

### حذف/تراجع

1. swipe يسار → حوار تأكيد → حذف
2. **問題**: لا يوجد "تراجع" بعد الحذف
3. **التقييم**: جزئي - يحتاج SnackBar مع تراجع

### وضع التسوق

1. من تفاصيل القائمة → أيقونة عربة التسوق
2. أو من الرئيسية → "وضع التسوق" → اختيار قائمة
3. **الميزات**: تجميع بالتصنيف، بحث، إضافة سريعة، شريط تقدم
4. **問題**: شريط التقدم بالإنجليزية
5. **التقييم**: جيد

### بدون اتصال

- **المشكلة الكبرى**: قائمة الانتظار دون اتصال **غير مفعّلة**
- `OfflineAwareShoppingRepository` موجود لكن غير مربوط بالـ Providers
- **التقييم**: خطر - التطبيق لا يعمل بدون اتصال

### المزامنة اللحظية

- **التنفيذ**: Supabase `.stream()` مع `primaryKey`
- **الميزات**: Presence (من يشاهد القائمة)، تحديثات فورية
- **التقييم**: جيد

### نقاط ضعف التدفق

1. لا يوجد "تراجع" بعد حذف عنصر
2. لا يوجد فلترة سريعة بالتصنيف في القائمة الرئيسية
3. شريط البحث في وضع التسوق يعمل لكنه غير بارز
4. QuickAddItemSheet يستخدم قوائم محددة مسبقاً بدلاً من البيانات الفعلية

---

## 12. تحليل تدفق التعاون (Collaboration Flow Analysis)

### إنشاء منزل

1. من Onboarding → "إنشاء منزل جديد" → نموذج → الرئيسية
2. أو من Drawer → "إدارة المنازل" → "+" → نموذج
3. **التقييم**: جيد

### دعوة عضو

1. من Drawer → "إدارة الأعضاء" → أيقونة "+" → نموذج دعوة
2. إدخال بريد + اختيار دور → "إرسال الدعوة"
3. **التقييم**: جيد

### قبول دعوة

1. من Drawer → "الدعوات" → عرض الدعوات المعلقة
2. أزرار "قبول" / "رفض"
3. **التقييم**: جيد

### تبديل المنازل

1. من رأس الشاشة الرئيسية → HomeSelectorDropdown
2. **التقييم**: جيد

### رؤية إجراءات الأعضاء

1. تبويب "النشاط" → سجل النشاطات
2. **المشكلة**: يستخدم FutureBuilder مباشر بدلاً من Provider
3. **التقييم**: جزئي

### سجل النشاطات

- **المصدر**: `activity_logs` table مع triggers
- **الإجراءات المتتبعة**: إنشاء/تعديل/حذف قوائم، إضافة/شراء/تعديل/حذف عناصر، انضمام/إزالة أعضاء، تغيير أدوار
- **التقييم**: جيد

### الإشعارات

- **المصدر**: `notifications` table عبر Edge Function
- **الأنواع**: إضافة عنصر، إكمال عنصر، مخزون منخفض، انتهاء صلاحية، إضافة مصروف، موعد مهمة
- **المشكلة**: لا يوجد اشتراك لحظي للإشعارات ( polling فقط)
- **التقييم**: جزئي

### المزامنة اللحظية

- **Presence**: يعرض من يشاهد القائمة حالياً
- **ItemUpdatedToast**: يظهر عند تحديث عنصر بواسطة مستخدم آخر
- **ConnectionStatusWidget**: يعرض حالة الاتصال
- **التقييم**: جيد

### الأدوار والصلاحيات

| الدور | الصلاحيات |
|-------|-----------|
| مالك (owner) | كل شيء |
| مدير (admin) | إدارة القوائم والأعضاء |
| عضو (member) | إضافة وتعديل وشراء العناصر |
| مشاهد (viewer) | عرض فقط |

- **التقييم**: جيد

### تحسينات مقترحة

1. إشعار لحظي عند إضافة/تعديل عنصر (وليس فقط عند فتح القائمة)
2. مؤشر "يكتب..." مثل تطبيقات المراسلة
3. تحسين Presence ليشمل عرض العنصر الذي يشاهده العضو

---

## 13. تحليل الإعدادات والملف الشخصي

### شاشة الملف الشخصي

- **الملف**: `lib/features/auth/presentation/screens/profile_screen.dart`
- **الوضعان**: عرض (قراءة فقط) وتعديل
- **الحقول**: الاسم الكامل، رقم الهاتف (اختياري)
- **ملاحظة**: البريد الإلكتروني للعرض فقط (لا يمكن تعديله)
- **التقييم**: جيد

### شاشة الإعدادات

لا توجد شاشة إعدادات مستقلة. الإعدادات موجودة في:
1. تبويب "الإعدادات" في HomeScreen
2. القائمة الجانبية (Drawer)

### العناصر المعروضة

| العنصر | الوجهة | يعمل؟ |
|--------|--------|-------|
| الملف الشخصي | `/profile` | نعم |
| إدارة المنازل | `/homes` | نعم |
| التصنيفات | `/categories` | نعم |
| وحدات القياس | `/units` | نعم |
| المهام | `/home/:id/tasks` | نعم |
| إعدادات الإشعارات | `/notifications/preferences` | نعم |
| تسجيل الخروج | تسجيل خروج | نعم |

### إعدادات الإشعارات

- **الملف**: `lib/features/notifications/presentation/screens/notification_preferences_screen.dart`
- **المفاتيح**: إضافة صنف، إكمال صنف، مخزون منخفض، تنبيه انتهاء الصلاحية، إضافة مصروف، موعد مهمة
- **التقييم**: جيد

### إدارة التصنيفات والوحدات

- عرض + إنشاء + حذف (للمخصصات فقط)
- **問題**: زر التعديل stub (فارغ)
- **التقييم**: جزئي

### تسجيل الخروج

- من Drawer أو تبويب "الإعدادات"
- **التنظيف**: يُبطل 20+ provider، يمسح الـ offline queue، يمسح البيانات المحلية، يتصرف قنوات Realtime
- **التقييم**: ممتاز

### ما ينقص الإعدادات

1. لا يوجد تبديل بين الوضع الفاتح/المظلم (يتابع النظام فقط)
2. لا يوجد تغيير اللغة
3. لا يوجد حذف حساب
4. لا يوجد تصدير البيانات
5. لا يوجد إعدادات متقدمة للإشعارات (أوقات، تردد)

---

## 14. مراجعة العربية و RTL

### الشاشات ذات العربية الجيدة

| الشاشة | التقييم | ملاحظات |
|--------|---------|---------|
| LoginScreen | ممتاز | جميع النصوص عربية |
| RegisterScreen | ممتاز | جميع النصوص عربية |
| HomeScreen | ممتاز | تحية صباح/مساء الخير |
| CreateHomeScreen | ممتاز | |
| SendInvitationScreen | ممتاز | شرح الأدوار |
| ShoppingListDetailScreen | ممتاز | |
| AddItemScreen | ممتاز | اقتراحات عربية |
| TaskListScreen | ممتاز | |
| AddTaskScreen | ممتاز | |
| ActivityFeedScreen | ممتاز | وقت عربي عبر timeago |

### الشاشات بنصوص إنجليزية متبقية

| الشاشة | المشكلة |
|--------|---------|
| ShoppingModeScreen | شريط التقدم: "X of Y" بالإنجليزية |
| NotificationCenterScreen | الوقت: "Just now", "Xm ago", "Xh ago", "Xd ago" |
| ShoppingModeScreen | `listName` الافتراضي: "Shopping List" بالإنجليزية |

### مشاكل اتجاه النص

| المشكلة | الموقع |
|---------|--------|
| حقل البريد الإلكتروني LTR | LoginScreen, RegisterScreen, SendInvitationScreen (صحيح) |
| حقل كلمة المرور LTR | LoginScreen, RegisterScreen (صحيح) |
| بعض الحقول لا تحدد `textDirection` | AddExpenseScreen, AddTaskScreen (يعتمد على الوراثة) |

### تنسيق التاريخ/الوقت

| المكتبة | الاستخدام | عربي؟ |
|---------|-----------|-------|
| `timeago` مع `locale: 'ar'` | ActivityLogTileWidget, InvitationCardWidget | نعم |
| `timeago` بدون locale | NotificationTileWidget | لا (إنجليزي) |
| تنسيك يدوي `DD/MM/YYYY` | ExpenseCard | جزئي |
| تنسيك يدوي `YYYY/MM/DD` | MemberCardWidget | جزئي |

### وضوح النصوص

| الفئة | التقييم | ملاحظات |
|-------|---------|---------|
| أزرار | ممتاز | جميعها عربية |
| رسائل الخطأ | جيد | معظمها عربي، بعضها يعرض `e.toString()` |
| حالات فارغة | ممتاز | جميعها عربية مع شرح واضح |
| تسميات الحقول | ممتاز | جميعها عربية |
| hints | ممتاز | جميعها عربية |

---

## 15. مراجعة التصميم البصري

### النمط العام

- **Material 3** مع `useMaterial3: true`
- **لون أساسي**: أخضر داكن (`#2E7D32`) مع `ColorScheme.fromSeed`
- **الخط**: Cairo (مُعرَّف لكن **غير مُحمَّل** - معلق في pubspec.yaml)
- **الوضع الداكن**: مدعوم عبر `ThemeMode.system` لكنه أقل اكتمالاً من الوضع الفاتح

### اتساق البطاقات

| البطاقة | borderRadius | elevation | padding | اتساق |
|---------|-------------|-----------|---------|-------|
| ActiveListCard | 12px | 2 | 16px | جيد |
| ShoppingListCardWidget | 12px | 2 | 16px | جيد |
| ShoppingItemTileWidget | 8px | 1 | 12px | جيد |
| TaskCard | 12px | 2 | 16px | جيد |
| HomeCardWidget | 12px | 2 | 16px | جيد |
| CategoryCardWidget | 12px | 2 | 16px | جيد |

**التقييم**: البطاقات متسقة بشكل عام.

### اتساق الأزرار

| النوع | الخصائص | اتساق |
|-------|---------|-------|
| ElevatedButton | أخضر، 24px/12px padding، 8px radius | جيد |
| TextButton | أخضر نص | جيد |
| IconButton | حسب السياق | جيد |
| FAB | أخضر، أيقونة + | جيد |

### التباعد

- **عام**: 16px padding أساسي
- **بين الأقسام**: 16-24px
- **بين العناصر**: 8-12px
- **التقييم**: جيد

### الألوان

- **المشكلة الكبرى**: 416+ مرجع لون مُضمن في الكود (inline) بدلاً من استخدام `AppTheme` tokens
- **أمثلة**: `Colors.red`, `Colors.grey[600]`, `Colors.green`, `Colors.blue`, `Colors.orange`
- **الخطر**: عدم اتساق بين الوضع الفاتح والمظلم
- **التقييم**: خطر

### الأيقونات

- **المكتبة**: Material Icons (مضمنة في Flutter)
- **الاستخدام**: مناسب وواضح
- **التقييم**: جيد

### أحجام أهداف اللمس

- **الأزرار**: مناسبة (48px+ ارتفاع)
- **البطاقات**: مناسبة
- **العناصر القابلة للنقر**: معظمها يستخدم ListTile أو GestureDetector مع padding كافٍ
- **التقييم**: جيد

### قابلية الاستخدام أثناء التسوق

- **وضع التسوق**: مصمم للاستخدام بيد واحدة
- **الأزرار كبيرة**: أزرار الشراء الدائرية سهلة النقر
- **التصنيفات الملونة**: تسهل التصفح السريع
- **المشكلة**: شريط التقدم بالإنجليزية
- **التقييم**: جيد

### الشاشات المزدحمة

1. HomeScreen (تبويب الرئيسية) -太多 معلومات
2. ShoppingListDetailScreen -许多 أزرار وإجراءات

### الشاشات الفارغة/غير المكتملة

1. OnboardingScreen - زر الانضمام بالرمز stub
2. CategoryCardWidget - زر التعديل stub
3. UnitCardWidget - زر التعديل stub
4. شاشات المصروفات - بدون مسارات مسجلة

---

## 16. جاهزية MVP حسب الميزة

| الميزة | الحالة | الجودة | مشاكل حائلة | الخطوة التالية المقترحة |
|--------|--------|--------|-------------|------------------------|
| المصادقة | جاهز | جيد | لا | - |
| المنازل | جاهز | جيد | لا | - |
| الأعضاء | جاهز | جيد | لا | - |
| الدعوات | جاهز | جيد | لا | - |
| قوائم التسوق | جاهز | جيد جداً | الوصف لا يُحفظ | إصلاح bug الوصف |
| عناصر التسوق | جاهز | ممتاز | لا يوجد تراجع بعد حذف | إضافة SnackBar تراجع |
| وضع التسوق | جاهز | جيد | شريط تقدم بالإنجليزية | ترجمة |
| المزامنة اللحظية | جاهز | جيد | لا | - |
| قائمة الانتظار دون اتصال | مكتمل لكن غير مفعّل | خطر | غير مربوط بالـ Providers | ربط OfflineAwareShoppingRepository |
| سجل النشاطات | جاهز | جيد | FutureBuilder بدلاً من Provider | توحيد |
| الإشعارات | جاهز | جزئي | وقت بالإنجليزية، لا اشتراك لحظي | ترجمة + اشتراك لحظي |
| التصنيفات | جاهز | جيد | زر تعديل stub | تنفيذ أو إزالة |
| الوحدات | جاهز | جيد | زر تعديل stub | تنفيذ أو إزالة |
| الملف الشخصي | جاهز | جيد | لا | - |
| الإعدادات | جاهز | جيد | لا تبديل وضع مظلم | تأجيل |
| المخزون | جاهز | جيد | بلا مسار Drawer فقط | تأجيل |
| المصروفات | مكتمل لكن غير متاح | مخاطر | بلا مسارات مسجلة | إضافة مسارات أو إخفاء |
| المهام | جاهز | جيد | لا | - |
| الذكاء الاصطناعي | مؤجل | - | - | تأجيل |

---

## 17. المشاكل والتكرار والتعقيد

### شاشات مكررة

1. **تبويب "القوائم"** في HomeScreen و **شاشة ShoppingListsScreen** تعرض نفس المحتوى (مقبول - تبويب سريع vs شاشة كاملة)

### أزرار مكررة

1. **زر "وضع التسوق"** موجود في: بطاقة القائمة النشطة، إجراءات سريعة
2. **زر "إضافة عنصر"** موجود في: إجراءات سريعة، FAB في القائمة

### تدفقات مربكة

1. **وضع التسوق**: يمكن الدخول من تفاصيل القائمة أو من تبويب "التسوق" أو من الرئيسية - ثلاث طرق مختلفة
2. **الإشعارات**: يمكن الوصول من AppBar أو من Drawer - طريقتان

### شاشات غير مستخدمة / UI ميت

1. **شاشة OnboardingScreen** - زر "الانضمام بالرمز" تم إخفاؤه
2. **شاشات المصروفات** (5 شاشات) - بدون مسارات مسجلة، مخفية عن المستخدم

### ميزات تجعل MVP كبيراً جداً

1. **المصروفات**: ميزة كاملة (5 شاشات + 4 جداول) لكنها غير متاحة - يجب إخفاؤها أو إتاحتها
2. **المخزون**: ميزة كاملة لكن ليست جوهرية لـ MVP قوائم التسوق
3. **المهام**: ميزة كاملة لكن ليست جوهرية لـ MVP

### أماكن يعد التطبيق بأكثر مما يقدم

1. **القائمة الجانبية** تعرض "المخزون"، "المهام"، "المصروفات" لكن بعضها قد لا يعمل بالكامل
2. **شاشة Onboarding** تعد بـ "الانضمام بالرمز" لكنه غير مكتمل

---

## 18. توصيات التحسين

### يجب إصلاحه قبل بيتا الداخلي ✅ (تم)

1. ~~إصلاح bug وصف قائمة التسوق~~: تم إزالة حقل الوصف من الواجهة
2. ~~إصلاح شريط التقدم بالإنجليزية~~: تم ترجمته إلى "X من Y"
3. ~~إصلاح وقت الإشعارات بالإنجليزية~~: تم ترجمته إلى "منذ X د/س/ي"
4. ~~إزالة stubs~~: تم إخفاء أزرار التعديل الفارغة
5. ~~إضافة مسارات للمصروفات~~: تم إخفاء شاشات المصروفات
6. ~~إصلاح `listName` الافتراضي بالإنجليزية~~: تم تغييره إلى "قائمة التسوق"
7. ~~تنظيف Drawer~~: تم تبسيط القائمة وإزالة التكرار
8. ~~أعلام الميزات~~: تم إنشاء `FeatureFlags` لإخفاء الميزات غير الجاهزة
9. ~~زر الانضمام بالرمز~~: تم إخفاؤه من شاشة الترحيب

### يجب إصلاحه قبل بيتا العام

1. **تفعيل قائمة الانتظار دون اتصال**: ربط `OfflineAwareShoppingRepository` بالـ Providers
2. **توحيد الألوان**: نقل جميع الألوان المُضمنة إلى `AppTheme` tokens
3. **تحميل خط Cairo**: إلغاء تعليق ملفات الخط في pubspec.yaml
4. **تحسين الوضع المظلم**: إضافة customizations أكثر للوضع المظلم
5. **إضافة "تراجع" بعد حذف عنصر**: SnackBar مع زر تراجع
6. **توحيد أنماط الأزرار**: إنشاء widget موحد للأزرار
7. **تحسين تبويب "الإعدادات"**: نقل العناصر غير الضرورية للـ Drawer فقط
8. **إضافة Semantics**: إضافة תוيات للميزات Accessibility

### يمكن تأجيله بعد بيتا

1. إضافة شريط بحث في الشاشة الرئيسية
2. إضافة إحصائيات منزل (عدد العناصر، الإنفاق، إلخ)
3. إضافة تبديل وضع مظلم في التطبيق
4. إضافة تغيير اللغة
5. إضافة حذف حساب
6. تحسين Presence ليشمل عرض العنصر الذي يشاهده العضو
7. إضافة "يكتب..." indicator
8. إضافة تصدير البيانات

### يجب إزالته أو إخفاؤه من MVP

1. **شاشة المصروفات**: إما إضافة مسارات وإتاحها أو إخفاؤها بالكامل
2. **زر "الانضمام بالرمز"** في Onboarding: إخفاء حتى يكتمل التنفيذ
3. **زر التعديل stub** في التصنيفات/الوحدات: إخفاء

---

## 19. أفضل خطوة تالية

### التوصية: **إصلاح واجهة المستخدم أولاً (Fix UI polish first)**

### الأسباب

1. **التطبيق يعمل تقنياً** لكن تجربة المستخدم تحتوي على ثغرات واضحة (نص إنجليزي، stubs، ألوان غير متسقة)
2. **قائمة الانتظار دون اتصال غير مُفعّلة** - هذا خطر لكنه لا يمنع الاستخدام الأساسي
3. **المصروفات بدون مسارات** - هذا يسبب خلطاً للمستخدم
4. **المشاكل اللغوية** (شريط التقدم، وقت الإشعارات) سهلة الإصلاح وتأثير كبير
5. **الـ stubs** (تعديل التصنيفات، الانضمام بالرمز) تسبب خلطاً

### الخطوات المقترحة

1. إصلاح جميع مشاكل الترجمة (ساعات عمل)
2. إخفاء stubs أو تنفيذها (ساعات عمل)
3. إخفاء شاشات المصروفات غير المتاحة (ساعات عمل)
4. توحيد الألوان في AppTheme (يوم عمل)
5. تفعيل قائمة الانتظار دون اتصال (يوم عمل)
6. ثم بدء بيتا الداخلي

---

## 20. ملخص المنتج النهائي

### ما هو سوا حالياً؟

سوا هو تطبيق Flutter + Supabase لإدارة قوائم التسوق المشتركة بين أفراد المنزل. التطبيق يعمل تقنياً ويدعم المزامنة اللحظية ويتضمن نظام أدوار وصلاحيات.

### ما يعمل بشكل جيد؟

- **تدفق التسوق الأساسي**: إنشاء قائمة → إضافة منتجات → الشراء → ملخص (ممتاز)
- **وضع التسوق**: تجربة مصممة للاستخدام في المتجر (جيدة)
- **المزامنة اللحظية**: تحديثات فورية مع Presence (جيدة)
- **سجل النشاطات**: تتبع شامل لجميع العمليات (جيد)
- **نظام الأدوار**: مالك/مدير/عضو/مشاهد (جيد)
- **دعم العربية و RTL**: شامل مع بعض الثغرات البسيطة (جيد)
- **القائمة الجانبية**: مختصة ولا تتكرر مع شريط التنقل السفلي (جيد)

### ما يبدو غير مكتمل؟

- **قائمة الانتظار دون اتصال**: غير مُفعّلة - التطبيق يحتاج اتصال بالإنترنت
- **المصروفات**: 5 شاشات موجودة لكن مخفية عن المستخدم
- **الخط**: Cairo مُعرَّف لكن غير مُحمَّل
- **الألوان المُضمنة**: أكثر من 400 مرجع لون في الكود

### ما قد يُربك المستخدمين؟

1. **لا يوجد "تراجع" بعد حذف عنصر** - قد يفوت المستخدم فرصة التراجع
2. **بعض الشاشات بلا قائمة جانبية** - مثل شاشات التفاصيل

### أولوية المنتج التالية

1. **بدء بيتا الداخلي** - التطبيق جاهز للاستخدام التجريبي
2. **تفعيل قائمة الانتظار دون اتصال** - لضمان العمل بدون إنترنت
3. **تحسين تجربة الحذف** - إضافة SnackBar مع تراجع
4. **تحميل خط Cairo** - لتحسين المظهر البصري

---

> تم إعداد هذا التقرير بناءً على تدقيق يدوي شامل للكود المصدري. جميع مسارات الملفات وأسماء الشاشات مأخوذة مباشرة من الكود.
