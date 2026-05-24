# Tasks: AI Smart Shopping Suggestions

**Input**: Design documents from `specs/016-ai-phase/`  
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, contracts/ ✅, quickstart.md ✅

**Tests**: Explicitly requested — test tasks included.

**Organization**: Tasks grouped by user story. User stories map to spec.md:
- **US1** → User Story 1: Request AI Shopping Suggestions (P1)
- **US2** → User Story 2: Feature Flag Gating (P1)
- **US3** → User Story 3: Review and Select Suggestions (P2)
- **US4** → User Story 4: Privacy-Safe Context Sending (P2)
- **US5** → User Story 5: Multilingual Support (P3)

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2)
- Exact file paths included in descriptions

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Create the AI feature folder structure and shared domain entities

- [x] T001 Create AI feature folder structure matching clean architecture layout under `lib/features/ai_suggestions/domain/entities/`, `lib/features/ai_suggestions/domain/repositories/`, `lib/features/ai_suggestions/domain/usecases/`, `lib/features/ai_suggestions/data/models/`, `lib/features/ai_suggestions/data/datasources/`, `lib/features/ai_suggestions/data/repositories/`, `lib/features/ai_suggestions/presentation/providers/`, `lib/features/ai_suggestions/presentation/screens/`, `lib/features/ai_suggestions/presentation/widgets/`
- [x] T002 [P] Create `AiSuggestion` domain entity in `lib/features/ai_suggestions/domain/entities/ai_suggestion.dart` with fields: `name` (String, required), `quantity` (double?, default 1.0), `unit` (String?), `category` (String?). Include validation: name non-empty and max 100 chars, quantity > 0 and <= 9999 if present. Add `copyWith` method.
- [x] T003 [P] Create `AiSuggestionRequest` domain entity in `lib/features/ai_suggestions/domain/entities/ai_suggestion_request.dart` with fields: `prompt` (String, required, max 500 chars), `homeType` (String, required), `listTitle` (String, required), `existingItems` (List<String>, max 100 items), `language` (String, must be 'ar' or 'en'). Add `validate()` method that returns errors.
- [x] T004 [P] Create `AiSuggestionModel` data model in `lib/features/ai_suggestions/data/models/ai_suggestion_model.dart` with `fromJson(Map<String, dynamic>)` factory and `toEntity()` method. Handle missing fields gracefully: default quantity to 1.0, trim name to 100 chars, strip null unit/category.
- [x] T005 [P] Create `AiSuggestionRequestModel` data model in `lib/features/ai_suggestions/data/models/ai_suggestion_request_model.dart` with `fromEntity(AiSuggestionRequest)` factory and `toJson()` method producing payload with exactly 5 keys: `prompt`, `homeType`, `listTitle`, `existingItems`, `language`.

**Checkpoint**: Feature skeleton created with all entities and models ready for data/domain wiring.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core data flow infrastructure that MUST be complete before any user story UI can work

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T006 Create abstract `AiSuggestionRepository` interface in `lib/features/ai_suggestions/domain/repositories/ai_suggestion_repository.dart` with single method: `Future<List<AiSuggestion>> getSuggestions(AiSuggestionRequest request)`. Import entity types from domain layer.
- [x] T007 Create `AiSuggestionRemoteDataSource` in `lib/features/ai_suggestions/data/datasources/ai_suggestion_remote_data_source.dart`. Implement `Future<List<AiSuggestionModel>> fetchSuggestions(AiSuggestionRequestModel request)` that calls `Supabase.instance.client.functions.invoke('generate-shopping-suggestions', body: request.toJson())`, parses the response JSON, validates `suggestions` array exists, maps each entry through `AiSuggestionModel.fromJson()`, and caps results at 20 items. Throw typed exceptions for HTTP errors (400 → `AiValidationException`, 500 → `AiServiceException`).
- [x] T008 Create `AiSuggestionRepositoryImpl` in `lib/features/ai_suggestions/data/repositories/ai_suggestion_repository_impl.dart` implementing `AiSuggestionRepository`. Accept `AiSuggestionRemoteDataSource` via constructor. Delegate `getSuggestions()` to data source, convert models to entities, handle exceptions with user-friendly error messages.
- [x] T009 Create `GetAiSuggestions` use case in `lib/features/ai_suggestions/domain/usecases/get_ai_suggestions.dart`. Accept `AiSuggestionRepository` via constructor. In `call(AiSuggestionRequest)`: validate request fields (prompt non-empty, language valid, existingItems <= 100), call repository, return `List<AiSuggestion>`. Throw `ValidationException` if request is invalid.
- [x] T010 Create `AiSuggestionsProvider` (Riverpod StateNotifier) in `lib/features/ai_suggestions/presentation/providers/ai_suggestions_provider.dart`. Define `AiSuggestionsState` sealed class with states: `AiSuggestionsIdle`, `AiSuggestionsLoading`, `AiSuggestionsSuccess(List<AiSuggestion> suggestions, Set<int> selectedIndices)`, `AiSuggestionsError(String message)`, `AiSuggestionsAdding`. Provide methods: `fetchSuggestions(AiSuggestionRequest)`, `toggleSelection(int index)`, `selectAll()`, `deselectAll()`, `getSelectedSuggestions()`, `reset()`. Wire up `GetAiSuggestions` use case. Use `ActionDebouncer` from `lib/core/utils/action_debouncer.dart` to debounce fetch requests.

**Checkpoint**: Full domain→data→presentation data pipeline ready. Provider can fetch, parse, and manage suggestion state.

---

## Phase 3: User Story 1 — Request AI Shopping Suggestions (Priority: P1) 🎯 MVP

**Goal**: A user can open a shopping list, tap AI Suggestions, type a prompt, and receive suggestions from OpenRouter via the Edge Function.

**Independent Test**: Open shopping list → tap AI Suggestions → type "items for breakfast" → verify suggestions appear within 10 seconds → verify no items added to list until confirmation.

### Implementation for User Story 1

- [x] T011 [US1] Configure `supabase/functions/generate-shopping-suggestions/index.ts` to use `AI_PROVIDER` and `OPENROUTER_API_KEY`.
- [x] T012 [US1] Implement OpenRouter API call with fallback model `deepseek/deepseek-v4-flash:free` ensuring JSON output.
- [x] T013 [US1] Implement response parsing and validation for OpenRouter, including `reason` field, sanitization (20 items, 100 char limit), and error handling.
- [x] T014 [US1] Create `AiSuggestionsScreen` in `lib/features/ai_suggestions/presentation/screens/ai_suggestions_screen.dart`. Full-screen modal (use `Scaffold` with `AppBar`). Contains: `AiPromptInput` widget at top, results area in center (shows idle message, loading indicator, suggestion list, or error), action buttons at bottom. Accept `listId`, `listTitle`, `homeType`, `existingItemNames` (List<String>) as constructor parameters. Read `AiSuggestionsProvider` state via `ref.watch`. Title: localized "AI Suggestions" / "اقتراحات ذكية".
- [x] T015 [P] [US1] Create `AiPromptInput` widget in `lib/features/ai_suggestions/presentation/widgets/ai_prompt_input.dart`. `TextField` with hint text ("What do you need?" / "ماذا تحتاج؟"), max 500 chars, text input action `send`. Submit button (icon or text) disabled when text is empty or provider state is loading. On submit: call `provider.fetchSuggestions()` with constructed `AiSuggestionRequest`. Support RTL text direction.
- [x] T016 [US1] Create loading, empty, and error state widgets within `AiSuggestionsScreen`: (a) Loading: `CircularProgressIndicator` centered with "Getting suggestions..." / "جارٍ الحصول على اقتراحات..." text, (b) Empty suggestions: friendly illustration/icon with "No suggestions found. Try a different prompt." / "لم يتم العثور على اقتراحات. جرب طلبًا مختلفًا.", (c) Error: error icon with message text and "Try Again" / "حاول مرة أخرى" button, (d) Offline: detect connectivity and show "You're offline" / "أنت غير متصل" message.

**Checkpoint**: End-to-end AI suggestion flow works — user types prompt → Edge Function calls OpenRouter → suggestions displayed in Flutter.

---

## Phase 4: User Story 2 — Feature Flag Gating (Priority: P1) 🎯 MVP

**Goal**: All AI UI is completely hidden and inaccessible when `FeatureFlags.enableAi = false`. No AI network requests when disabled.

**Independent Test**: Set `enableAi = false` → verify no AI buttons anywhere → set `enableAi = true` → verify AI button appears on shopping list.

### Implementation for User Story 2

- [x] T017 [US2] Add AI Suggestions entry point button in `ShoppingListDetailScreen` (locate existing file in `lib/features/shopping_lists/presentation/screens/`). Wrap button in `if (FeatureFlags.enableAi)` guard. Button: icon `Icons.auto_awesome` with label "اقتراحات ذكية" / "AI Suggestions". On tap: navigate to `AiSuggestionsScreen` passing `listId`, `listTitle`, `homeType`, and current item names. Position: in AppBar actions or as a floating action button secondary action.
- [x] T018 [US2] Add GoRouter route for `AiSuggestionsScreen` in the app router configuration. Path: `/shopping-list/:id/ai-suggestions`. Add route guard: if `FeatureFlags.enableAi == false`, redirect to shopping list detail. Pass required parameters (`listId`, `listTitle`, `homeType`, `existingItemNames`) via `GoRouterState.extra`.
- [x] T019 [US2] Verify that when `FeatureFlags.enableAi = false`: (a) the AI button is not rendered in `ShoppingListDetailScreen`, (b) direct navigation to `/shopping-list/:id/ai-suggestions` redirects away, (c) no `AiSuggestionsProvider` is instantiated, (d) no network requests to `generate-shopping-suggestions` are made.

**Checkpoint**: Feature flag fully controls AI visibility. Safe to ship with `enableAi = false`.

---

## Phase 5: User Story 3 — Review and Select Suggestions (Priority: P2)

**Goal**: Users can select/deselect individual suggestions, select all, deselect all, and confirm adding only selected items.

**Independent Test**: Receive 8 mock suggestions → select all → deselect 2 → tap "Add Selected" → verify only 6 items added to shopping list.

### Implementation for User Story 3

- [x] T020 [US3] Create `AiSuggestionTile` widget in `lib/features/ai_suggestions/presentation/widgets/ai_suggestion_tile.dart`. Display: checkbox, item name, quantity badge (if quantity != 1), unit label (if present), category chip (if present). Checkbox bound to `selectedIndices` in provider state. On tap checkbox: call `provider.toggleSelection(index)`. Support RTL layout with `Directionality`.
- [x] T021 [US3] Create `AiSuggestionsList` widget in `lib/features/ai_suggestions/presentation/widgets/ai_suggestions_list.dart`. `ListView.builder` rendering `AiSuggestionTile` for each suggestion. Header row with "Select All" / "تحديد الكل" and "Deselect All" / "إلغاء التحديد" buttons. Show selected count badge: "3 of 8 selected" / "تم تحديد 3 من 8".
- [x] T022 [US3] Add action buttons bar at bottom of `AiSuggestionsScreen`: (a) "Add Selected (N)" / "أضف المحدد (N)" — primary button, disabled when no items selected or state is `adding`, triggers `_addSelectedItems()`, (b) "Cancel" / "إلغاء" — secondary button, calls `provider.reset()` and `Navigator.pop()`. Wrap "Add Selected" in `ActionDebouncer.execute()`.
- [x] T023 [US3] Implement `_addSelectedItems()` in `AiSuggestionsScreen`: (a) set provider state to `AiSuggestionsAdding`, (b) get selected suggestions from provider, (c) for each selected suggestion call `ShoppingListRepository.createShoppingItem(listId: listId, name: suggestion.name, quantity: suggestion.quantity ?? 1.0, unitId: matchedUnitId, categoryId: matchedCategoryId)`, (d) log activity via `ActivityLogRepository` with action `ai_items_added` and metadata `{ source: "ai_suggestion", prompt: "<first 100 chars>", items_count: N, items: [...names] }`, (e) show success snackbar "Added N items" / "تمت إضافة N عناصر", (f) pop screen.

**Checkpoint**: Full select/confirm/cancel flow works. Items added only on explicit confirmation.

---

## Phase 6: User Story 4 — Privacy-Safe Context Sending (Priority: P2)

**Goal**: AI requests contain only the 5 allowed fields. Zero PII leakage.

**Independent Test**: Intercept request payload → verify exactly: `prompt`, `homeType`, `listTitle`, `existingItems`, `language` → verify no user ID, email, token, etc.

### Implementation for User Story 4

- [x] T024 [US4] Audit `AiSuggestionRequestModel.toJson()` in `lib/features/ai_suggestions/data/models/ai_suggestion_request_model.dart` to ensure it produces exactly 5 keys (`prompt`, `homeType`, `listTitle`, `existingItems`, `language`). Add assertion in debug mode: `assert(json.keys.length == 5)`. Ensure `existingItems` contains only item name strings (no IDs, quantities, metadata).
- [x] T025 [US4] Audit `AiSuggestionRemoteDataSource.fetchSuggestions()` in `lib/features/ai_suggestions/data/datasources/ai_suggestion_remote_data_source.dart` to verify it passes `request.toJson()` directly to `functions.invoke()` body without injecting any additional fields. Verify no user ID, auth token, home ID, or other metadata is appended.
- [x] T026 [US4] Add server-side input stripping in `supabase/functions/generate-shopping-suggestions/index.ts`: destructure only `{ prompt, homeType, listTitle, existingItems, language }` from request body, ignoring any extra fields. Ensure the OpenRouter prompt string contains no user IDs, emails, or auth tokens — only the 5 context fields.

**Checkpoint**: Privacy boundary verified on both client and server. No PII in AI request chain.

---

## Phase 7: User Story 5 — Multilingual Support (Priority: P3)

**Goal**: AI suggestions work correctly in both Arabic (RTL) and English (LTR).

**Independent Test**: Switch app to Arabic → request suggestions in Arabic → verify RTL layout and Arabic results.

### Implementation for User Story 5

- [x] T027 [US5] Ensure all user-facing strings in `AiSuggestionsScreen`, `AiPromptInput`, `AiSuggestionTile`, and `AiSuggestionsList` are localized in both English and Arabic. Add entries to the app's localization files (e.g., `lib/core/l10n/` or ARB files) for: "AI Suggestions", "What do you need?", "Getting suggestions...", "No suggestions found", "Add Selected", "Cancel", "Select All", "Deselect All", "Try Again", "You're offline", "items selected", "Duplicate item", "Added N items".
- [x] T028 [US5] Verify RTL layout in `AiSuggestionsScreen` and child widgets: (a) `AiPromptInput` text direction follows locale, (b) `AiSuggestionTile` checkbox on correct side for RTL, (c) action buttons and icons aligned correctly, (d) quantity/unit labels positioned correctly. Test with `Directionality(textDirection: TextDirection.rtl, ...)`.
- [x] T029 [US5] In `supabase/functions/generate-shopping-suggestions/index.ts`, update the OpenRouter system prompt to instruct: "Respond in {language}. If language is 'ar', all item names, units, and categories must be in Arabic." Verify OpenRouter returns Arabic suggestions when `language: "ar"`.

**Checkpoint**: Full Arabic RTL experience matches English LTR. No visual overflow or misalignment.

---

## Phase 8: Testing & Verification

**Purpose**: Automated tests ensuring safety, privacy, and correctness

### Tests

- [x] T030 [P] Create test `test/features/ai_suggestions/data/models/ai_suggestion_model_test.dart`: (a) `fromJson` parses valid suggestion correctly, (b) `fromJson` handles missing optional fields (quantity, unit, category), (c) `fromJson` truncates name to 100 chars, (d) `fromJson` defaults quantity to 1.0 when null/invalid, (e) `fromJson` handles empty name gracefully.
- [x] T031 [P] Create test `test/features/ai_suggestions/data/repositories/ai_suggestion_repository_impl_test.dart`: (a) returns parsed suggestions on success, (b) throws on HTTP 400 error, (c) throws on HTTP 500 error, (d) returns empty list when suggestions array is empty, (e) caps results at 20 items.
- [x] T032 [P] Create test `test/features/ai_suggestions/domain/usecases/get_ai_suggestions_test.dart`: (a) calls repository with valid request, (b) throws ValidationException for empty prompt, (c) throws ValidationException for invalid language, (d) throws ValidationException for prompt > 500 chars, (e) truncates existingItems to 100 if exceeded.
- [x] T033 [P] Create test `test/features/ai_suggestions/presentation/providers/ai_suggestions_provider_test.dart`: (a) initial state is idle, (b) transitions to loading then success on fetch, (c) transitions to loading then error on failure, (d) toggleSelection adds/removes indices, (e) selectAll selects all indices, (f) deselectAll clears selection, (g) getSelectedSuggestions returns only selected items, (h) reset returns to idle, (i) **AI does NOT auto-add items**.
- [x] T034 [P] Create test `test/features/ai_suggestions/privacy/privacy_leak_test.dart`: (a) `AiSuggestionRequestModel.toJson()` produces exactly 5 keys, (b) JSON keys are exactly `prompt`, `homeType`, `listTitle`, `existingItems`, `language`, (c) no `userId`, `email`, `token`, `homeId`, or `memberId` key exists, (d) `existingItems` contains only strings.
- [x] T035 [P] Create test `test/features/ai_suggestions/data/models/duplicate_filter_test.dart`: (a) case-insensitive match detects "Milk" == "milk", (b) trimmed match detects " Rice " == "Rice", (c) no false positive for "Chicken" vs "Chicken breast".
- [x] T036 [P] Create test `test/features/ai_suggestions/presentation/feature_flag_test.dart`: (a) when `FeatureFlags.enableAi = false`, AI button widget is not in widget tree, (b) when `FeatureFlags.enableAi = true`, AI button widget is present.
- [x] T037 [P] Create test `test/features/ai_suggestions/data/datasources/no_api_key_test.dart`: (a) verify `AiSuggestionRemoteDataSource` does not reference any API key constants, (b) verify request body from `toJson()` contains no key resembling `apiKey`, `api_key`, `OPENROUTER_API_KEY`, `authorization`, or `token`.

**Checkpoint**: All safety-critical behaviors verified by automated tests.

---

## Phase 9: Documentation & Polish

**Purpose**: Setup documentation, final validation, and code quality

- [x] T038 [P] Create `docs/ai/openrouter-key-setup.md` documenting: (a) how to obtain an OpenRouter API key, (b) how to set it as Supabase Secret: `npx supabase secrets set OPENROUTER_API_KEY=...`, (c) how to set AI_PROVIDER=openrouter, (d) how to deploy the Edge Function.
- [x] T039 [P] Update `docs/ai/ai-phase-1-plan.md` documenting: (a) feature overview and scope, (b) architecture diagram (Flutter → Edge Function → OpenRouter), (c) privacy rules, (d) safety rules.
- [x] T040 [P] Add duplicate item warning in `AiSuggestionTile`: when a suggestion name matches (case-insensitive, trimmed) an existing item in `existingItemNames`, show a warning badge/chip ("Already in list" / "موجود بالفعل في القائمة") on the tile. Non-blocking — user can still select and add the item.
- [x] T041 Run `flutter analyze lib/` and fix any lint errors, warnings, or info messages related to the `ai_suggestions` feature. Ensure zero analyzer issues.
- [x] T042 Run `flutter test test/features/ai_suggestions/` and verify all tests pass. Fix any failures.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately
- **Foundational (Phase 2)**: Depends on Phase 1 entities/models (T002–T005)
- **US1 (Phase 3)**: Depends on Phase 2 completion (repository, data source, provider ready)
- **US2 (Phase 4)**: Depends on Phase 3 (AI screen must exist to guard/navigate to)
- **US3 (Phase 5)**: Depends on Phase 3 (needs suggestion results to select from)
- **US4 (Phase 6)**: Can start after Phase 2 (audits existing code, no new UI)
- **US5 (Phase 7)**: Depends on Phase 3 + Phase 5 (needs working UI to localize)
- **Testing (Phase 8)**: Can start after Phase 2 for unit tests; after Phase 5 for integration tests
- **Polish (Phase 9)**: Depends on all implementation phases complete

### User Story Dependencies

- **US1 (P1)**: Depends on Foundational only — no cross-story dependencies
- **US2 (P1)**: Depends on US1 (screen must exist to route-guard)
- **US3 (P2)**: Depends on US1 (needs suggestion results to select)
- **US4 (P2)**: Independent of other stories — can run after Foundational
- **US5 (P3)**: Depends on US1 + US3 (needs full UI to localize)

### Within Each User Story

- Models before data sources
- Data sources before repositories
- Repositories before use cases
- Use cases before providers
- Providers before screens/widgets
- Edge Function before Flutter data source (US1)

### Parallel Opportunities

- T002, T003, T004, T005 can all run in parallel (Phase 1 — different files)
- T030–T037 can all run in parallel (Phase 8 — different test files)
- T038, T039, T040 can all run in parallel (Phase 9 — different files)
- US4 (privacy audit) can run in parallel with US3 (select/confirm UI)

---

## Parallel Example: Phase 1 Setup

```bash
# Launch all entity/model creation together:
Task T002: "Create AiSuggestion entity in domain/entities/ai_suggestion.dart"
Task T003: "Create AiSuggestionRequest entity in domain/entities/ai_suggestion_request.dart"
Task T004: "Create AiSuggestionModel in data/models/ai_suggestion_model.dart"
Task T005: "Create AiSuggestionRequestModel in data/models/ai_suggestion_request_model.dart"
```

## Parallel Example: Phase 8 Testing

```bash
# Launch all test files together:
Task T030: "Model serialization tests"
Task T031: "Repository tests"
Task T032: "Use case validation tests"
Task T033: "Provider state transition tests"
Task T034: "Privacy payload tests"
Task T035: "Duplicate filter tests"
Task T036: "Feature flag widget tests"
Task T037: "No API key leakage tests"
```

---

## Implementation Strategy

### MVP First (User Stories 1 + 2 Only)

1. Complete Phase 1: Setup (T001–T005)
2. Complete Phase 2: Foundational (T006–T010)
3. Complete Phase 3: US1 — Request Suggestions (T011–T016)
4. Complete Phase 4: US2 — Feature Flag Gating (T017–T019)
5. **STOP and VALIDATE**: Test end-to-end with `enableAi = true`, verify with `enableAi = false`
6. Deploy Edge Function, ship app with `enableAi = false` initially

### Incremental Delivery

1. Setup + Foundational → Data pipeline ready
2. US1 (Request Suggestions) → Core AI flow works → Edge Function deployed
3. US2 (Feature Flag) → Safe to ship with flag off
4. US3 (Review/Select) → Full confirmation flow → **Beta-ready**
5. US4 (Privacy Audit) → Verified safe for production
6. US5 (Multilingual) → Arabic users supported
7. Tests + Docs → Production-grade

### Parallel Team Strategy

With 2 developers:

1. Both complete Setup + Foundational together
2. Developer A: US1 (Edge Function + Flutter data flow) + US3 (Select/Confirm UI)
3. Developer B: US2 (Feature Flag) + US4 (Privacy Audit) + US5 (Localization)
4. Both: Tests + Docs in parallel

---

## Notes

- [P] tasks = different files, no dependencies on incomplete tasks
- [Story] label maps task to specific user story for traceability
- Each user story is independently testable at its checkpoint
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- Edge Function deployment (T011–T013) must happen before Flutter data source integration testing
- `FeatureFlags.enableAi` defaults to `false` — always safe to merge
