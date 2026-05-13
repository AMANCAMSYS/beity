# Implementation Plan: MVP Hardening and Beta

**Branch**: `012-mvp-hardening-beta` | **Date**: 2026-05-13 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/012-mvp-hardening-beta/spec.md`

## Summary

This spec hardens the existing Beity MVP (SPEC 001-011) for beta release. It covers: end-to-end integration testing, Firebase Crashlytics integration for crash/performance monitoring, an in-app feedback mechanism (menu option with device info attachment), beta welcome screen, RTL quality audit, accessibility labels, and performance validation under load. No new Supabase tables are needed — crash/feedback data flows to Firebase.

## Technical Context

**Language/Version**: Dart 3.x / Flutter (stable channel)
**Primary Dependencies**: Flutter, Riverpod, GoRouter, Supabase Flutter SDK, Firebase Core, Firebase Crashlytics, Firebase FCM
**Storage**: Supabase PostgreSQL (existing); Firebase Crashlytics (new — crash/performance data); no new local storage beyond existing offline queue
**Testing**: flutter_test, integration_test (Flutter integration testing framework)
**Target Platform**: iOS 15+, Android 12+ (mid-range devices: Samsung Galaxy A54, iPhone 12)
**Project Type**: mobile-app
**Performance Goals**: 60fps scrolling with 200 items, <2s screen loads, <3s cold start, <200ms mark-as-purchased tap response
**Constraints**: Offline-capable (queue actions), RTL layout for Arabic, 44x44pt minimum touch targets, <1% crash rate
**Scale/Scope**: Up to 100 concurrent beta users, 20 shopping lists per home, 500 items per home, 5 simultaneous editors

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle                        | Status | Notes                                                                                                         |
| -------------------------------- | ------ | ------------------------------------------------------------------------------------------------------------- |
| Feature-First Clean Architecture | PASS   | New code (feedback, beta screen, accessibility) will be placed in appropriate feature modules or `lib/shared`  |
| Spec-Driven Development          | PASS   | Following full specify → clarify → plan → tasks cycle                                                          |
| Security & RLS First             | PASS   | No new Supabase tables; feedback/crash data goes to Firebase, not Supabase                                     |
| MVP Discipline                   | PASS   | This spec stabilizes the MVP; no new features added                                                            |
| Arabic RTL from Day One          | PASS   | RTL audit and fixes are a core deliverable                                                                     |
| Realtime Collaboration           | PASS   | Existing realtime sync is validated, not modified                                                              |

**Gate Result**: All gates pass. No violations.

## Project Structure

### Documentation (this feature)

```text
specs/012-mvp-hardening-beta/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
└── tasks.md             # Phase 2 output (/speckit.tasks command)
```

### Source Code (repository root)

```text
lib/
├── core/
│   ├── monitoring/          # NEW: Crashlytics wrapper service
│   ├── error_handling/      # NEW: Centralized error handler, error screens
│   └── accessibility/       # NEW: Accessibility helpers, semantic labels
├── features/
│   ├── auth/                # EXISTING: Add accessibility labels, error handling
│   ├── homes/               # EXISTING: Add accessibility labels, error handling
│   ├── shopping_lists/      # EXISTING: Add accessibility labels, performance checks
│   ├── shopping_items/      # EXISTING: Add accessibility labels, performance checks
│   ├── shopping_mode/       # EXISTING: Add accessibility labels, performance checks
│   ├── categories/          # EXISTING: Add accessibility labels
│   ├── invitations/         # EXISTING: Add accessibility labels
│   ├── notifications/       # EXISTING: Add accessibility labels
│   ├── activity_logs/       # EXISTING: Add accessibility labels
│   ├── offline_queue/       # EXISTING: Validate offline/online transitions
│   └── beta/                # NEW: Beta welcome screen, feedback form, satisfaction survey
└── shared/
    └── widgets/             # EXISTING: Add accessibility semantics to shared widgets

test/
├── integration/             # NEW: End-to-end shopping journey tests
├── widget/                  # EXISTING: Add widget tests for new beta screens
└── unit/                    # EXISTING: Add unit tests for monitoring service

android/app/build.gradle     # ADD: Firebase Crashlytics plugin
ios/Runner/Info.plist        # ADD: Firebase Crashlytics configuration
pubspec.yaml                 # ADD: firebase_crashlytics dependency
```

**Structure Decision**: Follows the existing feature-first architecture. New code is isolated in `lib/features/beta/` (beta-specific UI) and `lib/core/monitoring/` (cross-cutting Crashlytics integration). No structural changes to existing features — only additive modifications (accessibility labels, error handling wrappers).
