# Implementation Plan: Invitations and Roles

**Branch**: `003-invitations-and-roles` | **Date**: 2026-05-12 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/003-invitations-and-roles/spec.md`

## Summary

Implement a complete invitation and role management system for Beity home management app. Users can invite others to join homes via email, accept/decline invitations, and manage member roles (owner, admin, member, viewer) with customizable permissions. Includes push notifications via Firebase FCM and automatic invitation expiry.

## Technical Context

**Language/Version**: Dart 3.x / Flutter 3.x  
**Primary Dependencies**: Riverpod, GoRouter, Supabase Flutter, Firebase FCM  
**Storage**: Supabase PostgreSQL with RLS  
**Testing**: flutter_test, mockito  
**Target Platform**: iOS, Android, Web  
**Project Type**: Mobile App (Flutter)  
**Performance Goals**: 60 fps UI, <2s screen load  
**Constraints**: Arabic RTL support, offline-first future  
**Scale/Scope**: ~10 screens, 4 new entities

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| Feature-First Clean Architecture | ✅ PASS | Will organize under `lib/features/invitations/` |
| Spec-Driven Development | ✅ PASS | Following full Spec Kit cycle |
| Security & RLS First | ✅ PASS | All tables will have RLS policies |
| MVP Discipline | ✅ PASS | Core feature for shared shopping lists |
| Arabic RTL from Day One | ✅ PASS | All UI will support RTL |
| Realtime Collaboration | ✅ PASS | Will use Supabase Realtime for invitations

## Project Structure

### Documentation (this feature)

```text
specs/003-invitations-and-roles/
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
│   └── invitations/
│       ├── data/
│       │   ├── models/
│       │   │   ├── invitation_model.dart
│       │   │   └── role_permission_model.dart
│       │   └── repositories/
│       │       ├── invitation_repository.dart
│       │       └── role_repository.dart
│       ├── domain/
│       │   ├── entities/
│       │   │   ├── invitation.dart
│       │   │   ├── role.dart
│       │   │   └── role_permission.dart
│       │   └── usecases/
│       │       ├── send_invitation_usecase.dart
│       │       ├── accept_invitation_usecase.dart
│       │       ├── decline_invitation_usecase.dart
│       │       ├── cancel_invitation_usecase.dart
│       │       ├── change_member_role_usecase.dart
│       │       ├── remove_member_usecase.dart
│       │       └── transfer_ownership_usecase.dart
│       └── presentation/
│           ├── providers/
│           │   ├── invitations_provider.dart
│           │   └── roles_provider.dart
│           ├── screens/
│           │   ├── invitations_list_screen.dart
│           │   ├── send_invitation_screen.dart
│           │   └── manage_roles_screen.dart
│           └── widgets/
│               ├── invitation_card_widget.dart
│               └── role_selector_widget.dart
└── core/
    └── services/
        └── notification_service.dart

tests/
├── unit/
│   └── features/
│       └── invitations/
│           ├── repositories/
│           └── usecases/
├── integration/
│   └── features/
│       └── invitations/
└── widget/
    └── features/
        └── invitations/
```

**Structure Decision**: Using Flutter feature-first architecture with Riverpod for state management. Feature isolated under `lib/features/invitations/` with clear separation of data, domain, and presentation layers.

## Complexity Tracking

> No constitution violations to justify. All principles satisfied.
