import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('shopping transfer UI is gated by inventory feature flag', () {
    final shoppingModeScreen = File(
      'lib/features/shopping_mode/presentation/screens/shopping_mode_screen.dart',
    ).readAsStringSync();
    final shoppingListsScreen = File(
      'lib/features/shopping_lists/presentation/screens/shopping_lists_screen.dart',
    ).readAsStringSync();

    expect(shoppingModeScreen, contains('FeatureFlags.enableInventory'));
    expect(
      shoppingModeScreen,
      contains('FeatureFlags.enableInventory && purchasedCount > 0'),
    );
    expect(shoppingListsScreen, contains('FeatureFlags.enableInventory &&'));
    expect(shoppingListsScreen, contains('isCompleted &&'));
    expect(shoppingListsScreen, contains('list.canTransferToInventory'));
  });
}
