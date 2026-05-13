# Implementation Plan: Realtime Sync

**Branch**: `feature/007-realtime-sync` | **Date**: 2026-05-13 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/007-realtime-sync/spec.md`

## Summary

Enhance the existing Supabase Realtime integration (`.stream()` for Postgres Changes) with presence tracking, connection state management, offline change queuing, and improved conflict UX. The project already uses `StreamProvider` with Supabase's `.stream(primaryKey:)` for shopping lists and items. This feature adds:
- **Presence**: Track who is viewing each shopping list using Supabase Realtime Presence
- **Connection state**: Detect online/offline transitions, show status indicators, fetch missed updates on reconnect
- **Offline queue**: Queue mutations locally while offline, discard on logout with warning
- **Conflict feedback**: Toast + item highlight when last-write-wins overwrites a user's edit
- **Home-level realtime**: Stream home_members and categories changes
- **Removed member redirect**: Detect removal via realtime and redirect with dialog

## Technical Context

**Language/Version**: Dart 3.x, Flutter 3.x
**Primary Dependencies**: supabase_flutter ^2.8.4, flutter_riverpod, go_router
**Storage**: Supabase PostgreSQL (existing), Shared Preferences (offline queue), no Isar yet (post-MVP)
**Testing**: flutter_test, mocktail for mocking Supabase client
**Target Platform**: Android (primary), iOS (secondary)
**Project Type**: Mobile app (Flutter)
**Performance Goals**: <1s sync latency for item changes, <3s reconnect sync
**Constraints**: Small family groups (2-10 members), Arabic RTL support required
**Scale/Scope**: Per-list presence, per-home realtime streams, offline queue bounded to active session

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Feature-First Clean Architecture | ✅ | New code under `lib/core/services/` (shared realtime service) and enhanced providers in existing feature dirs |
| II. Spec-Driven Development | ✅ | Spec completed with clarifications, plan in progress |
| III. Security & RLS First | ✅ | Existing RLS on shopping_lists/shopping_items already enforces home_id isolation. Presence data is ephemeral and scoped to list_id via channel naming |
| IV. MVP Discipline | ✅ | Realtime sync is core MVP requirement per AGENTS.md. Offline queue is minimal (session-only, no Isar). Push notifications deferred |
| V. Arabic RTL from Day One | ✅ | UI components (connection indicator, toast, dialog) must support RTL. No new text-heavy screens |
| VI. Realtime Collaboration | ✅ | This is the feature implementing this principle |

**Gate Result**: PASS — no violations.

## Project Structure

### Documentation (this feature)

```text
specs/007-realtime-sync/
├── plan.md              # This file
├── spec.md              # Feature specification
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```text
lib/
├── core/
│   └── services/
│       └── realtime_service.dart          # NEW: Supabase Realtime wrapper (presence, channels, connection state)
├── features/
│   └── shopping_lists/
│       ├── data/
│       │   └── repositories/
│       │       └── supabase_shopping_list_repository.dart  # MODIFY: add presence tracking to stream methods
│       └── presentation/
│           ├── providers/
│           │   ├── shopping_items_provider.dart    # MODIFY: add presence provider, connection state provider
│           │   └── shopping_lists_provider.dart    # MODIFY: add home-level realtime streams
│           └── widgets/
│               ├── connection_status_widget.dart    # NEW: "Disconnected" / "Syncing..." indicator
│               ├── presence_indicator_widget.dart   # NEW: user avatars/initials for online members
│               └── item_updated_toast.dart          # NEW: toast for conflict notification
```

**Structure Decision**: Feature-first architecture. Shared realtime service in `lib/core/services/`. Feature-specific providers and widgets stay within `lib/features/shopping_lists/`.
