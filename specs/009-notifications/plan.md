# Implementation Plan: Notifications

**Branch**: `feature/009-notifications` | **Date**: 2026-05-13 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/009-notifications/spec.md`

## Summary

Implement a notification system for Beity that delivers push notifications for shopping list changes, home activity, and invitations. Uses Firebase FCM via Supabase Edge Functions for reliable delivery, with server-side throttling (2-minute batching), per-user category preferences, a notification center with 30-day history, deep linking, and Arabic/English bilingual content. Notifications are private to each user and suppressed when the user is viewing the relevant screen in real-time.

## Technical Context

**Language/Version**: Dart 3.x / Flutter 3.x
**Primary Dependencies**: Riverpod, GoRouter, Supabase Flutter, Firebase FCM, flutter_local_notifications
**Storage**: Supabase PostgreSQL (notifications, notification_preferences), existing device_tokens table
**Testing**: flutter_test, mockito
**Target Platform**: iOS, Android
**Project Type**: Mobile App (Flutter)
**Performance Goals**: <5s notification delivery, <3s notification center load, 60 fps UI
**Constraints**: Arabic RTL support, bilingual content, 30-day retention, offline-resilient delivery
**Scale/Scope**: ~3 screens, 2 new entities, 5 Edge Functions, 3 database triggers

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| Feature-First Clean Architecture | ✅ PASS | Will organize under `lib/features/notifications/` |
| Spec-Driven Development | ✅ PASS | Following full Spec Kit cycle |
| Security & RLS First | ✅ PASS | All tables have RLS policies with user_id isolation (notifications are private) |
| MVP Discipline | ✅ PASS | Notifications support the core shopping list MVP collaboration |
| Arabic RTL from Day One | ✅ PASS | Server-side bilingual content, RTL-aware UI |
| Realtime Collaboration | ✅ PASS | Complements Realtime sync with background push delivery |

### Post-Phase 1 Re-evaluation

| Principle | Status | Notes |
|-----------|--------|-------|
| Feature-First Clean Architecture | ✅ PASS | Structure follows `lib/features/notifications/` with data/domain/presentation layers |
| Spec-Driven Development | ✅ PASS | All design artifacts generated (research, data-model, contracts, quickstart) |
| Security & RLS First | ✅ PASS | Both tables have RLS with user_id isolation; service role for inserts only |
| MVP Discipline | ✅ PASS | Focused on notification delivery and preferences; no analytics or advanced features |
| Arabic RTL from Day One | ✅ PASS | Bilingual templates defined in contracts, locale-aware Edge Function |
| Realtime Collaboration | ✅ PASS | Suppression logic coordinates with existing Realtime subscriptions |

## Project Structure

### Documentation (this feature)

```text
specs/009-notifications/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/
│   └── notification-functions.md  # Edge Function contracts
└── tasks.md             # Phase 2 output (/speckit.tasks command)
```

### Source Code (repository root)

```text
lib/
├── features/
│   └── notifications/
│       ├── data/
│       │   ├── models/
│       │   │   ├── notification_model.dart
│       │   │   └── notification_preference_model.dart
│       │   └── repositories/
│       │       ├── notification_repository.dart
│       │       └── supabase_notification_repository.dart
│       ├── domain/
│       │   ├── entities/
│       │   │   ├── notification.dart
│       │   │   └── notification_preference.dart
│       │   └── usecases/
│       │       ├── get_notification_history_usecase.dart
│       │       ├── mark_notifications_read_usecase.dart
│       │       ├── update_notification_preferences_usecase.dart
│       │       └── get_unread_count_usecase.dart
│       └── presentation/
│           ├── providers/
│           │   ├── notifications_provider.dart
│           │   ├── notification_preferences_provider.dart
│           │   └── unread_count_provider.dart
│           ├── screens/
│           │   ├── notification_center_screen.dart
│           │   └── notification_preferences_screen.dart
│           └── widgets/
│               ├── notification_tile_widget.dart
│               ├── notification_badge_widget.dart
│               └── notification_preference_toggle.dart
└── core/
    └── services/
        └── notification_service.dart  # Existing, updated with deep link handling

supabase/
└── functions/
    ├── send-notification/
    │   └── index.ts
    ├── get-notification-history/
    │   └── index.ts
    ├── mark-notifications-read/
    │   └── index.ts
    ├── update-notification-preferences/
    │   └── index.ts
    └── cleanup-old-notifications/
        └── index.ts

tests/
├── unit/
│   └── features/
│       └── notifications/
│           ├── repositories/
│           └── usecases/
├── widget/
│   └── features/
│       └── notifications/
└── integration/
    └── features/
        └── notifications/
```

**Structure Decision**: Using Flutter feature-first architecture with Riverpod. Feature isolated under `lib/features/notifications/` with data/domain/presentation layers. Edge Functions in `supabase/functions/`. Reuses existing `notification_service.dart` in core services for FCM handling.

## Complexity Tracking

> No constitution violations to justify. All principles satisfied.
