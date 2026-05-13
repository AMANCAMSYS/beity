# Data Model: MVP Hardening and Beta

**Feature**: 012-mvp-hardening-beta
**Date**: 2026-05-13

## Overview

This feature does not introduce new Supabase database tables. All existing tables from SPEC 001-011 remain unchanged. The new data entities (Crash Report, Performance Event, Beta Feedback) are stored in Firebase services, not in Supabase PostgreSQL.

## Entity Mapping

### Crash Report (Firebase Crashlytics)

Not stored as a custom entity in our codebase. Firebase Crashlytics handles crash data collection, deduplication, grouping, and dashboard display automatically. We only configure:

- **Custom keys set on crash**: `home_id`, `user_id` (anonymized), `app_version`, `build_number`
- **Breadcrumb logs**: Navigation events, shopping actions (limited to avoid noise)
- **Non-fatal errors**: Logged via `FirebaseCrashlytics.instance.recordError()` for caught exceptions in critical paths

### Performance Event (Firebase Crashlytics / Custom Log)

Logged as custom non-fatal errors or structured logs. Attributes:

| Field        | Type   | Description                                           |
| ------------ | ------ | ----------------------------------------------------- |
| operation    | string | Name of slow operation (e.g., "shopping_list_load")   |
| duration_ms  | int    | Measured duration in milliseconds                     |
| screen       | string | Screen/route where the operation occurred             |
| item_count   | int?   | Number of items in context (if applicable)            |
| device_model | string | Device model for performance correlation              |
| timestamp    | int    | Unix timestamp of the measurement                     |

Logged via `FirebaseCrashlytics.instance.log()` with structured key-value pairs. Only operations exceeding 3 seconds are logged (per FR-014).

### Beta Feedback (Supabase Edge Function → Team Channel)

Submitted via a Supabase Edge Function and stored in a Supabase table for team access.

**Table**: `beta_feedback`

| Column       | Type      | Constraints              | Description                                  |
| ------------ | --------- | ------------------------ | -------------------------------------------- |
| id           | uuid      | PK, default gen_random_uuid() | Unique feedback ID                     |
| user_id      | uuid      | FK → auth.users, nullable | Submitter (null if anonymous)              |
| feedback_type| text      | NOT NULL, CHECK IN ('bug', 'survey') | Type of feedback              |
| description  | text      | NOT NULL                 | User-provided description or comment         |
| star_rating  | smallint  | nullable, CHECK 1-5      | Satisfaction rating (survey type only)       |
| device_info  | jsonb     | NOT NULL                 | Device model, OS version, app version        |
| screen_route | text      | nullable                 | Screen user was on when submitting           |
| app_logs     | text[]    | nullable                 | Recent log entries (rotating buffer dump)    |
| created_at   | timestamptz | NOT NULL, default now() | Submission timestamp                         |

**RLS Policies**:
- INSERT: Authenticated users can insert their own feedback (`auth.uid() = user_id`)
- SELECT: Only service role can read (team access via dashboard)
- No UPDATE/DELETE from client

**Index**: `idx_beta_feedback_created_at` on `created_at DESC` for team dashboard queries.

### Satisfaction Survey State (SharedPreferences)

Stored locally on device. Not in Supabase.

| Key                        | Type   | Description                                    |
| -------------------------- | ------ | ---------------------------------------------- |
| beta_welcome_shown         | bool   | Whether the beta welcome screen was displayed  |
| satisfaction_survey_shown  | bool   | Whether the post-shopping survey was displayed |

## Relationships

```
beta_feedback
  └── user_id → auth.users (optional, nullable for anonymous submissions)

[No new relationships with existing tables]
```

## State Transitions

### Beta Feedback Lifecycle

```
[User submits] → INSERT into beta_feedback
[Team reviews] → Manual triage via Supabase dashboard
[Resolved] → Team marks as resolved (column TBD if needed, or handled externally)
```

No client-side state machine. Feedback is fire-and-forget from the app's perspective.
