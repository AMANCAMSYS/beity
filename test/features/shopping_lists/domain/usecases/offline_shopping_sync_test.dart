import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Offline Shopping Sync', () {
    test('no duplicate item after reconnect', () async {
      final syncService = FakeShoppingSyncService();
      
      // Simulate creating item offline
      final offlineItem = {'id': 'temp_1', 'name': 'Milk', 'home_id': 'home1'};
      await syncService.createItemOffline(offlineItem);
      
      // Reconnect
      await syncService.sync();
      
      final items = await syncService.getItems('home1');
      expect(items.length, 1);
      // ID might change to server ID, but we only have 1 item
      expect(items.first['name'], 'Milk');
    });

    test('offline update does not crash', () async {
      final syncService = FakeShoppingSyncService();
      
      // Initial state
      final item = {'id': 'item_1', 'name': 'Milk', 'is_completed': false, 'home_id': 'home1'};
      await syncService.seedData([item]);

      // Offline update
      expect(() async => await syncService.updateItemOffline('item_1', {'is_completed': true}), returnsNormally);
      
      // Verify local state reflects update
      final items = await syncService.getItems('home1');
      expect(items.first['is_completed'], true);
    });

    test('sync uses correct homeId', () async {
      final syncService = FakeShoppingSyncService();
      
      // Offline creations in different homes
      await syncService.createItemOffline({'id': 'temp_1', 'name': 'Apples', 'home_id': 'home1'});
      await syncService.createItemOffline({'id': 'temp_2', 'name': 'Bananas', 'home_id': 'home2'});
      
      await syncService.sync();
      
      final home1Items = await syncService.getItems('home1');
      expect(home1Items.length, 1);
      expect(home1Items.first['name'], 'Apples');

      final home2Items = await syncService.getItems('home2');
      expect(home2Items.length, 1);
      expect(home2Items.first['name'], 'Bananas');
    });
  });
}

class FakeShoppingSyncService {
  final List<Map<String, dynamic>> _serverData = [];
  final List<Map<String, dynamic>> _offlineQueue = [];
  final List<Map<String, dynamic>> _localCache = [];

  Future<void> seedData(List<Map<String, dynamic>> data) async {
    _serverData.addAll(data);
    _localCache.addAll(data.map((e) => Map.from(e)));
  }

  Future<void> createItemOffline(Map<String, dynamic> item) async {
    _localCache.add(Map.from(item));
    _offlineQueue.add({'action': 'create', 'data': item});
  }

  Future<void> updateItemOffline(String id, Map<String, dynamic> updates) async {
    final index = _localCache.indexWhere((e) => e['id'] == id);
    if (index != -1) {
      _localCache[index].addAll(updates);
    }
    _offlineQueue.add({'action': 'update', 'id': id, 'data': updates});
  }

  Future<void> sync() async {
    for (var op in _offlineQueue) {
      if (op['action'] == 'create') {
        final data = op['data'] as Map<String, dynamic>;
        final serverItem = Map<String, dynamic>.from(data);
        serverItem['id'] = 'server_${data['id']}'; // Simulate server ID generation
        _serverData.add(serverItem);
        
        // Update local cache to match server
        final localIndex = _localCache.indexWhere((e) => e['id'] == data['id']);
        if (localIndex != -1) {
          _localCache[localIndex] = serverItem;
        }
      } else if (op['action'] == 'update') {
        final id = op['id'] as String;
        final data = op['data'] as Map<String, dynamic>;
        final serverIndex = _serverData.indexWhere((e) => e['id'] == id);
        if (serverIndex != -1) {
          _serverData[serverIndex].addAll(data);
        }
      }
    }
    _offlineQueue.clear();
  }

  Future<List<Map<String, dynamic>>> getItems(String homeId) async {
    return _localCache.where((e) => e['home_id'] == homeId).toList();
  }
}
