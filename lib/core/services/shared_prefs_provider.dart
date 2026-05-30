import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Static and Riverpod container for pre-initialized SharedPreferences.
/// Avoids repeated calls to [SharedPreferences.getInstance()] which performs heavy Disk I/O.
class AppPreferences {
  static SharedPreferences? _instance;
  static SharedPreferences get instance => _instance!;

  /// Initializes the SharedPreferences instance. Must be called in main.dart before [runApp].
  static Future<void> init() async {
    _instance = await SharedPreferences.getInstance();
  }
}

/// Riverpod provider for SharedPreferences, allowing dependency injection
/// and clean overrides in tests.
final sharedPrefsProvider = Provider<SharedPreferences>((ref) {
  return AppPreferences.instance;
});
