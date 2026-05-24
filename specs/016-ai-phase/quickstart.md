# Quickstart: AI Smart Shopping Suggestions

**Date**: 2026-05-14  
**Spec**: [spec.md](./spec.md)

## Prerequisites

1. **Beity Flutter project** running with SPEC 05 (Shopping Lists) and SPEC 06 (Shopping Items) stable.
2. **Supabase project** with Edge Functions enabled.
3. **Gemini API key** from [Google AI Studio](https://aistudio.google.com/apikey).
4. **Supabase CLI** installed (`npx supabase`).

## Setup Steps

### 1. Set Gemini API Key as Supabase Secret

```bash
npx supabase secrets set GEMINI_API_KEY=your-gemini-api-key-here
```

> ⚠️ **Never** put the API key in Flutter code, `.env` files committed to git, or any client-accessible location.

### 2. Deploy the Edge Function

```bash
npx supabase functions deploy generate-shopping-suggestions
```

### 3. Enable the Feature Flag

In `lib/core/config/feature_flags.dart`, set:

```dart
static const bool enableAi = true;  // was false
```

### 4. Verify

1. Open the app → navigate to an active shopping list.
2. Tap the "✨ AI Suggestions" button (visible only when `enableAi = true`).
3. Type a prompt like "items for breakfast".
4. Verify suggestions appear within ~5-10 seconds.
5. Select items → tap "Add Selected" → verify items added to list.

## Project Structure

```text
lib/features/ai_suggestions/
├── domain/
│   ├── entities/
│   │   ├── ai_suggestion.dart          # AiSuggestion entity
│   │   └── ai_suggestion_request.dart  # AiSuggestionRequest entity
│   ├── repositories/
│   │   └── ai_suggestion_repository.dart  # Abstract repository interface
│   └── usecases/
│       └── get_ai_suggestions.dart     # GetAiSuggestions use case
├── data/
│   ├── models/
│   │   ├── ai_suggestion_model.dart    # JSON serialization model
│   │   └── ai_suggestion_request_model.dart
│   ├── datasources/
│   │   └── ai_suggestion_remote_data_source.dart  # Edge Function caller
│   └── repositories/
│       └── ai_suggestion_repository_impl.dart     # Repository implementation
└── presentation/
    ├── providers/
    │   └── ai_suggestions_provider.dart  # Riverpod state management
    ├── screens/
    │   └── ai_suggestions_screen.dart    # Full-screen suggestion flow
    └── widgets/
        ├── ai_suggestion_tile.dart       # Single suggestion item
        ├── ai_prompt_input.dart          # Prompt text field
        └── ai_suggestions_list.dart      # Selectable suggestion list

supabase/functions/
└── generate-shopping-suggestions/
    └── index.ts                          # Deno Edge Function
```

## Safety Rules

1. **No API keys in Flutter** — Gemini key lives only in Supabase Secrets.
2. **No auto-modifications** — AI cannot add, edit, delete, or purchase items without explicit user tap on "Add Selected".
3. **Minimal context** — Only `prompt`, `homeType`, `listTitle`, `existingItems`, and `language` are sent. No PII.
4. **Feature flag gated** — When `FeatureFlags.enableAi = false`, all AI UI is hidden and no AI network requests are made.
5. **Response validation** — Edge Function validates and sanitizes all AI output before returning to Flutter.
6. **Max 20 suggestions** — Server-side cap prevents overwhelming the user.

## Testing Checklist

- [ ] AI button visible only when `FeatureFlags.enableAi = true`
- [ ] AI button hidden when `FeatureFlags.enableAi = false`
- [ ] Empty prompt cannot be submitted
- [ ] Suggestions display correctly in English (LTR)
- [ ] Suggestions display correctly in Arabic (RTL)
- [ ] Selecting/deselecting individual items works
- [ ] "Select All" and "Deselect All" work
- [ ] "Add Selected" adds only selected items to shopping list
- [ ] "Cancel" dismisses without adding anything
- [ ] Duplicate item warning shows for matching names
- [ ] Loading indicator displays during request
- [ ] Error message displays when Edge Function is unavailable
- [ ] Error message displays for malformed AI response
- [ ] Rapid taps are debounced (only one request at a time)
- [ ] No PII in request payload (verify via Edge Function logs)
- [ ] Activity log entry created after items added
- [ ] Offline state shows appropriate message
- [ ] Items added via AI have correct `created_by` field
- [ ] Item names are truncated at 100 characters
- [ ] Max 20 suggestions returned from Edge Function

## Data Privacy Verification

To verify no PII leaks, check the Edge Function logs after a test request:

```bash
npx supabase functions logs generate-shopping-suggestions
```

Confirm the logged payload contains only: `prompt`, `homeType`, `listTitle`, `existingItems`, `language`.
