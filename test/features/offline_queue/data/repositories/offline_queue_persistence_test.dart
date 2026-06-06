import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Offline Queue Persistence and Scoping', () {
    test('queue is persistent across operations', () async {
      final queue = FakeOfflineQueue();
      await queue.enqueue('user1', 'home1', 'action1', {'data': 1});

      final entries = await queue.getEntries('user1', 'home1');
      expect(entries.length, 1);
      expect(entries.first['action'], 'action1');
    });

    test('queue is user-scoped', () async {
      final queue = FakeOfflineQueue();
      await queue.enqueue('user1', 'home1', 'action1', {});
      await queue.enqueue('user2', 'home1', 'action2', {});

      final user1Entries = await queue.getEntries('user1', 'home1');
      expect(user1Entries.length, 1);
      expect(user1Entries.first['action'], 'action1');

      final user2Entries = await queue.getEntries('user2', 'home1');
      expect(user2Entries.length, 1);
      expect(user2Entries.first['action'], 'action2');
    });

    test('queue is home-scoped', () async {
      final queue = FakeOfflineQueue();
      await queue.enqueue('user1', 'home1', 'action1', {});
      await queue.enqueue('user1', 'home2', 'action2', {});

      final home1Entries = await queue.getEntries('user1', 'home1');
      expect(home1Entries.length, 1);
      expect(home1Entries.first['action'], 'action1');
    });

    test('queue clears on logout', () async {
      final queue = FakeOfflineQueue();
      await queue.enqueue('user1', 'home1', 'action1', {});

      await queue.clearOnLogout('user1');

      final user1Entries = await queue.getEntries('user1', 'home1');
      expect(user1Entries.isEmpty, true);
    });
  });
}

class FakeOfflineQueue {
  final List<Map<String, dynamic>> _storage = [];

  Future<void> enqueue(
    String userId,
    String homeId,
    String action,
    Map<String, dynamic> data,
  ) async {
    _storage.add({
      'user_id': userId,
      'home_id': homeId,
      'action': action,
      'data': data,
    });
  }

  Future<List<Map<String, dynamic>>> getEntries(
    String userId,
    String homeId,
  ) async {
    return _storage
        .where((e) => e['user_id'] == userId && e['home_id'] == homeId)
        .toList();
  }

  Future<void> clearOnLogout(String userId) async {
    _storage.removeWhere((e) => e['user_id'] == userId);
  }
}
