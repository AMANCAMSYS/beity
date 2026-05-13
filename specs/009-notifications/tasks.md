# Tasks: Notifications

**Input**: Design documents from `/specs/009-notifications/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/notification-functions.md

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Phase 1: Setup

**Purpose**: Project initialization and directory structure

- [X] T001 Create notifications feature directory structure under `lib/features/notifications/{data/{models,repositories},domain/{entities,usecases},presentation/{providers,screens,widgets}}`
- [X] T002 Create Supabase Edge Functions directory structure under `supabase/functions/{send-notification,get-notification-history,mark-notifications-read,update-notification-preferences,cleanup-old-notifications}`
- [X] T003 Create initial database migration file scaffold in `supabase/migrations/` (replaced by T004-T006)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [X] T004 Implement `notification_preferences` table migration with RLS policies, indexes, and unique constraint on (user_id, category) in `supabase/migrations/`
- [X] T005 Implement `notifications` table migration with RLS policies, indexes (user_id, created_at DESC), (user_id, is_read), (batch_key, created_at DESC) in `supabase/migrations/`
- [X] T006 Implement pg_cron job for 30-day notification cleanup in `supabase/migrations/`
- [X] T007 [P] Create Notification entity in `lib/features/notifications/domain/entities/notification.dart`
- [X] T008 [P] Create NotificationPreference entity in `lib/features/notifications/domain/entities/notification_preference.dart`
- [X] T009 [P] Create NotificationModel data class with JSON serialization in `lib/features/notifications/data/models/notification_model.dart`
- [X] T010 [P] Create NotificationPreferenceModel data class with JSON serialization in `lib/features/notifications/data/models/notification_preference_model.dart`
- [X] T011 Create NotificationRepository interface in `lib/features/notifications/data/repositories/notification_repository.dart`
- [X] T012 Implement SupabaseNotificationRepository in `lib/features/notifications/data/repositories/supabase_notification_repository.dart`
- [X] T013 Deploy `send-notification` Edge Function with preference checking, throttling (2-min batch), bilingual content generation, and FCM delivery in `supabase/functions/send-notification/index.ts`
- [X] T014 Deploy `cleanup-old-notifications` Edge Function to delete notifications older than 30 days in `supabase/functions/cleanup-old-notifications/index.ts`

**Checkpoint**: Foundation ready — user story implementation can now begin

---

## Phase 3: User Story 1 — Receive shopping list update notifications (Priority: P1) 🎯 MVP

**Goal**: Home members receive push notifications when another member adds, edits, or completes a shopping list item

**Independent Test**: Two members in a home; one adds/completes an item; the other receives a notification. Verify notification content includes item name and actor name.

### Implementation for User Story 1

- [X] T015 [P] [US1] Create `notify_on_shopping_item_change` database trigger function (INSERT/UPDATE on shopping_items → calls send-notification Edge Function via pg_net) in `supabase/migrations/`
- [X] T016 [US1] Update `NotificationService` with foreground message handler using `flutter_local_notifications` in `lib/core/services/notification_service.dart`
- [X] T017 [US1] Add notification suppression logic — track active screen subscriptions, skip local display when screen is active in `lib/core/services/notification_service.dart`
- [X] T018 [US1] Add GoRouter deep link handling in `_handleNotificationTap` to navigate to shopping list from notification payload in `lib/core/services/notification_service.dart`
- [X] T019 [US1] Create `sendShoppingListNotification` helper method in `NotificationService` to invoke Edge Function from client in `lib/core/services/notification_service.dart`

> **Note**: T016-T019 all modify `notification_service.dart`. Execute sequentially: T016 → T017 → T018 → T019.

### Tests for User Story 1

- [X] T046 [P] [US1] Unit test for SupabaseNotificationRepository.sendNotification in `test/unit/features/notifications/repositories/notification_repository_test.dart`
- [X] T047 [P] [US1] Unit test for notification suppression logic in `test/unit/features/notifications/services/notification_suppression_test.dart`

**Checkpoint**: Shopping list notifications work end-to-end: item change → trigger → Edge Function → FCM → local notification → tap → deep link

---

## Phase 4: User Story 2 — Receive home and invitation notifications (Priority: P2)

**Goal**: Users receive notifications when invited to a home or when a new member joins their home

**Independent Test**: Invite a user to a home → they receive an invitation notification. A new member joins → existing members are notified. Tap navigates to invitation/home screen.

### Implementation for User Story 2

- [X] T020 [P] [US2] Create `notify_on_invitation` database trigger function (INSERT on invitations → calls send-notification Edge Function) in `supabase/migrations/`
- [X] T021 [P] [US2] Create `notify_on_member_joined` database trigger function (INSERT on home_members → calls send-notification Edge Function) in `supabase/migrations/`
- [X] T022 [US2] Add invitation and member-joined event types to `send-notification` Edge Function content templates (English + Arabic) in `supabase/functions/send-notification/index.ts`
- [X] T023 [US2] Add deep link routes for invitation details and home screens in `NotificationService._handleNotificationTap` in `lib/core/services/notification_service.dart`

**Checkpoint**: Home and invitation notifications work: invitation sent → notification received → tap → invitation screen

---

## Phase 5: User Story 3 — Manage notification preferences (Priority: P3)

**Goal**: Users can toggle notification categories on/off and changes take effect immediately

**Independent Test**: Toggle off "shopping list" category → verify no shopping list notifications are delivered. Toggle back on → verify notifications resume.

### Implementation for User Story 3

- [X] T024 [US3] Deploy `update-notification-preferences` Edge Function with upsert logic in `supabase/functions/update-notification-preferences/index.ts`
- [X] T025 [US3] Create GetNotificationPreferencesUseCase in `lib/features/notifications/domain/usecases/get_notification_preferences_usecase.dart`
- [X] T026 [US3] Create UpdateNotificationPreferencesUseCase in `lib/features/notifications/domain/usecases/update_notification_preferences_usecase.dart`
- [X] T027 [US3] Create NotificationPreferencesProvider with Riverpod in `lib/features/notifications/presentation/providers/notification_preferences_provider.dart`
- [X] T028 [US3] Create NotificationPreferencesScreen with category toggles in `lib/features/notifications/presentation/screens/notification_preferences_screen.dart`
- [X] T029 [P] [US3] Create NotificationPreferenceToggle widget in `lib/features/notifications/presentation/widgets/notification_preference_toggle.dart`
- [X] T030 [US3] Add default notification preferences seed (all categories enabled) for new users in `supabase/migrations/`

**Checkpoint**: Users can manage notification preferences; disabled categories stop delivering notifications

---

## Phase 6: User Story 4 — View notification history (Priority: P4)

**Goal**: Users can view a notification history/inbox with all recent events, mark as read, and navigate via deep links

**Independent Test**: Generate notifications → open notification center → verify list shows notifications with timestamps. Tap notification → navigate to relevant screen. Mark as read → verify read state.

### Implementation for User Story 4

- [X] T031 [US4] Deploy `get-notification-history` Edge Function with pagination, filtering, and unread count in `supabase/functions/get-notification-history/index.ts`
- [X] T032 [US4] Deploy `mark-notifications-read` Edge Function for single and bulk mark-as-read in `supabase/functions/mark-notifications-read/index.ts`
- [X] T033 [US4] Create GetNotificationHistoryUseCase in `lib/features/notifications/domain/usecases/get_notification_history_usecase.dart`
- [X] T034 [US4] Create MarkNotificationsReadUseCase in `lib/features/notifications/domain/usecases/mark_notifications_read_usecase.dart`
- [X] T035 [US4] Create GetUnreadCountUseCase in `lib/features/notifications/domain/usecases/get_unread_count_usecase.dart`
- [X] T036 [US4] Create NotificationsProvider with Riverpod (pagination, history, real-time updates) in `lib/features/notifications/presentation/providers/notifications_provider.dart`
- [X] T037 [US4] Create UnreadCountProvider with Riverpod in `lib/features/notifications/presentation/providers/unread_count_provider.dart`
- [X] T038 [US4] Create NotificationCenterScreen with paginated list, unread/read distinction in `lib/features/notifications/presentation/screens/notification_center_screen.dart`
- [X] T039 [P] [US4] Create NotificationTileWidget with read/unread styling and tap navigation in `lib/features/notifications/presentation/widgets/notification_tile_widget.dart`
- [X] T040 [P] [US4] Create NotificationBadgeWidget for unread count display in `lib/features/notifications/presentation/widgets/notification_badge_widget.dart`
- [X] T041 [US4] Add notification bell icon with badge to HomeScreen that navigates to notification center in `lib/features/home/presentation/screens/home_screen.dart`

### Tests for User Story 4

- [X] T048 [P] [US4] Unit test for GetNotificationHistoryUseCase in `test/unit/features/notifications/usecases/get_notification_history_test.dart`
- [X] T049 [P] [US4] Unit test for MarkNotificationsReadUseCase in `test/unit/features/notifications/usecases/mark_notifications_read_test.dart`
- [X] T050 [US4] Widget test for NotificationCenterScreen in `test/widget/features/notifications/notification_center_screen_test.dart`

**Checkpoint**: Full notification center works: history list, read/unread states, deep link navigation, badge count

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

- [X] T042 Verify Arabic RTL layout on all notification screens (notification center, preferences) in `lib/features/notifications/presentation/`
- [X] T043 Run `flutter analyze` and fix any issues across the notifications feature
- [X] T044 Verify RLS policies work correctly — users can only see their own notifications and preferences
- [X] T045 Verify notification suppression works when user is viewing the relevant shopping list in real-time

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion — BLOCKS all user stories
- **User Story 1 (Phase 3)**: Depends on Foundational (Phase 2)
- **User Story 2 (Phase 4)**: Depends on Foundational (Phase 2) — can run in parallel with US1
- **User Story 3 (Phase 5)**: Depends on Foundational (Phase 2) — can run in parallel with US1/US2
- **User Story 4 (Phase 6)**: Depends on Foundational (Phase 2) — can run in parallel with US1/US2/US3
- **Polish (Phase 7)**: Depends on all user stories being complete

### User Story Dependencies

- **US1 (P1)**: No dependencies on other stories
- **US2 (P2)**: No dependencies on other stories
- **US3 (P3)**: No dependencies on other stories (preference checking happens in Edge Function)
- **US4 (P4)**: No dependencies on other stories (history includes all events)

### Within Each User Story

- Models before services
- Services before UI
- Core implementation before integration

### Parallel Opportunities

- T007, T008, T009, T010 can all run in parallel (different entity/model files)
- T015 can run in parallel with T016-T019 (database trigger vs client code)
- T020, T021 can run in parallel (different triggers)
- T029 can run in parallel with T028 (widget vs screen)
- T039, T040 can run in parallel (different widgets)
- All user stories (Phases 3-6) can run in parallel after Phase 2 completes

---

## Parallel Example: User Story 1

```bash
# Database trigger can be created in parallel with client updates:
Task: "T015 [P] [US1] Create notify_on_shopping_item_change trigger"
Task: "T016 [US1] Update NotificationService with foreground handler"
# T017-T019 depend on T016 completing first
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (database, models, repository, send-notification Edge Function)
3. Complete Phase 3: User Story 1 (shopping list notifications)
4. **STOP and VALIDATE**: Two users in a home; one adds item; other gets notification
5. Deploy/demo if ready

### Incremental Delivery

1. Setup + Foundational → Foundation ready
2. Add User Story 1 → Shopping list notifications work → Deploy (MVP!)
3. Add User Story 2 → Home/invitation notifications work → Deploy
4. Add User Story 3 → Preferences toggleable → Deploy
5. Add User Story 4 → Notification center complete → Deploy

### Parallel Team Strategy

With multiple developers:

1. Team completes Setup + Foundational together
2. Once Foundational is done:
   - Developer A: User Story 1 (shopping list notifications)
   - Developer B: User Story 2 (home/invitation notifications)
   - Developer C: User Story 3 (preferences)
3. User Story 4 after others complete (or in parallel)

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- Existing `notification_service.dart` handles FCM token management — extend, don't replace
- Existing `device_tokens` table is reused — no new migration needed for tokens
