# SAWA Release Checklist

> **Last Updated:** 2026-06-05
> **Version:** 1.0.0+2003

---

## 1. Version & Build Number

### Current State
- `pubspec.yaml` version: `1.0.0+2003`
- `versionName`: 1.0.0
- `versionCode`: 2003

### Pre-Release Actions
- [ ] Decide on release version (e.g., `1.0.0+1` for first public release)
- [ ] Update `pubspec.yaml` version
- [ ] Update `CHANGELOG.md` with release notes
- [ ] Verify `versionName` and `versionCode` in Android manifest match pubspec
- [ ] Ensure `versionCode` increments with each Play Store upload

### Version Strategy
- **Major.Minor.Patch+BuildNumber** format
- Build number increments on every Play Store upload
- Semantic versioning for user-facing version

---

## 2. Android Signing Configuration

### Current State
- Signing config exists in `android/app/build.gradle.kts`
- Reads from `android/key.properties` (gitignored)
- Release signing config is properly wired

### Pre-Release Actions
- [ ] Verify `key.properties` exists with valid credentials
- [ ] Verify keystore file exists at configured path
- [ ] Test release signing: `./gradlew :app:assembleRelease`
- [ ] Backup keystore file and credentials securely
- [ ] Document keystore password location (password manager)

### Keystore Backup
- Store keystore in secure location (NOT in repository)
- Store passwords in password manager
- Document keystore alias and file path
- **CRITICAL:** Lost keystore = cannot update app on Play Store

---

## 3. ProGuard / R8 Release Build

### Current State
- `isMinifyEnabled = true` in release build type
- `isShrinkResources = true` in release build type
- `proguard-rules.pro` configured with rules for:
  - Flutter
  - Supabase
  - Firebase
  - json_serializable
  - Play Core tasks

### Pre-Release Actions
- [ ] Run release build: `cd android && ./gradlew :app:assembleRelease`
- [ ] Verify APK/AAB size is reasonable (<50 MB)
- [ ] Test release build on physical device
- [ ] Verify no ProGuard-related crashes in release mode
- [ ] Check that Supabase/Firebase classes are preserved
- [ ] Verify json_serializable models work in release

### Build Commands
```bash
# Clean build
cd android && ./gradlew clean

# Release APK
./gradlew :app:assembleRelease

# Release AAB (for Play Store)
./gradlew :app:bundleRelease
```

### Output Locations
- APK: `android/app/build/outputs/flutter-apk/app-release.apk`
- AAB: `android/app/build/outputs/bundle/release/app-release.aab`

---

## 4. Notification Permission Flow

### Current State
- Firebase Cloud Messaging (FCM) integrated
- Notification permission requested during service initialization
- Android 13+ runtime permission handled via `flutter_local_notifications`
- Local notification channel created: `sawa_notifications`
- Permission check: `areNotificationsEnabled()` → `requestNotificationsPermission()`

### Implementation Details
- `NotificationInitializer.requestPermission()` — requests FCM permission
- `NotificationInitializer.initializeLocalNotifications()` — sets up local notifications with Android permission
- Foreground messages handled via `FirebaseMessaging.onMessage`
- Background messages handled via `sawaFirebaseMessagingBackgroundHandler`
- Notification tap navigation via `NotificationNavigationHelper`

### Pre-Release Actions
- [ ] Verify notification permission prompt appears on Android 13+
- [ ] Verify notifications arrive when app is in foreground
- [ ] Verify notifications arrive when app is in background
- [ ] Verify notification tap navigates to correct screen
- [ ] Verify notification permission denial doesn't crash app
- [ ] Test notification with app killed (cold start from notification)
- [ ] Verify FCM token refresh works
- [ ] Verify notification channel name is in Arabic for Arabic users

### Test Scenarios
1. Fresh install → notification permission prompt
2. Deny permission → app continues normally
3. Grant permission → receive test notification
4. Tap notification → navigate to correct list
5. Notification while in Shopping Mode → don't interrupt
6. Cold start from notification → correct screen loads

---

## 5. Deep Links Verification

### Current State
- Notification-based deep links implemented via `NotificationNavigationHelper`
- Routes extracted from FCM `data['route']` field
- Navigation via GoRouter `.go()` method
- Pending route navigation supported (notification tap before router ready)
- Supported routes match GoRouter configuration

### Deep Link Routes

| Route | Screen | Trigger |
|-------|--------|---------|
| `/shopping-lists/:id` | Shopping list detail | Item added notification |
| `/invitations` | Invitations screen | Invitation notification |
| `/notifications` | Notification center | General notification |
| `/homes/:id/members` | Home members | Member joined notification |

### Pre-Release Actions
- [ ] Verify notification tap opens correct shopping list
- [ ] Verify invitation notification opens invitations screen
- [ ] Verify cold start from notification navigates correctly
- [ ] Verify pending route navigation works (notification before router ready)
- [ ] Verify invalid route in notification doesn't crash app
- [ ] Test deep link with app in background
- [ ] Test deep link with app killed
- [ ] Verify route validation (`route.startsWith('/')` check)

### Known Limitations
- No App Links / Universal Links configured (only notification-based deep links)
- No custom URL scheme configured
- Deep links only work from FCM notifications

---

## 6. Final Pre-Submission Checklist

### Build & Signing
- [ ] Release AAB builds successfully
- [ ] App signed with release keystore
- [ ] Version number correct in pubspec.yaml
- [ ] CHANGELOG.md updated

### Functionality
- [ ] Login/register works
- [ ] Home creation and invitation flow works
- [ ] Shopping list CRUD works
- [ ] Shopping Mode works correctly
- [ ] Realtime sync works between devices
- [ ] Offline queue activates and syncs
- [ ] Notifications arrive and navigate correctly
- [ ] Feedback button works

### Quality
- [ ] `flutter analyze` — 0 errors
- [ ] `flutter test` — all tests pass
- [ ] No crash on fresh install
- [ ] No crash on rapid navigation
- [ ] Arabic RTL displays correctly
- [ ] Dark mode works
- [ ] Performance acceptable on low-end device

### Store Listing
- [ ] App name and description (Arabic + English)
- [ ] Screenshots (4-8, Arabic RTL)
- [ ] Feature graphic (1024x500)
- [ ] App icon (512x512)
- [ ] Privacy policy URL
- [ ] Contact email
- [ ] Content rating completed
- [ ] Pricing set (Free)
- [ ] Countries/regions selected

### Post-Submission
- [ ] Internal testing track set up
- [ ] Crash monitoring active (Firebase Crashlytics)
- [ ] Feedback channel ready (WhatsApp/Telegram group)
- [ ] Hotfix process documented
- [ ] Rollback plan documented
