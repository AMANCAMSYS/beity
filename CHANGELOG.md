# Changelog

## [1.0.0+2] - MVP Polish Release
- **Added**: `flutter_native_splash` for polished Light and Dark mode splash screens, supporting Android 12+.
- **Updated**: Upgraded `flutter_launcher_icons` to `^0.14.4` and generated new icons.
- **Added**: Global Error Boundary (`SawaErrorWidget`) to gracefully catch UI exceptions instead of showing the red screen, with an option to return to the home screen.
- **Improved**: Replaced standard `Image.network` and `CircleAvatar` images with a custom `SawaCachedImage` widget to ensure caching, smooth loading placeholders, and error fallbacks.
