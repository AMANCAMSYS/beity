# SAWA v0.2.0-preview QA Checklist

## CI Quality Gate (T138-T142)

All four checks must pass before merging any PR.

### Quality Gate Commands

```bash
# 1. Formatting (T139)
/home/omar/flutter/bin/dart format --set-exit-if-changed .

# 2. Static analysis (T140)
/home/omar/flutter/bin/flutter analyze

# 3. Tests (T141)
/home/omar/flutter/bin/flutter test

# 4. Android release build (T142)
cd android && ./gradlew :app:assembleRelease
```

### Verification Results (2026-06-05)

| Check | Command | Status | Notes |
|-------|---------|--------|-------|
| T139: dart format | `dart format --set-exit-if-changed .` | PASS (after reformat) | 303 files reformatted; now clean |
| T140: flutter analyze | `flutter analyze` | PASS | 17 info/warnings, 0 errors |
| T141: flutter test | `flutter test` | PASS | 526 passed, 9 skipped, 0 failed |
| T142: Android release | `./gradlew :app:assembleRelease` | PASS | BUILD SUCCESSFUL (3m 2s) |

### Test Coverage Requirements

- All new code must have corresponding tests
- Minimum: repository + use case tests per feature
- Critical UI flows (login, add item, shopping mode) require widget tests
- No test may be permanently skipped without approval

### Pre-merge Checklist

- [ ] `dart format --set-exit-if-changed .` exits 0
- [ ] `flutter analyze` reports 0 errors (warnings/info acceptable)
- [ ] `flutter test` all tests pass (skips acceptable)
- [ ] Android release build succeeds
- [ ] No new `unused_import` warnings introduced
- [ ] RLS policies cover any new Supabase tables
- [ ] `created_by`/`updated_by` set on write operations

### Build Verification Steps

1. Run `dart format --set-exit-if-changed .` — must exit 0
2. Run `flutter analyze` — must show 0 errors
3. Run `flutter test` — must show "All tests passed!"
4. Run `cd android && ./gradlew :app:assembleRelease` — must show "BUILD SUCCESSFUL"
5. Verify APK exists at `android/app/build/outputs/flutter-apk/app-release.apk`

---

## Pre-Release Verification

### Build & Static Analysis
- [ ] `flutter analyze lib/` passes with 0 errors
- [ ] `flutter test` passes with all tests green (526+ tests)
- [ ] App builds successfully for Android (release)
- [ ] App builds successfully for iOS (debug)

### Auth & Session
- [ ] Fresh install shows login screen
- [ ] New user registration works
- [ ] Login with valid credentials succeeds
- [ ] Login with invalid credentials shows Arabic error message
- [ ] Logout clears all cached data
- [ ] Login with different account shows no previous user data
- [ ] Session persists across app restart
- [ ] Unauthenticated user is redirected to login from any route

### Home Management
- [ ] New user with no homes sees onboarding screen
- [ ] Create home with name and type works
- [ ] Home appears in home selector dropdown
- [ ] Switching homes updates all data (lists, items, activity)
- [ ] Homes list shows loading, empty, and error states
- [ ] Pull-to-refresh works on homes list

### Invitations & Members
- [ ] Send invitation to email works
- [ ] Invitation appears in recipient's invitations list
- [ ] Accept invitation adds user to home
- [ ] Decline invitation removes it from list
- [ ] Home members screen shows all active members
- [ ] Member roles (owner, admin, member) display correctly
- [ ] Empty state shows when no invitations exist
- [ ] Error state shows with retry on failure

### Shopping Lists
- [ ] Create shopping list with name works
- [ ] List appears in active lists tab
- [ ] List shows item count and progress
- [ ] Archive list moves it to archived tab
- [ ] Delete list with confirmation works
- [ ] Rename list works
- [ ] Empty state shows when no lists exist
- [ ] Loading spinner shows while fetching
- [ ] Error state with retry shows on failure

### Shopping Items
- [ ] Add item with name works
- [ ] Add item with quantity, unit, category, notes works
- [ ] Item appears in list immediately (optimistic UI)
- [ ] Mark item as purchased works
- [ ] Unmark item as purchased works
- [ ] Edit item details works
- [ ] Delete item with undo snackbar works
- [ ] Items grouped by category display correctly
- [ ] Search/filter items works
- [ ] Empty state shows when list is empty
- [ ] Soft-deleted items do not appear in active lists

### Shopping Mode
- [ ] Shopping mode opens from list detail
- [ ] Large touch targets for item toggling
- [ ] Progress bar updates on item toggle
- [ ] Connection status indicator shows

### Realtime Sync
- [ ] Changes from Device A appear on Device B within 2 seconds
- [ ] Presence indicators show who is viewing a list
- [ ] No duplicate items after realtime update
- [ ] Reconnection after network loss syncs correctly
- [ ] Subscriptions are cancelled on logout

### Offline Queue
- [ ] App shows offline status when disconnected
- [ ] Actions queued while offline
- [ ] Queue syncs automatically on reconnect
- [ ] Queue is user-scoped (no cross-user leakage)
- [ ] Pending count shows in UI
- [ ] Failed items show retry option
- [ ] Queue clears on logout

### Activity Logs
- [ ] Activity feed shows recent actions
- [ ] Activity detail shows full context
- [ ] Empty state shows when no activity
- [ ] List-specific activity filter works

### Notifications
- [ ] Notification center shows all notifications
- [ ] Unread count badge displays
- [ ] Mark all as read works
- [ ] Empty state shows when no notifications
- [ ] Error state with retry shows on failure
- [ ] Notification preferences toggle works

### Categories & Units
- [ ] Categories list shows all home categories
- [ ] Create category works
- [ ] Units list shows all units
- [ ] Create unit works
- [ ] Empty states show when no categories/units

### Profile
- [ ] Profile screen shows current user info
- [ ] Update profile name works
- [ ] Update profile phone works

### Navigation
- [ ] Bottom navigation switches tabs correctly
- [ ] Drawer menu navigates to all screens
- [ ] Back navigation works as expected
- [ ] Deep links from notifications work
- [ ] Logout redirects to login and clears stack
- [ ] "إدارة الأدوار" button in HomeMembersScreen works
- [ ] "دعوات هذا المنزل" button in HomeMembersScreen works
- [ ] Categories FAB navigates to create screen
- [ ] Units FAB navigates to create screen
- [ ] "إضافة سريعة" button in ShoppingListDetailScreen works
- [ ] Edit button in InventoryItemDetailScreen works
- [ ] "ملخص المصروفات" button in ExpenseListScreen works
- [ ] "الأرصدة" button in ExpenseListScreen works

### Inventory (enableInventory: true)
- [ ] Inventory screen accessible from Drawer
- [ ] Inventory screen shows items grouped by category
- [ ] Add inventory item FAB works
- [ ] Add inventory item form submits correctly
- [ ] Inventory item detail screen shows all info
- [ ] Edit button in inventory item detail navigates to edit screen
- [ ] Edit inventory item form submits correctly
- [ ] Delete inventory item with confirmation works
- [ ] Quantity adjuster (+/-) works
- [ ] Low stock badge displays correctly
- [ ] Empty state shows when no items

### Expenses (enableExpenses: true)
- [ ] Expenses screen accessible from Drawer with "تجريبي" badge
- [ ] Expense list shows all expenses
- [ ] FAB navigates to add expense screen
- [ ] Add expense form submits correctly
- [ ] Tapping expense navigates to detail screen
- [ ] Expense detail shows splits and delete option
- [ ] "ملخص المصروفات" button navigates to summary screen
- [ ] "الأرصدة" button navigates to balances screen
- [ ] Filter dialog works (date range)
- [ ] Empty state shows when no expenses

### Tasks (enableTasks: true)
- [ ] Tasks screen accessible from Drawer
- [ ] Task list shows tasks with tabs (مهامي / كل المهام)
- [ ] FAB navigates to add task screen
- [ ] Add task form submits correctly
- [ ] Tapping task navigates to detail screen
- [ ] Task detail shows edit and delete options
- [ ] Mark task as complete works
- [ ] Archived tasks screen accessible
- [ ] Empty state shows when no tasks

### Feature Flags
- [ ] enableInventory=false hides inventory from Drawer and Settings
- [ ] enableExpenses=false hides expenses from Drawer and Settings
- [ ] enableTasks=false hides tasks from Drawer and Settings
- [ ] AI shows as "قريبًا" (disabled) in Drawer

### Arabic & RTL
- [ ] All screens display Arabic text correctly
- [ ] RTL layout applied to forms and lists
- [ ] Mixed Arabic/English content renders correctly
- [ ] Date/time formatting in Arabic

## Device Matrix (Manual)
- [ ] Android physical device
- [ ] Android emulator
- [ ] iOS simulator (if available)
- [ ] RTL locale device

## Performance
- [ ] Home screen loads in < 2 seconds
- [ ] Shopping list loads in < 1 second
- [ ] Add item completes in < 500ms
- [ ] No visible jank during scrolling
- [ ] App doesn't crash on rapid navigation

---

## Post-Launch Monitoring (T169-T171)

### First 48-Hour Crash Monitoring Plan

#### Monitoring Stack
- **Firebase Crashlytics:** Primary crash reporting
- **Google Play Console:** ANR and crash metrics
- **Supabase Logs:** Backend errors and Edge Function failures

#### Hour 0-2 (Immediate Post-Release)
- [ ] Monitor Crashlytics dashboard continuously
- [ ] Check for any new crash clusters
- [ ] Verify crash-free rate stays above 99.5%
- [ ] Check Google Play Console for ANR reports
- [ ] Monitor Supabase Edge Function logs for errors
- [ ] Verify FCM delivery rate in Firebase Console

#### Hour 2-12
- [ ] Check Crashlytics every 2 hours
- [ ] Review any new crash signatures
- [ ] Monitor realtime sync error rates
- [ ] Check offline queue failure rates
- [ ] Review feedback submissions for patterns

#### Hour 12-48
- [ ] Check Crashlytics every 4 hours
- [ ] Compare crash rates across device types
- [ ] Monitor user retention (DAU)
- [ ] Review satisfaction survey ratings
- [ ] Document any recurring issues

#### Escalation Triggers (Immediate Hotfix Required)
- Crash-free rate drops below 99.0%
- Data loss reported by any user
- Authentication failures affecting multiple users
- Realtime sync completely broken
- Push notification delivery failure >50%

#### Monitoring Dashboard Checklist
- [ ] Firebase Crashlytics bookmarked and accessible
- [ ] Google Play Console crash section bookmarked
- [ ] Supabase dashboard accessible
- [ ] FCM delivery reports accessible
- [ ] Team notification channel set up (Slack/WhatsApp)

---

### Hotfix Path and Rollback Rules

#### Hotfix Process

1. **Identify:** Crash/bug reported via Crashlytics or user feedback
2. **Triage:** Classify severity (Critical / High / Medium / Low)
3. **Fix:** Branch from `main`, fix, test locally
4. **Verify:** Run full CI gate (`dart format`, `flutter analyze`, `flutter test`, release build)
5. **Release:** Increment build number, build AAB, upload to Play Store
6. **Monitor:** Watch Crashlytics for 2 hours post-release

#### Severity Classification

| Severity | Definition | Response Time | Example |
|----------|------------|---------------|---------|
| Critical | Data loss, auth broken, app unusable | < 2 hours | Offline queue loses items |
| High | Major feature broken, crash on common flow | < 8 hours | Shopping Mode crashes |
| Medium | Feature degraded, workaround exists | < 24 hours | Notification delay |
| Low | Cosmetic, minor inconvenience | Next release | Wrong icon color |

#### Hotfix Checklist
- [ ] Issue confirmed and reproduced
- [ ] Root cause identified
- [ ] Fix tested on physical device
- [ ] `flutter analyze` passes
- [ ] `flutter test` passes
- [ ] Release build succeeds
- [ ] Version number incremented
- [ ] CHANGELOG.md updated
- [ ] AAB uploaded to Play Store
- [ ] Crashlytics monitored post-release

#### Rollback Rules

**When to Rollback (Unpublish Previous Version):**
- Critical data loss affecting >1% of users
- Authentication system completely broken
- App crashes on launch for >5% of users
- Security vulnerability discovered

**Rollback Process:**
1. Go to Google Play Console → Release → Production
2. Halt rollout of current version
3. Promote previous version to production
4. Notify users via in-app message (if possible)
5. Document incident and root cause

**When NOT to Rollback:**
- Single user reports (investigate first)
- Device-specific issues (fix and release)
- Performance degradation <10%
- Cosmetic issues

---

### Known Issues Transparency

#### Internal Known Issues Tracking

All known issues must be documented in `docs/beta/known-issues.md` with:
- Issue description (Arabic + English)
- Severity (Critical / High / Medium / Low)
- Affected users / devices
- Workaround (if any)
- Status (Open / In Progress / Fixed / Won't Fix)
- GitHub issue link (if tracked)

#### Pre-Release Known Issues

| # | Issue | Severity | Workaround | Status |
|---|-------|----------|------------|--------|
| 1 | Offline queue not fully wired | Medium | Use app online | In Progress |
| 2 | Some notification text in English | Low | None needed | Open |
| 3 | Expense filters incomplete | Low | Use date filter only | Deferred |
| 4 | Shopping list description not saved | Low | Removed from UI | Deferred |
| 5 | Join by code button hidden | Low | Use invitation link | Deferred |

#### User-Facing Known Issues Communication

**For beta users:** Share known issues in beta group before release:
- List of known issues with workarounds
- Expected fix timeline
- How to report new issues (in-app feedback button)

**For Play Store listing:** Do NOT list known issues publicly. Fix critical issues before public release.

#### Post-Release Issue Response

| Timeframe | Action |
|-----------|--------|
| 0-2 hours | Monitor Crashlytics, no action unless critical |
| 2-8 hours | Triage new reports, update known-issues.md |
| 8-24 hours | Begin hotfix for high-severity issues |
| 24-48 hours | Release hotfix if needed |
| 48+ hours | Plan fixes for next release cycle
