# Implementation Plan: Activity Logs

**Branch**: `feature/008-activity-logs` | **Date**: 2026-05-13 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/008-activity-logs/spec.md`

## Summary

Implement an activity logging feature that tracks actions performed by home members on shopping lists, items, and membership. The `activity_logs` table already exists in Supabase with RLS policies. This feature adds:
- **Database triggers**: PostgreSQL triggers on `shopping_lists`, `shopping_items`, `home_members`, and `invitations` to automatically insert activity log entries
- **Actor name denormalization**: Add `actor_name` column to preserve display name at time of action
- **Flutter feature**: New `lib/features/activity_logs/` with repository, providers, screens, and widgets
- **Real-time feed**: Use existing `RealtimeService.watchTable()` to stream new log entries to the UI
- **Home-level and list-level views**: Home activity feed + per-list activity view
- **Filtering**: Filter by actor and action type

## Technical Context

**Language/Version**: Dart 3.x, Flutter 3.x
**Primary Dependencies**: supabase_flutter ^2.8.4, flutter_riverpod, go_router
**Storage**: Supabase PostgreSQL (existing `activity_logs` table + new triggers)
**Testing**: flutter_test, mocktail for mocking Supabase client
**Target Platform**: Android (primary), iOS (secondary)
**Project Type**: Mobile app (Flutter)
**Performance Goals**: <1s feed load, <3s log propagation, responsive with 500 entries
**Constraints**: Arabic RTL support, append-only logs, server-side generation via triggers
**Scale/Scope**: 1 new feature directory, 1 new migration (triggers + column), ~6 new Dart files

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Feature-First Clean Architecture | ✅ | New code under `lib/features/activity_logs/` with data/domain/presentation layers |
| II. Spec-Driven Development | ✅ | Spec completed with 5 clarifications, plan in progress |
| III. Security & RLS First | ✅ | Existing RLS on `activity_logs` enforces home_id isolation. SELECT and INSERT policies already in place. No new tables. |
| IV. MVP Discipline | ✅ | Activity logs provide transparency for shared shopping lists — core MVP coordination feature |
| V. Arabic RTL from Day One | ✅ | All new UI will support RTL. Feed layout adapts to locale direction |
| VI. Realtime Collaboration | ✅ | Uses existing RealtimeService to stream log entries in real-time |

**Gate Result**: PASS — no violations.

## Project Structure

### Documentation (this feature)

```text
specs/008-activity-logs/
├── plan.md              # This file
├── spec.md              # Feature specification
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
│   └── activity-log-repository.md
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```text
lib/
├── features/
│   └── activity_logs/                  # NEW feature directory
│       ├── data/
│       │   ├── models/
│       │   │   └── activity_log_model.dart          # Supabase row → domain entity mapper
│       │   └── repositories/
│       │       ├── activity_log_repository.dart       # Abstract interface
│       │       └── supabase_activity_log_repository.dart  # Supabase implementation
│       ├── domain/
│       │   └── entities/
│       │       └── activity_log.dart                 # Domain entity + ActionType enum
│       └── presentation/
│           ├── providers/
│           │   └── activity_logs_provider.dart        # Riverpod providers (home feed, list feed, filters)
│           ├── screens/
│           │   ├── activity_feed_screen.dart          # Home-level activity feed
│           │   ├── list_activity_screen.dart          # List-level activity view
│           │   └── activity_detail_screen.dart        # Single entry detail view
│           └── widgets/
│               ├── activity_log_tile_widget.dart      # Single log entry display
│               └── activity_filter_widget.dart        # Filter by actor/action type

supabase/
└── migrations/
    └── 20260513_add_activity_log_triggers.sql  # NEW: triggers + actor_name column

tests/
├── unit/
│   └── features/
│       └── activity_logs/
│           ├── repositories/
│           │   └── supabase_activity_log_repository_test.dart
│           └── domain/
│               └── activity_log_test.dart
├── integration/
│   └── features/
│       └── activity_logs/
└── widget/
    └── features/
        └── activity_logs/
```

**Structure Decision**: New feature directory `lib/features/activity_logs/` following feature-first clean architecture. Database triggers handle log generation server-side; Flutter app only reads and displays logs.

## Complexity Tracking

> No constitution violations to justify. All principles satisfied.
