# Feature Specification: MVP Hardening and Beta

**Feature Branch**: `012-mvp-hardening-beta`
**Created**: 2026-05-13
**Status**: Draft
**Input**: User description: "# SPEC 12 — MVP Hardening and Beta"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - End-to-End Shopping Journey (Priority: P1)

As a home member, I want to complete an entire shopping journey — from creating a list to marking the last item as purchased — without encountering crashes, data loss, or confusing states, so that I can trust the app for my daily shopping needs.

**Why this priority**: This validates that all previously built features (auth, homes, invitations, categories, shopping lists, shopping items, shopping mode, realtime sync, notifications, activity logs, offline queue) work together as a cohesive product. If the core journey breaks, nothing else matters.

**Independent Test**: Can be fully tested by walking through the complete flow: sign up → create home → invite member → create shopping list → add items (with categories/units) → enter shopping mode → mark items purchased → exit shopping mode → verify activity log and notifications — on both Arabic RTL and English LTR layouts.

**Acceptance Scenarios**:

1. **Given** a new user downloads the app, **When** they complete the sign-up flow and create a home, **Then** they land on an empty home dashboard with a clear call-to-action to create their first shopping list
2. **Given** a home with two members, **When** one member creates a list and adds items, **Then** the other member sees the list and items appear in real-time without manual refresh
3. **Given** a user enters shopping mode, **When** they mark items as purchased and exit, **Then** the activity log records the session and other members receive a notification
4. **Given** a user is on a slow or intermittent connection, **When** they perform shopping actions, **Then** the offline queue ensures no data is lost and sync completes when connectivity stabilizes
5. **Given** the app is used in Arabic, **When** the user navigates through all screens, **Then** all text is properly aligned RTL, all icons are mirrored where appropriate, and no text is truncated or overlapping

---

### User Story 2 - Beta Tester Onboarding (Priority: P1)

As a beta tester, I want to install the beta version of Beity and provide feedback easily, so that I can help improve the app before its public release.

**Why this priority**: Beta testing is the primary mechanism for discovering real-world issues before launch. If onboarding is friction-heavy, testers will drop off.

**Independent Test**: Can be tested by distributing a beta build to a small group, verifying they can install it, complete the core flow, and submit feedback without confusion.

**Acceptance Scenarios**:

1. **Given** a beta tester receives an invite link, **When** they install the app and open it, **Then** they see a brief welcome screen explaining they are using a beta version with guidance on how to report issues
2. **Given** a beta tester encounters a problem, **When** they access the feedback option from the app menu, **Then** they can submit a bug report with a description and automatic inclusion of device info and recent app logs
3. **Given** a beta tester completes their first shopping session, **When** they exit shopping mode, **Then** they are prompted with a one-time in-app satisfaction survey (1-5 star rating with optional text comment)

---

### User Story 3 - App Stability Under Load (Priority: P1)

As a home member with a large household, I want the app to remain fast and stable even with many shopping lists, items, and active members, so that the app does not slow down or crash during heavy use.

**Why this priority**: Stability is a prerequisite for trust. If the app crashes or freezes during a real shopping trip, users will abandon it permanently.

**Independent Test**: Can be tested by simulating a home with 5 members, 20 shopping lists, and 500+ items across lists, then verifying the app remains responsive (scrolling, adding, marking) with no crashes.

**Acceptance Scenarios**:

1. **Given** a home with 20 active shopping lists, **When** a user opens the lists screen, **Then** the list of lists loads within 2 seconds and scrolls smoothly
2. **Given** a shopping list with 200 items, **When** a user enters shopping mode, **Then** the items render without frame drops and marking items as purchased responds within 200ms
3. **Given** 5 members are simultaneously editing the same shopping list, **When** changes are made, **Then** all devices reflect the latest state within 3 seconds without duplicates or lost updates
4. **Given** the app has been running for 30 minutes of active shopping, **When** the user continues shopping, **Then** memory usage does not grow unboundedly and no out-of-memory crashes occur

---

### User Story 4 - Graceful Error Handling (Priority: P2)

As a home member, I want the app to show me clear, helpful error messages when something goes wrong — rather than crashes or blank screens — so that I can understand what happened and what to do next.

**Why this priority**: Users encounter errors in real-world scenarios (network failures, server outages, permission changes). Clear error handling prevents frustration and support requests.

**Independent Test**: Can be tested by triggering error conditions (airplane mode, invalid session, server 500) and verifying the app shows a user-friendly message with a recovery action.

**Acceptance Scenarios**:

1. **Given** the server is temporarily unavailable, **When** a user tries to create a shopping list, **Then** they see a message "Could not connect. Your changes will sync when you're back online." and the action is queued
2. **Given** a user's session has expired, **When** they perform any action, **Then** they are redirected to a re-authentication screen without losing their current view state
3. **Given** a user tries to access a home they were removed from, **When** the app loads, **Then** they see a message explaining they no longer have access and are taken to their homes list
4. **Given** an unexpected error occurs, **When** the app cannot recover automatically, **Then** the user sees a generic error screen with a "Try Again" button and a link to report the issue

---

### User Story 5 - Arabic RTL Quality (Priority: P2)

As an Arabic-speaking user, I want the app to feel native in Arabic — with proper text alignment, mirrored layouts, correct number formatting, and natural reading flow — so that I am not reminded I am using a translated app.

**Why this priority**: Beity targets Arabic-speaking households as a primary audience. A poor RTL experience would alienate the core user base.

**Independent Test**: Can be tested by switching the device language to Arabic and navigating every screen, verifying text alignment, icon mirroring, input field direction, number display, and list ordering are all correct.

**Acceptance Scenarios**:

1. **Given** the app is in Arabic, **When** a user views any screen, **Then** all text is right-aligned, navigation flows from right to left, and back arrows point to the right
2. **Given** the app is in Arabic, **When** a user views numeric data (quantities, prices, dates), **Then** numbers are displayed in the expected format for Arabic locales
3. **Given** the app is in Arabic, **When** a user interacts with forms and input fields, **Then** the cursor starts on the right side and text entry flows right-to-left
4. **Given** the app is in Arabic, **When** a user views icons that indicate direction (arrows, progress indicators), **Then** they are mirrored to match RTL reading direction

---

### User Story 6 - Accessibility Baseline (Priority: P2)

As a user with visual or motor impairments, I want the app to support screen readers and have adequately sized touch targets, so that I can use the core shopping functionality independently.

**Why this priority**: Accessibility is both an ethical obligation and a market expansion opportunity. Basic accessibility should be part of the MVP.

**Independent Test**: Can be tested by enabling VoiceOver/TalkBack and navigating the core shopping flow, verifying all interactive elements are labeled and reachable.

**Acceptance Scenarios**:

1. **Given** a screen reader is active, **When** a user navigates the shopping list, **Then** each item announces its name, quantity, unit, and purchased status
2. **Given** a screen reader is active, **When** a user taps the mark-as-purchased button, **Then** the reader announces the state change (e.g., "Milk, 2 kg, marked as purchased")
3. **Given** any user, **When** they interact with buttons and controls, **Then** all touch targets are at least 44x44 points and do not overlap

---

### User Story 7 - Crash and Performance Monitoring (Priority: P3)

As a product owner, I want the app to automatically report crashes and performance issues, so that the team can identify and fix problems proactively before users complain.

**Why this priority**: Without monitoring, the team relies on user reports to discover issues — which is slow and leaves many bugs unfound.

**Independent Test**: Can be tested by intentionally crashing the app in a test build and verifying the crash report appears in the monitoring dashboard.

**Acceptance Scenarios**:

1. **Given** the app crashes, **When** the user reopens it, **Then** the crash report is automatically sent with device info, app version, and stack trace (no user action required)
2. **Given** a slow operation occurs (screen load > 3 seconds), **When** the operation completes, **Then** a performance event is logged with the operation name and duration
3. **Given** the team reviews the monitoring dashboard, **When** they filter by app version, **Then** they can see crash rates, affected devices, and performance percentiles

---

### User Story 8 - Data Integrity Verification (Priority: P3)

As a home member, I want to be confident that my shopping data is always accurate and consistent — across devices, across sessions, and after offline sync — so that I never lose items or see contradictory states.

**Why this priority**: Data integrity issues (lost items, duplicate entries, stale purchased states) erode trust quickly and are hard to debug after the fact.

**Independent Test**: Can be tested by performing complex multi-device scenarios (user A adds item offline, user B marks different item online, user A comes back online) and verifying final state is consistent.

**Acceptance Scenarios**:

1. **Given** two users modify different items on the same list simultaneously, **When** both changes sync, **Then** both modifications are preserved without data loss
2. **Given** a user adds items offline and another user deletes a different item online, **When** the offline user reconnects, **Then** the added items appear and the deleted item remains removed
3. **Given** a shopping session is interrupted (app killed, phone dies), **When** the user reopens the app, **Then** all previously marked-as-purchased items retain their purchased state

---

### Edge Cases

- What happens when a user has 10+ homes and switches between them frequently? → Home switching must complete within 2 seconds; only the active home's data is loaded into memory
- How does the system handle a Supabase project hitting its connection limit? → The app shows a "server busy" message and retries automatically with backoff
- What happens when a beta tester's device has very limited storage? → The app warns the user when local storage falls below 50MB and suggests clearing cache
- How does the system handle mixed Arabic/English content in item names? → Mixed content renders correctly with proper bidirectional text handling
- What happens when a notification arrives while the user is in shopping mode? → The notification appears as a non-intrusive banner; shopping mode remains active
- How does the app behave after a long period of inactivity (app in background for 24+ hours)? → On resume, the app refreshes data silently and reconnects realtime subscriptions

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST complete the full sign-up → create home → create list → add items → shop → exit flow without crashes on both Android and iOS
- **FR-002**: System MUST display a beta welcome screen on first launch for beta builds with guidance on how to report issues
- **FR-003**: System MUST provide an in-app feedback mechanism via a menu option accessible from any screen
- **FR-004**: System MUST automatically include device info, app version, and recent logs in feedback submissions
- **FR-005**: System MUST remain responsive with up to 20 shopping lists and 500 items per home
- **FR-006**: System MUST render shopping mode with 200 items without frame drops or jank
- **FR-007**: System MUST handle server unavailability gracefully by queuing actions and showing informative messages
- **FR-008**: System MUST redirect to re-authentication when a session expires without losing the user's current navigation state
- **FR-009**: System MUST show proper RTL alignment, mirrored icons, and right-to-left text flow for all Arabic content
- **FR-010**: System MUST display numbers in appropriate locale format for Arabic users
- **FR-011**: System MUST provide accessibility labels for all interactive elements (buttons, items, controls)
- **FR-012**: System MUST ensure all touch targets are at least 44x44 points
- **FR-013**: System MUST automatically report crashes with device info, app version, and stack trace
- **FR-014**: System MUST log performance events for operations exceeding 3 seconds
- **FR-015**: System MUST preserve all shopping data across app kills, device reboots, and session interruptions
- **FR-016**: System MUST warn users when local storage falls below 50MB
- **FR-017**: System MUST handle mixed Arabic/English text with correct bidirectional rendering
- **FR-018**: System MUST refresh data and reconnect realtime subscriptions when the app returns from extended backgrounding
- **FR-019**: System MUST limit memory growth during extended shopping sessions (30+ minutes) to prevent out-of-memory crashes
- **FR-020**: System MUST handle home switching within 2 seconds regardless of the number of homes a user belongs to

### Key Entities

- **Crash Report**: Represents a recorded app crash. Contains device info, app version, stack trace, timestamp, and user context (anonymized). Used for proactive issue identification.
- **Performance Event**: Represents a slow operation. Contains operation name, duration, device info, and timestamp. Used for identifying performance bottlenecks.
- **Beta Feedback**: Represents a user-submitted report or survey response. For bug reports: contains user description, device info, app version, recent logs, and timestamp. For satisfaction surveys: contains star rating (1-5), optional text comment, and timestamp. Used for qualitative improvement.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 95% of users can complete the full sign-up to first shopping session without encountering a crash
- **SC-002**: The app maintains 60fps during shopping mode scrolling with 200 items on mid-range devices
- **SC-003**: Zero data loss for shopping actions performed offline and synced on reconnect
- **SC-004**: 90% of error states display a user-friendly message with a clear recovery action (no blank screens or cryptic errors)
- **SC-005**: All Arabic screens pass a manual RTL review with no alignment, mirroring, or text overflow issues
- **SC-006**: 100% of interactive elements have accessibility labels that screen readers can announce
- **SC-007**: Crash rate stays below 1% of sessions across the beta period
- **SC-008**: Beta testers report an average satisfaction rating of 4 out of 5 stars or higher
- **SC-009**: 95% of beta feedback submissions are triaged by the team within 48 hours of submission
- **SC-010**: App cold start time is under 3 seconds on a mid-range device

## Clarifications

### Session 2026-05-13

- Q: Should the in-app feedback mechanism use shake gesture, menu option, or both? → A: Menu option only
- Q: Which service should be used for crash and performance monitoring? → A: Firebase Crashlytics
- Q: What format should the post-shopping satisfaction survey use? → A: In-app 1-5 star rating with optional text comment
- Q: Should feedback be auto-categorized by the app or manually triaged by the team? → A: Team manually triages feedback

## Assumptions

- All features from SPEC 001 through SPEC 011 are implemented and merged before hardening begins
- Beta distribution will use standard platform mechanisms (TestFlight for iOS, Google Play Internal Testing for Android)
- Crash and performance monitoring will use Firebase Crashlytics
- The existing Supabase infrastructure supports the expected beta load (up to 100 concurrent users)
- Arabic translations for all existing screens have been completed in prior specs
- The hardening phase does not introduce new features — it only validates, polishes, and stabilizes existing ones
- Beta testers are recruited from the project team's personal network and are expected to be forgiving of minor issues
- Performance targets are measured on mid-range devices (e.g., Samsung Galaxy A54, iPhone 12)
