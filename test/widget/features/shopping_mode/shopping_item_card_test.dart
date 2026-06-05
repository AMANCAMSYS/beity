import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sawa/core/localization/app_localizations.dart';
import 'package:sawa/features/shopping_lists/data/models/shopping_item_model.dart';
import 'package:sawa/features/shopping_mode/presentation/widgets/shopping_item_card.dart';

void main() {
  Widget buildCard({
    required ShoppingItemModel item,
    required VoidCallback onTap,
    VoidCallback? onQuantityTap,
    String? unitName,
  }) {
    return ProviderScope(
      overrides: [
        appLocalizationsProvider.overrideWithValue(
          AppLocalizations(const Locale('en', 'US')),
        ),
      ],
      child: MaterialApp(
        theme: ThemeData(splashFactory: NoSplash.splashFactory),
        home: Scaffold(
          body: ShoppingItemCard(
            item: item,
            unitName: unitName,
            hapticsEnabled: false,
            onTap: onTap,
            onQuantityTap: onQuantityTap,
          ),
        ),
      ),
    );
  }

  testWidgets('ShoppingItemCard renders partial purchase progress', (
    tester,
  ) async {
    var quantityTapCount = 0;
    var itemTapCount = 0;
    const item = ShoppingItemModel(
      id: 'item-1',
      shoppingListId: 'list-1',
      name: 'Rice',
      quantity: 4,
      purchasedQuantity: 2,
      createdBy: 'user-1',
    );

    await tester.pumpWidget(
      buildCard(
        item: item,
        unitName: 'kg',
        onTap: () => itemTapCount++,
        onQuantityTap: () => quantityTapCount++,
      ),
    );

    expect(find.text('Rice'), findsOneWidget);
    expect(find.text('2 / 4 kg'), findsOneWidget);

    final progress = tester.widget<CircularProgressIndicator>(
      find.byType(CircularProgressIndicator),
    );
    expect(progress.value, 0.5);

    await tester.tap(find.byType(IconButton));
    expect(quantityTapCount, 1);

    await tester.tap(find.text('Rice'));
    await tester.pump(const Duration(milliseconds: 600));
    expect(itemTapCount, 1);
  });

  testWidgets(
    'ShoppingItemCard clears optimistic state when item identity changes',
    (tester) async {
      var itemTapCount = 0;
      const rice = ShoppingItemModel(
        id: 'item-rice',
        shoppingListId: 'list-1',
        name: 'Rice',
        quantity: 1,
        createdBy: 'user-1',
      );
      const beans = ShoppingItemModel(
        id: 'item-beans',
        shoppingListId: 'list-1',
        name: 'Beans',
        quantity: 1,
        createdBy: 'user-1',
      );

      await tester.pumpWidget(
        buildCard(item: rice, onTap: () => itemTapCount++),
      );

      await tester.tap(find.text('Rice'));
      await tester.pump();
      expect(find.byIcon(Icons.check), findsOneWidget);

      await tester.pumpWidget(
        buildCard(item: beans, onTap: () => itemTapCount++),
      );

      expect(find.text('Beans'), findsOneWidget);
      expect(find.byIcon(Icons.check), findsNothing);

      await tester.pump(const Duration(milliseconds: 600));
      expect(itemTapCount, 0);
    },
  );
}
