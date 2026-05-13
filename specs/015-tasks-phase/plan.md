# Implementation Plan: Tasks Phase

**Branch**: `015-tasks-phase` | **Date**: 2026-05-13 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/015-tasks-phase/spec.md`

## Summary

Implement shared household task management with assignment, completion tracking, recurring tasks, and comments. The feature enables home members to create tasks, assign them to members, track completion, set recurrence patterns (daily/weekly/monthly), filter and sort tasks, and add comments. Builds on existing home membership (SPEC 02) and category (SPEC 04) systems.

## Technical Context

**Language/Version**: Dart 3.x / Flutter 3.x
**Primary Dependencies**: Riverpod, GoRouter, Supabase (PostgreSQL, Auth, Realtime)
**Storage**: Supabase PostgreSQL with RLS
**Testing**: flutter test (unit, widget, integration)
**Target Platform**: iOS and Android mobile apps
**Performance Goals**: Task creation < 15s, list load < 2s, realtime sync < 2s, recurrence regen < 1s
**Constraints**: Arabic RTL support, offline deferred, role-based edit permissions
**Scale/Scope**: Home-level data (typically < 500 tasks per home, < 20 members)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| Feature-First Clean Architecture | ✅ PASS | Will organize under `lib/features/tasks` with data/domain/presentation layers |
| Spec-Driven Development | ✅ PASS | Following full spec cycle: specify → clarify → plan → tasks → analyze → implement |
| Security & RLS First | ✅ PASS | All tables will have `home_id` and RLS policies; access through home membership |
| MVP Discipline | ✅ PASS | Core shopping list MVP stable; tasks is next logical feature per roadmap |
| Arabic RTL from Day One | ✅ PASS | All UI will support RTL layout from implementation start |
| Realtime Collaboration | ✅ PASS | Task and comment changes sync via Supabase Realtime |

**Gate Result**: PASS — No violations detected.

## Project Structure

### Documentation (this feature)

```text
specs/015-tasks-phase/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
└── tasks.md             # Phase 2 output (via /speckit.tasks)
```

### Source Code (repository root)

```text
lib/
├── features/
│   └── tasks/
│       ├── data/
│       │   ├── datasources/
│       │   │   ├── task_remote_datasource.dart
│       │   │   └── task_comment_remote_datasource.dart
│       │   ├── models/
│       │   │   ├── task_model.dart
│       │   │   └── task_comment_model.dart
│       │   └── repositories/
│       │       ├── task_repository_impl.dart
│       │       └── task_comment_repository_impl.dart
│       ├── domain/
│       │   ├── entities/
│       │   │   ├── task.dart
│       │   │   └── task_comment.dart
│       │   ├── repositories/
│       │   │   ├── task_repository.dart
│       │   │   └── task_comment_repository.dart
│       │   └── usecases/
│       │       ├── create_task.dart
│       │       ├── edit_task.dart
│       │       ├── complete_task.dart
│       │       ├── assign_task.dart
│       │       ├── archive_task.dart
│       │       ├── manage_recurrence.dart
│       │       ├── add_comment.dart
│       │       └── get_tasks.dart
│       └── presentation/
│           ├── providers/
│           │   ├── task_providers.dart
│           │   └── task_filter_providers.dart
│           ├── screens/
│           │   ├── task_list_screen.dart
│           │   ├── add_task_screen.dart
│           │   ├── task_detail_screen.dart
│           │   └── archived_tasks_screen.dart
│           └── widgets/
│               ├── task_card.dart
│               ├── task_tabs.dart
│               ├── recurrence_selector.dart
│               ├── task_filter_bar.dart
│               └── comment_thread.dart
└── core/
    └── (existing shared code)

test/
├── features/
│   └── tasks/
│       ├── data/
│       │   └── repositories/
│       │       ├── task_repository_impl_test.dart
│       │       └── task_comment_repository_impl_test.dart
│       ├── domain/
│       │   └── usecases/
│       │       ├── create_task_test.dart
│       │       ├── complete_task_test.dart
│       │       ├── manage_recurrence_test.dart
│       │       └── archive_task_test.dart
│       └── presentation/
│           └── (widget tests for critical flows)
└── integration/
    └── task_flow_test.dart
```

**Structure Decision**: Following feature-first clean architecture pattern established in the project. Each layer (data, domain, presentation) is isolated under `lib/features/tasks`.
