# Implementation Plan: Shopping Lists

**Branch**: `005-shopping-lists` | **Date**: 2026-05-12 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/005-shopping-lists/spec.md`

## Summary

Implement a complete shopping list management system for Beity home management app. Users can create multiple shopping lists per home, add items with categories/units/prices, mark items as purchased, collaborate in real-time with family members, and receive notifications. Includes basic offline support (view + edit locally, auto-sync when reconnected) and Arabic RTL support.

## Technical Context

**Language/Version**: Dart 3.x / Flutter 3.x  
**Primary Dependencies**: Riverpod, GoRouter, Supabase Flutter, Firebase FCM  
**Storage**: Supabase PostgreSQL with RLS + Isar for offline caching (basic MVP - view/edit locally)  
**Testing**: flutter_test, mockito  
**Target Platform**: iOS, Android  
**Project Type**: Mobile App (Flutter)  
**Performance Goals**: 60 fps UI, <2s screen load, <2s real-time sync  
**Constraints**: Arabic RTL support, bilingual names, offline-capable (basic)  
**Scale/Scope**: ~10 screens, 3 new entities, up to 200 items per list

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| Feature-First Clean Architecture | ✅ PASS | Will organize under `lib/features/shopping_lists/` |
| Spec-Driven Development | ✅ PASS | Following full Spec Kit cycle |
| Security & RLS First | ✅ PASS | All tables will have RLS policies with home_id isolation |
| MVP Discipline | ✅ PASS | Shopping lists are the core MVP feature |
| Arabic RTL from Day One | ✅ PASS | All UI will support RTL with bilingual names |
| Realtime Collaboration | ✅ PASS | Will use Supabase Realtime for live updates |

### Post-Phase 1 Re-evaluation

| Principle | Status | Notes |
|-----------|--------|-------|
| Feature-First Clean Architecture | ✅ PASS | Structure follows `lib/features/shopping_lists/` with data/domain/presentation layers |
| Spec-Driven Development | ✅ PASS | All design artifacts generated (research, data-model, contracts, quickstart) |
| Security & RLS First | ✅ PASS | All 3 tables have comprehensive RLS policies with home_id isolation |
| MVP Discipline | ✅ PASS | No scope creep; focused on core shopping list functionality |
| Arabic RTL from Day One | ✅ PASS | Will reuse existing bilingual text helper and RTL patterns |
| Realtime Collaboration | ✅ PASS | Supabase Realtime subscriptions defined for shopping_items and shopping_lists |

## Project Structure

### Documentation (this feature)

```text
specs/005-shopping-lists/
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
├── features/
│   └── shopping_lists/
│       ├── data/
│       │   ├── models/
│       │   │   ├── shopping_list_model.dart
│       │   │   ├── shopping_item_model.dart
│       │   │   └── item_template_model.dart
│       │   └── repositories/
│       │       ├── shopping_list_repository.dart
│       │       └── supabase_shopping_list_repository.dart
│       ├── domain/
│       │   ├── entities/
│       │   │   ├── shopping_list.dart
│       │   │   ├── shopping_item.dart
│       │   │   └── item_template.dart
│       │   └── usecases/
│       │       ├── create_shopping_list_usecase.dart
│       │       ├── add_item_usecase.dart
│       │       ├── update_item_usecase.dart
│       │       ├── delete_item_usecase.dart
│       │       ├── mark_item_purchased_usecase.dart
│       │       ├── archive_list_usecase.dart
│       │       ├── delete_list_usecase.dart
│       │       ├── get_shopping_lists_usecase.dart
│       │       ├── get_shopping_items_usecase.dart
│       │       └── search_items_usecase.dart
│       └── presentation/
│           ├── providers/
│           │   ├── shopping_lists_provider.dart
│           │   └── shopping_items_provider.dart
│           ├── screens/
│           │   ├── shopping_lists_screen.dart
│           │   ├── shopping_list_detail_screen.dart
│           │   ├── add_item_screen.dart
│           │   ├── edit_item_screen.dart
│           │   ├── list_summary_screen.dart
│           │   └── quick_add_screen.dart
│           └── widgets/
│               ├── shopping_list_card_widget.dart
│               ├── shopping_item_tile_widget.dart
│               ├── item_suggestions_widget.dart
│               └── category_filter_widget.dart
└── core/
    └── utils/
        └── offline_sync_helper.dart

tests/
├── unit/
│   └── features/
│       └── shopping_lists/
│           ├── repositories/
│           └── usecases/
├── integration/
│   └── features/
│       └── shopping_lists/
└── widget/
    └── features/
        └── shopping_lists/
```

**Structure Decision**: Using Flutter feature-first architecture with Riverpod for state management. Feature isolated under `lib/features/shopping_lists/` with clear separation of data, domain, and presentation layers. Includes offline sync helper for basic offline support.

## Complexity Tracking

> No constitution violations to justify. All principles satisfied.
