import 'dart:async';
import 'dart:ffi';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sawa/core/local_database/app_database.dart';
import 'package:sawa/core/local_database/daos/homes_dao.dart';
import 'package:sawa/features/homes/data/repositories/home_repository.dart';
import 'package:sawa/features/homes/data/repositories/home_local_data_source.dart';
import 'package:sawa/features/homes/data/models/home_model.dart';
import 'package:sawa/core/services/shared_prefs_provider.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockUser extends Mock implements User {}

class MockSupabaseQueryBuilder extends Mock implements SupabaseQueryBuilder {}

class MockPostgrestFilterBuilder extends Mock
    implements PostgrestFilterBuilder<List<Map<String, dynamic>>> {}

class FakePostgrestFilterBuilder<T> extends Fake
    implements PostgrestFilterBuilder<T> {
  final T value;
  FakePostgrestFilterBuilder(this.value);

  @override
  Future<R> then<R>(FutureOr<R> Function(T) onValue, {Function? onError}) {
    return Future.value(onValue(value));
  }
}

void main() {
  final sqliteSkip = _sqliteSkipReason();
  late MockSupabaseClient mockSupabase;
  late MockGoTrueClient mockAuth;
  late MockUser mockUser;
  late MockSupabaseQueryBuilder mockQueryBuilder;
  late MockPostgrestFilterBuilder mockFilterBuilder;
  late AppDatabase db;
  late HomeLocalDataSource localDS;
  late HomeRepositoryImpl repository;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://placeholder.supabase.co',
      publishableKey: 'placeholderAnonKey',
    );
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppPreferences.init(); // Re-initialize preferences with clean mock values

    mockSupabase = MockSupabaseClient();
    mockAuth = MockGoTrueClient();
    mockUser = MockUser();
    mockQueryBuilder = MockSupabaseQueryBuilder();
    mockFilterBuilder = MockPostgrestFilterBuilder();
    db = AppDatabase(NativeDatabase.memory());
    localDS = HomeLocalDataSource(mockSupabase, HomesDao(db));

    when(() => mockUser.id).thenReturn('user-123');
    when(() => mockAuth.currentUser).thenReturn(mockUser);
    when(() => mockSupabase.auth).thenAnswer((_) => mockAuth);

    repository = HomeRepositoryImpl(mockSupabase, localDataSource: localDS);
  });

  tearDown(() async {
    await db.close();
  });

  group('Homes & Members Local-First Architecture', () {
    final tHome = HomeModel(
      id: 'home-123',
      name: 'SAWA Sweet Home',
      type: 'family',
      defaultCurrency: 'USD',
      ownerId: 'user-123',
      createdAt: DateTime.parse('2026-05-30T00:00:00Z'),
    );

    test(
      'watchLocalUserHomes and getCachedUserHomes should be strictly network-free',
      () async {
        // 1. Arrange: Setup local cache directly in Drift.
        await localDS.saveUserHomes('user-123', [tHome]);

        // 2. Act: Read cached homes and listen to watchLocalUserHomes stream
        final cachedHomes = await repository.getCachedUserHomes();
        final streamResult = await repository.watchLocalUserHomes().first;

        // 3. Assert:
        expect(cachedHomes.first.id, tHome.id);
        expect(streamResult.first.id, tHome.id);

        // Confirm that mockSupabase was NEVER called for database operations
        verifyNever(() => mockSupabase.from(any()));
      },
    );

    test(
      'hasHomes should not show onboarding screen before initial sync completed',
      () async {
        // Case A: Initial sync not completed yet, cache is empty
        await localDS.setInitialSyncCompleted('user-123', false);

        final hasHomesA = await repository.hasHomes();
        // Should return true to prevent showing onboarding creation immediately (forces Preparing/Loading State)
        expect(hasHomesA, isTrue);

        // Case B: Initial sync completed, and cache is empty
        await localDS.setInitialSyncCompleted('user-123', true);

        final hasHomesB = await repository.hasHomes();
        // Should correctly return false to safely redirect to onboarding creation
        expect(hasHomesB, isFalse);

        // Case C: Initial sync completed, and cache has homes
        await localDS.saveUserHomes('user-123', [tHome]);

        final hasHomesC = await repository.hasHomes();
        expect(hasHomesC, isTrue);
      },
    );

    test(
      'activeHomeId should be read and watched locally immediately',
      () async {
        // Arrange: Set active home ID
        await localDS.setActiveHome('home-123', 'SAWA Sweet Home');

        // Act: Get active home ID
        final cachedActiveId = await repository.getCachedActiveHomeId(
          'user-123',
        );
        final streamedActiveId = await repository
            .watchActiveHomeId('user-123')
            .first;

        // Assert:
        expect(cachedActiveId, 'home-123');
        expect(streamedActiveId, 'home-123');
        verifyNever(() => mockSupabase.from(any()));
      },
    );

    test(
      'membership revocation should delete all data associated with that home',
      () async {
        // Arrange: setup initial homes cache
        await localDS.saveUserHomes('user-123', [tHome]);
        await localDS.setActiveHome('home-123', 'SAWA Sweet Home');
        await _insertShoppingGraph(db, homeId: 'home-123');

        // Setup Supabase mock response for syncHomesWithServer yielding empty homes (meaning user was removed)
        when(
          () => mockSupabase.from(any()),
        ).thenAnswer((_) => mockQueryBuilder);
        when(
          () => mockQueryBuilder.select(any()),
        ).thenAnswer((_) => mockFilterBuilder);
        when(
          () => mockFilterBuilder.eq(any(), any()),
        ).thenAnswer((_) => mockFilterBuilder);

        final fakeTransform =
            FakePostgrestFilterBuilder<List<Map<String, dynamic>>>([]);
        when(
          () => mockFilterBuilder.isFilter(any(), any()),
        ).thenAnswer((_) => fakeTransform);
        when(
          () => mockFilterBuilder.limit(any()),
        ).thenAnswer((_) => fakeTransform);

        // Act: Trigger syncHomesWithServer
        await repository.syncHomesWithServer();

        // Assert:
        final homes = await repository.getCachedUserHomes();
        final activeHome = await localDS.getActiveHomeIdForUser('user-123');
        final localLists = await (db.select(
          db.localShoppingLists,
        )..where((tbl) => tbl.homeId.equals('home-123'))).get();
        final localItems = await (db.select(
          db.localShoppingItems,
        )..where((tbl) => tbl.homeId.equals('home-123'))).get();

        expect(homes, isEmpty);
        expect(activeHome, isNull); // Reset active home since user was removed!
        expect(localLists, isEmpty);
        expect(localItems, isEmpty);
      },
    );

    test('logout should purge all user cached data completely', () async {
      // Arrange: setup user-owned cache keys
      await localDS.saveUserHomes('user-123', [tHome]);
      await localDS.setActiveHome('home-123', 'SAWA Sweet Home');
      await localDS.setInitialSyncCompleted('user-123', true);

      final prefs = AppPreferences.instance;
      await prefs.setString('user-123_custom_key', 'cached_data');

      // Act: Trigger comprehensive purge
      await localDS.clearAllUserDataForUser('user-123');

      // Assert:
      final homes = await localDS.getUserHomes('user-123');
      final activeHomeId = await localDS.getActiveHomeIdForUser('user-123');
      final syncCompleted = await localDS.isInitialSyncCompleted('user-123');

      expect(homes, isEmpty);
      expect(activeHomeId, isNull);
      expect(syncCompleted, isFalse);
      expect(prefs.getString('user-123_custom_key'), isNull);
    });
  }, skip: sqliteSkip ?? false);
}

Future<void> _insertShoppingGraph(
  AppDatabase db, {
  required String homeId,
}) async {
  await db
      .into(db.localShoppingLists)
      .insert(
        LocalShoppingListsCompanion.insert(
          id: 'list-$homeId',
          homeId: homeId,
          title: 'Local List',
          createdBy: 'user-123',
        ),
      );
  await db
      .into(db.localShoppingItems)
      .insert(
        LocalShoppingItemsCompanion.insert(
          id: 'item-$homeId',
          listId: 'list-$homeId',
          homeId: homeId,
          name: 'Milk',
          createdBy: 'user-123',
        ),
      );
}

String? _sqliteSkipReason() {
  if (!Platform.isLinux) return null;
  try {
    DynamicLibrary.open('libsqlite3.so');
    return null;
  } catch (_) {
    return 'libsqlite3.so is not available in this test environment';
  }
}
