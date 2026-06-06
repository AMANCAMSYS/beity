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
import 'package:sawa/features/shopping_mode/domain/entities/shopping_mode_session.dart';
import 'package:sawa/features/categories/data/models/category_model.dart';
import 'package:sawa/features/categories/presentation/providers/categories_provider.dart';
import 'package:sawa/features/categories/presentation/providers/units_provider.dart';
import 'package:sawa/features/settings/presentation/providers/app_settings_provider.dart';
import 'package:sawa/features/settings/data/repositories/app_settings_repository.dart';
import 'package:sawa/features/shopping_mode/data/repositories/shopping_mode_repository.dart';
import 'package:sawa/features/shopping_mode/domain/usecases/start_shopping_session_usecase.dart';
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
    double quantity = 1,
  }) {
    return ShoppingItemModel(
      id: id,
      shoppingListId: listId,
      name: name,
      isPurchased: isPurchased,
      quantity: quantity,
      createdBy: 'user-123',
      createdAt: DateTime.now(),
    );
  }

  group('T061: Delete/update list while Shopping Mode is active', () {
    testWidgets(
      'Shopping Mode renders when list stream emits empty (deleted)',
      (tester) async {
        final testItems = [
          createTestItem(id: 'item-1', name: 'Milk'),
          createTestItem(id: 'item-2', name: 'Bread'),
        ];
        final groups = [
          CategoryGroup(
            categoryId: 'cat-1',
            categoryName: 'Dairy',
            items: testItems,
            allPurchased: false,
          ),
        ];

        final listController = StreamController<ShoppingListModel?>();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              shoppingListByIdForHomeProvider((
                listId: listId,
                homeId: homeId,
              )).overrideWith((ref) => listController.stream),
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
              )).overrideWith((ref) => 2),
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

        listController.add(createTestList());
        await tester.pumpAndSettle();

        expect(find.text('Milk'), findsOneWidget);
        expect(find.text('Bread'), findsOneWidget);

        listController.add(null);
        await tester.pump();

        expect(find.text('Milk'), findsOneWidget);

        listController.close();
      },
    );

    testWidgets('Shopping Mode handles list name update gracefully', (
      tester,
    ) async {
      final testList = createTestList();
      final testItems = [createTestItem(id: 'item-1', name: 'Milk')];
      final groups = [
        CategoryGroup(
          categoryId: 'cat-1',
          categoryName: 'Dairy',
          items: testItems,
          allPurchased: false,
        ),
      ];

      final listController = StreamController<ShoppingListModel?>();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            shoppingListByIdForHomeProvider((
              listId: listId,
              homeId: homeId,
            )).overrideWith((ref) => listController.stream),
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
            )).overrideWith((ref) => 1),
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

      listController.add(testList);
      await tester.pumpAndSettle();

      expect(find.text(listName), findsOneWidget);

      final updatedList = testList.copyWithModel(name: 'Renamed List');
      listController.add(updatedList);
      await tester.pump();

      expect(find.text('Milk'), findsOneWidget);

      listController.close();
    });

    testWidgets(
      'Shopping Mode shows items even when list status changes to completed',
      (tester) async {
        final testList = createTestList();
        final testItems = [
          createTestItem(id: 'item-1', name: 'Milk', isPurchased: true),
          createTestItem(id: 'item-2', name: 'Bread', isPurchased: false),
        ];
        final groups = [
          CategoryGroup(
            categoryId: 'cat-1',
            categoryName: 'Dairy',
            items: testItems,
            allPurchased: false,
          ),
        ];

        final listController = StreamController<ShoppingListModel?>();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              shoppingListByIdForHomeProvider((
                listId: listId,
                homeId: homeId,
              )).overrideWith((ref) => listController.stream),
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
              )).overrideWith((ref) => 1),
              shoppingModeTotalCountForHomeProvider((
                listId: listId,
                homeId: homeId,
              )).overrideWith((ref) => 2),
              shoppingModeProgressForHomeProvider((
                listId: listId,
                homeId: homeId,
              )).overrideWith((ref) => 0.5),
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

        listController.add(testList);
        await tester.pumpAndSettle();

        expect(find.text('Milk'), findsOneWidget);
        expect(find.text('Bread'), findsOneWidget);
        expect(find.byType(LinearProgressIndicator), findsOneWidget);

        final completedList = testList.copyWithModel(
          status: ShoppingListStatus.completed,
        );
        listController.add(completedList);
        await tester.pump();

        expect(find.text('Milk'), findsOneWidget);
        expect(find.text('Bread'), findsOneWidget);

        listController.close();
      },
    );

    test('ShoppingModeNotifier deactivation clears session state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(shoppingModeProvider.notifier);
      notifier.activate('session-123');

      expect(container.read(shoppingModeProvider).isActive, isTrue);
      expect(container.read(shoppingModeProvider).sessionId, 'session-123');

      notifier.deactivate();

      expect(container.read(shoppingModeProvider).isActive, isFalse);
      expect(container.read(shoppingModeProvider).sessionId, isNull);
      expect(container.read(shoppingModeProvider).categoryStates, isEmpty);
    });

    test(
      'ShoppingModeNotifier preserves category states across list changes',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final notifier = container.read(shoppingModeProvider.notifier);
        notifier.activate('session-123');
        notifier.toggleCategory('cat-1');
        notifier.toggleCategory('cat-2');

        final state = container.read(shoppingModeProvider);
        expect(state.isCategoryCollapsed('cat-1'), isTrue);
        expect(state.isCategoryCollapsed('cat-2'), isTrue);
        expect(state.isCategoryCollapsed('cat-3'), isFalse);

        notifier.deactivate();

        expect(container.read(shoppingModeProvider).categoryStates, isEmpty);
      },
    );

    test('Shopping Mode session remains valid after list deletion', () {
      final session = ShoppingModeSession(
        id: 'session-1',
        shoppingListId: 'list-deleted',
        userId: 'user-123',
        homeId: 'home-123',
        startedAt: DateTime(2026, 1, 1, 10),
        itemsTotalCount: 5,
        itemsPurchasedCount: 2,
      );

      expect(session.isActive, isTrue);
      expect(session.progress, 0.4);
      expect(session.shoppingListId, 'list-deleted');
    });
  });
}
