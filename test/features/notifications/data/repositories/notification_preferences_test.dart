import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Notification Preferences', () {
    test('missing row returns defaults', () async {
      final repo = FakeNotificationPreferencesRepository();
      
      final prefs = await repo.getPreferences('user1', 'home1');
      expect(prefs['push_enabled'], true);
      expect(prefs['email_enabled'], false);
      expect(prefs['new_item_alerts'], true);
    });

    test('null fields are safely handled and fall back to default', () async {
      final repo = FakeNotificationPreferencesRepository();
      
      await repo.setRawData('user1', 'home1', {
        'push_enabled': null,
        'email_enabled': true,
      });

      final prefs = await repo.getPreferences('user1', 'home1');
      expect(prefs['push_enabled'], true); // fallback
      expect(prefs['email_enabled'], true);
      expect(prefs['new_item_alerts'], true); // fallback for missing
    });

    test('no active home is handled safely', () async {
      final repo = FakeNotificationPreferencesRepository();
      
      expect(() async => await repo.getPreferences('user1', null), returnsNormally);
      final prefs = await repo.getPreferences('user1', null);
      
      expect(prefs['push_enabled'], true);
    });
  });
}

class FakeNotificationPreferencesRepository {
  final Map<String, Map<String, dynamic>> _db = {};

  String _key(String userId, String? homeId) => '${userId}_${homeId ?? 'global'}';

  Future<void> setRawData(String userId, String? homeId, Map<String, dynamic> data) async {
    _db[_key(userId, homeId)] = data;
  }

  Future<Map<String, dynamic>> getPreferences(String userId, String? homeId) async {
    final rawData = _db[_key(userId, homeId)];
    
    // Default preferences
    final defaults = {
      'push_enabled': true,
      'email_enabled': false,
      'new_item_alerts': true,
    };

    if (rawData == null) {
      return defaults;
    }

    // Safely parse nulls
    return {
      'push_enabled': rawData['push_enabled'] ?? defaults['push_enabled'],
      'email_enabled': rawData['email_enabled'] ?? defaults['email_enabled'],
      'new_item_alerts': rawData['new_item_alerts'] ?? defaults['new_item_alerts'],
    };
  }
}
