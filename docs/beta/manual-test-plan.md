# SAWA Closed Beta Manual Test Plan

> **Version:** 1.0.0+2003
> **Last Updated:** 2026-06-05
> **Beta Type:** Closed beta, 10-30 real household users

---

## Beta Plan Overview

### Objectives
- Validate SAWA with real households (families, roommates, shared homes)
- Identify crash/data-loss issues before public release
- Collect satisfaction ratings and qualitative feedback
- Verify realtime sync under real-world network conditions

### Target Users
- **Count:** 10-30 users across 5-15 households
- **Profile:** Real families and roommates who share shopping responsibilities
- **Language:** Arabic-primary users, some English users
- **Duration:** 2-3 weeks minimum before public release

### Device Requirements

| Requirement | Minimum | Recommended |
|-------------|---------|-------------|
| Android SDK | API 26 (Android 8.0) | API 33+ (Android 13+) |
| RAM | 3 GB | 4 GB+ |
| Storage | 100 MB free | 500 MB free |
| Screen | 720p | 1080p+ |

#### Required Device Coverage
- [ ] Low-end device (e.g., Samsung Galaxy A14, 3 GB RAM)
- [ ] Mid-range device (e.g., Samsung Galaxy A54, 6 GB RAM)
- [ ] High-end device (e.g., Samsung Galaxy S24, 8 GB RAM)
- [ ] Tablet (if available, e.g., Samsung Tab A8)
- [ ] Device with Arabic system locale set
- [ ] Device with English system locale set

### Network Scenarios

| Scenario | How to Simulate | Expected Behavior |
|----------|-----------------|-------------------|
| Stable WiFi | Normal home WiFi | All features work normally |
| Weak WiFi (1-2 bars) | Move far from router | App remains responsive, sync may be slower |
| Mobile data (4G/5G) | Disable WiFi, use cellular | All features work, notifications arrive |
| Intermittent connection | Elevator / underground parking | Offline queue activates, syncs on reconnect |
| Airplane mode | Toggle airplane mode | Offline indicator shows, actions queue |
| Network switch | WiFi → mobile data mid-action | Session persists, no data loss |
| No internet on launch | Airplane mode at app start | Shows cached data, offline indicator |

---

## Test Scenarios

### Phase 1: First-Time Experience (Day 1)

#### FT-01: Fresh Install & Onboarding
1. Install APK on clean device
2. Launch app
3. **Verify:** Login screen appears with Arabic text
4. Register new account
5. **Verify:** Onboarding flow guides through home creation
6. Create first home with Arabic name
7. **Verify:** Home dashboard shows empty state with clear CTA

#### FT-02: Create First Shopping List
1. From home dashboard, tap "قوائم المشتريات"
2. Tap + FAB to create list
3. Enter list name in Arabic
4. **Verify:** List appears immediately
5. Open list and add 3-5 items
6. **Verify:** Items appear instantly (optimistic UI)
7. **Verify:** Items are grouped by category

#### FT-03: Invite Family Member
1. Navigate to "إدارة الأعضاء"
2. Invite another beta tester by email
3. **Verify:** Invitation sent successfully
4. Second tester accepts invitation
5. **Verify:** Both users see the same home and lists

### Phase 2: Daily Usage (Days 2-7)

#### DU-01: Daily Shopping Flow
1. Open existing shopping list
2. Add items needed for the week
3. Enter Shopping Mode
4. Toggle items as purchased while shopping
5. **Verify:** Progress bar updates
6. Exit Shopping Mode
7. **Verify:** Satisfaction survey appears (first time only, beta mode)

#### DU-02: Multi-User Realtime
1. User A and User B open same list
2. User A adds item "حليب"
3. **Verify:** User B sees "حليب" within 2 seconds
4. User B marks item as purchased
5. **Verify:** User A sees item move to purchased section
6. **Verify:** Presence indicators show both users

#### DU-03: Offline Shopping
1. Open shopping list
2. Enable airplane mode
3. Add several items
4. **Verify:** Items appear in UI (optimistic)
5. **Verify:** Offline indicator/banner shows
6. Disable airplane mode
7. **Verify:** Items sync automatically
8. **Verify:** No duplicate items

#### DU-04: Weak Connection Resilience
1. Connect to very weak WiFi (1 bar)
2. Open shopping list
3. Add items
4. **Verify:** App doesn't freeze or crash
5. **Verify:** Items eventually sync
6. **Verify:** Error messages are user-friendly (Arabic)

### Phase 3: Stress & Edge Cases (Days 7-14)

#### SE-01: Large List Performance
1. Add 50+ items to a single list
2. Scroll through list in Shopping Mode
3. **Verify:** Smooth scrolling, no jank
4. Search/filter within large list
5. **Verify:** Filter responds instantly

#### SE-02: Background/Foreground
1. Open shopping list
2. Send app to background for 5+ minutes
3. Return to foreground
4. **Verify:** Data still displayed
5. **Verify:** Realtime reconnects
6. Make a change
7. **Verify:** Change syncs to other device

#### SE-03: Account Switching
1. Log out from Account A
2. Log in with Account B
3. **Verify:** No data from Account A visible
4. Log out from Account B
5. Log back in with Account A
6. **Verify:** All Account A data intact

#### SE-04: Rapid Actions
1. Quickly toggle items as purchased/unpurchased
2. Rapidly switch between tabs
3. Add and immediately delete items
4. **Verify:** No crashes
5. **Verify:** No data corruption

#### SE-05: Notification Delivery
1. User A adds item to shared list
2. **Verify:** User B receives notification
3. Tap notification
4. **Verify:** App opens to correct list/item
5. **Verify:** Notification badge updates

### Phase 4: Feedback Collection (Days 14-21)

#### FB-01: In-App Feedback
1. Open drawer menu
2. Tap "ملاحظات" (Feedback)
3. Select feedback type (bug/suggestion)
4. Enter description
5. Submit
6. **Verify:** Success message appears
7. **Verify:** Feedback recorded in Supabase

#### FB-02: Satisfaction Survey
1. Complete a Shopping Mode session
2. Exit Shopping Mode
3. **Verify:** Satisfaction survey dialog appears (first time)
4. Submit rating and optional comment
5. **Verify:** Thank you message appears
6. **Verify:** Survey doesn't show again

---

## Feedback Collection

### Quantitative Metrics
- Crash-free rate (target: >99.5%)
- Average add-item time (target: <500ms)
- Realtime sync latency (target: <2s)
- Session duration
- Lists created per household

### Qualitative Feedback
- In-app feedback button (bug/suggestion)
- Satisfaction survey after first Shopping Mode session
- Direct WhatsApp/Telegram group for beta testers
- Weekly check-in form

---

## Success Criteria for Beta Exit

| Metric | Threshold |
|--------|-----------|
| Crash-free users | >99.5% |
| Data loss incidents | 0 |
| Realtime sync success | >98% |
| Average satisfaction rating | >4.0/5 |
| Critical bugs open | 0 |
| High-priority bugs open | <3 |
