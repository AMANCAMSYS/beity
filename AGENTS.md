# Beity Project Agent Rules

## Product Direction
Beity is a home management app focused first on shared shopping lists, then inventory, expenses, tasks, and AI suggestions.

## MVP Priority
Do not implement inventory, expenses, tasks, stores, OCR, payments, or AI before the core shared shopping-list MVP is stable.

## Tech Stack
- Flutter
- Riverpod
- GoRouter
- Supabase Auth
- Supabase PostgreSQL
- Supabase Realtime
- Firebase FCM
- Isar for offline support later

## Development Rules
- Use feature-first clean architecture.
- Keep features isolated under `lib/features/<feature_name>`.
- Every Supabase table must have RLS policies.
- Every write action must include `created_by` or `updated_by` where relevant.
- Never bypass home membership checks.
- Prefer small commits per Spec.
- Add tests for repositories, use cases, and critical UI flows.

## UX Rules
- The app must be fast for shopping mode.
- Add-item flow must be one of the fastest flows in the app.
- Empty states must explain what to do next.
- Arabic RTL must be supported from the beginning.

## Spec Kit Workflow
Use the following sequence for each spec:
1. /speckit.specify
2. /speckit.clarify
3. /speckit.plan
4. /speckit.tasks
5. /speckit.analyze
6. /speckit.implement

## Current Phase
SPEC 00 - Project Foundation (COMPLETED)
SPEC 01 - Auth and User Profile (COMPLETED)
SPEC 02 - Homes and Members (COMPLETED)
SPEC 03 - Invitations and Roles (COMPLETED)
SPEC 04 - Categories and Units (COMPLETED)
SPEC 05 - Shopping Lists (COMPLETED)
SPEC 06 - Shopping Items (COMPLETED)
SPEC 07 - Realtime Sync (COMPLETED)
SPEC 08 - Activity Logs (COMPLETED)
SPEC 09 - Notifications (COMPLETED)
SPEC 10 - Shopping Mode (COMPLETED)
SPEC 11 - Offline Queue (COMPLETED)
SPEC 12 - MVP Hardening & Beta (COMPLETED)
SPEC 13 - Inventory Phase (COMPLETED)
SPEC 14 - Expenses Phase (COMPLETED)
SPEC 15 - Tasks Phase (COMPLETED)
SPEC 16 - AI Phase 1 (COMPLETED)

<!-- SPECKIT START -->
For additional context about technologies to be used, project structure,
shell commands, and other important information, read the current plan:
specs/016-ai-phase/plan.md
<!-- SPECKIT END -->
