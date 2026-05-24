# Implementation Plan: AI Smart Shopping Suggestions

**Branch**: `spec-16-ai-phase` | **Date**: 2026-05-14 | **Spec**: [spec.md](./spec.md)  
**Input**: Feature specification from `specs/016-ai-phase/spec.md`

## Summary

Add AI Phase 1 to Beity: smart shopping list suggestions powered by Gemini API through a Supabase Edge Function. The feature is optional (controlled by `FeatureFlags.enableAi`), privacy-safe (minimal non-PII context only), and confirmation-gated (no data modified without explicit user action). Implementation follows clean architecture under `lib/features/ai_suggestions/` with a new Deno Edge Function `generate-shopping-suggestions`.

## Technical Context

**Language/Version**: Dart 3.x (Flutter), TypeScript (Deno Edge Function)  
**Primary Dependencies**: Flutter, Riverpod, GoRouter, Supabase Flutter SDK, Google Gemini API  
**Storage**: No new database tables — transient in-memory entities only; confirmed items use existing `shopping_items` table  
**Testing**: Flutter test (unit + widget), manual Edge Function testing via cURL  
**Target Platform**: iOS, Android (Flutter mobile app) + Supabase Edge Function (Deno)  
**Project Type**: Mobile app with serverless backend  
**Performance Goals**: AI suggestions returned within 10 seconds in 95% of cases  
**Constraints**: No API keys in Flutter binary; max 20 suggestions; max 500-char prompt  
**Scale/Scope**: <100 users Phase 1; single Edge Function; ~15 new Flutter files

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Feature-First Clean Architecture | ✅ PASS | New `lib/features/ai_suggestions/` with domain/data/presentation layers |
| II. Spec-Driven Development | ✅ PASS | Full spec-kit cycle: specify → clarify → plan → tasks |
| III. Security & RLS First | ✅ PASS | No new tables; API key server-side only; Edge Function auth via JWT; items added via existing RLS-protected flow |
| IV. MVP Discipline | ✅ PASS | AI is explicitly post-MVP (SPEC 16), shipped after stable core. Feature-flagged for safe rollout |
| V. Arabic RTL from Day One | ✅ PASS | AI UI supports RTL; language sent to Gemini for Arabic responses |
| VI. Realtime Collaboration | ✅ N/A | AI suggestions are transient/local; added items inherit existing realtime sync |
| No API keys in client | ✅ PASS | `GEMINI_API_KEY` in Supabase Secrets only |

**Post-Phase 1 Re-check**: All gates still pass. No new tables, no new RLS policies needed, no PII exposure.

## Project Structure

### Documentation (this feature)

```text
specs/016-ai-phase/
├── spec.md              # Feature specification
├── plan.md              # This file
├── research.md          # Phase 0 research decisions
├── data-model.md        # Entity and contract definitions
├── quickstart.md        # Setup guide and testing checklist
├── contracts/
│   └── edge-function-api.md  # Edge Function API contract
├── checklists/
│   └── requirements.md  # Spec quality checklist
└── tasks.md             # Phase 2 output (created by /speckit.tasks)
```

### Source Code (repository root)

```text
lib/features/ai_suggestions/
├── domain/
│   ├── entities/
│   │   ├── ai_suggestion.dart
│   │   └── ai_suggestion_request.dart
│   ├── repositories/
│   │   └── ai_suggestion_repository.dart
│   └── usecases/
│       └── get_ai_suggestions.dart
├── data/
│   ├── models/
│   │   ├── ai_suggestion_model.dart
│   │   └── ai_suggestion_request_model.dart
│   ├── datasources/
│   │   └── ai_suggestion_remote_data_source.dart
│   └── repositories/
│       └── ai_suggestion_repository_impl.dart
└── presentation/
    ├── providers/
    │   └── ai_suggestions_provider.dart
    ├── screens/
    │   └── ai_suggestions_screen.dart
    └── widgets/
        ├── ai_suggestion_tile.dart
        ├── ai_prompt_input.dart
        └── ai_suggestions_list.dart

supabase/functions/generate-shopping-suggestions/
└── index.ts

test/features/ai_suggestions/
├── domain/usecases/
│   └── get_ai_suggestions_test.dart
├── data/
│   ├── models/ai_suggestion_model_test.dart
│   └── repositories/ai_suggestion_repository_impl_test.dart
└── presentation/
    └── providers/ai_suggestions_provider_test.dart

docs/
└── ai-setup-guide.md
```

**Structure Decision**: Feature-first clean architecture under `lib/features/ai_suggestions/` matching existing features (tasks, expenses, inventory). Edge Function follows existing `supabase/functions/<name>/index.ts` pattern (6 functions already deployed).

## Component Design

### 1. Supabase Edge Function (`generate-shopping-suggestions/index.ts`)

- Reads `GEMINI_API_KEY` from `Deno.env.get()`
- Validates incoming request payload (prompt length, language, existingItems count)
- Constructs a structured Gemini prompt with system instructions for shopping context
- Calls Gemini 2.0 Flash with `responseMimeType: "application/json"` and a `responseSchema`
- Validates and sanitizes the AI response (cap 20 items, truncate names, strip extra fields)
- Returns standardized JSON response or error

### 2. Domain Layer (Flutter)

- **Entities**: `AiSuggestion` (name, quantity?, unit?, category?), `AiSuggestionRequest` (prompt, homeType, listTitle, existingItems, language)
- **Repository Interface**: `AiSuggestionRepository` with single method `getSuggestions(AiSuggestionRequest) → Future<List<AiSuggestion>>`
- **Use Case**: `GetAiSuggestions` — validates request, calls repository, returns suggestions

### 3. Data Layer (Flutter)

- **Remote Data Source**: `AiSuggestionRemoteDataSource` — calls `Supabase.instance.client.functions.invoke('generate-shopping-suggestions', body: ...)` and parses response
- **Models**: `AiSuggestionModel` (fromJson/toJson), `AiSuggestionRequestModel` (toJson)
- **Repository Impl**: `AiSuggestionRepositoryImpl` — delegates to remote data source, handles errors

### 4. Presentation Layer (Flutter)

- **Provider**: `AiSuggestionsProvider` (Riverpod StateNotifier) managing states: `idle`, `loading`, `success(suggestions)`, `error(message)`, `adding`
- **Screen**: `AiSuggestionsScreen` — full-screen modal with prompt input, suggestion list, action buttons
- **Widgets**: `AiPromptInput` (text field + submit), `AiSuggestionsList` (selectable list with select all/deselect all), `AiSuggestionTile` (checkbox + name + quantity + duplicate badge)

### 5. Integration Points

- **Shopping List Screen**: Add AI Suggestions button (gated by `FeatureFlags.enableAi`) that navigates to `AiSuggestionsScreen`
- **Item Creation**: Selected suggestions added via existing `ShoppingListRepository.createShoppingItem()` — one call per item
- **Activity Log**: `ActivityLogRepository.createLog()` called after batch item addition with `action: 'ai_items_added'`
- **Feature Flag**: `FeatureFlags.enableAi` controls button visibility in shopping list screen and route guard
- **Debouncing**: `ActionDebouncer.execute()` wraps the submit action

## Complexity Tracking

No constitution violations. No complexity justification needed.

## Key Decisions Summary

| Decision | Choice | Reference |
|----------|--------|-----------|
| AI API | Gemini 2.0 Flash | [research.md#R1](./research.md) |
| Key storage | Supabase Secrets | [research.md#R1](./research.md) |
| Payload privacy | 5 allowed fields only | [research.md#R2](./research.md) |
| Response format | Structured JSON with server validation | [research.md#R3](./research.md) |
| Flutter architecture | Feature-first under `ai_suggestions/` | [research.md#R4](./research.md) |
| Duplicate handling | Client-side warning, not blocking | [research.md#R5](./research.md) |
| Rate limiting | Client-side ActionDebouncer only | [research.md#R6](./research.md) |
| Activity logging | Log on confirmed add only | [research.md#R7](./research.md) |
| Database changes | None — no new tables | [data-model.md](./data-model.md) |
| Max suggestions | 20 (server-enforced) | [contracts/edge-function-api.md](./contracts/edge-function-api.md) |
