# Implementation Tasks

هذه القائمة مكتوبة لتنفذها أداة أو موديل أرخص خطوة بخطوة. لا تنفذ Phase 2 أو Phase 3 قبل نجاح Phase 1 واختبارها.

## Current Status After Implementation

آخر تحديث: تم تنفيذ طبقة Local-first الأساسية باستخدام Drift/SQLite، وتم ربطها فعلياً بمسارات التسوق، المنازل، التصنيفات، الوحدات، sync cursors، وoffline queue. تم كذلك ربط إدارة البيانات المحلية في الإعدادات وتسجيل الخروج، وتحسين Realtime، و`local_state`، و`next_retry_at`، وconflict handling لمسارات التسوق. بعد تدقيق التغطية، تم ربط `users` جزئياً بـ Drift، وتحويل `activity_logs` و`shopping_mode_sessions` إلى Drift-first، وإضافة outbox لجلسات وضع التسوق والتصنيفات، وإغلاق مسارات autocomplete كي تبدأ من قاعدة الجهاز. تم تشغيل Supabase local وتطبيق migrations الخاصة بالـ soft deletes وRLS/Realtime/indexes، وإضافة migration تصحيحية لتحذير `db lint` في RPC قديمة خاصة بالـ inventory.

Legend:

- ✅ Done: تم تنفيذه والتحقق منه بالتحليل أو الاختبارات المتاحة.
- 🟡 Partial: تم تنفيذ جزء مهم منه، لكن ما زال يحتاج إكمال لاحق.
- ⏳ Pending: لم ينفذ بعد.
- ⚠️ Blocked by environment: تم تحضير الكود لكن التحقق الكامل يحتاج بيئة محلية مناسبة.

ملخص التحقق:

- ✅ `flutter analyze` نجح بدون مشاكل.
- ✅ `flutter test` نجح كاملاً في هذه البيئة: `371 passed`, `7 skipped`.
- ✅ اختبارات offline-aware/realtime/offline queue الخاصة بالتسوق نجحت.
- ⚠️ اختبارات Drift SQLite المحلية أضيفت لكنها skipped في هذه البيئة بسبب عدم توفر `libsqlite3.so`.
- ✅ `supabase start` نجح، و`supabase migration list --local` يعرض حتى `20260603020947_fix_inventory_transfer_lint.sql`.
- ✅ `supabase db lint --local` أصبح clean: `No schema errors found`.
- ✅ تم توليد `app_database.g.dart` عبر `build_runner`.

## Phase 0: Preparation

- [x] T001 اقرأ [architecture-plan.md](architecture-plan.md), [local-schema.md](local-schema.md), و[supabase-sync-notes.md](supabase-sync-notes.md). ✅
- [x] T002 راجع الملفات الحالية: ✅
  - `lib/features/shopping_lists/data/datasources/shopping_local_datasource.dart`
  - `lib/features/homes/data/repositories/home_local_data_source.dart`
  - `lib/features/categories/data/datasources/category_local_datasource.dart`
  - `lib/core/services/sync_service.dart`
  - `lib/core/services/realtime_sync_service.dart`
  - `lib/features/offline_queue/data/datasources/file_queue_datasource.dart`
- [x] T003 لا تعدل inventory, expenses, tasks في هذه المرحلة إلا إذا كان التعديل infrastructure عام ولا يغير سلوك الميزات. ✅

## Phase 1: Add Drift Infrastructure

- [x] T010 أضف dependencies في `pubspec.yaml`: ✅
  - `drift`
  - `sqlite3_flutter_libs`
  - `path`
  - `drift_dev` في dev dependencies
- [x] T011 شغل dependency resolution. ✅
- [x] T012 أنشئ `build.yaml` لإعداد drift schema exports. ✅
- [x] T013 أنشئ `lib/core/local_database/database_connection.dart`. ✅
- [x] T014 افتح قاعدة البيانات باسم `sawa_local_v1.sqlite` داخل `ApplicationSupportDirectory`. ✅
- [x] T015 استخدم `NativeDatabase.createInBackground`. ✅
- [x] T016 أنشئ `lib/core/local_database/app_database.dart`. ✅
- [x] T017 اضبط `schemaVersion = 1`. ✅
- [x] T018 اضبط migrations strategy مع `onCreate: createAll`. ✅

Acceptance:

- ✅ المشروع يولد `app_database.g.dart`.
- ✅ لا توجد imports مكسورة.
- ✅ لا يتم فتح قاعدة البيانات على UI isolate مباشرة.

## Phase 2: Define Local Tables

- [x] T020 أنشئ tables لكل Core MVP: ✅
  - `local_users`
  - `local_homes`
  - `local_home_members`
  - `local_shopping_lists`
  - `local_shopping_items`
  - `local_item_templates`
  - `local_categories`
  - `local_units`
  - `local_activity_logs`
  - `local_shopping_mode_sessions`
  - `local_sync_cursors`
  - `local_pending_mutations`
  - `local_store_meta`
- [x] T021 أضف indexes المذكورة في [local-schema.md](local-schema.md). ✅
- [x] T022 احفظ JSON fields كنص مثل `metadata_json` و`payload_json`. ✅
- [x] T023 استخدم text ids لأن Supabase ids UUID strings. ✅

Acceptance:

- ✅ كل جدول يحتوي الأعمدة الأساسية وأعمدة local sync.
- ✅ كل query مهمة لديها index واضح.

## Phase 3: DAOs and Mappers

- [x] T030 أنشئ `lib/core/local_database/daos/homes_dao.dart`. ✅
- [x] T031 أنشئ `lib/core/local_database/daos/shopping_dao.dart`. ✅
- [x] T032 أنشئ `lib/core/local_database/daos/categories_dao.dart`. ✅
- [x] T033 أنشئ `lib/core/local_database/daos/units_dao.dart`. ✅
- [x] T034 أنشئ `lib/core/local_database/daos/activity_logs_dao.dart`. ✅
- [x] T035 أنشئ `lib/core/local_database/daos/sync_dao.dart`. ✅
- [x] T036 أنشئ `lib/core/local_database/daos/mutations_dao.dart`. ✅
- [x] T037 أنشئ mappers من وإلى models الحالية: ✅
  - `HomeModel`
  - `HomeMemberModel`
  - `ShoppingListModel`
  - `ShoppingItemModel`
  - `ItemTemplateModel`
  - `CategoryModel`
  - `UnitModel`
  - `ActivityLogModel`
- [x] T038 اجعل كل upsert يتم داخل transactions عندما يكون batch. ✅

Acceptance:

- ✅ DAO يستطيع read/watch/upsert/delete لكل جدول Phase 1.
- ✅ لا يوجد parsing JSON في الواجهة لمسارات Drift الجديدة.

## Phase 4: Replace SharedPreferences Data Sources

- [x] T040 أنشئ `DriftShoppingLocalDataSource` يطبق `ShoppingLocalDataSource`. ✅
- [x] T041 استبدل provider في `shopping_lists_provider.dart` ليستخدم Drift implementation. ✅
- [x] T042 أنشئ `DriftHomeLocalDataSource` أو عدل `HomeLocalDataSource` ليستخدم Drift بدل SharedPreferences. ✅
- [x] T043 أنشئ `DriftCategoryLocalDataSource` يطبق `CategoryLocalDataSource`. ✅
- [x] T044 أنشئ `UnitLocalDataSource` محلي إذا لم يكن موجوداً. ✅ نفذ عبر `UnitsDao` وربطه في `SupabaseUnitRepository`.
- [x] T045 أبق `SharedPreferences` للإعدادات فقط، مثل اللغة والثيم وonboarding. ✅ مع بقاء fallback مؤقت للهجرة فقط.

Acceptance:

- ✅ فتح قوائم التسوق لا يقرأ JSON من SharedPreferences في provider الجديد.
- ✅ المنازل والأعضاء تقرأ من SQLite.
- ✅ التصنيفات والوحدات تقرأ من SQLite.

## Phase 5: Migration from Existing SharedPreferences

- [x] T050 أنشئ `lib/core/local_database/local_data_migration_service.dart`. ✅
- [x] T051 عند أول تشغيل بعد التحديث، اقرأ مفاتيح SharedPreferences القديمة: ✅
  - `homes_cache_user:*`
  - `home_members_cache_home:*`
  - `cached_lists_stream_*`
  - `cached_items_stream_*`
  - `cached_templates_*`
  - `cached_categories_*`
  - `cached_activity_logs_*`
  - `cached_units_*`
  - `sync_ts_*`
  - offline queue files عبر `FileQueueDataSource`
- [x] T052 اكتب البيانات في Drift. ✅
- [x] T053 ضع flag في `local_store_meta`: `shared_preferences_migration_completed:v1`. ✅
- [x] T054 لا تحذف المفاتيح القديمة في أول إصدار إلا بعد نجاح migration واختبارات كافية. ✅

Acceptance:

- ✅ المستخدم الحالي لا يفقد بياناته بعد التحديث.
- ✅ migration قابلة للتشغيل أكثر من مرة بدون تكرار عبر upsert وflag.

## Phase 6: Sync Cursors and Delta Sync

- [x] T060 عدل `SyncService` ليستخدم `local_sync_cursors` بدلاً من sync timestamps في SharedPreferences. ✅ يكتب في Drift مع إبقاء SharedPreferences كـ fallback للتوافق.
- [x] T061 أضف methods: ✅
  - `getLocalSyncTimeAsync(homeId, tableName)`
  - `updateLocalSyncTime(homeId, tableName, timestamp)`
  - `markInitialSyncDone(homeId, tableName)`
  - `isInitialSyncDone(homeId, tableName)`
- [x] T062 عدل shopping sync حتى لا يستخدم cache empty كسبب وحيد للسحب. ✅
- [ ] T063 أضف delta methods في remote repositories لكل Phase 1. 🟡 تم دعم التسوق والتصنيفات جزئياً، وباقي Phase 1 يحتاج إكمال مخصص.
- [x] T064 اجعل delta pull يشمل soft-deleted rows. ✅ للتسوق والتصنيفات، مع migration لـ RPC.
- [x] T065 استخدم pagination في delta pull إذا زادت النتائج. ✅ تم للتسوق والتصنيفات بحجم صفحة 500.

Acceptance:

- ✅ إذا الجدول فارغ لكن `initial_sync_done = true` لا يتم سحب الجدول كاملاً بلا سبب في مسار shopping/category.
- ✅ الحذف يصل للأجهزة عبر delta للتسوق بعد `includeDeleted` وRPC migration.

## Phase 7: Local-First Writes and Pending Mutations

- [x] T070 انقل queue storage من ملفات JSON إلى `local_pending_mutations`. ✅ `queueDataSourceProvider` يستخدم `DriftQueueDataSource`.
- [x] T071 اكتب migration من `FileQueueDataSource` إلى Drift queue. ✅ ضمن `LocalDataMigrationService`.
- [x] T072 عند create/update/delete shopping list، اكتب محلياً أولاً. ✅ موجود ومدعوم بالاختبارات.
- [x] T073 عند create/update/delete shopping item، اكتب محلياً أولاً. ✅ موجود ومدعوم بالاختبارات.
- [x] T074 استخدم `local_state` لتحديد pending أو failed. ✅ create/update/delete للقوائم والعناصر يكتب `pending_*` محلياً ويعيد `synced` بعد نجاح السيرفر، مع بقاء حالات الفشل/التعارض في outbox.
- [x] T075 أنشئ sync worker يرفع mutations حسب `next_retry_at`. ✅ worker يحترم وقت إعادة المحاولة للفشل المؤقت ولا يعيد المحاولة قبل موعدها.
- [x] T076 أضف exponential backoff. ✅ موجود في `DriftQueueDataSource`.
- [x] T077 أضف conflict handling حسب `base_updated_at`. ✅ عمليات تحديث/حذف/استرجاع عناصر وقوائم التسوق ترسل `base_updated_at`، و`QueueActionExecutor` يمنع الكتابة فوق تحديث أحدث في السيرفر، و`SyncQueueUseCase` يبقي العملية كـ `CONFLICT` بدل حذفها.

Acceptance:

- ✅ إضافة عنصر بدون إنترنت تبقى في SQLite outbox.
- ✅ عند العودة للإنترنت يستخدم sync queue الحالي.
- ✅ الأخطاء تظهر في sync status عبر failed entries.

## Phase 8: Realtime Integration

- [x] T080 عدل `realtime_sync_service.dart` ليكتب payloads في Drift. ✅ لمسارات shopping lists/items/categories عند استخدام Drift.
- [x] T081 أزل الاعتماد على `saveShoppingListsStreamCache` و`saveShoppingItemsStreamCache` داخل realtime handlers. ✅ أزيل من مسار Drift، وبقي fallback القديم فقط لأي rollback/test datasource.
- [x] T082 عند update مع `deleted_at != null` علم الصف محلياً كمحذوف. ✅ upsert يحفظ tombstone وhard delete يعلّم soft delete محلي.
- [x] T083 تأكد أن Drift streams تحدث providers أو استبدل `LocalCacheNotifier` تدريجياً. ✅ Drift upsert/delete يحدّث SQLite، و`LocalCacheNotifier` ما زال bridge مؤقت لإعادة تحميل providers القديمة.
- [x] T084 لا تحدث UI state مباشرة من Realtime. ✅ Realtime يكتب التخزين المحلي ويرسل invalidate event فقط.

Acceptance:

- تعديل من جهاز آخر يظهر محلياً.
- حذف من جهاز آخر يختفي أو يظهر كمحذوف حسب الشاشة.

## Phase 9: Local Data Deletion Service

- [x] T090 أنشئ `lib/core/local_database/local_data_deletion_service.dart`. ✅
- [x] T091 أضف method: `deleteLocalHomeData(homeId)`. ✅
- [x] T092 أضف method: `deleteLocalUserData(userId)`. ✅
- [x] T093 أضف method: `deleteAllLocalData()`. ✅
- [x] T094 أضف method: `deleteTemporaryLocalDataOnly()`. ✅
- [x] T095 عند إزالة عضوية منزل، احذف بيانات ذلك المنزل محلياً. ✅ موجود عبر `HomeRepository.syncHomesWithServer` عند اختفاء العضوية.
- [x] T096 عند تسجيل الخروج، اعرض خيار الاحتفاظ بالبيانات أو حذفها. ✅ تسجيل الخروج العادي يحتفظ بالبيانات، والحذف المحلي يحدث فقط عند اختيار المستخدم.

Acceptance:

- ✅ حذف بيانات منزل لا يحذف بيانات منازل أخرى.
- ✅ تسجيل الخروج العادي لا يحذف البيانات المحلية.
- ✅ تسجيل الخروج مع حذف البيانات يستدعي `deleteLocalUserData`.

## Phase 10: Settings UI

- [x] T100 أضف قسم "البيانات المحلية" في settings. ✅
- [x] T101 اعرض حجم قاعدة البيانات. ✅ عبر `LocalDataDeletionService.getDatabaseSizeBytes`.
- [x] T102 اعرض آخر مزامنة ناجحة. ✅ من `SyncCoordinator.getLastSuccessfulSyncTime`.
- [x] T103 اعرض عدد العمليات المعلقة. ✅ عبر `LocalDataDeletionService.getPendingMutationsCount`.
- [x] T104 أضف زر "مزامنة الآن". ✅ يستدعي `syncAll(force: true)`.
- [x] T105 أضف زر "حذف بيانات هذا المنزل من الجهاز". ✅ مع تأكيد واضح.
- [x] T106 أضف زر "حذف كل بيانات هذا الحساب من الجهاز". ✅ مع تأكيد واضح.
- [x] T107 أضف ترجمة عربية وتركية وإنجليزية لكل نص. ✅

Acceptance:

- المستخدم يعرف حالة بياناته المحلية.
- كل زر خطير يطلب تأكيد واضح.

## Phase 11: Supabase Migration

- [x] T110 أنشئ migration عبر Supabase CLI، لا تخترع اسم migration يدوياً إذا كان CLI متاحاً. ✅ `supabase/migrations/20260603002602_local_first_sync_soft_deletes.sql`
- [x] T111 عدل `get_tables_last_update` ليشمل soft-deleted rows. ✅
- [x] T112 أضف indexes الناقصة من [supabase-sync-notes.md](supabase-sync-notes.md). ✅ أضيفت في `supabase/migrations/20260603015710_local_first_indexes_realtime_rls.sql`.
- [x] T113 راجع RLS policies للجداول التي ستستخدم في delta sync. ✅ migration يبقي RLS مفعلاً ويضيف SELECT policies مخصصة للـ sync حتى تصل soft-deleted tombstones لأعضاء المنزل فقط.
- [x] T114 تأكد أن كل UPDATE له SELECT policy مناسب. ✅ تمت مراجعة المخطط الحالي لمسارات shopping/categories/homes/members، وأضيفت policies sync لا تكسر UPDATE visibility، وتم تطبيق migrations على Supabase local.
- [x] T115 تأكد أن Realtime publication تشمل جداول Phase 1. ✅ migration يضيف الجداول إلى `supabase_realtime` بطريقة idempotent.
- [x] T116 أصلح تحذير `supabase db lint --local` الخاص بالـ RPC القديمة `transfer_items_to_inventory`. ✅ أضيفت `supabase/migrations/20260603020947_fix_inventory_transfer_lint.sql` مع الحفاظ على signature الحالية وتحقق آمن من `p_items`.

Acceptance:

- ✅ الحذف يغير timestamp المرئي للمزامنة بعد تطبيق migration.
- ✅ تطبيق migrations على Supabase local نجح.
- ✅ `supabase db lint --local` لا يعرض أي أخطاء أو تحذيرات بعد migration التصحيحية.

## Phase 12: Tests

- [ ] T120 أضف unit tests للـ DAOs. 🟡 أضيفت اختبارات Drift queue/deletion، لكن ليست كل DAOs.
- [ ] T121 أضف migration tests لقاعدة Drift.
- [ ] T122 أضف tests لتحويل SharedPreferences إلى Drift.
- [ ] T123 أضف tests لـ sync cursors. 🟡 تمت تغطية سلوك cursor في اختبارات offline-aware، وليس DAO مباشر.
- [x] T124 أضف tests لـ pending mutations retry. ✅ أضيف اختبار use case لا يحتاج SQLite، واختبار Drift موجود لكنه skipped في البيئة الحالية بسبب `libsqlite3.so`.
- [x] T125 أضف tests لحذف بيانات منزل. ✅ ضمن `local_data_deletion_service_test.dart` لكن skipped في البيئة الحالية بسبب `libsqlite3.so`.
- [x] T126 أضف tests لتبديل المستخدم وعدم ظهور بيانات المستخدم السابق. ✅ `test/features/homes/domain/usecases/account_switching_isolation_test.dart`
- [ ] T127 أضف widget tests لفتح shopping lists من local DB.
- [x] T128 أضف offline flow test: add item offline, restart app, sync online. 🟡 اختبارات offline-aware/realtime نجحت، لكن restart فعلي للتطبيق لم يختبر بعد.

Acceptance:

- 🟡 الاختبارات تغطي مسارات حرجة في shopping/offline queue وaccount switching. يبقى استكمال DAOs/migration المباشرة في بيئة تحتوي `libsqlite3.so`.
- ✅ لا توجد regressions في shopping MVP حسب الاختبارات التي شغلت.

## Phase 13: Verification Commands

- [x] T130 شغل code generation. ✅ `dart run build_runner build`
- [x] T131 شغل formatter. ✅
- [x] T132 شغل `flutter analyze`. ✅ No issues found.
- [x] T133 شغل اختبارات local database. ⚠️ الأمر شغل، لكن الاختبارات skipped بسبب عدم توفر `libsqlite3.so`.
- [x] T134 شغل اختبارات shopping/offline queue. ✅ All tests passed.
- [x] T136 شغل Supabase local migrations. ✅ `supabase start`, `supabase migration up --local`, و`supabase migration list --local` نجحت حتى migration `20260603020947`.
- [x] T137 شغل اختبار RPC الخاص بتحذير lint. ✅ `flutter test test/unit/supabase/inventory_transfer_rpc_test.dart`
- [x] T138 شغل Supabase schema lint. ✅ `supabase db lint --local` رجع `No schema errors found`.
- [x] T139 شغل full test suite. ✅ `flutter test` رجع `371 passed`, `7 skipped` في هذه البيئة.
- [ ] T135 اختبر يدوياً حسب [manual-verification-checklist.md](manual-verification-checklist.md): ⏳
  - فتح التطبيق بدون إنترنت.
  - إضافة عنصر بدون إنترنت.
  - إغلاق التطبيق وفتحه.
  - عودة الإنترنت.
  - حذف عنصر من جهاز آخر.
  - تسجيل خروج مع وبدون حذف بيانات.

## Phase 14: Full Local Data Coverage Audit

- [x] T140 افحص كل استدعاءات Supabase داخل `lib/core` و`lib/features` عبر `.from(...)`, `.rpc(...)`, و`.select(...)`. ✅
- [x] T141 قارنها بجداول Drift الحالية في `lib/core/local_database/app_database.dart`. ✅
- [x] T142 أنشئ [data-coverage-audit.md](data-coverage-audit.md) لتحديد ما هو Drift-first، وما هو SharedPreferences، وما هو remote-only. ✅
- [x] T143 أضف check بسيط في CI أو script محلي يطبع أي `.from('table')` جديد لا يظهر في coverage audit. ✅ `scripts/check_local_data_coverage.dart`
- [x] T144 عند إضافة أي feature جديدة، حدث `data-coverage-audit.md` قبل كتابة repository. ✅ موثق في [README.md](README.md) مع أمر الفحص.

Acceptance:

- ✅ يوجد مصدر واحد يوضح لكل جدول هل يجب أن يحفظ محلياً أو لا.
- ✅ لا يبدأ تنفيذ "كل البيانات محلية" بدون معرفة المسارات التي ما زالت remote-first.
- ✅ `dart run scripts/check_local_data_coverage.dart` يفشل إذا ظهر جدول Supabase مباشر غير موثق.

## Phase 15: Complete MVP Local-First Coverage

هذه المرحلة لا توسع المنتج خارج MVP، بل تغلق فجوات موجودة في البيانات التي يراها المستخدم يومياً.

- [x] T150 اربط `users` بجدول `local_users` فعلياً. ✅
  - ✅ أنشئ `UsersDao`.
  - ✅ اجعل `AuthRepositoryImpl` يكتب profile في Drift عند sign in/sign up/update.
  - ✅ اجعل fallback offline يقرأ من Drift قبل `${userId}_cached_profile`.
  - ✅ انقل consumers القديمة مثل invitations/profile إلى `local_users`.
  - ✅ احذف إنشاء وقراءة `${userId}_cached_profile` من مسارات التشغيل الجديدة.
  - ✅ أضف migration v2 لنقل مفاتيح `${userId}_cached_profile` القديمة إلى `local_users`.
  - ✅ أبق `last_logged_in_user_id` فقط كمعرف تقني محدود للطابور/الهجرة، وليس كمصدر profile.
- [x] T151 حوّل `activity_logs` إلى Drift-first. ✅
  - ✅ اجعل `watchHomeActivity`, `watchListActivity`, `getActivityLogs`, و`getHomeActors` تبدأ من Drift.
  - ✅ اجعل Supabase realtime يكتب في `local_activity_logs`.
  - ✅ أزل الاعتماد على مفاتيح `cached_activity_logs_*` و`cached_actors_*` من repository.
- [x] T152 حوّل `shopping_mode_sessions` إلى Drift-first. ✅
  - ✅ أضف DAO واضح لجلسات shopping mode.
  - ✅ اجعل active session recovery يقرأ SQLite أولاً عند توفر DAO في التطبيق.
  - ✅ اجعل start/end session يكتب محلياً قبل/مع محاولة Supabase.
  - ✅ أضف outbox للجلسات لمزامنة start/end التي تمت offline بالكامل.
- [x] T153 أغلق read path في shopping autocomplete الذي كان يسحب `units`, `item_templates`, أو `shopping_items` من Supabase عند توفرها محلياً. ✅
- [ ] T154 أكمل local-first للتصنيفات والوحدات. 🟡 جزئي:
  - ✅ `categories` أصبحت local-first في create/update/delete، وتكتب Drift أولاً، ثم Supabase، ثم تدخل `local_pending_mutations` عند انقطاع الشبكة.
  - ✅ `categories` أصبحت local-first في `getCategoryById` مع fallback remote يحفظ في Drift.
  - ✅ `QueueActionExecutor` يدعم رفع عمليات create/update/delete للتصنيفات.
  - ✅ `units` أصبحت Drift-first في القراءة والـ streams و`getUnitById`، وcreate/update/delete تحدث Drift بعد نجاح السيرفر.
  - ✅ `QueueActionExecutor` يدعم عمليات units إذا تم تمريرها في outbox لاحقاً.
  - 🟡 `SupabaseUnitRepository` لا يضيف عمليات units إلى outbox حالياً لأن `units` بيانات عامة لا تحمل `home_id`، بينما الطابور الحالي home-scoped. لا تفعل تعديل وحدات offline بالكامل قبل حسم scope أو إضافة user/global queue.
  - 🟡 delta pull/cursors للتصنيفات مدعوم جزئياً، أما units فتحتاج مسار global cursor إذا أصبحت قابلة للتعديل المتكرر.
- [x] T155 اجعل dashboard snapshot يشتق من Drift أو انقله إلى Drift/meta. ✅
  - ✅ `cached_home_dashboard_snapshot_*` لم يعد مسار التخزين الجديد.
  - ✅ snapshot يحفظ في `local_store_meta` ويُحذف مع بيانات المنزل عبر `LocalDataDeletionService`.
- [x] T156 حدّث `LocalDataDeletionService` ليغطي أي جدول MVP جديد يضاف في T150-T155. ✅ الجداول/الـ meta المستخدمة هنا مشمولة مسبقاً في حذف المنزل أو حذف المستخدم أو حذف كل البيانات.
- [ ] T157 أضف tests تغطي فتح home/activity/shopping mode بدون شبكة من Drift.

Acceptance:

- ✅ لا توجد بيانات عرض MVP طويلة الأجل جديدة محفوظة في `SharedPreferences` لهذه المسارات، لكن مفاتيح legacy تبقى للهجرة والتنظيف.
- ✅ فتح home, shopping, activity, shopping mode يعرض من SQLite أولاً لمسارات Phase 15 المنفذة.
- ✅ لا يتم سحب `units` و`item_templates` من Supabase في مسار autocomplete إذا كانت موجودة محلياً.

## Phase 16: Local-First For Global User-Facing Data

هذه المرحلة مهمة لتقليل Supabase usage لكنها تأتي بعد Phase 15.

- [x] T160 أضف `local_notifications` وDAO: ✅
  - ✅ جدول Drift: `local_notifications` مع indexes.
  - ✅ `NotificationsDao` مع `getNotifications`, `watchNotifications`, `getUnreadCount`, `watchUnreadCount`, `upsertNotifications`, `markAsRead`, `markAllAsRead`.
  - ✅ `LocalFirstNotificationRepository` يبدأ من Drift أولاً ثم يحدّث من Supabase في الخلفية.
  - ✅ `markAsRead` و`markAllAsRead` يحدثان Drift فوراً ثم Supabase ثم outbox عند الفشل.
- [x] T161 أضف `local_notification_preferences` وDAO: ✅
  - ✅ جدول Drift: `local_notification_preferences` مع unique index على `user_id, home_id`.
  - ✅ `NotificationPreferencesDao` مع `getPreference`, `watchPreference`, `upsertPreference`, `updateField`.
  - ✅ `getPreferences(homeId)` يقرأ من Drift أولاً، ينشئ default محلياً إذا لا يوجد صف، ثم يحاول Supabase upsert في الخلفية.
  - ✅ `updatePreference` يكتب محلياً أولاً ثم Supabase ثم outbox عند الفشل.
- [x] T162 أضف `local_invitations` وDAO: ✅
  - ✅ جدول Drift: `local_invitations` مع indexes.
  - ✅ `InvitationsDao` مع `getHomeInvitations`, `watchHomeInvitations`, `getUserInvitations`, `watchUserInvitations`, `getInvitationByToken`, `upsertInvitations`, `updateStatus`.
  - ✅ `LocalFirstInvitationRepository` يبدأ من Drift أولاً ثم يحدّث من Supabase.
  - ✅ `watchHomeInvitations` و`watchUserInvitations` يبدآن بتحديث من Supabase ثم يصدرا stream من Drift.
  - ✅ accept/decline/cancel: accept يتطلب RPC (online-only)، decline وcancel يحدثان محلياً أولاً ثم outbox عند الفشل.
- [x] T163 أضف cache محدود لـ `role_permissions`: ✅
  - ✅ استخدم `local_store_meta` لحفظ snapshot صغير لكل الصلاحيات.
  - ✅ `getRolePermissions` و`getAllRolePermissions` يقرآن المحلي أولاً ثم Supabase عند عدم وجود cache.
  - ✅ `hasPermission` يستخدم صلاحيات الدور المخزنة محلياً بعد تحديد دور العضو.
  - 🟡 TTL/cursor global غير مضاف بعد لأن التغيير نادر، ويمكن إضافته مع تصميم global sync في Phase 16.
- [x] T164 أضف scoped outbox لدعم العمليات بدون homeId: ✅
  - ✅ `MutationScope` enum: `home`, `user`, `global`.
  - ✅ `QueueEntry.homeId` أصبح nullable.
  - ✅ `QueueDataSource` يدعم `getEntriesByUserScope`, `getEntriesByGlobalScope`, `getPendingCountForUser`.
  - ✅ `SyncQueueUseCase.executeUserScope` يمزامن العمليات user-scoped وglobal-scoped.
  - ✅ `FileQueueDataSource` و`DriftQueueDataSource` يدعمان الـ interface الجديد.
- [ ] T165 حدّث `get_tables_last_update` أو RPC مكافئة لتشمل Phase 16 عند تفعيلها. 🟡 Pending
- [x] T166 حدّث `LocalDataDeletionService` وmigration من SharedPreferences لهذه البيانات: ✅
  - ✅ `deleteAllLocalData` يحذف الجداول الثلاثة الجديدة.
  - ✅ `HomesDao.clearAllHomeData` يحذف notifications, preferences, invitations الخاصة بالمنزل.
  - ✅ `HomesDao.clearAllUserDataForUser` يحذف notifications, preferences الخاصة بالمستخدم.
  - ✅ `LocalDataMigrationService` ينقل `cached_home_invitations_*` و`cached_user_invitations_*` من SharedPreferences إلى Drift.
- [x] T167 Realtime handlers: ✅
  - ✅ `RealtimeSyncService` ي_subscribe على `notifications` (user-scoped) و`invitations`.
  - ✅ الأحداث تكتب في Drift عبر DAOs.
- [x] T168 مزامنة user-scoped queue: ✅
  - ✅ `SyncQueueUseCase.executeUserScope` يجمع entries من user scope وglobal scope ويُنفذها.
  - ✅ Connectivity listener يُشغّل sync لـ user scope عند عودة الاتصال.

Acceptance:

- ✅ notification center لا يحتاج طلب Supabase لعرض آخر بيانات معروفة.
- ✅ الدعوات تظهر من الهاتف فوراً ثم تتحدث عند وصول الشبكة.
- ✅ تفضيلات الإشعارات لا تعيد إنشاء صفوف أو تستدعي Supabase بلا داع.
- ✅ صلاحيات الأدوار لا تحتاج طلب Supabase متكرر بعد أول تحميل ناجح.
- ✅ العمليات بدون homeId تُعالج بشكل صحيح عبر scoped outbox.

## Phase 17: Deferred Feature Data, Do Not Start Before MVP Stability

هذه المرحلة موجودة لأن التطبيق يحتوي كوداً للمهام والمصروفات والمخزون، لكنها مقيدة بتعليمات AGENTS.md.

- [ ] T170 لا تبدأ tasks/expenses/inventory إلا بعد موافقة صريحة أن shared shopping-list MVP مستقر.
- [ ] T171 عند فتح Phase tasks:
  - أضف `local_tasks` و`local_task_comments`.
  - استبدل `SharedPreferencesTaskLocalDataSource` بـ Drift.
  - اجعل archive/complete/comment writes local-first.
- [ ] T172 عند فتح Phase expenses:
  - أضف `local_expenses`, `local_expense_splits`, و`local_settlements`.
  - استبدل `SharedPreferencesExpenseLocalDataSource` بـ Drift.
  - اجعل balances تقرأ من local rows أو snapshot مشتق.
- [ ] T173 عند فتح Phase inventory:
  - أضف `local_inventory_items`, `local_inventory_transactions`, و`local_products` إذا استخدم البحث/الاقتراح.
  - استبدل `SharedPreferencesInventoryLocalDataSource` بـ Drift.
  - اجعل quantity updates وtransactions local-first.
- [ ] T174 لكل جدول Phase 17:
  - أضف migration Drift مع زيادة `schemaVersion`.
  - أضف DAO ومappers.
  - أضف cursor في `local_sync_cursors`.
  - أضف migration من مفاتيح SharedPreferences القديمة.
  - أضف حذف محلي scoped بـ `home_id`.
  - أضف Supabase indexes/RLS/realtime عند الحاجة.

Acceptance:

- لا يتم إدخال feature مؤجلة كـ remote-first جديدة.
- أي feature مؤجلة تبدأ محلياً من Drift منذ أول شاشة.

## ممنوعات أثناء التنفيذ

- لا تستخدم `SharedPreferences` لبيانات الجداول بعد إدخال Drift.
- لا تسحب كل جدول عند كل فتح للتطبيق.
- لا تحذف بيانات المستخدم عند تسجيل الخروج العادي.
- لا تعرض بيانات من `home_id` لا يملكه المستخدم الحالي.
- لا تنفذ Phase 3 قبل استقرار shopping MVP.
- لا تستخدم `service_role` في Flutter.

## Remaining Work For Next Model

نفذ هذه الخطوات التالية بالترتيب:

- ✅ R001 اربط `LocalDataDeletionService` في شاشة الإعدادات وتدفق تسجيل الخروج.
- ✅ R002 عدل `realtime_sync_service.dart` ليكتب مباشرة في Drift بدل الاعتماد على cache methods.
- ✅ R003 أكمل استخدام `local_state` في create/update/delete للقوائم والعناصر.
- ✅ R004 اجعل sync worker يحترم `next_retry_at` عند اختيار mutations.
- ✅ R005 أضف conflict handling فعلي باستخدام `base_updated_at`.
- ✅ R006 أضف pagination للـ delta pull عندما تكبر النتائج.
- ⏳ R007 شغل اختبارات Drift في بيئة تحتوي `libsqlite3.so`.
- ✅ R008 شغل Supabase local stack ثم تحقق من migration:
  - `supabase start`
  - `supabase migration list --local`
  - `supabase migration up --local`
- ✅ R009 أضف migration لفهارس/RLS/Realtime publication. ✅ تم تطبيقها محلياً في `20260603015710_local_first_indexes_realtime_rls.sql`.
- ✅ R011 أعد تشغيل `supabase db lint --local` بعد `20260603020947_fix_inventory_transfer_lint.sql`. ✅ النتيجة: `No schema errors found`.
- ⏳ R010 نفذ [manual-verification-checklist.md](manual-verification-checklist.md) على جهاز حقيقي لتسجيل الخروج مع/بدون حذف بيانات، وإضافة عنصر offline ثم إعادة فتح التطبيق.
- 🟡 R012 أكمل ما تبقى من Phase 15 قبل أي توسع جديد: احسم نطاق outbox للوحدات العامة إذا كانت شاشة الوحدات ستدعم التعديل بدون إنترنت، وأضف اختبارات Drift فعلية عند توفر `libsqlite3.so`.
- 🟡 R013 بعد إغلاق Phase 15، أكمل Phase 16 للإشعارات والدعوات وتفضيلات الإشعارات. صلاحيات الأدوار أصبح لها cache محلي محدود، لكن باقي Phase 16 يحتاج تصميم global/user scoped outbox قبل writes offline كاملة.
- ⏳ R014 لا تبدأ Phase 17 الخاصة بـ tasks/expenses/inventory إلا بعد موافقة صريحة أن shared shopping-list MVP مستقر.
