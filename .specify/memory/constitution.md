<!--
Sync Impact Report
==================
Version change: 0.0.0 → 1.0.0 (MAJOR - initial constitution)
Modified principles: N/A (new)
Added sections:
  - Core Principles (6 principles)
  - Technical Stack
  - Development Workflow
  - Security & Data Isolation
  - Governance
Removed sections: N/A
Templates requiring updates:
  - .specify/templates/plan-template.md ✅ compatible
  - .specify/templates/spec-template.md ✅ compatible
  - .specify/templates/tasks-template.md ✅ compatible
Follow-up TODOs: None
-->

# SAWA Constitution

## Core Principles

### I. Feature-First Clean Architecture

Every feature MUST be organized under `lib/features/<feature_name>` with clear separation of data, domain, and presentation layers. Features MUST be independently testable and not create circular dependencies. Shared code belongs in `lib/core` or `lib/shared`.

### II. Spec-Driven Development

No feature implementation begins without a completed Spec Kit cycle: specify → clarify → plan → tasks → analyze → implement. Each spec MUST have clear acceptance criteria, scope boundaries, and out-of-scope declarations. One spec per Git branch.

### III. Security & RLS First

Every Supabase table MUST have Row Level Security (RLS) policies. Users can only access data where they are active members of the associated `home_id`. Write operations MUST include `created_by` or `updated_by` audit fields. No data leakage between homes is acceptable.

### IV. MVP Discipline

The initial release focuses exclusively on shared shopping lists. Inventory, expenses, tasks, AI, OCR, payments, and store integrations are deferred until the MVP is stable. Features are added incrementally based on validated user needs, not speculative planning.

### V. Arabic RTL from Day One

All UI MUST support right-to-left (RTL) layout for Arabic from the beginning. This is not a localization afterthought but a core design constraint. Text, navigation, icons, and layout direction MUST adapt to the selected locale.

### VI. Realtime Collaboration

Shared data (shopping lists, items) MUST synchronize in real-time between home members using Supabase Realtime. The UI MUST handle optimistic updates, conflict resolution based on `updated_at`, and proper subscription lifecycle management.

## Technical Stack

- **Frontend**: Flutter with Riverpod for state management
- **Routing**: GoRouter with route guards for authentication
- **Backend**: Supabase (PostgreSQL, Auth, Realtime, Storage, Edge Functions)
- **Notifications**: Firebase FCM (behind service abstraction)
- **Offline**: Isar for local caching (post-MVP)
- **Analytics**: PostHog (post-MVP)

## Development Workflow

- Each spec follows the Spec Kit workflow in sequence
- Each spec gets its own Git branch (`spec-XX-feature-name`)
- `flutter analyze` MUST pass before any commit
- Tests MUST pass for repositories, use cases, and critical UI flows
- Database migrations MUST include RLS policies
- Commit messages follow conventional commits format

## Security & Data Isolation

- All tables MUST have `home_id` for data isolation
- Tables without direct `home_id` MUST enforce access through parent relationships (e.g., `shopping_items` → `shopping_lists` → `homes` → `home_members`)
- Role-based access: owner, admin, member, viewer
- Soft delete with `deleted_at` for audit trails
- No API keys or secrets in mobile client code

## Governance

This constitution supersedes all other development practices for the SAWA project. Amendments require:
1. Documentation of the proposed change
2. Impact analysis on existing specs and implementations
3. Version increment following semantic versioning (MAJOR for breaking changes, MINOR for new principles, PATCH for clarifications)

All pull requests and code reviews MUST verify compliance with these principles. Complexity or scope expansion MUST be justified against the MVP Discipline principle.

**Version**: 1.0.0 | **Ratified**: 2026-05-12 | **Last Amended**: 2026-05-12
