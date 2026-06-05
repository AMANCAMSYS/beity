# Audit Remediation Tasks

**Created:** 2026-06-05
**Completed:** 2026-06-05
**Source:** docs/audits/full-system-audit-2026-06-05.md

---

## Phase 1: Critical Security Fixes (Database)

- [x] **1.1** Revoke `GRANT ALL` on `beta_feedback` and `sync_operations_log` from `anon` role
- [x] **1.2** Restrict `auto_archive_completed_tasks` to `service_role` only
- [x] **1.3** Add UPDATE/DELETE RLS policies on `products` table

## Phase 2: High Priority (Data Integrity & Auth)

- [x] **2.1** Add `created_by`/`updated_by` columns to `homes` table
- [x] **2.2** Add `created_by`/`updated_by` columns to `expense_splits` table
- [x] **2.3** Add `created_by`/`updated_by` columns to `notification_preferences` table
- [x] **2.4** Add `updated_by` column to `categories` table
- [x] **2.5** Add `updated_by` column to `task_comments` table
- [x] **2.6** Fix password validation (add uppercase, number, special char checks)
- [x] **2.7** Fix email regex to support `+` tags and longer TLDs

## Phase 3: Medium Priority (Code Quality)

- [x] **3.1** Replace silent `catch (_) {}` with `MonitoringService().logError()` in critical paths
- [x] **3.2** Extract duplicated `_getIconData` to shared utility (`ShoppingUiUtils`)
- [x] **3.3** Extract duplicated `_getProgressColor` to shared utility (`ShoppingUiUtils`)

## Phase 4: Low Priority (Cleanup)

- [x] **4.1** Delete dead code: `User` entity (auth/domain/entities/user.dart)
- [x] **4.2** Delete dead code: 4 Isar stub files
- [x] **4.3** Delete dead code: 3 unused home widgets
- [x] **4.4** Delete dead code: 3 unused shopping_lists widgets
- [x] **4.5** Replace `e.toString()` with localized error messages in home UI
- [x] **4.6** Fix `firstWhere` null-safety in `home_header_sliver.dart`

---

## Files Modified

### Database Migration
- `supabase/migrations/20260605_audit_critical_security_fixes.sql` (NEW)

### Dart Files Modified
- `lib/core/utils/auth_error_messages.dart` - Password & email validation
- `lib/core/utils/shopping_ui_utils.dart` (NEW) - Shared icon & progress utilities
- `lib/core/localization/translations/ar.dart` - New translation keys
- `lib/core/localization/translations/en.dart` - New translation keys
- `lib/core/localization/translations/tr.dart` - New translation keys
- `lib/features/home/presentation/screens/home_screen.dart` - Localized error messages
- `lib/features/home/presentation/widgets/app_drawer.dart` - Localized error messages
- `lib/features/home/presentation/widgets/home_header_sliver.dart` - firstWhere fix + error logging
- `lib/features/home/presentation/widgets/home_active_list_card.dart` - Use shared utility
- `lib/features/home/presentation/widgets/shopping_list_tile.dart` - Use shared utility
- `lib/features/shopping_lists/presentation/widgets/shopping_list_card_widget.dart` - Use shared utility

### Dead Code Deleted (11 files)
- `lib/features/auth/domain/entities/user.dart`
- `lib/features/shopping_lists/data/datasources/isar_shopping_local_datasource.dart`
- `lib/features/shopping_lists/data/models/isar_item_template.dart`
- `lib/features/shopping_lists/data/models/isar_shopping_item.dart`
- `lib/features/shopping_lists/data/models/isar_shopping_list.dart`
- `lib/features/home/presentation/widgets/recent_lists_widget.dart`
- `lib/features/home/presentation/widgets/active_list_card.dart`
- `lib/features/home/presentation/widgets/quick_add_item_sheet.dart`
- `lib/features/shopping_lists/presentation/widgets/connection_status_widget.dart`
- `lib/features/shopping_lists/presentation/widgets/item_updated_toast.dart`
- `lib/features/shopping_lists/presentation/widgets/list_detail_category_section.dart`
