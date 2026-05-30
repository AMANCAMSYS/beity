import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:beity/core/services/shared_prefs_provider.dart';

/// Versioned onboarding storage.
///
/// Uses integer version keys so that bumping the version
/// automatically re-shows the onboarding/tour to all users.
class OnboardingStorage {
  static const String _welcomeSeenVersionKey = 'welcomeOnboardingSeenVersion';
  static const String _appTourSeenVersionKey = 'appTourSeenVersion';
  static const String _inventoryTourSeenVersionKey = 'inventoryTourSeenVersion';
  static const String _expensesTourSeenVersionKey = 'expensesTourSeenVersion';

  /// Bump these to force re-show after content changes.
  static const int currentWelcomeOnboardingVersion = 1;
  static const int currentAppTourVersion = 1;
  static const int currentInventoryTourVersion = 1;
  static const int currentExpensesTourVersion = 1;

  // ── Welcome Onboarding ─────────────────────────────────────────────

  /// Returns `true` when the user has NOT seen the current welcome version.
  static bool shouldShowWelcomeOnboarding() {
    final seen = AppPreferences.instance.getInt(_welcomeSeenVersionKey) ?? 0;
    return seen < currentWelcomeOnboardingVersion;
  }

  static Future<void> markWelcomeOnboardingSeen() async {
    await AppPreferences.instance.setInt(
      _welcomeSeenVersionKey,
      currentWelcomeOnboardingVersion,
    );
  }

  static Future<void> resetWelcomeOnboarding() async {
    await AppPreferences.instance.setInt(_welcomeSeenVersionKey, 0);
  }

  // ── App Tour ───────────────────────────────────────────────────────

  /// Returns `true` when the user has NOT seen the current tour version.
  static bool shouldShowAppTour() {
    final seen = AppPreferences.instance.getInt(_appTourSeenVersionKey) ?? 0;
    return seen < currentAppTourVersion;
  }

  static Future<void> markAppTourSeen() async {
    await AppPreferences.instance.setInt(
      _appTourSeenVersionKey,
      currentAppTourVersion,
    );
  }

  static Future<void> resetAppTour() async {
    await AppPreferences.instance.setInt(_appTourSeenVersionKey, 0);
  }

  // ── Inventory Tour ───────────────────────────────────────────────────

  static bool shouldShowInventoryTour() {
    final seen = AppPreferences.instance.getInt(_inventoryTourSeenVersionKey) ?? 0;
    return seen < currentInventoryTourVersion;
  }

  static Future<void> markInventoryTourSeen() async {
    await AppPreferences.instance.setInt(
      _inventoryTourSeenVersionKey,
      currentInventoryTourVersion,
    );
  }

  static Future<void> resetInventoryTour() async {
    await AppPreferences.instance.setInt(_inventoryTourSeenVersionKey, 0);
  }

  // ── Expenses Tour ────────────────────────────────────────────────────

  static bool shouldShowExpensesTour() {
    final seen = AppPreferences.instance.getInt(_expensesTourSeenVersionKey) ?? 0;
    return seen < currentExpensesTourVersion;
  }

  static Future<void> markExpensesTourSeen() async {
    await AppPreferences.instance.setInt(
      _expensesTourSeenVersionKey,
      currentExpensesTourVersion,
    );
  }

  static Future<void> resetExpensesTour() async {
    await AppPreferences.instance.setInt(_expensesTourSeenVersionKey, 0);
  }
}

/// Riverpod provider wrapper for [OnboardingStorage].
final onboardingStorageProvider = Provider<OnboardingStorage>((ref) {
  return OnboardingStorage();
});
