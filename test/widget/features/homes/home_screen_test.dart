import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sawa/features/homes/presentation/providers/homes_provider.dart';
import 'package:sawa/features/homes/data/models/home_model.dart';
import 'package:sawa/features/home/presentation/screens/home_screen.dart';
import 'package:sawa/features/homes/presentation/screens/onboarding_screen.dart';
import 'package:sawa/features/shopping_lists/data/models/shopping_list_model.dart';
import 'package:sawa/features/shopping_lists/presentation/providers/shopping_lists_provider.dart';
import 'package:sawa/features/activity_logs/data/models/activity_log_model.dart';
import 'package:sawa/features/activity_logs/presentation/providers/activity_logs_provider.dart';
import 'package:sawa/features/home/data/datasources/home_dashboard_snapshot_datasource.dart';
import 'package:sawa/features/offline_queue/domain/entities/device_sync_status.dart';
import 'package:sawa/features/offline_queue/presentation/providers/connectivity_provider.dart';
import 'package:sawa/core/localization/app_localizations.dart';
import 'package:sawa/core/services/shared_prefs_provider.dart';
import 'package:sawa/core/services/initial_data_hydration_service.dart';
import 'package:sawa/core/services/startup_prefetch_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sawa/features/homes/data/repositories/home_repository.dart';
import 'package:sawa/features/homes/data/repositories/home_local_data_source.dart';
import 'package:sawa/core/services/sync_coordinator.dart';

class MockHomeRepository extends Mock implements HomeRepository {}

class MockHomeLocalDataSource extends Mock implements HomeLocalDataSource {}

class MockSyncCoordinator extends StateNotifier<SyncState>
    with Mock
    implements SyncCoordinator {
  MockSyncCoordinator() : super(SyncState(status: SyncStatus.idle));
}

class FakeHydrationService extends InitialDataHydrationService {
  FakeHydrationService(HydrationState state)
    : super(
        homeRepository: MockHomeRepository(),
        syncCoordinator: MockSyncCoordinator(),
        localDataSource: MockHomeLocalDataSource(),
        autoHydrate: false,
      ) {
    this.state = state;
  }

  @override
  Future<void> hydrate({bool force = false}) async {}
}

void main() {
  late MockSyncCoordinator mockSyncCoordinator;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await AppPreferences.init();
  });

  setUp(() {
    mockSyncCoordinator = MockSyncCoordinator();
  });

  testWidgets('HomeScreen should render loading state initially', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          hasHomesProvider.overrideWith((ref) => const Stream<bool>.empty()),
          appLocalizationsProvider.overrideWithValue(
            AppLocalizations(const Locale('en', 'US')),
          ),
          initialDataHydrationServiceProvider.overrideWith(
            (ref) => FakeHydrationService(
              HydrationState(status: HydrationStatus.success),
            ),
          ),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('HomeScreen should render empty state when no homes exist', (
    tester,
  ) async {
    final localizations = AppLocalizations(const Locale('en', 'US'));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          hasHomesProvider.overrideWith((ref) => Stream.value(false)),
          appLocalizationsProvider.overrideWithValue(localizations),
          initialDataHydrationServiceProvider.overrideWith(
            (ref) => FakeHydrationService(
              HydrationState(status: HydrationStatus.success),
            ),
          ),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );

    await tester.pumpAndSettle();

    // Verify OnboardingScreen is rendered when no homes exist
    expect(find.byType(OnboardingScreen), findsOneWidget);
  });

  testWidgets(
    'HomeScreen falls back to cached home when active home id is unresolved',
    (tester) async {
      var shoppingListsQueried = false;
      final testHome = HomeModel(
        id: 'home-123',
        name: 'Family Home',
        type: 'family',
        ownerId: 'owner-123',
        defaultCurrency: 'SAR',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            hasHomesProvider.overrideWith((ref) => Stream.value(true)),
            cachedUserHomesProvider.overrideWithValue([testHome]),
            cachedActiveHomeIdProvider.overrideWithValue(null),
            startupPrefetchProvider.overrideWith((ref) {}),
            syncCoordinatorProvider.overrideWith((ref) => mockSyncCoordinator),
            connectivityStatusProvider.overrideWith(
              (ref) => Stream.value(DeviceSyncStatus.online),
            ),
            cachedHomeDashboardSnapshotProvider(
              'home-123',
            ).overrideWithValue(null),
            appLocalizationsProvider.overrideWithValue(
              AppLocalizations(const Locale('en', 'US')),
            ),
            initialDataHydrationServiceProvider.overrideWith(
              (ref) => FakeHydrationService(
                HydrationState(status: HydrationStatus.idle),
              ),
            ),
            shoppingListsProvider('home-123').overrideWith((ref) {
              shoppingListsQueried = true;
              return Stream.value(<ShoppingListModel>[]);
            }),
            recentHomeActivityProvider(
              'home-123',
            ).overrideWith((ref) => Stream.value(<ActivityLogModel>[])),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );

      await tester.pump();

      expect(find.text('Family Home'), findsWidgets);
      expect(shoppingListsQueried, isTrue);
    },
  );
}
