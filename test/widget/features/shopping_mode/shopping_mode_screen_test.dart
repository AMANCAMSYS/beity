import 'package:sawa/shared/widgets/design_system/sawa_skeleton_list.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sawa/core/services/supabase_service.dart';
import 'package:sawa/features/shopping_lists/data/models/shopping_item_model.dart';
import 'package:sawa/features/shopping_lists/data/models/shopping_list_model.dart';
import 'package:sawa/features/shopping_lists/domain/entities/shopping_list.dart';
import 'package:sawa/features/shopping_lists/presentation/providers/shopping_items_provider.dart';
import 'package:sawa/features/shopping_lists/presentation/providers/shopping_lists_provider.dart';
import 'package:sawa/features/shopping_mode/presentation/providers/shopping_mode_provider.dart';
import 'package:sawa/features/shopping_mode/presentation/providers/shopping_mode_items_provider.dart';
import 'package:sawa/features/shopping_mode/presentation/providers/shopping_mode_session_provider.dart';
import 'package:sawa/features/shopping_mode/presentation/screens/shopping_mode_screen.dart';
import 'package:sawa/features/categories/data/models/category_model.dart';
import 'package:sawa/features/categories/presentation/providers/categories_provider.dart';
import 'package:sawa/features/categories/presentation/providers/units_provider.dart';
import 'package:sawa/features/settings/presentation/providers/app_settings_provider.dart';
import 'package:sawa/features/settings/data/repositories/app_settings_repository.dart';
import 'package:sawa/features/shopping_mode/data/repositories/shopping_mode_repository.dart';
import 'package:sawa/features/shopping_mode/domain/usecases/start_shopping_session_usecase.dart';
import 'package:sawa/core/localization/app_localizations.dart';
import 'package:sawa/core/services/realtime_service.dart';
import 'package:sawa/features/shopping_lists/presentation/providers/realtime_providers.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockRealtimeService extends Mock implements RealtimeService {
  @override
  bool get isDisposed => false;
}

class MockShoppingModeRepository extends Mock
    implements ShoppingModeRepository {}

class MockAppSettingsRepository extends Mock implements AppSettingsRepository {}

class FakePresencePayload extends Fake implements PresencePayload {}

void main() {
  const listId = 'list-123';
  const homeId = 'home-123';
  const listName = 'Weekly Groceries';

  late MockSupabaseClient mockSupabaseClient;
  late MockGoTrueClient mockGoTrueClient;
  late MockRealtimeService mockRealtime;
  late MockAppSettingsRepository mockSettingsRepo;

  setUpAll(() {
    registerFallbackValue(FakePresencePayload());
  });

  setUp(() {
    mockSupabaseClient = MockSupabaseClient();
    mockGoTrueClient = MockGoTrueClient();
    mockRealtime = MockRealtimeService();
    mockSettingsRepo = MockAppSettingsRepository();

    when(() => mockSupabaseClient.auth).thenReturn(mockGoTrueClient);
    when(() => mockGoTrueClient.currentUser).thenReturn(null);
    SupabaseService.client = mockSupabaseClient;

    when(
      () => mockRealtime.watchPresence(
        channelName: any(named: 'channelName'),
        userPayload: any(named: 'userPayload'),
      ),
    ).thenAnswer((_) => const Stream.empty());

    when(
      () => mockSettingsRepo.getThemeMode(),
    ).thenAnswer((_) async => ThemeMode.system);
    when(
      () => mockSettingsRepo.getLocale(),
    ).thenAnswer((_) async => const Locale('en', 'US'));
    when(
      () => mockSettingsRepo.getFontSizeScale(),
    ).thenAnswer((_) async => 1.0);
    when(
      () => mockSettingsRepo.getHapticFeedback(),
    ).thenAnswer((_) async => true);
    when(
      () => mockSettingsRepo.getSoundEffects(),
    ).thenAnswer((_) async => true);
    when(
      () => mockSettingsRepo.getKeepScreenOn(),
    ).thenAnswer((_) async => false);
    when(
      () => mockSettingsRepo.getCompactListMode(),
    ).thenAnswer((_) async => false);
    when(
      () => mockSettingsRepo.getGroupedByCategory(),
    ).thenAnswer((_) async => true);
    when(
      () => mockSettingsRepo.getSyncOverWifiOnly(),
    ).thenAnswer((_) async => false);
    when(
      () => mockSettingsRepo.getPurchaseNotifications(),
    ).thenAnswer((_) async => true);
    when(() => mockSettingsRepo.getCountry()).thenAnswer((_) async => 'US');
    when(
      () => mockSettingsRepo.getDialect(),
    ).thenAnswer((_) async => 'standard');
  });

  ShoppingListModel createTestList({
    String id = listId,
    String name = listName,
    ShoppingListStatus status = ShoppingListStatus.active,
  }) {
    return ShoppingListModel(
      id: id,
      homeId: homeId,
      name: name,
      createdBy: 'user-123',
      status: status,
      createdAt: DateTime.now(),
    );
  }

  ShoppingItemModel createTestItem({
    String id = 'item-1',
    String name = 'Milk',
    bool isPurchased = false,
    String? categoryId,
    double quantity = 1,
  }) {
    return ShoppingItemModel(
      id: id,
      shoppingListId: listId,
      name: name,
      isPurchased: isPurchased,
      categoryId: categoryId,
      quantity: quantity,
      createdBy: 'user-123',
      createdAt: DateTime.now(),
    );
  }

  group('ShoppingModeScreen', () {
    testWidgets('should display loading state when items are loading', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            shoppingListByIdForHomeProvider((
              listId: listId,
              homeId: homeId,
            )).overrideWith((ref) => const Stream.empty()),
            shoppingItemsForHomeProvider((
              listId: listId,
              homeId: homeId,
            )).overrideWith((ref) => const Stream.empty()),
            shoppingModeItemsProvider((
              listId: listId,
              homeId: homeId,
            )).overrideWith((ref) => const AsyncLoading()),
            shoppingModeProvider.overrideWith(() => ShoppingModeNotifier()),
            shoppingModePurchasedCountForHomeProvider((
              listId: listId,
              homeId: homeId,
            )).overrideWith((ref) => 0),
            shoppingModeTotalCountForHomeProvider((
              listId: listId,
              homeId: homeId,
            )).overrideWith((ref) => 0),
            shoppingModeProgressForHomeProvider((
              listId: listId,
              homeId: homeId,
            )).overrideWith((ref) => 0.0),
            categoriesProvider(
              homeId,
            ).overrideWith((ref) => Future.value(<CategoryModel>[])),
            unitsProvider(null).overrideWith((ref) => Future.value([])),
            appSettingsRepositoryProvider.overrideWithValue(mockSettingsRepo),
            realtimeServiceProvider.overrideWithValue(mockRealtime),
            startShoppingSessionUseCaseProvider.overrideWith(
              (ref) =>
                  StartShoppingSessionUseCase(MockShoppingModeRepository()),
            ),
          ],
          child: const MaterialApp(
            home: ShoppingModeScreen(
              listId: listId,
              homeId: homeId,
              listName: listName,
            ),
          ),
        ),
      );

      expect(find.byType(SawaSkeletonList), findsOneWidget);
    });

    testWidgets('should display items in shopping mode', (tester) async {
      final testList = createTestList();
      final testItems = [
        createTestItem(id: 'item-1', name: 'Milk'),
        createTestItem(id: 'item-2', name: 'Bread'),
        createTestItem(id: 'item-3', name: 'Eggs'),
      ];
      final groups = [
        CategoryGroup(
          categoryId: 'cat-1',
          categoryName: 'Dairy',
          items: testItems,
          allPurchased: false,
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            shoppingListByIdForHomeProvider((
              listId: listId,
              homeId: homeId,
            )).overrideWith((ref) => Stream.value(testList)),
            shoppingItemsForHomeProvider((
              listId: listId,
              homeId: homeId,
            )).overrideWith((ref) => Stream.value(testItems)),
            shoppingModeItemsProvider((
              listId: listId,
              homeId: homeId,
            )).overrideWith((ref) => AsyncData(groups)),
            shoppingModeProvider.overrideWith(() => ShoppingModeNotifier()),
            shoppingModePurchasedCountForHomeProvider((
              listId: listId,
              homeId: homeId,
            )).overrideWith((ref) => 0),
            shoppingModeTotalCountForHomeProvider((
              listId: listId,
              homeId: homeId,
            )).overrideWith((ref) => 3),
            shoppingModeProgressForHomeProvider((
              listId: listId,
              homeId: homeId,
            )).overrideWith((ref) => 0.0),
            categoriesProvider(
              homeId,
            ).overrideWith((ref) => Future.value(<CategoryModel>[])),
            unitsProvider(null).overrideWith((ref) => Future.value([])),
            appSettingsRepositoryProvider.overrideWithValue(mockSettingsRepo),
            realtimeServiceProvider.overrideWithValue(mockRealtime),
            startShoppingSessionUseCaseProvider.overrideWith(
              (ref) =>
                  StartShoppingSessionUseCase(MockShoppingModeRepository()),
            ),
          ],
          child: const MaterialApp(
            home: ShoppingModeScreen(
              listId: listId,
              homeId: homeId,
              listName: listName,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Milk'), findsOneWidget);
      expect(find.text('Bread'), findsOneWidget);
      expect(find.text('Eggs'), findsOneWidget);
    });

    testWidgets('should display list name in app bar', (tester) async {
      final testList = createTestList();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            shoppingListByIdForHomeProvider((
              listId: listId,
              homeId: homeId,
            )).overrideWith((ref) => Stream.value(testList)),
            shoppingItemsForHomeProvider((
              listId: listId,
              homeId: homeId,
            )).overrideWith((ref) => Stream.value(<ShoppingItemModel>[])),
            shoppingModeItemsProvider((
              listId: listId,
              homeId: homeId,
            )).overrideWith((ref) => const AsyncData(<CategoryGroup>[])),
            shoppingModeProvider.overrideWith(() => ShoppingModeNotifier()),
            shoppingModePurchasedCountForHomeProvider((
              listId: listId,
              homeId: homeId,
            )).overrideWith((ref) => 0),
            shoppingModeTotalCountForHomeProvider((
              listId: listId,
              homeId: homeId,
            )).overrideWith((ref) => 0),
            shoppingModeProgressForHomeProvider((
              listId: listId,
              homeId: homeId,
            )).overrideWith((ref) => 0.0),
            categoriesProvider(
              homeId,
            ).overrideWith((ref) => Future.value(<CategoryModel>[])),
            unitsProvider(null).overrideWith((ref) => Future.value([])),
            appSettingsRepositoryProvider.overrideWithValue(mockSettingsRepo),
            realtimeServiceProvider.overrideWithValue(mockRealtime),
            startShoppingSessionUseCaseProvider.overrideWith(
              (ref) =>
                  StartShoppingSessionUseCase(MockShoppingModeRepository()),
            ),
          ],
          child: const MaterialApp(
            home: ShoppingModeScreen(
              listId: listId,
              homeId: homeId,
              listName: listName,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text(listName), findsOneWidget);
    });

    testWidgets('should display progress bar', (tester) async {
      final testList = createTestList();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            shoppingListByIdForHomeProvider((
              listId: listId,
              homeId: homeId,
            )).overrideWith((ref) => Stream.value(testList)),
            shoppingItemsForHomeProvider((
              listId: listId,
              homeId: homeId,
            )).overrideWith((ref) => Stream.value(<ShoppingItemModel>[])),
            shoppingModeItemsProvider((
              listId: listId,
              homeId: homeId,
            )).overrideWith((ref) => const AsyncData(<CategoryGroup>[])),
            shoppingModeProvider.overrideWith(() => ShoppingModeNotifier()),
            shoppingModePurchasedCountForHomeProvider((
              listId: listId,
              homeId: homeId,
            )).overrideWith((ref) => 2),
            shoppingModeTotalCountForHomeProvider((
              listId: listId,
              homeId: homeId,
            )).overrideWith((ref) => 5),
            shoppingModeProgressForHomeProvider((
              listId: listId,
              homeId: homeId,
            )).overrideWith((ref) => 0.4),
            categoriesProvider(
              homeId,
            ).overrideWith((ref) => Future.value(<CategoryModel>[])),
            unitsProvider(null).overrideWith((ref) => Future.value([])),
            appSettingsRepositoryProvider.overrideWithValue(mockSettingsRepo),
            realtimeServiceProvider.overrideWithValue(mockRealtime),
            startShoppingSessionUseCaseProvider.overrideWith(
              (ref) =>
                  StartShoppingSessionUseCase(MockShoppingModeRepository()),
            ),
          ],
          child: const MaterialApp(
            home: ShoppingModeScreen(
              listId: listId,
              homeId: homeId,
              listName: listName,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('should display floating action button', (tester) async {
      final testList = createTestList();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            shoppingListByIdForHomeProvider((
              listId: listId,
              homeId: homeId,
            )).overrideWith((ref) => Stream.value(testList)),
            shoppingItemsForHomeProvider((
              listId: listId,
              homeId: homeId,
            )).overrideWith((ref) => Stream.value(<ShoppingItemModel>[])),
            shoppingModeItemsProvider((
              listId: listId,
              homeId: homeId,
            )).overrideWith((ref) => const AsyncData(<CategoryGroup>[])),
            shoppingModeProvider.overrideWith(() => ShoppingModeNotifier()),
            shoppingModePurchasedCountForHomeProvider((
              listId: listId,
              homeId: homeId,
            )).overrideWith((ref) => 0),
            shoppingModeTotalCountForHomeProvider((
              listId: listId,
              homeId: homeId,
            )).overrideWith((ref) => 0),
            shoppingModeProgressForHomeProvider((
              listId: listId,
              homeId: homeId,
            )).overrideWith((ref) => 0.0),
            categoriesProvider(
              homeId,
            ).overrideWith((ref) => Future.value(<CategoryModel>[])),
            unitsProvider(null).overrideWith((ref) => Future.value([])),
            appSettingsRepositoryProvider.overrideWithValue(mockSettingsRepo),
            realtimeServiceProvider.overrideWithValue(mockRealtime),
            startShoppingSessionUseCaseProvider.overrideWith(
              (ref) =>
                  StartShoppingSessionUseCase(MockShoppingModeRepository()),
            ),
          ],
          child: const MaterialApp(
            home: ShoppingModeScreen(
              listId: listId,
              homeId: homeId,
              listName: listName,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('should display done shopping button', (tester) async {
      final testList = createTestList();
      final localizations = AppLocalizations(const Locale('en', 'US'));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            shoppingListByIdForHomeProvider((
              listId: listId,
              homeId: homeId,
            )).overrideWith((ref) => Stream.value(testList)),
            shoppingItemsForHomeProvider((
              listId: listId,
              homeId: homeId,
            )).overrideWith((ref) => Stream.value(<ShoppingItemModel>[])),
            shoppingModeItemsProvider((
              listId: listId,
              homeId: homeId,
            )).overrideWith((ref) => const AsyncData(<CategoryGroup>[])),
            shoppingModeProvider.overrideWith(() => ShoppingModeNotifier()),
            shoppingModePurchasedCountForHomeProvider((
              listId: listId,
              homeId: homeId,
            )).overrideWith((ref) => 0),
            shoppingModeTotalCountForHomeProvider((
              listId: listId,
              homeId: homeId,
            )).overrideWith((ref) => 0),
            shoppingModeProgressForHomeProvider((
              listId: listId,
              homeId: homeId,
            )).overrideWith((ref) => 0.0),
            categoriesProvider(
              homeId,
            ).overrideWith((ref) => Future.value(<CategoryModel>[])),
            unitsProvider(null).overrideWith((ref) => Future.value([])),
            appSettingsRepositoryProvider.overrideWithValue(mockSettingsRepo),
            realtimeServiceProvider.overrideWithValue(mockRealtime),
            startShoppingSessionUseCaseProvider.overrideWith(
              (ref) =>
                  StartShoppingSessionUseCase(MockShoppingModeRepository()),
            ),
            appLocalizationsProvider.overrideWithValue(localizations),
          ],
          child: const MaterialApp(
            home: ShoppingModeScreen(
              listId: listId,
              homeId: homeId,
              listName: listName,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.text(localizations.translate('done_shopping')),
        findsOneWidget,
      );
    });

    testWidgets('should display search button in app bar', (tester) async {
      final testList = createTestList();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            shoppingListByIdForHomeProvider((
              listId: listId,
              homeId: homeId,
            )).overrideWith((ref) => Stream.value(testList)),
            shoppingItemsForHomeProvider((
              listId: listId,
              homeId: homeId,
            )).overrideWith((ref) => Stream.value(<ShoppingItemModel>[])),
            shoppingModeItemsProvider((
              listId: listId,
              homeId: homeId,
            )).overrideWith((ref) => const AsyncData(<CategoryGroup>[])),
            shoppingModeProvider.overrideWith(() => ShoppingModeNotifier()),
            shoppingModePurchasedCountForHomeProvider((
              listId: listId,
              homeId: homeId,
            )).overrideWith((ref) => 0),
            shoppingModeTotalCountForHomeProvider((
              listId: listId,
              homeId: homeId,
            )).overrideWith((ref) => 0),
            shoppingModeProgressForHomeProvider((
              listId: listId,
              homeId: homeId,
            )).overrideWith((ref) => 0.0),
            categoriesProvider(
              homeId,
            ).overrideWith((ref) => Future.value(<CategoryModel>[])),
            unitsProvider(null).overrideWith((ref) => Future.value([])),
            appSettingsRepositoryProvider.overrideWithValue(mockSettingsRepo),
            realtimeServiceProvider.overrideWithValue(mockRealtime),
            startShoppingSessionUseCaseProvider.overrideWith(
              (ref) =>
                  StartShoppingSessionUseCase(MockShoppingModeRepository()),
            ),
          ],
          child: const MaterialApp(
            home: ShoppingModeScreen(
              listId: listId,
              homeId: homeId,
              listName: listName,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.search), findsOneWidget);
    });
  });
}
