# Quickstart: Activity Logs

**Date**: 2026-05-13
**Feature**: 008-activity-logs

## Prerequisites

- Supabase project with existing tables (homes, home_members, shopping_lists, shopping_items, invitations, users)
- Flutter project with Riverpod, GoRouter, supabase_flutter configured
- SPEC 07 (Realtime Sync) completed — `RealtimeService` available in `lib/core/services/`

## Setup Steps

### 1. Run Database Migration

Apply the activity log triggers migration:

```bash
supabase migration up
```

This will:
- Add `actor_name` column to `activity_logs` table
- Create indexes for efficient querying
- Create trigger functions for automatic log generation
- Attach triggers to `shopping_lists`, `shopping_items`, `home_members`, `invitations`

### 2. Verify RLS Policies

Existing RLS policies should already be in place. Verify:

```sql
SELECT policyname, cmd FROM pg_policies WHERE tablename = 'activity_logs';
```

Expected:
- `Users can view activity from their homes` (SELECT)
- `Authenticated users can insert activity logs` (INSERT)

### 3. Create Feature Directory

```bash
mkdir -p lib/features/activity_logs/{data/{models,repositories},domain/entities,presentation/{providers,screens,widgets}}
```

### 4. Implement in Order

1. Domain entity: `activity_log.dart` (ActionType, EntityType enums + ActivityLog class)
2. Data model: `activity_log_model.dart` (fromJson/toJson mappers)
3. Repository interface: `activity_log_repository.dart`
4. Repository implementation: `supabase_activity_log_repository.dart`
5. Providers: `activity_logs_provider.dart`
6. Screens: `activity_feed_screen.dart`, `list_activity_screen.dart`, `activity_detail_screen.dart`
7. Widgets: `activity_log_tile_widget.dart`, `activity_filter_widget.dart`
8. Route registration in `app_router.dart`

### 5. Test

```bash
flutter test test/unit/features/activity_logs/
flutter analyze
```

## Key Integration Points

| Integration | How | Notes |
|------------|-----|-------|
| RealtimeService | `watchTable(table: 'activity_logs', filterColumn: 'home_id', filterValue: homeId)` | Reuse from SPEC 07 |
| Home members | RLS handles access control | No additional checks needed |
| Shopping list detail | Add "Activity" button/tab | Navigates to list_activity_screen |
| App router | Add routes for `/activity`, `/lists/:id/activity` | GoRouter integration |

## Verification Checklist

- [ ] Activity log entries appear when items are added, edited, purchased, deleted
- [ ] Activity log entries appear when lists are created, renamed, archived, deleted
- [ ] Activity log entries appear when members join, are removed, or have role changed
- [ ] Activity log entries appear when invitations are accepted
- [ ] Home-level feed shows all activity for the home
- [ ] List-level feed shows only activity for that list
- [ ] Real-time: new entries appear without refresh
- [ ] Filters by actor and action type work correctly
- [ ] Empty state shows when no activity exists
- [ ] Arabic RTL layout works correctly
- [ ] Actor name is preserved even after user changes display name
