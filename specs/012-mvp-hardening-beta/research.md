# Research: MVP Hardening and Beta

**Feature**: 012-mvp-hardening-beta
**Date**: 2026-05-13

## Research Topics

### 1. Firebase Crashlytics Integration in Flutter

**Decision**: Use `firebase_crashlytics` package with `FirebaseCrashlytics.instance` singleton.

**Rationale**: Firebase Crashlytics is already in the project's dependency chain (via Firebase Core for FCM). The Flutter plugin provides automatic crash collection, custom log keys for user context, and non-fatal error logging for performance events.

**Alternatives considered**:
- Sentry: Richer context and breadcrumbs, but adds a new dependency and requires a Sentry server. Overkill for a 100-user beta.
- Custom Supabase logging: Full control but requires building a dashboard, alerting, and crash grouping. Not justified for MVP.
- Firebase Performance Monitoring: Complementary to Crashlytics but separate package. Can be added post-beta if needed.

**Key integration points**:
- Initialize in `main.dart` before `runApp()`
- Set user identifier (anonymized) after auth
- Log custom keys for `home_id`, `app_version`
- Use `recordFlutterError` for Flutter framework errors
- Use `recordError` for try-catch blocks in critical paths
- Disable collection in debug builds via `setCrashlyticsCollectionEnabled(false)`

---

### 2. In-App Feedback Mechanism

**Decision**: Add a "Send Feedback" option in the app's settings/menu that opens a modal bottom sheet with: text field for description, auto-attached device info (hidden from user), and a submit button. Data is sent to a Supabase Edge Function that forwards to a team webhook or stores in a Supabase table.

**Rationale**: Menu-based access is discoverable and doesn't interfere with shopping flows. Using a Supabase Edge Function keeps feedback within the existing infrastructure and allows the team to control routing (email, Slack, database).

**Alternatives considered**:
- Direct Firebase Crashlytics logging: Crashlytics doesn't support user-submitted feedback natively.
- Email intent: Opens email client, but loses structured data and device info attachment.
- Third-party SDK (Instabug, UserVoice): Adds significant dependency and cost for a small beta.

**Data captured automatically**:
- Device model, OS version
- App version and build number
- Current screen/route name
- User ID (anonymized)
- Home ID
- Last 50 app log entries (from a rotating in-memory buffer)

---

### 3. Beta Welcome Screen

**Decision**: A one-time full-screen dialog shown on first launch of beta builds. Content: "You're using a Beity Beta" message, brief explanation of the beta program, and a "How to Report Issues" section pointing to the menu feedback option. Stored flag in shared preferences to avoid re-showing.

**Rationale**: Sets expectations for beta testers and directs them to the feedback mechanism. One-time display avoids repeated friction.

**Implementation approach**:
- Use a build-time flag (e.g., `--dart-define=BETA=true`) to enable beta features
- Check `SharedPreferences` for `beta_welcome_shown` flag on app start
- Show dialog before navigating to main content
- The flag is per-device, not per-user (no need to re-show after login/logout)

---

### 4. Accessibility Labels in Flutter

**Decision**: Use Flutter's `Semantics` widget and `SemanticsProperties` to add labels to all interactive elements. Use `MergeSemantics` for compound widgets (e.g., item cards with name + quantity + checkbox).

**Rationale**: Flutter has built-in accessibility support via the Semantics widget tree. No additional packages needed. The `excludeFromSemantics` property can be used to hide decorative elements.

**Key patterns**:
- `Semantics(label: 'Milk, 2 kg, not purchased')` for shopping item cards
- `Semantics(button: true, label: 'Mark as purchased')` for tap targets
- `Semantics(label: 'Shopping list: Weekly Groceries, 12 items')` for list tiles
- `MergeSemantics()` wrapping compound item widgets
- `ExcludeSemantics()` for decorative icons/images
- Ensure all `IconButton`, `GestureDetector`, and `InkWell` have semantic labels

**Testing approach**:
- `flutter test --accessibility` (Flutter's built-in semantic testing)
- Manual VoiceOver (iOS) and TalkBack (Android) walkthrough of core flows
- `SemanticsTester` in widget tests for programmatic verification

---

### 5. Performance Optimization for Large Lists

**Decision**: Use `ListView.builder` with `const` constructors, `AutomaticKeepAliveClientMixin` for off-screen preservation, and `addAutomaticKeepAlives: false` for shopping mode (where items frequently change state).

**Rationale**: Flutter's `ListView.builder` already provides virtualization. The main risks are: unnecessary rebuilds from Riverpod state changes, expensive item card widgets, and category group headers.

**Optimization strategies**:
- Use `const` widget constructors where possible to skip rebuilds
- Use `ref.select()` instead of `ref.watch()` for granular rebuilds (e.g., only watch `isPurchased` for a specific item)
- Debounce search/filter input to avoid rebuilding on every keystroke
- Use `RepaintBoundary` around item cards for isolated repaints
- Profile with Flutter DevTools Timeline to identify jank sources
- Consider `SliverList` with `SliverChildBuilderDelegate` for category-grouped lists

**Validation target**: 60fps with 200 items on Samsung Galaxy A54 / iPhone 12 (measured via Flutter DevTools Performance overlay).

---

### 6. End-to-End Integration Testing Strategy

**Decision**: Use Flutter's `integration_test` package for E2E tests. Focus on the critical path: sign up → create home → create list → add items → shopping mode → mark purchased → exit.

**Rationale**: `integration_test` runs on real devices/emulators and can interact with Supabase. It's the official Flutter integration testing solution.

**Test scenarios to implement**:
1. Full shopping journey (happy path, P1)
2. Offline → online sync (P1)
3. Multi-device concurrent editing (P2, requires two test instances)
4. Session expiry → re-auth → state preservation (P2)
5. Arabic RTL layout verification (P2)

**Limitations**:
- Multi-device testing requires manual coordination or CI with multiple emulators
- Realtime sync testing depends on Supabase staging environment
- Accessibility testing requires platform-level tools (VoiceOver/TalkBack), not fully automatable

---

### 7. RTL Audit Approach

**Decision**: Manual walkthrough of every screen in Arabic locale, checking: text alignment, icon mirroring, input field direction, navigation direction, number formatting, and mixed content rendering. Document issues in a shared spreadsheet with screenshots.

**Rationale**: RTL issues are visual and context-dependent. Automated checks can catch some cases (e.g., `Directionality` widget), but many issues require human judgment (e.g., icon meaning in RTL context, text truncation with Arabic diacritics).

**Checklist per screen**:
- [ ] All text right-aligned
- [ ] Back/forward navigation mirrored
- [ ] Directional icons mirrored (arrows, chevrons)
- [ ] Input fields start from right
- [ ] Numbers display correctly (Western or Eastern Arabic numerals per locale)
- [ ] Mixed Arabic/English text renders without reordering issues
- [ ] No text overflow or truncation
- [ ] List ordering matches RTL expectations
- [ ] Swipe gestures work in correct direction
- [ ] FAB and action buttons positioned correctly

---

### 8. Error Handling Strategy

**Decision**: Create a centralized `ErrorHandler` class in `lib/core/error_handling/` that maps exception types to user-friendly messages and recovery actions. Each error type gets a consistent error screen or snackbar.

**Rationale**: Currently, error handling is likely scattered across features. Centralizing ensures consistency and makes it easy to add new error types.

**Error categories and UX**:
| Error Type          | User Message                                                     | Recovery Action              |
| ------------------- | ---------------------------------------------------------------- | ---------------------------- |
| Network unavailable | "You're offline. Changes will sync when you're back online."     | Queue action, show indicator |
| Session expired     | "Your session expired. Please sign in again."                    | Redirect to auth screen      |
| Permission denied   | "You no longer have access to this home."                        | Navigate to homes list       |
| Server error (5xx)  | "Something went wrong on our end. Please try again."             | Retry button                 |
| Storage full        | "Your device is running low on storage. Please free up space."   | Settings link                |
| Unknown             | "An unexpected error occurred. Please try again or report this." | Retry + report link          |
