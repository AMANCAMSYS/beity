import 'package:flutter_test/flutter_test.dart';
import 'package:beity/features/home/data/models/home_dashboard_snapshot.dart';

void main() {
  group('HomeDashboardSnapshot Model', () {
    final testTime = DateTime(2026, 5, 30, 14, 0, 0);

    test('toJson produces correct structure', () {
      final snapshot = HomeDashboardSnapshot(
        homeId: 'home-123',
        homeName: 'My Sweet Home',
        activeListId: 'list-456',
        activeListName: 'Weekly Groceries',
        remainingShoppingItemsCount: 5,
        totalShoppingItemsCount: 8,
        totalActiveListsCount: 3,
        lastActivityText: 'أضاف أحمد: حليب',
        updatedAt: testTime,
      );

      final json = snapshot.toJson();

      expect(json['homeId'], 'home-123');
      expect(json['homeName'], 'My Sweet Home');
      expect(json['activeListId'], 'list-456');
      expect(json['activeListName'], 'Weekly Groceries');
      expect(json['remainingShoppingItemsCount'], 5);
      expect(json['totalShoppingItemsCount'], 8);
      expect(json['totalActiveListsCount'], 3);
      expect(json['lastActivityText'], 'أضاف أحمد: حليب');
      expect(json['updatedAt'], testTime.toIso8601String());
    });

    test('fromJson parses correct structure', () {
      final json = {
        'homeId': 'home-789',
        'homeName': 'Beity',
        'activeListId': 'list-999',
        'activeListName': 'Monthly Stock',
        'remainingShoppingItemsCount': 12,
        'totalShoppingItemsCount': 20,
        'totalActiveListsCount': 1,
        'lastActivityText': 'اشترى خالد: خبز',
        'updatedAt': testTime.toIso8601String(),
      };

      final snapshot = HomeDashboardSnapshot.fromJson(json);

      expect(snapshot.homeId, 'home-789');
      expect(snapshot.homeName, 'Beity');
      expect(snapshot.activeListId, 'list-999');
      expect(snapshot.activeListName, 'Monthly Stock');
      expect(snapshot.remainingShoppingItemsCount, 12);
      expect(snapshot.totalShoppingItemsCount, 20);
      expect(snapshot.totalActiveListsCount, 1);
      expect(snapshot.lastActivityText, 'اشترى خالد: خبز');
      expect(snapshot.updatedAt, testTime);
    });

    test('fromJson handles null values with defaults', () {
      final json = {
        'homeId': 'home-empty',
        'homeName': 'Empty Home',
        'activeListId': null,
        'activeListName': null,
        'remainingShoppingItemsCount': null,
        'totalShoppingItemsCount': null,
        'totalActiveListsCount': null,
        'lastActivityText': null,
        'updatedAt': testTime.toIso8601String(),
      };

      final snapshot = HomeDashboardSnapshot.fromJson(json);

      expect(snapshot.homeId, 'home-empty');
      expect(snapshot.homeName, 'Empty Home');
      expect(snapshot.activeListId, isNull);
      expect(snapshot.activeListName, isNull);
      expect(snapshot.remainingShoppingItemsCount, 0);
      expect(snapshot.totalShoppingItemsCount, 0);
      expect(snapshot.totalActiveListsCount, 0);
      expect(snapshot.lastActivityText, isNull);
      expect(snapshot.updatedAt, testTime);
    });
  });
}
