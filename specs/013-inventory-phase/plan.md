# Implementation Plan: Inventory Phase

**Branch**: `013-inventory-phase` | **Date**: 2026-05-13 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/013-inventory-phase/spec.md`

## Summary

This spec introduces home inventory tracking to Beity. Users can add, view, update, and delete inventory items grouped by category. Items support fractional quantities, user-defined low-stock thresholds with restock suggestions, and an optional notes field. A full transaction log records every quantity change for accountability. The inventory bridges to the existing shopping list feature: users can add low-stock items to a shopping list, and purchased shopping items can optionally be added to inventory. All data syncs in real-time via Supabase Realtime, and RLS enforces home-scoped access.

## Technical Context

**Language/Version**: Dart 3.x / Flutter (stable channel)
**Primary Dependencies**: Flutter, Riverpod, GoRouter, Supabase Flutter SDK
**Storage**: Supabase PostgreSQL (existing project); two new tables (`inventory_items`, `inventory_transactions`)
**Testing**: flutter_test, integration_test
**Target Platform**: iOS 15+, Android 12+ (mid-range devices: Samsung Galaxy A54, iPhone 12)
**Project Type**: mobile-app
**Performance Goals**: 60fps scrolling with 500 items, <2s screen loads, <200ms quick-adjust tap response, <2s realtime sync
**Constraints**: Offline-capable (queue actions via existing offline queue), RTL layout for Arabic, 44x44pt minimum touch targets
**Scale/Scope**: Up to 500 inventory items per home, 5 simultaneous editors, 100 homes

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle                        | Status | Notes                                                                                                         |
| -------------------------------- | ------ | ------------------------------------------------------------------------------------------------------------- |
| Feature-First Clean Architecture | PASS   | New code isolated in `lib/features/inventory/` with data/domain/presentation layers                           |
| Spec-Driven Development          | PASS   | Following full specify → clarify → plan → tasks cycle                                                          |
| Security & RLS First             | PASS   | Two new tables with RLS policies enforcing home membership via `home_members`                                  |
| MVP Discipline                   | PASS   | Inventory is the next incremental feature after stable shopping-list MVP per AGENTS.md roadmap                 |
| Arabic RTL from Day One          | PASS   | All new screens will support RTL layout from the start                                                         |
| Realtime Collaboration           | PASS   | Inventory changes synced via Supabase Realtime, same pattern as shopping items                                 |

**Gate Result**: All gates pass. No violations.

## Project Structure

### Documentation (this feature)

```text
specs/013-inventory-phase/
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
│   └── inventory/                  # NEW feature module
│       ├── data/
│       │   ├── models/
│       │   │   ├── inventory_item_model.dart
│       │   │   └── inventory_transaction_model.dart
│       │   └── repositories/
│       │       ├── inventory_repository.dart          # Interface
│       │       └── supabase_inventory_repository.dart  # Implementation
│       ├── domain/
│       │   ├── entities/
│       │   │   ├── inventory_item.dart
│       │   │   └── inventory_transaction.dart
│       │   └── usecases/
│       │       ├── add_inventory_item_usecase.dart
│       │       ├── update_inventory_quantity_usecase.dart
│       │       ├── delete_inventory_item_usecase.dart
│       │       ├── get_inventory_items_usecase.dart
│       │       ├── add_to_shopping_list_usecase.dart
│       │       └── add_purchased_to_inventory_usecase.dart
│       └── presentation/
│           ├── providers/
│           │   ├── inventory_provider.dart
│           │   └── inventory_transactions_provider.dart
│           ├── screens/
│           │   ├── inventory_screen.dart
│           │   ├── add_inventory_item_screen.dart
│           │   ├── edit_inventory_item_screen.dart
│           │   └── inventory_item_detail_screen.dart
│           └── widgets/
│               ├── inventory_item_tile.dart
│               ├── quantity_adjuster_widget.dart
│               ├── low_stock_badge.dart
│               └── category_group_header.dart
└── shared/
    └── widgets/                    # EXISTING: may reuse category chips, search bar

test/
├── unit/
│   └── features/
│       └── inventory/              # Repository + use case tests
├── widget/
│   └── features/
│       └── inventory/              # Widget tests for new screens
└── integration/
    └── features/
        └── inventory/              # End-to-end inventory flow tests

supabase/migrations/
└── YYYYMMDDHHMMSS_create_inventory_tables.sql   # NEW migration
```

**Structure Decision**: Follows existing feature-first architecture. New `lib/features/inventory/` module with clean data/domain/presentation separation, matching the pattern established by `shopping_lists`, `categories`, etc.
