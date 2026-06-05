import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sawa/core/services/shared_prefs_provider.dart';
import 'package:sawa/features/shopping_lists/domain/entities/shopping_item.dart';
import 'package:sawa/features/shopping_lists/presentation/widgets/shopping_item_tile_widget.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppPreferences.init();
  });

  testWidgets('swipe delete confirms and calls onDelete', (tester) async {
    var deleted = false;

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: ShoppingItemTileWidget(
              item: const ShoppingItem(
                id: 'item-1',
                shoppingListId: 'list-1',
                name: 'Milk',
                quantity: 1,
                createdBy: 'user-1',
              ),
              hapticsEnabled: false,
              soundsEnabled: false,
              onDelete: () => deleted = true,
            ),
          ),
        ),
      ),
    );

    await tester.drag(find.text('Milk'), const Offset(-500, 0));
    await tester.pumpAndSettle();

    await tester.tap(find.text('حذف').last);
    await tester.pumpAndSettle();

    expect(deleted, isTrue);
  });
}
