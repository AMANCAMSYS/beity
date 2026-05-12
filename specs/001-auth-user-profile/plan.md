# Implementation Plan: Auth and User Profile

**Branch**: `spec-01-auth-and-user-profile` | **Date**: 2026-05-12 | **Spec**: [spec.md](./spec.md)  
**Input**: Feature specification from `/specs/001-auth-user-profile/spec.md`

## Summary

Implement authentication and user profile management for Beity. Users can register with email/password, login, logout, and view/edit their profile. Uses Supabase Auth with automatic user profile sync. All UI supports Arabic RTL.

## Technical Context

**Language/Version**: Dart 3.11.5, Flutter 3.41.9  
**Primary Dependencies**: flutter_riverpod 2.6.1, go_router 14.8.1, supabase_flutter 2.12.4  
**Storage**: Supabase PostgreSQL (users table linked to auth.users)  
**Testing**: flutter_test, mocktail  
**Target Platform**: Android, iOS, Web  
**Project Type**: Mobile app with Supabase backend  
**Performance Goals**: <1min registration, <30s login, <2s profile save  
**Constraints**: Arabic RTL support, offline-first later (post-MVP)  
**Scale/Scope**: Initial beta 10-30 users, scalable to 10k+  

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Evidence |
|-----------|--------|----------|
| I. Feature-First Clean Architecture | ✅ PASS | Feature under `lib/features/auth/` |
| II. Spec-Driven Development | ✅ PASS | Following spec → plan → tasks flow |
| III. Security & RLS First | ✅ PASS | RLS on users table, auth.uid() based |
| IV. MVP Discipline | ✅ PASS | Email/password only, no social login |
| V. Arabic RTL from Day One | ✅ PASS | RTL support required in spec |
| VI. Realtime Collaboration | ⏭️ N/A | Not applicable for auth feature |

## Project Structure

### Documentation (this feature)

```text
specs/001-auth-user-profile/
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
│   └── auth/                    # THIS FEATURE
│       ├── data/
│       │   ├── models/
│       │   └── repositories/
│       ├── domain/
│       │   ├── entities/
│       │   └── usecases/
│       └── presentation/
│           ├── providers/
│           └── screens/
└── shared/
    └── widgets/

tests/
├── unit/
│   └── features/
│       └── auth/
├── integration/
│   └── features/
│       └── auth/
└── widget/
    └── features/
        └── auth/
```

**Structure Decision**: Using Flutter feature-first architecture. Auth feature is isolated under `lib/features/auth/` with data/domain/presentation layers. Tests mirror the source structure.

## Complexity Tracking

> No constitution violations to justify. All principles pass.
