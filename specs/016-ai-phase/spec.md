# Feature Specification: AI Smart Shopping Suggestions

**Feature Branch**: `spec-16-ai-phase`  
**Created**: 2026-05-14  
**Status**: Draft  
**Input**: User description: "Add AI Phase 1 to Beity as smart shopping list suggestions only. The AI feature must be optional, controlled by FeatureFlags.enableAi, and hidden when disabled. Users can open AI suggestions from a shopping list, write a request, receive suggested shopping items, review them, select items, and explicitly confirm before adding them. AI must not automatically add, edit, delete, purchase, archive, or modify data without user confirmation. Use Gemini API through a Supabase Edge Function. Do not put any AI API key inside Flutter. Send only minimal non-sensitive context such as home type, list title, existing item names, user prompt, and language. Do not send emails, phone numbers, user IDs, member names, tokens, full activity logs, or expense data."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Request AI Shopping Suggestions (Priority: P1)

A home member opens an active shopping list and taps an "AI Suggestions" button. They type a natural-language request such as "suggest items for a BBQ party" or "what do I need for pancakes?". The system sends the request along with minimal list context to a server-side AI service. The user receives a list of suggested items displayed as a reviewable preview. Nothing is added to the shopping list until the user explicitly selects items and confirms.

**Why this priority**: This is the core value proposition of AI Phase 1 — helping users think of items they might forget or need for a specific occasion. Without this flow, there is no AI feature.

**Independent Test**: Can be fully tested by opening a shopping list, tapping AI Suggestions, typing a prompt, receiving suggestions, and verifying no data changes until confirmation.

**Acceptance Scenarios**:

1. **Given** a member has an active shopping list, **When** they tap AI Suggestions and type "items for breakfast", **Then** the system displays a list of suggested items within 10 seconds without adding anything to the list.
2. **Given** the AI returns suggestions, **When** the user selects 3 of 5 suggested items and taps "Add Selected", **Then** only the 3 selected items are added to the shopping list with correct names.
3. **Given** the AI returns suggestions, **When** the user taps "Cancel" or closes the suggestion panel, **Then** no items are added and the list remains unchanged.
4. **Given** the AI service is unavailable or returns an error, **When** the user requests suggestions, **Then** a friendly error message is shown and the user can dismiss it and continue using the list normally.

---

### User Story 2 - Feature Flag Gating (Priority: P1)

The entire AI feature is controlled by a feature flag. When the flag is disabled, all AI-related UI elements (buttons, menu entries, screens) are completely hidden. No AI-related network requests are made. When the flag is enabled, the AI Suggestions button appears on shopping list screens.

**Why this priority**: Feature flag gating is equally critical — it ensures the AI feature can be shipped safely, toggled for gradual rollout, and hidden in regions or builds where it is not ready.

**Independent Test**: Can be tested by toggling the feature flag and verifying UI presence/absence of all AI elements.

**Acceptance Scenarios**:

1. **Given** the AI feature flag is disabled, **When** a user views a shopping list, **Then** no AI-related buttons, menus, or options are visible anywhere in the app.
2. **Given** the AI feature flag is enabled, **When** a user views an active shopping list, **Then** an AI Suggestions button or entry point is visible.
3. **Given** the AI feature flag is disabled, **When** the app loads, **Then** no AI-related network requests are made.

---

### User Story 3 - Review and Select Suggestions (Priority: P2)

After the AI returns suggestions, the user sees each suggestion as a selectable item with a name, optional quantity, and optional category. The user can select/deselect individual items, select all, or deselect all. Only after tapping a clear "Add Selected" confirmation button are items added to the shopping list.

**Why this priority**: The review-and-select experience is what makes AI suggestions safe and trustworthy. Users must feel in control of what gets added.

**Independent Test**: Can be tested by receiving a mock set of suggestions and verifying the select/deselect/confirm/cancel interactions.

**Acceptance Scenarios**:

1. **Given** AI returns 8 suggestions, **When** the user taps "Select All", **Then** all 8 items are marked as selected.
2. **Given** all items are selected, **When** the user deselects 2 items and taps "Add Selected", **Then** only 6 items are added to the shopping list.
3. **Given** suggestions are displayed, **When** the user taps "Cancel", **Then** no items are added and the suggestion view closes.
4. **Given** suggestions are displayed, **When** the user selects items that already exist in the shopping list by the same name, **Then** the system warns the user about duplicates before adding.

---

### User Story 4 - Privacy-Safe Context Sending (Priority: P2)

When the user requests AI suggestions, the system sends only minimal, non-sensitive context to the AI service: the home type (e.g., "family", "students"), the shopping list title, existing item names in the list, the user's prompt text, and the app language. The system must never send emails, phone numbers, user IDs, member names, authentication tokens, activity logs, expense data, or any other personally identifiable information.

**Why this priority**: Privacy is a trust requirement. Users must be confident that their personal data is not leaked to third-party AI services.

**Independent Test**: Can be tested by intercepting or logging the outbound request payload and verifying it contains only the allowed fields.

**Acceptance Scenarios**:

1. **Given** a user requests AI suggestions, **When** the request is sent to the server, **Then** the payload contains only: home type, list title, existing item names, user prompt, and language.
2. **Given** a user requests AI suggestions, **When** the request is sent, **Then** no email, phone number, user ID, member name, token, activity log, or expense data is included in the payload.

---

### User Story 5 - Multilingual Support (Priority: P3)

The AI suggestions system supports at least Arabic and English. The user's app language is sent as context so the AI returns suggestions in the same language. The AI prompt interface and suggestion results display correctly in both LTR and RTL layouts.

**Why this priority**: Beity already supports Arabic RTL. AI suggestions must maintain this consistency to avoid a broken experience for Arabic-speaking users.

**Independent Test**: Can be tested by switching the app language to Arabic, requesting suggestions, and verifying RTL display and Arabic-language results.

**Acceptance Scenarios**:

1. **Given** the app language is Arabic, **When** the user types a prompt in Arabic, **Then** the AI returns suggestions in Arabic.
2. **Given** the app language is English, **When** the user types a prompt in English, **Then** the AI returns suggestions in English.
3. **Given** the app is in RTL mode, **When** suggestions are displayed, **Then** all text and UI elements are correctly aligned for RTL.

---

### Edge Cases

- What happens when the AI returns zero suggestions? → The system displays a friendly "No suggestions found" message with a prompt to try a different request.
- What happens when the AI returns malformed or unparseable data? → The system displays a graceful error message and does not crash or show raw data.
- What happens when the user submits an empty prompt? → The submit button is disabled when the prompt field is empty.
- What happens when the user sends multiple rapid requests? → Only one request is processed at a time; subsequent taps are debounced or disabled while a request is in progress.
- What happens when the network is offline? → The system detects offline state and shows an appropriate message instead of attempting the request.
- What happens when the user tries to add a suggested item that has been deleted from the list between request and confirmation? → The item is added fresh; no conflict occurs.
- What happens when the AI suggests items with very long names or special characters? → Item names are truncated to the maximum allowed length and sanitized before display and storage.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST provide an entry point for AI suggestions from any active shopping list, visible only when the AI feature flag is enabled.
- **FR-002**: System MUST allow the user to type a free-text prompt describing what items they need suggestions for.
- **FR-003**: System MUST send the prompt along with minimal non-sensitive context (home type, list title, existing item names, language) to a server-side AI service.
- **FR-004**: System MUST NOT include any personally identifiable information (emails, phone numbers, user IDs, member names, tokens, activity logs, expense data) in the AI request payload.
- **FR-005**: System MUST display AI-generated suggestions as a reviewable list where each item can be individually selected or deselected.
- **FR-006**: System MUST NOT add, edit, delete, purchase, archive, or modify any data without explicit user confirmation.
- **FR-007**: System MUST provide a clear "Add Selected" confirmation action and a "Cancel" action for the suggestion review.
- **FR-008**: System MUST hide all AI-related UI elements when the AI feature flag is disabled.
- **FR-009**: System MUST handle AI service errors gracefully with user-friendly messages without crashing or showing technical details.
- **FR-010**: System MUST prevent sending requests when the prompt is empty.
- **FR-011**: System MUST debounce or disable repeated submission while a request is in progress.
- **FR-012**: System MUST support displaying suggestions in both Arabic (RTL) and English (LTR).
- **FR-013**: System MUST warn the user when a selected suggestion has the same name as an existing item in the shopping list.
- **FR-014**: System MUST process AI communication exclusively through a server-side function — no AI API keys or direct AI API calls from the mobile app.
- **FR-015**: System MUST show a loading indicator while waiting for AI suggestions.
- **FR-016**: System MUST allow any authenticated home member with at least "member" role to use AI suggestions on lists they can access.
- **FR-017**: System MUST log AI suggestion usage in the activity log when items are actually added (not when merely requested).

### Key Entities

- **AI Suggestion Request**: Represents a user's prompt along with minimal context sent to the AI service. Contains: prompt text, home type, list title, existing item names, language.
- **AI Suggestion Response**: Represents the AI's returned list of suggested items. Each suggestion contains: item name, optional suggested quantity, optional suggested unit, optional suggested category.
- **AI Suggestion Session**: A transient interaction where the user requests, reviews, selects, and confirms suggestions. No persistent entity is stored unless items are added to the list.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users receive AI suggestions within 10 seconds of submitting a prompt in 95% of cases when online.
- **SC-002**: 100% of AI suggestion requests contain zero personally identifiable information in the payload.
- **SC-003**: No data is modified in any shopping list without an explicit user confirmation action (Add Selected button tap).
- **SC-004**: AI UI elements are completely invisible to users when the feature flag is disabled — zero AI-related elements rendered.
- **SC-005**: At least 70% of users who receive suggestions select and add at least one item, indicating suggestion quality and relevance.
- **SC-006**: AI suggestion errors are handled gracefully with zero app crashes attributable to the AI feature.
- **SC-007**: AI suggestions display correctly in both Arabic RTL and English LTR layouts with no visual overflow or misalignment.
- **SC-008**: No AI API key or secret is present anywhere in the mobile application binary or source code.

## Assumptions

- The existing shopping list and shopping item infrastructure (SPEC 05, SPEC 06) is stable and can accept new items programmatically through the existing item creation flow.
- The AI feature flag (`FeatureFlags.enableAi`) already exists in the codebase and is currently set to `false`.
- The Gemini API is available and supports the languages needed (Arabic, English) with adequate free-tier or paid-tier quotas for the current user base.
- The server-side AI service will be a stateless function — it does not store prompts, suggestions, or user context beyond the lifetime of a single request.
- Users have an active internet connection when using AI suggestions; offline AI suggestions are out of scope for Phase 1.
- The existing activity log system (SPEC 08) can record AI-related events using the current schema.
- Home membership and role checks from existing RLS and Flutter-side guards are sufficient to control access to AI suggestions.
- Suggestion items are added using the same flow as manually added shopping items, inheriting all existing validation and RLS protections.
