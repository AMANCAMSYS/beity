# Tasks: MVP Hardening and Beta

**Input**: Design documents from `/specs/012-mvp-hardening-beta/`
**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/

**Tests**: Integration tests are included for critical paths (end-to-end journey, offline sync, data integrity) as specified in the spec's acceptance scenarios.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Flutter app**: `lib/` at repository root
- **Features**: `lib/features/<feature_name>/`
- **Core/Shared**: `lib/core/`, `lib/shared/`
- **Tests**: `test/`, `integration_test/`
- **Backend**: `supabase/functions/`, `supabase/migrations/`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Add new dependencies and configure beta build infrastructure

- [x] T001 Add `firebase_crashlytics` dependency to `pubspec.yaml`
- [x] T002 Create `beta_feedback` table migration in `supabase/migrations/` with RLS policies per data-model.md
- [x] T003 [P] Create `submit-feedback` Edge Function in `supabase/functions/submit-feedback/index.ts` per contracts/feedback-submission.md
- [x] T004 [P] Add `BETA` dart-define flag handling in `lib/main.dart` (read `--dart-define=BETA=true` and expose via a constant)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T005 Create `MonitoringService` wrapper in `lib/core/monitoring/monitoring_service.dart` with methods: `initialize()`, `setUser()`, `logError()`, `logPerformanceEvent()`, `log()`
- [x] T006 Initialize Firebase Crashlytics in `lib/main.dart` — set `FlutterError.onError`, disable in debug builds
- [x] T007 Create `ErrorHandler` class in `lib/core/error_handling/error_handler.dart` mapping exception types to user-friendly messages per research.md error categories table
- [x] T008 [P] Create `ErrorScreen` widget in `lib/core/error_handling/error_screen.dart` with "Try Again" button and "Report Issue" link
- [x] T009 [P] Create `DeviceInfoService` in `lib/core/monitoring/device_info_service.dart` collecting device model, OS version, app version, build number, platform
- [x] T010 [P] Create `AppLogBuffer` in `lib/core/monitoring/app_log_buffer.dart` — rotating in-memory buffer of last 50 log entries
- [x] T011 [P] Create `AccessibilityHelpers` mixin/extension in `lib/core/accessibility/semantics_helpers.dart` with common semantic label builders for shopping items, lists, buttons
- [x] T012 [P] Create shared `StarRating` widget in `lib/shared/widgets/star_rating.dart` — tappable 1-5 stars with semantic labels

**Checkpoint**: Foundation ready — monitoring, error handling, accessibility helpers, and shared widgets available for all user stories

---

## Phase 3: User Story 1 — End-to-End Shopping Journey (Priority: P1) 🎯 MVP

**Goal**: Validate that the complete sign-up → create home → invite → create list → add items → shop → mark purchased → exit flow works without crashes on both Arabic RTL and English LTR

**Independent Test**: Walk through the complete flow manually and via integration test on both Android and iOS; verify no crashes, data loss, or confusing states

### Implementation for User Story 1

- [x] T013 [US1] Create integration test scaffold in `integration_test/shopping_journey_test.dart` with setup/teardown for test Supabase user and home
- [x] T014 [US1] Implement happy-path E2E test: sign up → create home → create list → add items → enter shopping mode → mark items purchased → exit shopping mode in `integration_test/shopping_journey_test.dart`
- [x] T015 [P] [US1] Add `Semantics` labels to `lib/features/auth/` screens — sign-up, login, and profile screens
- [x] T016 [P] [US1] Add `Semantics` labels to `lib/features/homes/` screens — home list, create home, home dashboard
- [x] T017 [P] [US1] Add `Semantics` labels to `lib/features/invitations/` screens — invite flow, accept/decline
- [x] T018 [US1] Add `Semantics` labels to `lib/features/shopping_lists/` screens — list view, create list, list detail
- [x] T019 [US1] Add `Semantics` labels to `lib/features/shopping_items/` screens — item cards, add item, edit item, mark purchased
- [x] T020 [US1] Add `Semantics` labels to `lib/features/shopping_mode/` screens — shopping mode view, progress indicator, exit summary
- [x] T021 [US1] Wrap critical shopping list operations in try-catch with `MonitoringService.logError()` in `lib/features/shopping_lists/` providers/repositories
- [x] T022 [US1] Wrap critical shopping item operations in try-catch with `MonitoringService.logError()` in `lib/features/shopping_items/` providers/repositories
- [x] T023 [US1] Add performance timing to shopping list load and shopping mode entry in `lib/features/shopping_lists/` and `lib/features/shopping_mode/` — log if > 3s via `MonitoringService.logPerformanceEvent()`
- [ ] T024 [US1] Run integration test on Android emulator and verify pass
- [ ] T025 [US1] Run integration test on iOS simulator and verify pass

**Checkpoint**: End-to-end shopping journey works without crashes; accessibility labels on all core screens; crash/performance logging active

---

## Phase 4: User Story 2 — Beta Tester Onboarding (Priority: P1)

**Goal**: Beta testers can install the app, see a welcome screen, submit feedback via menu, and complete a satisfaction survey after their first shopping session

**Independent Test**: Install beta build, verify welcome screen appears once, submit feedback via menu, exit shopping mode and verify survey appears

### Implementation for User Story 2

- [x] T026 [US2] Create `BetaConfig` class in `lib/features/beta/data/beta_config.dart` — reads `BETA` dart-define flag and exposes `isBeta` getter
- [x] T027 [US2] Create `BetaPreferences` repository in `lib/features/beta/data/beta_preferences.dart` — reads/writes `beta_welcome_shown` and `satisfaction_survey_shown` in SharedPreferences
- [x] T028 [US2] Create `FeedbackRepository` in `lib/features/beta/data/feedback_repository.dart` — calls `submit-feedback` Edge Function with device info from `DeviceInfoService` and logs from `AppLogBuffer`
- [x] T029 [US2] Create `BetaWelcomeDialog` widget in `lib/features/beta/presentation/beta_welcome_dialog.dart` per contracts/beta-ui-screens.md Screen 1 spec — RTL support, semantic labels, "Got it!" button
- [x] T030 [US2] Create `FeedbackBottomSheet` widget in `lib/features/beta/presentation/feedback_bottom_sheet.dart` per contracts/beta-ui-screens.md Screen 2 spec — type selector, description field, submit, loading/error states
- [x] T031 [US2] Create `SatisfactionSurveyDialog` widget in `lib/features/beta/presentation/satisfaction_survey_dialog.dart` per contracts/beta-ui-screens.md Screen 3 spec — star rating, optional comment, submit/skip
- [x] T032 [US2] Add "Send Feedback" option to the global app menu/scaffold in `lib/features/presentation/` or `lib/app/` — opens `FeedbackBottomSheet`
- [x] T033 [US2] Add beta welcome check to app startup in `lib/app/app.dart` or `lib/main.dart` — show `BetaWelcomeDialog` if `isBeta && !beta_welcome_shown`
- [x] T034 [US2] Add satisfaction survey trigger to shopping mode exit in `lib/features/shopping_mode/presentation/` — show `SatisfactionSurveyDialog` if `isBeta && !satisfaction_survey_shown`
- [x] T035 [P] [US2] Add `Semantics` labels to `lib/features/categories/` screens
- [x] T036 [P] [US2] Add `Semantics` labels to `lib/features/notifications/` screens
- [x] T037 [P] [US2] Add `Semantics` labels to `lib/features/activity_logs/` screens

**Checkpoint**: Beta onboarding complete — welcome screen, feedback form, satisfaction survey all functional; accessibility labels on remaining feature screens

---

## Phase 5: User Story 3 — App Stability Under Load (Priority: P1)

**Goal**: App remains fast and stable with 20 shopping lists, 500 items, 5 simultaneous editors, and 30-minute shopping sessions

**Independent Test**: Simulate load (20 lists, 500+ items, 5 concurrent users) and verify: list screen < 2s load, shopping mode 60fps with 200 items, mark-as-purchased < 200ms, no memory leaks over 30 min

### Implementation for User Story 3

- [x] T038 [US3] Audit `lib/features/shopping_lists/presentation/` — ensure `ListView.builder` with `const` constructors for list tiles; use `ref.select()` for granular rebuilds
- [x] T039 [US3] Audit `lib/features/shopping_items/presentation/` — ensure `ListView.builder` with `const` item cards; use `ref.select()` for `isPurchased` state; add `RepaintBoundary` around item cards
- [x] T040 [US3] Audit `lib/features/shopping_mode/presentation/` — ensure virtualized list, `const` constructors, minimal rebuilds on mark-as-purchased
- [x] T041 [US3] Debounce search/filter input in `lib/features/shopping_items/presentation/` — 300ms debounce to avoid rebuilding on every keystroke
- [ ] T042 [US3] Add memory profiling test in `integration_test/memory_test.dart` — simulate 30-minute shopping session, verify no unbounded memory growth
- [ ] T043 [US3] Add performance benchmark test in `integration_test/performance_test.dart` — measure scroll FPS with 200 items, mark-as-purchased latency, list load time

**Checkpoint**: Performance targets met — 60fps scrolling, <200ms mark response, <2s loads, stable memory over 30 min

---

## Phase 6: User Story 4 — Graceful Error Handling (Priority: P2)

**Goal**: All error states show user-friendly messages with clear recovery actions; no blank screens or cryptic errors

**Independent Test**: Trigger error conditions (airplane mode, expired session, revoked access, server 500) and verify each shows the correct message and recovery action per research.md error categories

### Implementation for User Story 4

- [x] T044 [US4] Integrate `ErrorHandler` into `lib/features/auth/` — wrap auth operations; handle session expiry with redirect to re-auth screen preserving navigation state
- [x] T045 [US4] Integrate `ErrorHandler` into `lib/features/homes/` — handle permission denied (removed from home) with message and redirect to homes list
- [x] T046 [US4] Integrate `ErrorHandler` into `lib/features/shopping_lists/` — handle network unavailability with queue message; handle server errors with retry
- [x] T047 [US4] Integrate `ErrorHandler` into `lib/features/shopping_items/` — handle network unavailability, server errors, storage full
- [x] T048 [US4] Create generic `ErrorBoundary` widget in `lib/core/error_handling/error_boundary.dart` — catches unhandled widget errors, shows `ErrorScreen` with "Try Again" and "Report Issue"
- [x] T049 [US4] Apply `ErrorBoundary` to main app shell in `lib/app/app.dart` — wraps the router outlet
- [x] T050 [US4] Add server-busy detection with automatic backoff retry in `lib/core/error_handling/` — detect Supabase connection limit errors, show "server busy" message

**Checkpoint**: All error states handled gracefully — no blank screens, no cryptic errors, clear recovery paths

---

## Phase 7: User Story 5 — Arabic RTL Quality (Priority: P2)

**Goal**: All screens pass manual RTL review with no alignment, mirroring, or text overflow issues

**Independent Test**: Switch device to Arabic, navigate every screen, verify: text right-aligned, icons mirrored, inputs RTL, numbers correct, no truncation

### Implementation for User Story 5

- [x] T051 [US5] RTL audit: `lib/features/auth/` screens — verify text alignment, input direction, icon mirroring, navigation direction; fix any issues
- [x] T052 [US5] RTL audit: `lib/features/homes/` screens — verify and fix
- [x] T053 [US5] RTL audit: `lib/features/shopping_lists/` screens — verify and fix
- [x] T054 [US5] RTL audit: `lib/features/shopping_items/` screens — verify and fix; ensure mixed Arabic/English item names render correctly with bidirectional text
- [x] T055 [US5] RTL audit: `lib/features/shopping_mode/` screens — verify and fix; ensure progress indicator, category headers, and item cards are RTL-correct
- [x] T056 [P] [US5] RTL audit: `lib/features/categories/` screens — verify and fix
- [x] T057 [P] [US5] RTL audit: `lib/features/invitations/` screens — verify and fix
- [x] T058 [P] [US5] RTL audit: `lib/features/notifications/` screens — verify and fix
- [x] T059 [P] [US5] RTL audit: `lib/features/activity_logs/` screens — verify and fix
- [x] T060 [US5] RTL audit: `lib/features/beta/` screens (welcome, feedback, survey) — verify and fix
- [x] T061 [US5] Verify number formatting for Arabic locales across all screens — quantities, prices, dates display correctly
- [x] T062 [US5] Verify swipe gesture direction in RTL — item swipe-to-delete, list swipe actions work in correct direction

**Checkpoint**: All screens pass RTL review — no alignment, mirroring, or overflow issues

---

## Phase 8: User Story 6 — Accessibility Baseline (Priority: P2)

**Goal**: 100% of interactive elements have accessibility labels; all touch targets ≥ 44x44 points

**Independent Test**: Enable VoiceOver/TalkBack, navigate core shopping flow, verify all elements announce labels; measure touch targets

### Implementation for User Story 6

- [x] T063 [US6] Add `Semantics` labels to `lib/shared/widgets/` — all shared buttons, cards, inputs, and decorative elements
- [x] T064 [US6] Audit and fix touch target sizes across all screens — ensure minimum 44x44 points for all interactive elements; add padding where needed
- [x] T065 [US6] Add `MergeSemantics()` to compound item widgets in `lib/features/shopping_items/presentation/` — item card should announce name + quantity + unit + purchased status as one unit
- [x] T066 [US6] Add `ExcludeSemantics()` to decorative icons/images across all features
- [x] T067 [US6] Verify screen reader announces mark-as-purchased state change — "Milk, 2 kg, marked as purchased" in `lib/features/shopping_items/` and `lib/features/shopping_mode/`
- [ ] T068 [US6] Add accessibility test using `SemanticsTester` in `test/accessibility/` for core shopping item widget

**Checkpoint**: All interactive elements have semantic labels; touch targets ≥ 44x44; screen reader announces state changes

---

## Phase 9: User Story 7 — Crash and Performance Monitoring (Priority: P3)

**Goal**: App automatically reports crashes and logs slow operations (> 3s) to Firebase Crashlytics

**Independent Test**: Trigger test crash, verify report in Firebase Console; trigger slow operation, verify performance log

### Implementation for User Story 7

- [x] T069 [US7] Set custom Crashlytics keys on auth state change in `lib/features/auth/` — `user_id` (anonymized), `home_id` via `MonitoringService`
- [x] T070 [US7] Add breadcrumb logging for navigation events in `lib/app/router.dart` or GoRouter observer — log route changes via `MonitoringService.log()`
- [x] T071 [US7] Add breadcrumb logging for key shopping actions in `lib/features/shopping_items/` and `lib/features/shopping_mode/` — log add, delete, mark purchased via `MonitoringService.log()`
- [x] T072 [US7] Add non-fatal error logging in `lib/core/error_handling/error_handler.dart` — call `MonitoringService.logError()` for all caught exceptions
- [x] T073 [US7] Add performance threshold logging in `lib/core/monitoring/performance_monitor.dart` — wrap async operations, log via `MonitoringService.logPerformanceEvent()` if > 3s

**Checkpoint**: Crash reports and performance events appear in Firebase Console; custom keys and breadcrumbs provide debugging context

---

## Phase 10: User Story 8 — Data Integrity Verification (Priority: P3)

**Goal**: Shopping data is always accurate and consistent across devices, sessions, and after offline sync

**Independent Test**: Multi-device scenarios: user A adds item offline, user B marks different item online, user A reconnects — verify final state is consistent; app kill/restart preserves purchased state

### Implementation for User Story 8

- [x] T074 [US8] Create integration test for offline→online sync in `integration_test/offline_sync_test.dart` — user A goes offline, adds items, reconnects, verifies items sync
- [x] T075 [US8] Create integration test for concurrent edits in `integration_test/concurrent_edits_test.dart` — two users edit different items simultaneously, verify both preserved
- [x] T076 [US8] Create integration test for session interruption in `integration_test/session_interruption_test.dart` — mark items purchased, kill app, reopen, verify state preserved
- [x] T077 [US8] Verify offline queue correctly handles items added offline and items deleted by another user — test in `integration_test/offline_sync_test.dart`
- [x] T078 [US8] Verify realtime subscription reconnection after extended backgrounding (24h+ simulation) in `integration_test/reconnection_test.dart`

**Checkpoint**: Data integrity verified across all multi-device and interruption scenarios; zero data loss confirmed

---

## Phase 11: Polish & Cross-Cutting Concerns

**Purpose**: Final validation, documentation, and release preparation

- [x] T079 [P] Update `lib/core/monitoring/` with storage warning — detect < 50MB local storage and show user warning per FR-016
- [x] T080 [P] Add home switching performance check in `lib/features/homes/` — ensure < 2s switch time per FR-020
- [x] T081 Verify realtime subscription lifecycle on app resume in `lib/features/shopping_lists/` and `lib/features/shopping_items/` — reconnect after extended background per FR-018
- [ ] T082 Run `flutter analyze` and fix all warnings
- [ ] T083 Run full integration test suite on Android emulator — all tests pass
- [ ] T084 Run full integration test suite on iOS simulator — all tests pass
- [ ] T085 Manual RTL walkthrough — every screen in Arabic, document and fix any remaining issues
- [ ] T086 Manual accessibility walkthrough — VoiceOver on iOS, TalkBack on Android, document and fix remaining issues
- [ ] T087 Build release APK with `--dart-define=BETA=true` and verify beta features work
- [ ] T088 Build release IPA with `--dart-define=BETA=true` and verify beta features work
- [ ] T089 Run quickstart.md validation — verify all setup steps and verification procedures work

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion — BLOCKS all user stories
- **US1 (Phase 3)**: Depends on Foundational — E2E integration tests + accessibility labels for core screens
- **US2 (Phase 4)**: Depends on Foundational — Beta UI screens + remaining accessibility labels
- **US3 (Phase 5)**: Depends on Foundational + US1 (needs working screens to optimize) — Performance optimization
- **US4 (Phase 6)**: Depends on Foundational — Error handling integration across all features
- **US5 (Phase 7)**: Depends on Foundational + US2 (beta screens exist) — RTL audit
- **US6 (Phase 8)**: Depends on US1 + US4 (screens + error screens exist) — Accessibility audit
- **US7 (Phase 9)**: Depends on Foundational — Crashlytics integration (mostly additive)
- **US8 (Phase 10)**: Depends on US1 (E2E flow works) — Data integrity testing
- **Polish (Phase 11)**: Depends on all user stories

### User Story Dependencies

- **US1 (P1)**: Can start after Foundational — No dependencies on other stories
- **US2 (P1)**: Can start after Foundational — No dependencies on other stories
- **US3 (P1)**: Best after US1 (needs working screens to optimize)
- **US4 (P2)**: Can start after Foundational — Integrates with existing features
- **US5 (P2)**: Best after US2 (all screens exist for audit)
- **US6 (P2)**: Best after US1 + US4 (all screens including error screens exist)
- **US7 (P3)**: Can start after Foundational — Mostly additive
- **US8 (P3)**: Best after US1 (E2E flow works for testing)

### Within Each User Story

- Models/data before services
- Services before UI
- Core implementation before integration/testing
- Story complete before moving to next priority

### Parallel Opportunities

- T003, T004 can run in parallel (different files)
- T008, T009, T010, T011, T012 can run in parallel (different files, no dependencies)
- T015, T016, T017 can run in parallel (different feature directories)
- T035, T036, T037 can run in parallel (different feature directories)
- T056, T057, T058, T059 can run in parallel (different feature directories)
- US1 and US2 can run in parallel after Foundational completes
- US4 and US7 can run in parallel after Foundational completes
- US5 and US6 can run in parallel after US2 completes

---

## Parallel Example: User Story 1

```bash
# Launch parallel accessibility label tasks (different feature dirs):
Task: "Add Semantics labels to lib/features/auth/ screens (T015)"
Task: "Add Semantics labels to lib/features/homes/ screens (T016)"
Task: "Add Semantics labels to lib/features/invitations/ screens (T017)"

# Launch parallel error wrapping tasks (different feature dirs):
Task: "Wrap shopping list operations in try-catch (T021)"
Task: "Wrap shopping item operations in try-catch (T022)"
```

---

## Implementation Strategy

### MVP First (User Story 1 + 2 Only)

1. Complete Phase 1: Setup (dependencies, migration, edge function, beta flag)
2. Complete Phase 2: Foundational (monitoring, error handling, accessibility helpers)
3. Complete Phase 3: User Story 1 (E2E journey + core accessibility labels)
4. Complete Phase 4: User Story 2 (beta onboarding + remaining accessibility labels)
5. **STOP and VALIDATE**: Beta build works end-to-end with welcome screen and feedback
6. Deploy beta build to TestFlight / Google Play Internal Testing

### Incremental Delivery

1. Setup + Foundational → Infrastructure ready
2. US1 + US2 → Beta build deployable (MVP!)
3. US3 → Performance validated → Confident for real-world use
4. US4 → Error handling polished → Better UX on failures
5. US5 + US6 → RTL + accessibility complete → Inclusive product
6. US7 + US8 → Monitoring + data integrity → Production-ready
7. Polish → Release candidate

### Parallel Team Strategy

With multiple developers:

1. Team completes Setup + Foundational together
2. Once Foundational is done:
   - Developer A: US1 (E2E tests + core accessibility)
   - Developer B: US2 (beta screens + remaining accessibility)
3. After US1 + US2:
   - Developer A: US3 (performance optimization)
   - Developer B: US4 (error handling)
   - Developer C: US5 (RTL audit)
4. After US4 + US5:
   - Developer A: US7 (Crashlytics integration)
   - Developer B: US6 (accessibility audit)
   - Developer C: US8 (data integrity tests)
5. Team: Polish + release

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- This spec does NOT introduce new Supabase tables for monitoring — all crash/performance data goes to Firebase
- The `beta_feedback` table is the only new Supabase table (for user-submitted feedback)
- Accessibility labels and RTL fixes are additive — they should not break existing functionality
