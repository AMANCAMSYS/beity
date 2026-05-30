import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:beity/core/services/initial_data_hydration_service.dart';
import 'package:beity/core/services/sync_coordinator.dart';
import 'package:beity/core/services/shared_prefs_provider.dart';
import 'package:beity/core/services/supabase_service.dart';
import 'package:beity/features/homes/data/repositories/home_repository.dart';
import 'package:beity/features/homes/data/repositories/home_local_data_source.dart';
import 'package:beity/features/homes/data/models/home_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockHomeRepository extends Mock implements HomeRepository {}
class MockSyncCoordinator extends Mock implements SyncCoordinator {}
class MockHomeLocalDataSource extends Mock implements HomeLocalDataSource {}
class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockGoTrueClient extends Mock implements GoTrueClient {}
class MockUser extends Mock implements User {}

void main() {
  late MockHomeRepository mockHomeRepository;
  late MockSyncCoordinator mockSyncCoordinator;
  late MockHomeLocalDataSource mockHomeLocalDataSource;
  late MockSupabaseClient mockSupabaseClient;
  late MockGoTrueClient mockGoTrueClient;
  late MockUser mockUser;
  late InitialDataHydrationService hydrationService;

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
    when(() => mockHomeLocalDataSource.isInitialSyncCompleted(userId)).thenAnswer((_) async => false);
    when(() => mockHomeLocalDataSource.setInitialSyncCompleted(userId, any())).thenAnswer((_) async {});
    when(() => mockHomeLocalDataSource.setHomeInitialSyncCompleted(any(), any())).thenAnswer((_) async {});
    when(() => mockHomeLocalDataSource.isHomeInitialSyncCompleted(any())).thenAnswer((_) async => false);
    when(() => mockHomeLocalDataSource.getActiveHomeIdForUser(userId)).thenAnswer((_) async => null);
    when(() => mockHomeLocalDataSource.setActiveHome(any(), any())).thenAnswer((_) async {});

    when(() => mockHomeRepository.syncHomesWithServer()).thenAnswer((_) async {});
    when(() => mockHomeRepository.getCachedUserHomes()).thenAnswer((_) async => []);

    when(() => mockSyncCoordinator.initialFullSync(any())).thenAnswer((_) async {});
  });

  group('InitialDataHydrationService Tests', () {
    test('1. First login with no activeHomeId selects the single home automatically', () async {
      // Setup: 1 home returned
      when(() => mockHomeRepository.getCachedUserHomes()).thenAnswer((_) async => [singleHome]);

      hydrationService = InitialDataHydrationService(
        homeRepository: mockHomeRepository,
        syncCoordinator: mockSyncCoordinator,
        localDataSource: mockHomeLocalDataSource,
        autoHydrate: false,
      );

      await hydrationService.hydrate();

      // Verify that it selected the single home and set active home
      verify(() => mockHomeLocalDataSource.setActiveHome('home-1', 'Single Home')).called(1);
      verify(() => mockSyncCoordinator.initialFullSync('home-1')).called(1);
      verify(() => mockHomeLocalDataSource.setInitialSyncCompleted(userId, true)).called(1);
      verify(() => mockHomeLocalDataSource.setHomeInitialSyncCompleted('home-1', true)).called(1);
      expect(hydrationService.state.status, HydrationStatus.success);
      expect(hydrationService.state.activeHomeId, 'home-1');
    });

    test('2. Multiple homes: selects the first/newest home as fallback', () async {
      // Setup: 2 homes returned
      when(() => mockHomeRepository.getCachedUserHomes()).thenAnswer((_) async => [firstHome, secondHome]);

      hydrationService = InitialDataHydrationService(
        homeRepository: mockHomeRepository,
        syncCoordinator: mockSyncCoordinator,
        localDataSource: mockHomeLocalDataSource,
        autoHydrate: false,
      );

      await hydrationService.hydrate();

      // Verify fallback choice: should be first home
      verify(() => mockHomeLocalDataSource.setActiveHome('home-first', 'First Home')).called(1);
      verify(() => mockSyncCoordinator.initialFullSync('home-first')).called(1);
      verify(() => mockHomeLocalDataSource.setInitialSyncCompleted(userId, true)).called(1);
      verify(() => mockHomeLocalDataSource.setHomeInitialSyncCompleted('home-first', true)).called(1);
      expect(hydrationService.state.status, HydrationStatus.success);
      expect(hydrationService.state.activeHomeId, 'home-first');
    });

    test('3. Obsolete activeHomeId is replaced with a valid fallback', () async {
      // Setup: activeHomeId is obsolete ('old-deleted-home') and no longer in fetched list
      when(() => mockHomeLocalDataSource.getActiveHomeIdForUser(userId)).thenAnswer((_) async => 'old-deleted-home');
      when(() => mockHomeRepository.getCachedUserHomes()).thenAnswer((_) async => [secondHome]);

      hydrationService = InitialDataHydrationService(
        homeRepository: mockHomeRepository,
        syncCoordinator: mockSyncCoordinator,
        localDataSource: mockHomeLocalDataSource,
        autoHydrate: false,
      );

      await hydrationService.hydrate();

      // Verify obsolete home replaced with secondHome
      verify(() => mockHomeLocalDataSource.setActiveHome('home-second', 'Second Home')).called(1);
      verify(() => mockSyncCoordinator.initialFullSync('home-second')).called(1);
      expect(hydrationService.state.status, HydrationStatus.success);
      expect(hydrationService.state.activeHomeId, 'home-second');
    });

    test('4. Success flags are NOT saved when initial sync fails', () async {
      // Setup: single home but full sync throws exception
      when(() => mockHomeRepository.getCachedUserHomes()).thenAnswer((_) async => [singleHome]);
      when(() => mockSyncCoordinator.initialFullSync('home-1')).thenThrow(Exception('مزامنة البيانات فشلت'));

      hydrationService = InitialDataHydrationService(
        homeRepository: mockHomeRepository,
        syncCoordinator: mockSyncCoordinator,
        localDataSource: mockHomeLocalDataSource,
        autoHydrate: false,
      );

      await hydrationService.hydrate();

      // Verify sync completion flags were NOT written
      verifyNever(() => mockHomeLocalDataSource.setInitialSyncCompleted(userId, true));
      verifyNever(() => mockHomeLocalDataSource.setHomeInitialSyncCompleted('home-1', true));
      
      expect(hydrationService.state.status, HydrationStatus.error);
      expect(hydrationService.state.error, contains('مزامنة البيانات فشلت'));
    });

    test('5. Full initial sync runs only once and does not repeat after success', () async {
      // Setup: isInitialSyncCompleted is true
      when(() => mockHomeLocalDataSource.isInitialSyncCompleted(userId)).thenAnswer((_) async => true);

      hydrationService = InitialDataHydrationService(
        homeRepository: mockHomeRepository,
        syncCoordinator: mockSyncCoordinator,
        localDataSource: mockHomeLocalDataSource,
        autoHydrate: false,
      );

      await hydrationService.hydrate();

      // Verify it bypasses everything and transitions straight to success
      verifyNever(() => mockHomeRepository.syncHomesWithServer());
      verifyNever(() => mockSyncCoordinator.initialFullSync(any()));
      expect(hydrationService.state.status, HydrationStatus.success);
    });
  });
}
