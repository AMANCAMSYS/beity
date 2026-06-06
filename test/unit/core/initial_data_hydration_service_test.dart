import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sawa/core/services/initial_data_hydration_service.dart';
import 'package:sawa/core/services/sync_coordinator.dart';
import 'package:sawa/core/services/shared_prefs_provider.dart';
import 'package:sawa/core/services/supabase_service.dart';
import 'package:sawa/features/homes/data/repositories/home_repository.dart';
import 'package:sawa/features/homes/data/repositories/home_local_data_source.dart';
import 'package:sawa/features/homes/data/models/home_model.dart';
import 'package:sawa/features/homes/presentation/providers/homes_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockHomeRepository extends Mock implements HomeRepository {}

class MockSyncCoordinator extends Notifier<SyncState>
    with Mock
    implements SyncCoordinator {
  @override
  SyncState build() => SyncState(status: SyncStatus.idle);
}

class MockHomeLocalDataSource extends Mock implements HomeLocalDataSource {}

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockUser extends Mock implements User {}

class FakeInitialDataHydrationService extends InitialDataHydrationService {
  @override
  HydrationState build() {
    return HydrationState.idle();
  }
}

void main() {
  late MockHomeRepository mockHomeRepository;
  late MockSyncCoordinator mockSyncCoordinator;
  late MockHomeLocalDataSource mockHomeLocalDataSource;
  late MockSupabaseClient mockSupabaseClient;
  late MockGoTrueClient mockGoTrueClient;
  late MockUser mockUser;
  late InitialDataHydrationService hydrationService;
  late ProviderContainer container;

  const userId = 'user-abc';

  final singleHome = HomeModel(
    id: 'home-1',
    name: 'Single Home',
    type: 'family',
    ownerId: userId,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  final firstHome = HomeModel(
    id: 'home-first',
    name: 'First Home',
    type: 'family',
    ownerId: userId,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  final secondHome = HomeModel(
    id: 'home-second',
    name: 'Second Home',
    type: 'couple',
    ownerId: userId,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  setUp(() async {
    mockHomeRepository = MockHomeRepository();
    mockSyncCoordinator = MockSyncCoordinator();
    mockHomeLocalDataSource = MockHomeLocalDataSource();
    mockSupabaseClient = MockSupabaseClient();
    mockGoTrueClient = MockGoTrueClient();
    mockUser = MockUser();

    SharedPreferences.setMockInitialValues({});
    await AppPreferences.init();

    // Stub Supabase static current user
    SupabaseService.client = mockSupabaseClient;
    when(() => mockSupabaseClient.auth).thenReturn(mockGoTrueClient);
    when(() => mockGoTrueClient.currentUser).thenReturn(mockUser);
    when(() => mockUser.id).thenReturn(userId);

    // Default mock behavior
    when(
      () => mockHomeLocalDataSource.isInitialSyncCompleted(userId),
    ).thenAnswer((_) async => false);
    when(
      () => mockHomeLocalDataSource.setInitialSyncCompleted(userId, any()),
    ).thenAnswer((_) async {});
    when(
      () => mockHomeLocalDataSource.setHomeInitialSyncCompleted(any(), any()),
    ).thenAnswer((_) async {});
    when(
      () => mockHomeLocalDataSource.isHomeInitialSyncCompleted(any()),
    ).thenAnswer((_) async => false);
    when(
      () => mockHomeLocalDataSource.getActiveHomeIdForUser(userId),
    ).thenAnswer((_) async => null);
    when(
      () => mockHomeLocalDataSource.setActiveHome(any(), any()),
    ).thenAnswer((_) async {});

    when(
      () => mockHomeRepository.syncHomesWithServer(),
    ).thenAnswer((_) async {});
    when(
      () => mockHomeRepository.getCachedUserHomes(),
    ).thenAnswer((_) async => []);

    when(
      () => mockSyncCoordinator.initialFullSync(any()),
    ).thenAnswer((_) async {});

    container = ProviderContainer(
      overrides: [
        homeRepositoryProvider.overrideWithValue(mockHomeRepository),
        syncCoordinatorProvider.overrideWith(() => mockSyncCoordinator),
        homeLocalDataSourceProvider.overrideWithValue(mockHomeLocalDataSource),
        initialDataHydrationServiceProvider.overrideWith(
          () => FakeInitialDataHydrationService(),
        ),
      ],
    );
    hydrationService = container.read(
      initialDataHydrationServiceProvider.notifier,
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('InitialDataHydrationService Tests', () {
    test(
      '1. First login with no activeHomeId selects the single home automatically',
      () async {
        // Setup: 1 home returned
        when(
          () => mockHomeRepository.getCachedUserHomes(),
        ).thenAnswer((_) async => [singleHome]);

        hydrationService = container.read(
          initialDataHydrationServiceProvider.notifier,
        );

        await hydrationService.hydrate();

        // Verify that it selected the single home and set active home
        verify(
          () => mockHomeLocalDataSource.setActiveHome('home-1', 'Single Home'),
        ).called(1);
        verify(() => mockSyncCoordinator.initialFullSync('home-1')).called(1);
        verify(
          () => mockHomeLocalDataSource.setInitialSyncCompleted(userId, true),
        ).called(1);
        verify(
          () => mockHomeLocalDataSource.setHomeInitialSyncCompleted(
            'home-1',
            true,
          ),
        ).called(1);
        expect(hydrationService.state.status, HydrationStatus.success);
        expect(hydrationService.state.activeHomeId, 'home-1');
      },
    );

    test('2. Multiple homes: selects the newest home as fallback', () async {
      // Setup: 2 homes returned
      when(
        () => mockHomeRepository.getCachedUserHomes(),
      ).thenAnswer((_) async => [firstHome, secondHome]);

      hydrationService = container.read(
        initialDataHydrationServiceProvider.notifier,
      );

      await hydrationService.hydrate();

      // Verify fallback choice: should be newest non-deleted home
      verify(
        () =>
            mockHomeLocalDataSource.setActiveHome('home-second', 'Second Home'),
      ).called(1);
      verify(
        () => mockSyncCoordinator.initialFullSync('home-second'),
      ).called(1);
      verify(
        () => mockHomeLocalDataSource.setInitialSyncCompleted(userId, true),
      ).called(1);
      verify(
        () => mockHomeLocalDataSource.setHomeInitialSyncCompleted(
          'home-second',
          true,
        ),
      ).called(1);
      expect(hydrationService.state.status, HydrationStatus.success);
      expect(hydrationService.state.activeHomeId, 'home-second');
    });

    test('3. Obsolete activeHomeId is replaced with a valid fallback', () async {
      // Setup: activeHomeId is obsolete ('old-deleted-home') and no longer in fetched list
      when(
        () => mockHomeLocalDataSource.getActiveHomeIdForUser(userId),
      ).thenAnswer((_) async => 'old-deleted-home');
      when(
        () => mockHomeRepository.getCachedUserHomes(),
      ).thenAnswer((_) async => [secondHome]);

      hydrationService = container.read(
        initialDataHydrationServiceProvider.notifier,
      );

      await hydrationService.hydrate();

      // Verify obsolete home replaced with secondHome
      verify(
        () =>
            mockHomeLocalDataSource.setActiveHome('home-second', 'Second Home'),
      ).called(1);
      verify(
        () => mockSyncCoordinator.initialFullSync('home-second'),
      ).called(1);
      expect(hydrationService.state.status, HydrationStatus.success);
      expect(hydrationService.state.activeHomeId, 'home-second');
    });

    test('4. Success flags are NOT saved when initial sync fails', () async {
      // Setup: single home but full sync throws exception
      when(
        () => mockHomeRepository.getCachedUserHomes(),
      ).thenAnswer((_) async => [singleHome]);
      when(
        () => mockSyncCoordinator.initialFullSync('home-1'),
      ).thenThrow(Exception('مزامنة البيانات فشلت'));

      hydrationService = container.read(
        initialDataHydrationServiceProvider.notifier,
      );

      await hydrationService.hydrate();

      // Verify sync completion flags were NOT written
      verifyNever(
        () => mockHomeLocalDataSource.setInitialSyncCompleted(userId, true),
      );
      verifyNever(
        () =>
            mockHomeLocalDataSource.setHomeInitialSyncCompleted('home-1', true),
      );

      expect(hydrationService.state.status, HydrationStatus.error);
      expect(hydrationService.state.error, contains('مزامنة البيانات فشلت'));
    });

    test(
      '5. Full initial sync runs only once and does not repeat after success',
      () async {
        // Setup: isInitialSyncCompleted is true
        when(
          () => mockHomeLocalDataSource.isInitialSyncCompleted(userId),
        ).thenAnswer((_) async => true);

        hydrationService = container.read(
          initialDataHydrationServiceProvider.notifier,
        );

        await hydrationService.hydrate();

        // It may refresh homes for membership safety, but it must not rerun the
        // expensive full home data sync after the initial success flag is set.
        verify(() => mockHomeRepository.syncHomesWithServer()).called(1);
        verifyNever(() => mockSyncCoordinator.initialFullSync(any()));
        expect(hydrationService.state.status, HydrationStatus.success);
      },
    );
  });
}
