# Implementation Plan: Shopping Items

**Branch**: `006-shopping-items` | **Date**: 2026-05-12 | **Spec**: [spec.md](spec.md)  
**Input**: Feature specification from `/specs/006-shopping-items/spec.md`

## Summary

Enhance the existing shopping lists feature (SPEC 05) with advanced item management: category-based grouping with collapsible headers, duplicate name warnings, autocomplete suggestions showing name+quantity+unit, template auto-create on add only, running price total for unpurchased items, search/filter within lists, Quick Add from templates, and undo delete with 5-second window. No new Supabase tables required — all functionality builds on existing `shopping_items` and `item_templates` tables.

## Technical Context

**Language/Version**: Dart 3.x / Flutter 3.x  
**Primary Dependencies**: Riverpod, GoRouter, Supabase Flutter, Firebase FCM  
**Storage**: Supabase PostgreSQL with RLS (existing tables: `shopping_items`, `item_templates`)  
**Testing**: flutter_test, mockito  
**Target Platform**: iOS, Android  
**Project Type**: Mobile App (Flutter)  
**Performance Goals**: 60 fps UI, <500ms autocomplete, <2s real-time sync  
**Constraints**: Arabic RTL support, bilingual names, offline-capable (basic)  
**Scale/Scope**: ~8 enhanced screens/widgets, 0 new entities, up to 200 items per list

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| Feature-First Clean Architecture | ✅ PASS | Enhances existing `lib/features/shopping_lists/` — no new feature directory needed |
| Spec-Driven Development | ✅ PASS | Following full Spec Kit cycle |
| Security & RLS First | ✅ PASS | All existing RLS policies remain valid; no new tables |
| MVP Discipline | ✅ PASS | Shopping items are core MVP; no scope creep |
| Arabic RTL from Day One | ✅ PASS | All enhanced UI will support RTL with bilingual names |
| Realtime Collaboration | ✅ PASS | Existing Supabase Realtime subscriptions handle sync |

### Post-Phase 1 Re-evaluation

| Principle | Status | Notes |
|-----------|--------|-------|
| Feature-First Clean Architecture | ✅ PASS | All changes contained within existing feature structure |
| Spec-Driven Development | ✅ PASS | All design artifacts generated (research, data-model, contracts, quickstart) |
| Security & RLS First | ✅ PASS | No schema changes; existing RLS policies sufficient |
| MVP Discipline | ✅ PASS | No scope creep; focused on item management enhancements |
| Arabic RTL from Day One | ✅ PASS | Will reuse existing bilingual text helper and RTL patterns |
| Realtime Collaboration | ✅ PASS | Existing subscriptions cover all item operations |

## Project Structure

### Documentation (this feature)

```text
specs/006-shopping-items/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
│   └── provider-contracts.md
└── tasks.md             # Phase 2 output (/speckit.tasks command)
```

### Source Code (repository root)

```text
lib/
├── features/
│   └── shopping_lists/          # Enhanced from SPEC 05
│       ├── data/
│       │   ├── models/
│       │   │   ├── shopping_list_model.dart        (no change)
│       │   │   ├── shopping_item_model.dart         (no change)
│       │   │   └── item_template_model.dart         (no change)
│       │   └── repositories/
│       │       ├── shopping_list_repository.dart     (add autocomplete method)
│       │       ├── supabase_shopping_list_repository.dart  (implement autocomplete)
│       │       └── item_template_repository.dart     (add sync-on-add)
│       ├── domain/
│       │   ├── entities/
│       │   │   ├── shopping_list.dart               (no change)
│       │   │   ├── shopping_item.dart               (no change)
│       │   │   └── item_template.dart               (no change)
│       │   └── usecases/
│       │       ├── add_item_usecase.dart             (add duplicate check + template sync)
│       │       ├── update_item_usecase.dart           (ensure no template sync)
│       │       ├── delete_item_usecase.dart           (add undo support)
│       │       ├── get_shopping_items_usecase.dart    (add grouping logic)
│       │       ├── search_items_usecase.dart          (add autocomplete source)
│       │       ├── mark_item_purchased_usecase.dart   (no change)
│       │       ├── create_shopping_list_usecase.dart  (no change)
│       │       ├── archive_list_usecase.dart          (no change)
│       │       ├── delete_list_usecase.dart           (no change)
│       │       └── get_shopping_lists_usecase.dart    (no change)
│       └── presentation/
│           ├── providers/
│           │   ├── shopping_lists_provider.dart       (no change)
│           │   └── shopping_items_provider.dart       (add grouping, filter, undo, price total)
│           ├── screens/
│           │   ├── shopping_list_detail_screen.dart   (add category grouping, search, filter, price total)
│           │   ├── add_item_screen.dart               (add autocomplete, duplicate warning)
│           │   ├── edit_item_screen.dart               (ensure no template sync)
│           │   ├── shopping_lists_screen.dart          (no change)
│           │   ├── list_summary_screen.dart            (no change)
│           │   └── quick_add_screen.dart               (enhance template picker)
│           └── widgets/
│               ├── shopping_item_tile_widget.dart      (update for grouped display)
│               ├── item_suggestions_widget.dart        (enhance autocomplete content)
│               ├── category_filter_widget.dart         (add filter functionality)
│               └── shopping_list_card_widget.dart      (no change)
└── core/
    └── utils/
        └── offline_sync_helper.dart                    (no change)

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

**Structure Decision**: Enhancing existing `lib/features/shopping_lists/` from SPEC 05. No new feature directory. All changes are incremental enhancements to existing files. Zero new entities or tables.

## Complexity Tracking

> No constitution violations to justify. All principles satisfied.
