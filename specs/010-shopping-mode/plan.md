# Implementation Plan: Shopping Mode

**Branch**: `010-shopping-mode` | **Date**: 2026-05-13 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/010-shopping-mode/spec.md`

## Summary

Implement a dedicated shopping mode for Beity that provides a fast, distraction-free interface for actively shopping at a store. Shopping mode is a UI layer over existing shopping list data with a new `shopping_mode_sessions` table for session tracking and history. Features include large tap-to-purchase item cards, category-based grouping with auto-collapse for completed categories, quick-add overlay, progress indicator, search, inline quantity adjustment, screen-awake, and exit summary. Supports multiple simultaneous shoppers on the same list with real-time sync.

## Technical Context

**Language/Version**: Dart 3.x / Flutter 3.x  
**Primary Dependencies**: Riverpod, GoRouter, Supabase Flutter, wakelock_plus  
**Storage**: Supabase PostgreSQL (new `shopping_mode_sessions` table)  
**Testing**: flutter_test, mockito, integration_test  
**Target Platform**: iOS, Android  
**Project Type**: Mobile App (Flutter)  
**Performance Goals**: <2s mark-as-purchased, <10s add item, 60 fps UI, <2s real-time sync  
**Constraints**: Arabic RTL support, offline-resilient, <200 items responsive, screen-awake  
**Scale/Scope**: 1 new screen, 1 new table, ~8 widgets, ~4 providers, ~4 use cases

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| Feature-First Clean Architecture | ✅ PASS | Will organize under `lib/features/shopping_mode/` |
| Spec-Driven Development | ✅ PASS | Following full Spec Kit cycle |
| Security & RLS First | ✅ PASS | `shopping_mode_sessions` table will have RLS with home membership isolation |
| MVP Discipline | ✅ PASS | Shopping mode enhances core shared shopping list experience |
| Arabic RTL from Day One | ✅ PASS | RTL layout specified for all shopping mode UI |
| Realtime Collaboration | ✅ PASS | Real-time sync for concurrent shoppers specified |

### Post-Phase 1 Re-evaluation

| Principle | Status | Notes |
|-----------|--------|-------|
| Feature-First Clean Architecture | ✅ PASS | Structure follows `lib/features/shopping_mode/` with data/domain/presentation layers |
| Spec-Driven Development | ✅ PASS | All design artifacts generated (research, data-model, contracts, quickstart) |
| Security & RLS First | ✅ PASS | `shopping_mode_sessions` has RLS with home_id isolation via parent list |
| MVP Discipline | ✅ PASS | Focused on shopping UI layer; no barcode scanning, price comparison, or store layouts |
| Arabic RTL from Day One | ✅ PASS | RTL layout defined in quickstart, all widgets support text direction |
| Realtime Collaboration | ✅ PASS | Reuses existing Supabase Realtime subscriptions from SPEC 007 |

## Project Structure

### Documentation (this feature)

```text
specs/010-shopping-mode/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/
│   └── shopping-mode-ui-contracts.md  # UI component contracts
└── tasks.md             # Phase 2 output (/speckit.tasks command)
```

### Source Code (repository root)

```text
lib/
├── features/
│   └── shopping_mode/
│       ├── data/
│       │   ├── models/
│       │   │   └── shopping_mode_session_model.dart
│       │   └── repositories/
│       │       ├── shopping_mode_repository.dart
│       │       └── supabase_shopping_mode_repository.dart
│       ├── domain/
│       │   ├── entities/
│       │   │   └── shopping_mode_session.dart
│       │   └── usecases/
│       │       ├── start_shopping_session_usecase.dart
│       │       ├── end_shopping_session_usecase.dart
│       │       ├── get_active_session_usecase.dart
│       │       └── get_shopping_history_usecase.dart
│       └── presentation/
│           ├── providers/
│           │   ├── shopping_mode_provider.dart
│           │   ├── shopping_mode_items_provider.dart
│           │   └── shopping_mode_session_provider.dart
│           ├── screens/
│           │   └── shopping_mode_screen.dart
│           └── widgets/
│               ├── shopping_item_card.dart
│               ├── shopping_category_group.dart
│               ├── shopping_progress_bar.dart
│               ├── shopping_quick_add_overlay.dart
│               ├── shopping_quantity_controls.dart
│               ├── shopping_exit_summary.dart
│               └── shopping_mode_search_bar.dart

supabase/
└── migrations/
    └── 20260513_add_shopping_mode_sessions.sql

tests/
├── unit/
│   └── features/
│       └── shopping_mode/
│           ├── repositories/
│           └── usecases/
├── widget/
│   └── features/
│       └── shopping_mode/
└── integration/
    └── features/
        └── shopping_mode/
```

**Structure Decision**: Using Flutter feature-first architecture with Riverpod. Feature isolated under `lib/features/shopping_mode/` with data/domain/presentation layers. Single migration for the new `shopping_mode_sessions` table. Reuses existing shopping list and item infrastructure from `lib/features/shopping_lists/`.

## Complexity Tracking

> No constitution violations to justify. All principles satisfied.
