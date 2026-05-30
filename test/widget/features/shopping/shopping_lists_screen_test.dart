import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:beity/features/shopping_lists/data/models/shopping_list_model.dart';
import 'package:beity/features/shopping_lists/presentation/providers/shopping_lists_provider.dart';
import 'package:beity/features/shopping_lists/presentation/screens/shopping_lists_screen.dart';
import 'package:beity/core/localization/app_localizations.dart';

void main() {
  testWidgets('ShoppingListsScreen should render loading state initially', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          shoppingListsProvider('home-123').overrideWith((ref) => StreamController<List<ShoppingListModel>>().stream),
          activeShoppingListsProvider('home-123').overrideWith((ref) => []),
          archivedShoppingListsProvider('home-123').overrideWith((ref) => []),
          appLocalizationsProvider.overrideWithValue(AppLocalizations(const Locale('en', 'US'))),
        ],
        child: const MaterialApp(
          home: ShoppingListsScreen(homeId: 'home-123'),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('ShoppingListsScreen should render empty state when lists are empty', (tester) async {
    final localizations = AppLocalizations(const Locale('en', 'US'));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          shoppingListsProvider('home-123').overrideWith((ref) => Stream.value(<ShoppingListModel>[])),
          activeShoppingListsProvider('home-123').overrideWith((ref) => []),
          archivedShoppingListsProvider('home-123').overrideWith((ref) => []),
          appLocalizationsProvider.overrideWithValue(localizations),
        ],
        child: const MaterialApp(
          home: ShoppingListsScreen(homeId: 'home-123'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify empty state is rendered
    expect(find.text(localizations.translate('no_shopping_lists')), findsOneWidget);
  });
}
