# Implementation Plan: Categories and Units

**Branch**: `004-categories-and-units` | **Date**: 2026-05-12 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/004-categories-and-units/spec.md`

## Summary

Implement a complete categories and units management system for Beity home management app. Users can view default categories and units, create custom ones for their homes, and manage them with full CRUD operations. Includes bilingual support (Arabic/English) and role-based permissions.

## Technical Context

**Language/Version**: Dart 3.x / Flutter 3.x  
**Primary Dependencies**: Riverpod, GoRouter, Supabase Flutter  
**Storage**: Supabase PostgreSQL with RLS  
**Testing**: flutter_test, mockito  
**Target Platform**: iOS, Android, Web  
**Project Type**: Mobile App (Flutter)  
**Performance Goals**: 60 fps UI, <2s screen load  
**Constraints**: Arabic RTL support, bilingual names  
**Scale/Scope**: ~8 screens, 2 new entities

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| Feature-First Clean Architecture | ✅ PASS | Will organize under `lib/features/categories/` |
| Spec-Driven Development | ✅ PASS | Following full Spec Kit cycle |
| Security & RLS First | ✅ PASS | All tables will have RLS policies |
| MVP Discipline | ✅ PASS | Categories/units are core for shopping lists |
| Arabic RTL from Day One | ✅ PASS | All UI will support RTL with bilingual names |
| Realtime Collaboration | ✅ PASS | Will use Supabase Realtime for updates |

## Project Structure

### Documentation (this feature)

```text
specs/004-categories-and-units/
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
│   └── categories/
│       ├── data/
│       │   ├── models/
│       │   │   ├── category_model.dart
│       │   │   └── unit_model.dart
│       │   └── repositories/
│       │       ├── category_repository.dart
│       │       └── unit_repository.dart
│       ├── domain/
│       │   ├── entities/
│       │   │   ├── category.dart
│       │   │   └── unit.dart
│       │   └── usecases/
│       │       ├── get_categories_usecase.dart
│       │       ├── create_category_usecase.dart
│       │       ├── update_category_usecase.dart
│       │       ├── delete_category_usecase.dart
│       │       ├── get_units_usecase.dart
│       │       ├── create_unit_usecase.dart
│       │       ├── update_unit_usecase.dart
│       │       └── delete_unit_usecase.dart
│       └── presentation/
│           ├── providers/
│           │   ├── categories_provider.dart
│           │   └── units_provider.dart
│           ├── screens/
│           │   ├── categories_list_screen.dart
│           │   ├── create_category_screen.dart
│           │   ├── units_list_screen.dart
│           │   └── create_unit_screen.dart
│           └── widgets/
│               ├── category_card_widget.dart
│               └── unit_card_widget.dart
└── core/
    └── utils/
        └── bilingual_text_helper.dart

tests/
├── unit/
│   └── features/
│       └── categories/
│           ├── repositories/
│           └── usecases/
├── integration/
│   └── features/
│       └── categories/
└── widget/
    └── features/
        └── categories/
```

**Structure Decision**: Using Flutter feature-first architecture with Riverpod for state management. Feature isolated under `lib/features/categories/` with clear separation of data, domain, and presentation layers. Includes bilingual text helper for Arabic/English support.

## Complexity Tracking

> No constitution violations to justify. All principles satisfied.
