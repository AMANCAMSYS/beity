# SAWA In-App Feedback Implementation Report

> **Last Updated:** 2026-06-05
> **Tasks:** T157-T158 (In-app feedback and store rating prompts)

---

## Current Implementation Summary

### 1. Feedback Button (Always Available)

**Location:** Drawer menu → "ملاحظات" (Feedback)
**Implementation:** `lib/features/home/presentation/widgets/app_drawer.dart:237-242`
**Condition:** Visible only when `BetaConfig.isBeta == true`

The feedback button opens `FeedbackBottomSheet` which provides:
- Feedback type selector: Bug / Suggestion
- Description text field (max 2000 chars)
- Auto-attaches: device info, recent app logs, current screen route
- Submits to Supabase Edge Function `submit-feedback`

### 2. Satisfaction Survey (Post-Shopping Mode)

**Location:** Triggered when exiting Shopping Mode
**Implementation:** `lib/features/shopping_mode/presentation/screens/widgets/shopping_mode_exit_handler.dart:149-151`
**Condition:** `BetaConfig.isBeta == true` AND survey not yet shown

The `SatisfactionSurveyDialog` provides:
- Star rating (1-5)
- Optional comment field (max 1000 chars)
- Skip option
- Submits to Supabase Edge Function `submit-feedback` with type `survey`
- Stores `satisfaction_survey_shown` in SharedPreferences to show only once

### 3. Beta Welcome Dialog

**Location:** Shown on first app launch in beta mode
**Implementation:** `lib/features/home/presentation/screens/home_screen.dart:56-58`
**Condition:** `BetaConfig.isBeta == true` AND welcome not yet shown

### 4. Beta Configuration

**Implementation:** `lib/features/beta/data/beta_config.dart`
- Uses `--dart-define=BETA=true` at build time
- Default: `false` (feedback features hidden in production)

---

## T157: Feedback After First Completed Shopping List

### Current Behavior

The satisfaction survey triggers when:
1. User exits Shopping Mode (not after first list completion)
2. `BetaConfig.isBeta` is `true`
3. Survey hasn't been shown before (`satisfaction_survey_shown` is false)

### Gap Analysis

| Requirement | Current State | Gap |
|-------------|---------------|-----|
| Feedback after first completed list | Triggers after Shopping Mode exit | Timing differs — not tied to list completion |
| Only for beta users | ✅ `BetaConfig.isBeta` check | None |
| Shows only once | ✅ SharedPreferences flag | None |
| No prompt after crash | ❌ No crash state check | **Gap:** Survey could show after crash if user restarts and exits Shopping Mode |
| No prompt after sync failure | ❌ No sync failure check | **Gap:** Survey could show during sync issues |

### Recommendations

1. **Add crash guard:** Check `MonitoringService` for recent crash before showing survey
2. **Add sync guard:** Check offline queue status — if recent sync failures, defer survey
3. **Consider list-completion trigger:** Move trigger to when all items in a list are marked purchased (alternative to Shopping Mode exit)

---

## T158: Store Rating Prompts After Crash/Sync Failure

### Current State

**No store rating prompt exists.** The app has:
- In-app satisfaction survey (star rating, not store rating)
- Feedback button for bug reports and suggestions
- No link to Google Play Store rating

### Gap Analysis

| Requirement | Current State | Gap |
|-------------|---------------|-----|
| Store rating prompt | Not implemented | **Gap:** No Play Store rating flow |
| Don't show after crash | N/A | **Gap:** No store rating to guard |
| Don't show after sync failure | N/A | **Gap:** No store rating to guard |

### Recommendations for Store Rating Implementation

1. **Use `in_app_review` package** for native Play Store rating prompt
2. **Gate conditions (all must be true):**
   - User has completed at least 3 shopping sessions
   - No crash in last 7 days
   - No sync failure in last 24 hours
   - Satisfaction survey rating >= 4 stars
   - Not shown in last 30 days
3. **Trigger:** After successful Shopping Mode exit (when gate conditions met)
4. **Implementation location:** `shopping_mode_exit_handler.dart` after survey flow

### Suggested Gate Logic

```dart
Future<bool> _shouldShowStoreRating() async {
  final recentCrash = await MonitoringService().hasRecentCrash(days: 7);
  if (recentCrash) return false;

  final recentSyncFailure = await OfflineQueueService().hasRecentFailure(hours: 24);
  if (recentSyncFailure) return false;

  final surveyRating = await BetaPreferences.getLastSurveyRating();
  if (surveyRating < 4) return false;

  final sessionCount = await ShoppingSessionService().getCompletedSessionCount();
  if (sessionCount < 3) return false;

  final lastShown = await BetaPreferences.getLastStoreRatingPromptDate();
  if (lastShown != null && DateTime.now().difference(lastShown).inDays < 30) {
    return false;
  }

  return true;
}
```

---

## Feedback Data Flow

```
User Action → FeedbackBottomSheet / SatisfactionSurveyDialog
    ↓
FeedbackRepository.submitFeedback()
    ↓
Supabase Edge Function: submit-feedback
    ↓
beta_feedback table (with device_info, app_logs, screen_route)
```

### Data Attached to Each Submission
- `feedback_type`: 'bug', 'survey', or 'suggestion'
- `description`: User-provided text
- `star_rating`: 1-5 (survey only)
- `device_info`: Model, OS version, app version
- `screen_route`: Current screen when feedback was opened
- `app_logs`: Recent log buffer entries

---

## Files Involved

| File | Purpose |
|------|---------|
| `lib/features/beta/data/beta_config.dart` | Beta mode flag |
| `lib/features/beta/data/beta_preferences.dart` | Survey/welcome shown state |
| `lib/features/beta/data/feedback_repository.dart` | Submits to Supabase Edge Function |
| `lib/features/beta/presentation/feedback_bottom_sheet.dart` | Bug/suggestion feedback UI |
| `lib/features/beta/presentation/satisfaction_survey_dialog.dart` | Star rating survey UI |
| `lib/features/beta/presentation/beta_welcome_dialog.dart` | First-launch welcome dialog |
| `lib/features/shopping_mode/presentation/screens/widgets/shopping_mode_exit_handler.dart` | Survey trigger point |
| `lib/features/home/presentation/widgets/app_drawer.dart` | Feedback button in drawer |
