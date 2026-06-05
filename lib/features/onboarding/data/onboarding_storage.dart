import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sawa/core/services/shared_prefs_provider.dart';

/// Versioned onboarding storage.
///
/// Uses integer version keys so that bumping the version
/// automatically re-shows the onboarding/tour to all users.
class OnboardingStorage {
  static const String _welcomeSeenVersionKey = 'welcomeOnboardingSeenVersion';
  static const String _appTourSeenVersionKey = 'appTourSeenVersion';
  static const String _inventoryTourSeenVersionKey = 'inventoryTourSeenVersion';
  static const String _expensesTourSeenVersionKey = 'expensesTourSeenVersion';
  static const String _tasksTourSeenVersionKey = 'tasksTourSeenVersion';
  static const String _categoriesTourSeenVersionKey = 'categoriesTourSeenVersion';
  static const String _unitsTourSeenVersionKey = 'unitsTourSeenVersion';

  /// Bump these to force re-show after content changes.
  static const int currentWelcomeOnboardingVersion = 1;
  static const int currentAppTourVersion = 1;
  static const int currentInventoryTourVersion = 1;
  static const int currentExpensesTourVersion = 1;
  static const int currentTasksTourVersion = 1;
  static const int currentCategoriesTourVersion = 1;
  static const int currentUnitsTourVersion = 1;

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

  // ── Tasks Tour ───────────────────────────────────────────────────────

  static bool shouldShowTasksTour() {
    final seen = AppPreferences.instance.getInt(_tasksTourSeenVersionKey) ?? 0;
    return seen < currentTasksTourVersion;
  }

  static Future<void> markTasksTourSeen() async {
    await AppPreferences.instance.setInt(
      _tasksTourSeenVersionKey,
      currentTasksTourVersion,
    );
  }

  static Future<void> resetTasksTour() async {
    await AppPreferences.instance.setInt(_tasksTourSeenVersionKey, 0);
  }

  // ── Categories Tour ───────────────────────────────────────────────────

  static bool shouldShowCategoriesTour() {
    final seen = AppPreferences.instance.getInt(_categoriesTourSeenVersionKey) ?? 0;
    return seen < currentCategoriesTourVersion;
  }

  static Future<void> markCategoriesTourSeen() async {
    await AppPreferences.instance.setInt(
      _categoriesTourSeenVersionKey,
      currentCategoriesTourVersion,
    );
  }

  static Future<void> resetCategoriesTour() async {
    await AppPreferences.instance.setInt(_categoriesTourSeenVersionKey, 0);
  }

  // ── Units Tour ───────────────────────────────────────────────────────

  static bool shouldShowUnitsTour() {
    final seen = AppPreferences.instance.getInt(_unitsTourSeenVersionKey) ?? 0;
    return seen < currentUnitsTourVersion;
  }

  static Future<void> markUnitsTourSeen() async {
    await AppPreferences.instance.setInt(
      _unitsTourSeenVersionKey,
      currentUnitsTourVersion,
    );
  }

  static Future<void> resetUnitsTour() async {
    await AppPreferences.instance.setInt(_unitsTourSeenVersionKey, 0);
  }
}

/// Riverpod provider wrapper for [OnboardingStorage].
final onboardingStorageProvider = Provider<OnboardingStorage>((ref) {
  return OnboardingStorage();
});
