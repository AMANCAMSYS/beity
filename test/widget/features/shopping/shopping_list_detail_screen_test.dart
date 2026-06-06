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
import 'package:sawa/features/shopping_lists/presentation/screens/shopping_list_detail_screen.dart';
import 'package:sawa/features/categories/data/models/category_model.dart';
import 'package:sawa/features/categories/domain/entities/category.dart';
import 'package:sawa/features/categories/presentation/providers/categories_provider.dart';
import 'package:sawa/features/categories/presentation/providers/units_provider.dart';
import 'package:sawa/features/settings/presentation/providers/app_settings_provider.dart';
import 'package:sawa/features/settings/data/repositories/app_settings_repository.dart';
import 'package:sawa/features/offline_queue/presentation/providers/connectivity_provider.dart';
import 'package:sawa/features/offline_queue/presentation/providers/offline_queue_provider.dart';
import 'package:sawa/features/offline_queue/domain/entities/device_sync_status.dart';
import 'package:sawa/features/offline_queue/domain/entities/queue_entry.dart';
import 'package:sawa/core/localization/app_localizations.dart';
import 'package:sawa/core/services/realtime_service.dart';
import 'package:sawa/features/shopping_lists/presentation/providers/realtime_providers.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockRealtimeService extends Mock implements RealtimeService {
  @override
  bool get isDisposed => false;
}

class MockAppSettingsRepository extends Mock implements AppSettingsRepository {}

class FakePresencePayload extends Fake implements PresencePayload {}

void main() {
  const listId = 'list-123';
  const homeId = 'home-123';

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
    String name = 'Test Shopping List',
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
    double price = 5.0,
  }) {
    return ShoppingItemModel(
      id: id,
      shoppingListId: listId,
      name: name,
      isPurchased: isPurchased,
      categoryId: categoryId,
      quantity: quantity,
      price: price,
      createdBy: 'user-123',
      createdAt: DateTime.now(),
    );
  }

  group('ShoppingListDetailScreen', () {
    testWidgets('should display loading state when list is loading', (
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
            categoriesProvider(
              homeId,
            ).overrideWith((ref) => Future.value(<CategoryModel>[])),
            unitsProvider(null).overrideWith((ref) => Future.value([])),
            appSettingsRepositoryProvider.overrideWithValue(mockSettingsRepo),
            connectivityStatusProvider.overrideWith(
              (ref) => Stream.value(DeviceSyncStatus.online),
            ),
            queueEntriesProvider(
              homeId,
            ).overrideWith((ref) => Future.value(<QueueEntry>[])),
            realtimeServiceProvider.overrideWithValue(mockRealtime),
          ],
          child: const MaterialApp(
            home: ShoppingListDetailScreen(listId: listId, homeId: homeId),
          ),
        ),
      );

      expect(find.byType(SawaSkeletonList), findsOneWidget);
    });

    testWidgets('should display empty state when no items', (tester) async {
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
            categoriesProvider(
              homeId,
            ).overrideWith((ref) => Future.value(<CategoryModel>[])),
            unitsProvider(null).overrideWith((ref) => Future.value([])),
            appSettingsRepositoryProvider.overrideWithValue(mockSettingsRepo),
            connectivityStatusProvider.overrideWith(
              (ref) => Stream.value(DeviceSyncStatus.online),
            ),
            queueEntriesProvider(
              homeId,
            ).overrideWith((ref) => Future.value(<QueueEntry>[])),
            realtimeServiceProvider.overrideWithValue(mockRealtime),
            appLocalizationsProvider.overrideWithValue(localizations),
          ],
          child: const MaterialApp(
            home: ShoppingListDetailScreen(listId: listId, homeId: homeId),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text(localizations.translate('list_empty')), findsOneWidget);
    });

    testWidgets('should display shopping list items', (tester) async {
      final testList = createTestList();
      final testItems = [
        createTestItem(id: 'item-1', name: 'Milk'),
        createTestItem(id: 'item-2', name: 'Bread'),
        createTestItem(id: 'item-3', name: 'Eggs'),
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
            categoriesProvider(
              homeId,
            ).overrideWith((ref) => Future.value(<CategoryModel>[])),
            unitsProvider(null).overrideWith((ref) => Future.value([])),
            appSettingsRepositoryProvider.overrideWithValue(mockSettingsRepo),
            connectivityStatusProvider.overrideWith(
              (ref) => Stream.value(DeviceSyncStatus.online),
            ),
            queueEntriesProvider(
              homeId,
            ).overrideWith((ref) => Future.value(<QueueEntry>[])),
            realtimeServiceProvider.overrideWithValue(mockRealtime),
          ],
          child: const MaterialApp(
            home: ShoppingListDetailScreen(listId: listId, homeId: homeId),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Milk'), findsOneWidget);
      expect(find.text('Bread'), findsOneWidget);
      expect(find.text('Eggs'), findsOneWidget);
    });

    testWidgets('should display category grouping', (tester) async {
      final testList = createTestList();
      final categories = [
        const CategoryModel(
          id: 'cat-1',
          name: 'Dairy',
          type: CategoryType.shopping,
        ),
        const CategoryModel(
          id: 'cat-2',
          name: 'Bakery',
          type: CategoryType.shopping,
        ),
      ];
      final testItems = [
        createTestItem(id: 'item-1', name: 'Milk', categoryId: 'cat-1'),
        createTestItem(id: 'item-2', name: 'Cheese', categoryId: 'cat-1'),
        createTestItem(id: 'item-3', name: 'Bread', categoryId: 'cat-2'),
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
            categoriesProvider(
              homeId,
            ).overrideWith((ref) => Future.value(categories)),
            unitsProvider(null).overrideWith((ref) => Future.value([])),
            appSettingsRepositoryProvider.overrideWithValue(mockSettingsRepo),
            connectivityStatusProvider.overrideWith(
              (ref) => Stream.value(DeviceSyncStatus.online),
            ),
            queueEntriesProvider(
              homeId,
            ).overrideWith((ref) => Future.value(<QueueEntry>[])),
            realtimeServiceProvider.overrideWithValue(mockRealtime),
          ],
          child: const MaterialApp(
            home: ShoppingListDetailScreen(listId: listId, homeId: homeId),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Dairy'), findsAtLeast(1));
      expect(find.text('Bakery'), findsAtLeast(1));
      expect(find.text('Milk'), findsOneWidget);
      expect(find.text('Cheese'), findsOneWidget);
      expect(find.text('Bread'), findsOneWidget);
    });

    testWidgets('should display list name in app bar', (tester) async {
      final testList = createTestList(name: 'Weekly Groceries');

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
            categoriesProvider(
              homeId,
            ).overrideWith((ref) => Future.value(<CategoryModel>[])),
            unitsProvider(null).overrideWith((ref) => Future.value([])),
            appSettingsRepositoryProvider.overrideWithValue(mockSettingsRepo),
            connectivityStatusProvider.overrideWith(
              (ref) => Stream.value(DeviceSyncStatus.online),
            ),
            queueEntriesProvider(
              homeId,
            ).overrideWith((ref) => Future.value(<QueueEntry>[])),
            realtimeServiceProvider.overrideWithValue(mockRealtime),
          ],
          child: const MaterialApp(
            home: ShoppingListDetailScreen(listId: listId, homeId: homeId),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Weekly Groceries'), findsOneWidget);
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
            categoriesProvider(
              homeId,
            ).overrideWith((ref) => Future.value(<CategoryModel>[])),
            unitsProvider(null).overrideWith((ref) => Future.value([])),
            appSettingsRepositoryProvider.overrideWithValue(mockSettingsRepo),
            connectivityStatusProvider.overrideWith(
              (ref) => Stream.value(DeviceSyncStatus.online),
            ),
            queueEntriesProvider(
              homeId,
            ).overrideWith((ref) => Future.value(<QueueEntry>[])),
            realtimeServiceProvider.overrideWithValue(mockRealtime),
          ],
          child: const MaterialApp(
            home: ShoppingListDetailScreen(listId: listId, homeId: homeId),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.search_rounded), findsOneWidget);
    });

    testWidgets('should display more options button in app bar', (
      tester,
    ) async {
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
            categoriesProvider(
              homeId,
            ).overrideWith((ref) => Future.value(<CategoryModel>[])),
            unitsProvider(null).overrideWith((ref) => Future.value([])),
            appSettingsRepositoryProvider.overrideWithValue(mockSettingsRepo),
            connectivityStatusProvider.overrideWith(
              (ref) => Stream.value(DeviceSyncStatus.online),
            ),
            queueEntriesProvider(
              homeId,
            ).overrideWith((ref) => Future.value(<QueueEntry>[])),
            realtimeServiceProvider.overrideWithValue(mockRealtime),
          ],
          child: const MaterialApp(
            home: ShoppingListDetailScreen(listId: listId, homeId: homeId),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.more_horiz_rounded), findsOneWidget);
    });
  });
}
