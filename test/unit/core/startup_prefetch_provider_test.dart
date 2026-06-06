import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sawa/core/services/initial_data_hydration_service.dart';
import 'package:sawa/core/services/realtime_sync_service.dart';
import 'package:sawa/core/services/startup_prefetch_provider.dart';
import 'package:sawa/core/services/sync_coordinator.dart';
import 'package:sawa/features/homes/data/repositories/home_local_data_source.dart';
import 'package:sawa/features/homes/data/repositories/home_repository.dart';
import 'package:sawa/features/homes/presentation/providers/homes_provider.dart';

class MockRealtimeSyncService extends Mock implements RealtimeSyncService {}

class MockHomeLocalDataSource extends Mock implements HomeLocalDataSource {}

class MockHomeRepository extends Mock implements HomeRepository {}

class MockSyncCoordinator extends Notifier<SyncState>
    with Mock
    implements SyncCoordinator {
  @override
  SyncState build() => SyncState(status: SyncStatus.idle);
}

class FakeHydrationService extends InitialDataHydrationService {
  final HydrationState _initialState;

  FakeHydrationService(this._initialState);

  @override
  HydrationState build() {
    return _initialState;
  }
}

void main() {
  setUp(resetStartupPrefetchStateForTesting);

  test(
    'runs non-throttled catch-up after active home recovers from null',
    () async {
      final realtimeService = MockRealtimeSyncService();
      final localDataSource = MockHomeLocalDataSource();
      final syncCoordinator = MockSyncCoordinator();

      when(() => realtimeService.init(any())).thenReturn(null);
      when(() => realtimeService.flushBuffer()).thenAnswer((_) async {});
      when(
        () => localDataSource.isHomeInitialSyncCompleted('home-123'),
      ).thenAnswer((_) async => false);
      when(
        () => localDataSource.setHomeInitialSyncCompleted(any(), any()),
      ).thenAnswer((_) async {});
      when(
        () => syncCoordinator.initialFullSync(any()),
      ).thenAnswer((_) async {});
      when(
        () => syncCoordinator.smartResumeSync(any()),
      ).thenAnswer((_) async {});

      final unresolvedContainer = ProviderContainer(
        overrides: [
          cachedActiveHomeIdProvider.overrideWithValue(null),
          initialDataHydrationServiceProvider.overrideWith(
            () => FakeHydrationService(
              HydrationState(status: HydrationStatus.success),
            ),
          ),
          realtimeSyncServiceProvider.overrideWithValue(realtimeService),
          homeLocalDataSourceProvider.overrideWithValue(localDataSource),
          syncCoordinatorProvider.overrideWith(() => syncCoordinator),
        ],
      );
      addTearDown(unresolvedContainer.dispose);
      unresolvedContainer.read(startupPrefetchProvider);
      unresolvedContainer.dispose();

      final resolvedContainer = ProviderContainer(
        overrides: [
          cachedActiveHomeIdProvider.overrideWithValue('home-123'),
          initialDataHydrationServiceProvider.overrideWith(
            () => FakeHydrationService(
              HydrationState(status: HydrationStatus.success),
            ),
          ),
          realtimeSyncServiceProvider.overrideWithValue(realtimeService),
          homeLocalDataSourceProvider.overrideWithValue(localDataSource),
          syncCoordinatorProvider.overrideWith(() => syncCoordinator),
        ],
      );
      addTearDown(resolvedContainer.dispose);

      resolvedContainer.read(startupPrefetchProvider);
      await Future<void>.delayed(const Duration(milliseconds: 700));

      verify(() => syncCoordinator.initialFullSync('home-123')).called(1);
      verifyNever(() => syncCoordinator.smartResumeSync(any()));
      verify(() => realtimeService.init('home-123')).called(1);
    },
  );

  test(
    'reset clears prefetched homes so logout cannot skip next user sync',
    () async {
      final realtimeService = MockRealtimeSyncService();
      final localDataSource = MockHomeLocalDataSource();
      final syncCoordinator = MockSyncCoordinator();

      when(() => realtimeService.init(any())).thenReturn(null);
      when(() => realtimeService.flushBuffer()).thenAnswer((_) async {});
      when(
        () => localDataSource.isHomeInitialSyncCompleted('home-123'),
      ).thenAnswer((_) async => true);
      when(
        () => syncCoordinator.smartResumeSync(any()),
      ).thenAnswer((_) async {});

      markStartupPrefetchCompletedForTesting('home-123');
      resetStartupPrefetchState();

      final container = ProviderContainer(
        overrides: [
          cachedActiveHomeIdProvider.overrideWithValue('home-123'),
          initialDataHydrationServiceProvider.overrideWith(
            () => FakeHydrationService(
              HydrationState(status: HydrationStatus.success),
            ),
          ),
          realtimeSyncServiceProvider.overrideWithValue(realtimeService),
          homeLocalDataSourceProvider.overrideWithValue(localDataSource),
          syncCoordinatorProvider.overrideWith(() => syncCoordinator),
        ],
      );
      addTearDown(container.dispose);

      container.read(startupPrefetchProvider);
      await Future<void>.delayed(const Duration(milliseconds: 700));

      verify(() => syncCoordinator.smartResumeSync('home-123')).called(1);
      verify(() => realtimeService.init('home-123')).called(1);
    },
  );
}
