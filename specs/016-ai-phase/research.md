# Research: AI Smart Shopping Suggestions

**Date**: 2026-05-14  
**Spec**: [spec.md](./spec.md)

## R1: Gemini API via Supabase Edge Function

**Decision**: Use Google Gemini API (`gemini-2.0-flash`) called from a Deno-based Supabase Edge Function named `generate-shopping-suggestions`.

**Rationale**:
- Gemini 2.0 Flash offers low latency, multilingual support (Arabic/English), and structured JSON output via `responseMimeType: "application/json"`.
- Supabase Edge Functions already used in the project (6 existing functions: `send-notification`, `submit-feedback`, etc.) — the pattern is established.
- Edge Function reads `GEMINI_API_KEY` from `Deno.env.get()` (Supabase Secrets), keeping keys server-side only.
- Flutter calls via `Supabase.instance.client.functions.invoke('generate-shopping-suggestions', body: {...})` — same pattern as existing `send-notification` calls.

**Alternatives considered**:
- OpenAI GPT-4: Higher cost, no established pattern in this project. Gemini free tier is sufficient for MVP.
- Direct Flutter HTTP to Gemini: Rejected — exposes API key in mobile binary, violates FR-014 and constitution ("No API keys or secrets in mobile client code").
- Supabase Database Function (pg): Not suitable for external HTTP calls to AI APIs.

## R2: Request Payload Privacy Design

**Decision**: Flutter sends a structured JSON payload containing only 5 allowed fields: `prompt`, `homeType`, `listTitle`, `existingItems` (array of item name strings), and `language`.

**Rationale**:
- The Edge Function constructs the Gemini prompt server-side using these fields.
- No user IDs, emails, tokens, or PII ever leave the Flutter client for AI purposes.
- The Edge Function validates the incoming payload shape and rejects any unexpected fields.
- `existingItems` is limited to item names only (no IDs, quantities, or metadata) to prevent data leakage.

**Alternatives considered**:
- Sending full item objects: Rejected — includes IDs, timestamps, user references.
- Having Flutter construct the full AI prompt: Rejected — prompt engineering belongs server-side for easier iteration.

## R3: AI Response Format and Validation

**Decision**: Edge Function instructs Gemini to return a JSON array of suggestion objects. Edge Function validates and sanitizes before returning to Flutter.

**Rationale**:
- Gemini supports `responseMimeType: "application/json"` with a `responseSchema` to enforce structure.
- Edge Function caps the array at 20 items, truncates names to 100 characters, strips unexpected fields.
- Each suggestion object: `{ name: string, quantity?: number, unit?: string, category?: string }`.
- If Gemini returns malformed JSON, Edge Function returns a standardized error response.

**Alternatives considered**:
- Free-text response with client-side parsing: Fragile, language-dependent, hard to test.
- No server-side validation: Risky — malformed AI responses would crash the Flutter parser.

## R4: Flutter Architecture Pattern

**Decision**: Follow existing feature-first clean architecture under `lib/features/ai_suggestions/` with domain/data/presentation layers.

**Rationale**:
- Matches constitution principle I (Feature-First Clean Architecture).
- Matches existing features (tasks, expenses, inventory) all following `data/models`, `data/datasources`, `data/repositories`, `domain/entities`, `domain/usecases`, `presentation/providers`, `presentation/screens`, `presentation/widgets`.
- AI feature is isolated — no circular dependencies with shopping_lists beyond using the existing `createShoppingItem` method.

**Alternatives considered**:
- Embedding AI logic directly in shopping_lists feature: Rejected — violates feature isolation, harder to disable/remove.
- Using a shared service in `lib/core`: Rejected — AI is a full feature with its own UI, not a utility.

## R5: Duplicate Detection Strategy

**Decision**: Client-side case-insensitive name matching against existing items in the shopping list. Show inline warning badges on duplicates, but still allow the user to add them.

**Rationale**:
- Simple, fast, no additional server round-trip.
- Users may intentionally want duplicates (e.g., different sizes).
- Warning is informational, not blocking — respects user control.

**Alternatives considered**:
- Server-side dedup: Over-engineered for name-matching; item names are already available client-side.
- Hard-blocking duplicates: Too restrictive — users may have legitimate reasons.

## R6: Rate Limiting and Debouncing

**Decision**: Client-side debounce using existing `ActionDebouncer` utility. No server-side per-user rate limiting in Phase 1.

**Rationale**:
- `ActionDebouncer` already standardized across all features (auth, tasks, expenses, etc.).
- Supabase Edge Functions have built-in concurrency limits.
- For Phase 1 user base (<100 users), server-side rate limiting is unnecessary overhead.

**Alternatives considered**:
- Server-side Redis rate limiting: Over-engineered for MVP user base.
- No debouncing at all: Risky — users could double-tap and generate duplicate requests.

## R7: Activity Log Integration

**Decision**: Log `ai_items_added` action to `activity_logs` table when the user confirms adding AI-suggested items, using the existing `ActivityLogRepository`.

**Rationale**:
- Matches existing activity log pattern (entity_type, entity_id, action, metadata).
- Only logs confirmed additions, not mere requests — avoids log noise.
- `metadata` JSONB field stores: `{ source: "ai_suggestion", prompt: "<truncated>", items_count: N }`.

**Alternatives considered**:
- Logging every request: Too noisy, privacy concern (stores prompts for non-actions).
- No logging: Violates FR-017 and loses observability.
