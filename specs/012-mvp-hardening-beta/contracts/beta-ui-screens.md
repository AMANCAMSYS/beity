# Contract: Beta UI Screens

**Feature**: 012-mvp-hardening-beta
**Type**: Flutter Widget Contracts

## Screen 1: Beta Welcome Dialog

### Trigger
- Shown once on first app launch when `SharedPreferences.beta_welcome_shown == false`
- Only shown in beta builds (controlled by `BETA` dart-define flag)
- Shown after splash screen, before navigating to main content

### Layout

```
┌─────────────────────────────────────┐
│                                     │
│         🏠 Beity Beta               │
│                                     │
│  Welcome to the Beity Beta!         │
│  You're among the first to try      │
│  our family shopping app.           │
│                                     │
│  ─────────────────────────────────  │
│                                     │
│  How to Report Issues:              │
│  • Tap the menu (☰) on any screen   │
│  • Select "Send Feedback"           │
│  • Describe what happened           │
│                                     │
│  Your feedback helps us improve!    │
│                                     │
│         [ Got it! ]                 │
│                                     │
└─────────────────────────────────────┘
```

### Behavior
- Tapping "Got it!" sets `beta_welcome_shown = true` and dismisses the dialog
- Dialog is not dismissible by tapping outside (must tap button)
- Supports Arabic RTL layout (text right-aligned, mirrored)
- Accessibility: Dialog title and button have semantic labels

### State
- **Local storage key**: `beta_welcome_shown` (bool)
- **Default**: `false`
- **On dismiss**: set to `true`

---

## Screen 2: Feedback Bottom Sheet

### Trigger
- Opened from app menu → "Send Feedback" option
- Available on any screen via the global menu/scaffold

### Layout

```
┌─────────────────────────────────────┐
│  Send Feedback                  [✕] │
│  ─────────────────────────────────  │
│                                     │
│  Type:  ( ) Bug Report              │
│         (•) Suggestion              │
│                                     │
│  ┌─────────────────────────────┐    │
│  │ Describe what happened or   │    │
│  │ what you'd like to see...   │    │
│  │                             │    │
│  │                             │    │
│  └─────────────────────────────┘    │
│                                     │
│  Attached automatically:            │
│  Device info, app version, logs     │
│                                     │
│         [ Submit Feedback ]         │
│                                     │
└─────────────────────────────────────┘
```

### Behavior
- Type selector: Radio buttons for "Bug Report" or "Suggestion"
- Description field: Multiline text input, required, 1-2000 characters
- Character count shown below field
- Device info shown as a collapsible "Attached automatically" section
- Submit button disabled until description is non-empty
- On submit: POST to `submit-feedback` Edge Function
- Success: Show snackbar "Feedback sent. Thank you!" and dismiss sheet
- Error: Show inline error message, keep sheet open
- Loading state: Show spinner on submit button during network request
- Accessibility: All form fields and buttons have semantic labels

### State
- **Feedback type**: Local state (default: "bug")
- **Description**: Local state
- **Submission status**: Local state (idle, loading, success, error)
- **Device info**: Injected from device info service (read-only)

---

## Screen 3: Satisfaction Survey Dialog

### Trigger
- Shown once after user exits shopping mode for the first time
- Only in beta builds
- Only if `SharedPreferences.satisfaction_survey_shown == false`

### Layout

```
┌─────────────────────────────────────┐
│                                     │
│  How was your shopping experience?  │
│                                     │
│     ★ ★ ★ ★ ★                       │
│                                     │
│  ┌─────────────────────────────┐    │
│  │ Any additional comments?    │    │
│  │ (optional)                  │    │
│  └─────────────────────────────┘    │
│                                     │
│         [ Submit ]                  │
│                                     │
│         [ Skip ]                    │
│                                     │
└─────────────────────────────────────┘
```

### Behavior
- Star rating: Tappable stars, required (default: 0, must select to submit)
- Comment field: Optional, max 1000 characters
- Submit: POST to `submit-feedback` with `feedback_type: "survey"`
- Skip: Dismisses without submitting, sets `satisfaction_survey_shown = true`
- On submit success: Set `satisfaction_survey_shown = true`, show "Thanks!" snackbar
- Accessibility: Stars have labels ("1 star", "2 stars", etc.), submit button labeled

### State
- **Star rating**: Local state (default: 0)
- **Comment**: Local state
- **Submission status**: Local state
- **Storage key**: `satisfaction_survey_shown` (bool)
