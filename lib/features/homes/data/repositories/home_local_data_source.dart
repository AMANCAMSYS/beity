import 'package:shared_preferences/shared_preferences.dart';

class HomeLocalDataSource {
  static const _activeHomeKey = 'active_home_id';
  static const _activeHomeNameKey = 'active_home_name';

  Future<void> setActiveHome(String homeId, String homeName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeHomeKey, homeId);
    await prefs.setString(_activeHomeNameKey, homeName);
  }

  Future<String?> getActiveHomeId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_activeHomeKey);
  }

  Future<String?> getActiveHomeName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_activeHomeNameKey);
  }

  Future<void> clearActiveHome() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_activeHomeKey);
    await prefs.remove(_activeHomeNameKey);
  }

  Future<bool> hasActiveHome() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_activeHomeKey);
  }
}
