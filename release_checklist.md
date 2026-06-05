# SAWA Release Checklist

## 1. App Icons & Splash Screens
- [ ] Run `dart run flutter_launcher_icons` to generate launcher icons for all platforms.
- [ ] Run `dart run flutter_native_splash:create` to generate native splash screens (Light/Dark mode + Android 12 support).
- [ ] Verify App Icon looks correct on iOS Simulator and Android Emulator.
- [ ] Verify Splash Screen transition is smooth and handles Dark Mode correctly.

## 2. Global Error Boundaries
- [ ] Artificially trigger an exception in the UI (e.g., inside a button `onPressed`) and verify that the `SawaErrorWidget` is displayed instead of the default Red Screen of Death.
- [ ] Verify the "Return to Home" button correctly navigates back, and respects the authentication state (via GoRouter).
- [ ] Verify the error is successfully logged to Firebase Crashlytics via `MonitoringService`.

## 3. UI/UX & Caching Polish
- [ ] Disconnect from the internet and verify that `SawaCachedImage` successfully shows placeholders/fallback error widgets without crashing or endless loading.
- [ ] Test the app on small screen devices (e.g., iPhone SE) to ensure there are no pixel overflow errors.
- [ ] Switch between Light and Dark mode globally, ensuring all texts and containers maintain contrast.
- [ ] Switch the device language to Arabic to ensure all RTL layouts, alignments, and padding behave as expected.

## 4. Final App Store Readiness
- [x] Increment the `version` and build number in `pubspec.yaml` (e.g., `1.0.0+2`).
- [x] Update `CHANGELOG.md` with recent polish notes.
- [ ] Execute a full release build for Android (`flutter build appbundle --release`).
- [ ] Execute a full release build for iOS (`flutter build ipa --release`).
