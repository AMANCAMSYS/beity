import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Account Switching Isolation', () {
    test('User A data never appears for User B', () async {
      final repository = FakeHomeRepository();

      // Setup User A
      repository.currentUserId = 'userA';
      await repository.addHome({'id': 'home1', 'name': 'User A Home'});

      var homesA = await repository.getHomes();
      expect(homesA.length, 1);
      expect(homesA.first['name'], 'User A Home');

      // Switch to User B
      repository.currentUserId = 'userB';

      // User B should not see User A's data
      var homesB = await repository.getHomes();
      expect(homesB.isEmpty, true);

      // Add data for User B
      await repository.addHome({'id': 'home2', 'name': 'User B Home'});
      homesB = await repository.getHomes();
      expect(homesB.length, 1);
      expect(homesB.first['name'], 'User B Home');

      // Switch back to User A
      repository.currentUserId = 'userA';
      homesA = await repository.getHomes();
      expect(homesA.length, 1);
      expect(homesA.first['name'], 'User A Home');
    });
  });
}

class FakeHomeRepository {
  String currentUserId = '';
  final List<Map<String, dynamic>> _allHomes = [];

  Future<void> addHome(Map<String, dynamic> home) async {
    final newHome = Map<String, dynamic>.from(home);
    newHome['user_id'] = currentUserId;
    _allHomes.add(newHome);
  }

  Future<List<Map<String, dynamic>>> getHomes() async {
    return _allHomes.where((h) => h['user_id'] == currentUserId).toList();
  }
}
