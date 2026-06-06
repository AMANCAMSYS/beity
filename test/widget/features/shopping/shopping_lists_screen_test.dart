import 'package:sawa/shared/widgets/design_system/sawa_skeleton_list.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sawa/features/shopping_lists/data/models/shopping_list_model.dart';
import 'package:sawa/features/shopping_lists/presentation/providers/shopping_lists_provider.dart';
import 'package:sawa/features/shopping_lists/presentation/screens/shopping_lists_screen.dart';
import 'package:sawa/core/localization/app_localizations.dart';
import 'package:sawa/core/providers/permissions_provider.dart';

void main() {
  testWidgets('ShoppingListsScreen should render loading state initially', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          shoppingListsProvider('home-123').overrideWith(
            (ref) => const Stream<List<ShoppingListModel>>.empty(),
          ),
          activeShoppingListsProvider(
            'home-123',
          ).overrideWith((ref) => const []),
          archivedShoppingListsProvider(
            'home-123',
          ).overrideWith((ref) => const []),
          currentHomePermissionsProvider('home-123').overrideWithValue(
            const HomePermissions(canView: true, canEdit: true),
          ),
          appLocalizationsProvider.overrideWithValue(
            AppLocalizations(const Locale('en', 'US')),
          ),
        ],
        child: const MaterialApp(home: ShoppingListsScreen(homeId: 'home-123')),
      ),
    );

    expect(find.byType(SawaSkeletonList), findsOneWidget);
  });

  testWidgets(
    'ShoppingListsScreen should render empty state when lists are empty',
    (tester) async {
      final localizations = AppLocalizations(const Locale('en', 'US'));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            shoppingListsProvider(
              'home-123',
            ).overrideWith((ref) => Stream.value(<ShoppingListModel>[])),
            activeShoppingListsProvider('home-123').overrideWith((ref) => []),
            archivedShoppingListsProvider('home-123').overrideWith((ref) => []),
            currentHomePermissionsProvider('home-123').overrideWithValue(
              const HomePermissions(canView: true, canEdit: true),
            ),
            appLocalizationsProvider.overrideWithValue(localizations),
          ],
          child: const MaterialApp(
            home: ShoppingListsScreen(homeId: 'home-123'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify empty state is rendered
      expect(
        find.text(localizations.translate('no_shopping_lists')),
        findsOneWidget,
      );
    },
  );
}
