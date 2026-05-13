# Implementation Plan: Expenses Phase

**Branch**: `014-expenses-phase` | **Date**: 2026-05-13 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/014-expenses-phase/spec.md`

## Summary

Implement household expense tracking with split capabilities, balance calculations, and settlement recording. The feature enables home members to record shared expenses, split costs fairly, track who owes whom, and record settlements. Builds on existing home membership (SPEC 02) and category (SPEC 04) systems.

## Technical Context

**Language/Version**: Dart 3.x / Flutter 3.x
**Primary Dependencies**: Riverpod, GoRouter, Supabase (PostgreSQL, Auth, Realtime)
**Storage**: Supabase PostgreSQL with RLS
**Testing**: flutter test (unit, widget, integration)
**Target Platform**: iOS and Android mobile apps
**Performance Goals**: Expense recording < 30s, history load < 2s, balance calc < 1s, realtime sync < 2s
**Constraints**: Arabic RTL support, offline deferred, manual currency conversion
**Scale/Scope**: Home-level data (typically < 1000 expenses per home, < 20 members)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| Feature-First Clean Architecture | ✅ PASS | Will organize under `lib/features/expenses` with data/domain/presentation layers |
| Spec-Driven Development | ✅ PASS | Following full spec cycle: specify → clarify → plan → tasks → analyze → implement |
| Security & RLS First | ✅ PASS | All tables will have `home_id` and RLS policies; access through home membership |
| MVP Discipline | ✅ PASS | Core shopping list MVP stable; expenses is next logical feature per roadmap |
| Arabic RTL from Day One | ✅ PASS | All UI will support RTL layout from implementation start |
| Realtime Collaboration | ✅ PASS | Expense and settlement changes sync via Supabase Realtime |

**Gate Result**: PASS — No violations detected.

## Project Structure

### Documentation (this feature)

```text
specs/014-expenses-phase/
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
│   └── expenses/
│       ├── data/
│       │   ├── datasources/
│       │   │   ├── expense_remote_datasource.dart
│       │   │   └── settlement_remote_datasource.dart
│       │   ├── models/
│       │   │   ├── expense_model.dart
│       │   │   ├── expense_split_model.dart
│       │   │   └── settlement_model.dart
│       │   └── repositories/
│       │       ├── expense_repository_impl.dart
│       │       └── settlement_repository_impl.dart
│       ├── domain/
│       │   ├── entities/
│       │   │   ├── expense.dart
│       │   │   ├── expense_split.dart
│       │   │   ├── settlement.dart
│       │   │   └── balance.dart
│       │   ├── repositories/
│       │   │   ├── expense_repository.dart
│       │   │   └── settlement_repository.dart
│       │   └── usecases/
│       │       ├── add_expense.dart
│       │       ├── edit_expense.dart
│       │       ├── delete_expense.dart
│       │       ├── split_expense.dart
│       │       ├── calculate_balances.dart
│       │       ├── record_settlement.dart
│       │       └── get_expense_summary.dart
│       └── presentation/
│           ├── providers/
│           │   ├── expense_providers.dart
│           │   └── balance_providers.dart
│           ├── screens/
│           │   ├── expense_list_screen.dart
│           │   ├── add_expense_screen.dart
│           │   ├── expense_detail_screen.dart
│           │   ├── balances_screen.dart
│           │   └── expense_summary_screen.dart
│           └── widgets/
│               ├── expense_card.dart
│               ├── split_selector.dart
│               ├── balance_card.dart
│               └── settlement_form.dart
└── core/
    └── (existing shared code)

test/
├── features/
│   └── expenses/
│       ├── data/
│       │   └── repositories/
│       │       ├── expense_repository_impl_test.dart
│       │       └── settlement_repository_impl_test.dart
│       ├── domain/
│       │   └── usecases/
│       │       ├── add_expense_test.dart
│       │       ├── split_expense_test.dart
│       │       ├── calculate_balances_test.dart
│       │       └── record_settlement_test.dart
│       └── presentation/
│           └── (widget tests for critical flows)
└── integration/
    └── expense_flow_test.dart
```

**Structure Decision**: Following feature-first clean architecture pattern established in the project. Each layer (data, domain, presentation) is isolated under `lib/features/expenses`.
