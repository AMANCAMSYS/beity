# Implementation Plan: Offline Queue

**Branch**: `011-offline-queue` | **Date**: 2026-05-13 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/011-offline-queue/spec.md`

## Summary

Implement an offline queue system for Beity that captures shopping list actions (add, update, delete, mark purchased) when the device loses connectivity, persists them locally using Isar, and automatically syncs when connectivity is restored. Uses last-write-wins conflict resolution with exponential backoff retry (max 5 attempts). Queue entries are cleaned up immediately on successful sync. Supports Arabic RTL layout for all UI elements.

## Technical Context

**Language/Version**: Dart 3.x / Flutter 3.x  
**Primary Dependencies**: Riverpod, GoRouter, Supabase Flutter, Isar, connectivity_plus  
**Storage**: Isar (local queue persistence), Supabase PostgreSQL (server state)  
**Testing**: flutter_test, mockito, integration_test  
**Target Platform**: iOS, Android  
**Project Type**: Mobile App (Flutter)  
**Performance Goals**: <1s local queue write, <30s full sync on reconnect, 60 fps UI, <2s real-time sync  
**Constraints**: Arabic RTL support, <200 queued actions without degradation, hybrid offline detection  
**Scale/Scope**: 1 new feature module, 0 new Supabase tables, ~6 widgets, ~5 providers, ~5 use cases

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| Feature-First Clean Architecture | ✅ PASS | Will organize under `lib/features/offline_queue/` |
| Spec-Driven Development | ✅ PASS | Following full Spec Kit cycle |
| Security & RLS First | ✅ PASS | No new Supabase tables; reuses existing RLS on shopping_items |
| MVP Discipline | ✅ PASS | Offline queue enhances core shared shopping list experience |
| Arabic RTL from Day One | ✅ PASS | RTL layout specified for all offline queue UI elements |
| Realtime Collaboration | ✅ PASS | Integrates with existing Supabase Realtime for connectivity detection |

### Post-Phase 1 Re-evaluation

| Principle | Status | Notes |
|-----------|--------|-------|
| Feature-First Clean Architecture | ✅ PASS | Structure follows `lib/features/offline_queue/` with data/domain/presentation layers |
| Spec-Driven Development | ✅ PASS | All design artifacts generated (research, data-model, contracts, quickstart) |
| Security & RLS First | ✅ PASS | No new tables; queue is local-only; existing RLS applies during sync |
| MVP Discipline | ✅ PASS | Focused on offline queue for shopping actions only |
| Arabic RTL from Day One | ✅ PASS | RTL layout defined in quickstart, all widgets support text direction |
| Realtime Collaboration | ✅ PASS | Reuses connectivity detection from Supabase Realtime subscription state |

## Project Structure

### Documentation (this feature)

```text
specs/011-offline-queue/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/
│   └── offline-queue-contracts.md  # Repository and use case contracts
└── tasks.md             # Phase 2 output (/speckit.tasks command)
```

### Source Code (repository root)

```text
lib/
├── features/
│   └── offline_queue/
│       ├── data/
│       │   ├── datasources/
│       │   │   └── isar_queue_datasource.dart
│       │   ├── models/
│       │   │   └── queue_entry_model.dart
│       │   └── repositories/
│       │       ├── offline_queue_repository.dart
│       │       └── isar_offline_queue_repository.dart
│       ├── domain/
│       │   ├── entities/
│       │   │   ├── queue_entry.dart
│       │   │   └── sync_status.dart
│       │   └── usecases/
│       │       ├── enqueue_action_usecase.dart
│       │       ├── sync_queue_usecase.dart
│       │       ├── retry_failed_action_usecase.dart
│       │       ├── get_pending_count_usecase.dart
│       │       └── get_queue_entries_usecase.dart
│       └── presentation/
│           ├── providers/
│           │   ├── offline_queue_provider.dart
│           │   ├── connectivity_provider.dart
│           │   └── sync_status_provider.dart
│           └── widgets/
│               ├── pending_sync_indicator.dart
│               ├── sync_status_banner.dart
│               ├── queue_entry_tile.dart
│               ├── retry_button.dart
│               └── offline_mode_indicator.dart

tests/
├── unit/
│   └── features/
│       └── offline_queue/
│           ├── datasources/
│           ├── repositories/
│           └── usecases/
├── widget/
│   └── features/
│       └── offline_queue/
└── integration/
    └── features/
        └── offline_queue/
```

**Structure Decision**: Using Flutter feature-first architecture with Riverpod. Feature isolated under `lib/features/offline_queue/` with data/domain/presentation layers. No new Supabase tables — queue is local-only using Isar. Integrates with existing shopping_lists and shopping_items features for action execution during sync.

## Complexity Tracking

> No constitution violations to justify. All principles satisfied.
