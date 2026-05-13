import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeLocalDataSource {
  static const _activeHomeKey = 'active_home_id';
  static const _activeHomeNameKey = 'active_home_name';

  String _getUserId() {
    final user = Supabase.instance.client.auth.currentUser;
    return user?.id ?? 'anonymous';
  }

  String _userKey(String key) => '${_getUserId()}_$key';

  Future<void> setActiveHome(String homeId, String homeName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey(_activeHomeKey), homeId);
    await prefs.setString(_userKey(_activeHomeNameKey), homeName);
  }

  Future<String?> getActiveHomeId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userKey(_activeHomeKey));
  }

  Future<String?> getActiveHomeName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userKey(_activeHomeNameKey));
  }

  Future<void> clearActiveHome() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = _getUserId();
    await prefs.remove('${userId}_$_activeHomeKey');
    await prefs.remove('${userId}_$_activeHomeNameKey');
  }

  Future<void> clearAllUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().toList();
    final userId = _getUserId();
    for (final key in keys) {
      if (key.startsWith('${userId}_')) {
        await prefs.remove(key);
      }
    }
  }

  Future<bool> hasActiveHome() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_userKey(_activeHomeKey));
  }
}
