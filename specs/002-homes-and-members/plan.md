# Implementation Plan: Homes and Members

**Branch**: `spec-02-homes-and-members` | **Date**: 2026-05-12 | **Spec**: [spec.md](./spec.md)  
**Input**: Feature specification from `/specs/002-homes-and-members/spec.md`

## Summary

Implement home workspace management for Beity. Users can create homes, automatically become owners, view all homes they belong to, switch active home, and view home members. Includes mandatory onboarding flow for new users and subscription-based limits placeholder.

## Technical Context

**Language/Version**: Dart 3.11.5, Flutter 3.41.9  
**Primary Dependencies**: flutter_riverpod 2.6.1, go_router 14.8.1, supabase_flutter 2.12.4  
**Storage**: Supabase PostgreSQL (homes, home_members tables)  
**Testing**: flutter_test, mocktail  
**Target Platform**: Android, iOS, Web  
**Project Type**: Mobile app with Supabase backend  
**Performance Goals**: <2s home list load, <30s home creation, <5s home switch  
**Constraints**: Arabic RTL support, offline-first later (post-MVP)  
**Scale/Scope**: Initial beta 10-30 users, scalable to 10k+  

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Evidence |
|-----------|--------|----------|
| I. Feature-First Clean Architecture | ✅ PASS | Feature under `lib/features/homes/` |
| II. Spec-Driven Development | ✅ PASS | Following spec → plan → tasks flow |
| III. Security & RLS First | ✅ PASS | RLS policies defined in spec |
| IV. MVP Discipline | ✅ PASS | Only homes/members, no shopping yet |
| V. Arabic RTL from Day One | ✅ PASS | RTL support required in spec |
| VI. Realtime Collaboration | ⏭️ DEFERRED | Realtime sync is SPEC 07 |

## Project Structure

### Documentation (this feature)

```text
specs/002-homes-and-members/
├── plan.md              # This file
├── spec.md              # Feature specification
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
└── tasks.md             # Phase 2 output (via /speckit.tasks)
```

### Source Code (repository root)

```text
lib/
├── app/
│   ├── config/
│   ├── theme/
│   └── router/
├── core/
│   ├── constants/
│   ├── errors/
│   ├── services/
│   └── utils/
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   ├── models/
│   │   │   └── repositories/
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   └── usecases/
│   │   └── presentation/
│   │       ├── providers/
│   │       └── screens/
│   └── homes/                    # NEW FEATURE
│       ├── data/
│       │   ├── models/
│       │   └── repositories/
│       ├── domain/
│       │   ├── entities/
│       │   └── usecases/
│       └── presentation/
│           ├── providers/
│           ├── screens/
│           └── widgets/
└── shared/
    └── widgets/

tests/
├── unit/
│   ├── features/
│   │   └── homes/
│       ├── data/
│       └── domain/
├── integration/
│   └── features/
│       └── homes/
└── widget/
    └── features/
        └── homes/
```

**Structure Decision**: Using Flutter feature-first architecture. Homes feature is isolated under `lib/features/homes/` with data/domain/presentation layers. Tests mirror the source structure.

## Complexity Tracking

> No constitution violations to justify. All principles pass.
