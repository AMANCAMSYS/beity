# Quickstart: MVP Hardening and Beta

**Feature**: 012-mvp-hardening-beta
**Date**: 2026-05-13

## Prerequisites

- Flutter SDK (stable channel)
- Firebase project configured (already set up for FCM)
- Supabase project with existing tables (SPEC 001-011 migrations applied)
- Android Studio / Xcode for device testing

## Setup

### 1. Add Firebase Crashlytics dependency

```yaml
# pubspec.yaml
dependencies:
  firebase_crashlytics: ^4.0.0
```

### 2. Configure Crashlytics

```dart
// lib/main.dart (add before runApp)
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Pass all uncaught errors to Crashlytics
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;

  runApp(const BeityApp());
}
```

### 3. Create beta_feedback table

Run the migration in `supabase/migrations/` to create the `beta_feedback` table with RLS policies (see [data-model.md](./data-model.md)).

### 4. Deploy feedback Edge Function

```bash
supabase functions deploy submit-feedback
```

### 5. Run with beta flag

```bash
# Development
flutter run --dart-define=BETA=true

# Build for testing
flutter build apk --dart-define=BETA=true
flutter build ios --dart-define=BETA=true
```

## Key Commands

| Command                                          | Description                             |
| ------------------------------------------------ | --------------------------------------- |
| `flutter test`                                   | Run unit and widget tests               |
| `flutter test integration_test/`                 | Run integration tests on connected device |
| `flutter analyze`                                | Static analysis (must pass before commit) |
| `flutter run --dart-define=BETA=true`            | Run app in beta mode                    |
| `supabase functions deploy submit-feedback`      | Deploy feedback Edge Function           |

## Verification

### Crash Reporting
1. Run app with `--dart-define=BETA=true`
2. Trigger a test crash (e.g., `FirebaseCrashlytics.instance.crash()`)
3. Reopen app and check Firebase Console → Crashlytics for the report

### Feedback Submission
1. Open app menu → "Send Feedback"
2. Fill in description and submit
3. Check Supabase `beta_feedback` table for the record

### Accessibility
1. Enable VoiceOver (iOS) or TalkBack (Android)
2. Navigate the core shopping flow
3. Verify all interactive elements announce their labels

### RTL
1. Set device language to Arabic
2. Navigate every screen
3. Verify text alignment, icon mirroring, input direction
