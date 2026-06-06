import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sawa/features/homes/presentation/providers/homes_provider.dart';
import 'package:sawa/features/homes/data/models/home_model.dart';
import 'package:sawa/features/home/presentation/screens/home_screen.dart';
import 'package:sawa/features/home/data/models/home_dashboard_snapshot.dart';
import 'package:sawa/features/home/data/datasources/home_dashboard_snapshot_datasource.dart';
import 'package:sawa/features/shopping_lists/data/models/shopping_list_model.dart';
import 'package:sawa/features/shopping_lists/presentation/providers/shopping_lists_provider.dart';
import 'package:sawa/features/activity_logs/presentation/providers/activity_logs_provider.dart';
import 'package:sawa/features/activity_logs/data/models/activity_log_model.dart';
import 'package:sawa/features/offline_queue/presentation/providers/connectivity_provider.dart';
import 'package:sawa/features/offline_queue/domain/entities/device_sync_status.dart';
import 'package:sawa/core/localization/app_localizations.dart';
import 'package:sawa/core/services/shared_prefs_provider.dart';
import 'package:sawa/core/services/sync_coordinator.dart';
import 'package:sawa/core/services/startup_prefetch_provider.dart';
import 'package:sawa/core/services/initial_data_hydration_service.dart';
import 'package:sawa/features/homes/data/repositories/home_repository.dart';
import 'package:sawa/features/homes/data/repositories/home_local_data_source.dart';

class MockHomeRepository extends Mock implements HomeRepository {}

class MockHomeLocalDataSource extends Mock implements HomeLocalDataSource {}

class FakeHydrationService extends InitialDataHydrationService {
  final HydrationState _initialState;

  FakeHydrationService(this._initialState);

  @override
  HydrationState build() => _initialState;

  @override
  Future<void> hydrate({bool force = false}) async {}
}

class MockSyncCoordinator extends Notifier<SyncState>
    with Mock
    implements SyncCoordinator {
  @override
  SyncState build() => SyncState(status: SyncStatus.idle);
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

  testWidgets(
    'HomeScreen should render cached snapshot data instantly when live providers are loading',
    (tester) async {
      final localizations = AppLocalizations(const Locale('en', 'US'));
      final testHome = HomeModel(
        id: 'home-123',
        name: 'Lovely Sweet Home',
        type: 'family',
        ownerId: 'owner-123',
        defaultCurrency: 'SAR',
        createdAt: DateTime.now(),
      );

      final testSnapshot = HomeDashboardSnapshot(
        homeId: 'home-123',
        homeName: 'Lovely Sweet Home',
        activeListId: 'list-456',
        activeListName: 'Weekly Veggies',
        remainingShoppingItemsCount: 4,
        totalShoppingItemsCount: 6,
        totalActiveListsCount: 2,
        lastActivityText: 'Ahmed added Milk',
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            hasHomesProvider.overrideWith((ref) => Stream.value(true)),
            cachedUserHomesProvider.overrideWithValue([testHome]),
            cachedActiveHomeIdProvider.overrideWithValue('home-123'),
            startupPrefetchProvider.overrideWith((ref) {}),
            syncCoordinatorProvider.overrideWith(() => mockSyncCoordinator),
            connectivityStatusProvider.overrideWith(
              (ref) => Stream.value(DeviceSyncStatus.online),
            ),
            initialDataHydrationServiceProvider.overrideWith(
              () => FakeHydrationService(
                HydrationState(status: HydrationStatus.success),
              ),
            ),

            // Force shopping lists and activity log providers to stay in loading state
            shoppingListsProvider('home-123').overrideWith(
              (ref) => StreamController<List<ShoppingListModel>>().stream,
            ),
            recentHomeActivityProvider('home-123').overrideWith(
              (ref) => StreamController<List<ActivityLogModel>>().stream,
            ),

            // Provide our synchronous cached snapshot
            cachedHomeDashboardSnapshotProvider(
              'home-123',
            ).overrideWithValue(testSnapshot),
            appLocalizationsProvider.overrideWithValue(localizations),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );

      // Initial build frame
      await tester.pump();

      // Verify: Even though live shopping lists and activities are loading, we DO NOT show a full screen CircularProgressIndicator.
      expect(find.byType(CircularProgressIndicator), findsNothing);

      // Verify: The active list card shows snapshot data instead of loading indicator
      expect(find.text('Lovely Sweet Home'), findsWidgets);
      expect(find.text('Weekly Veggies'), findsOneWidget);
      expect(find.text('4 remaining of 6'), findsOneWidget);

      // Verify: The recent activity block shows the last activity text from the snapshot
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is RichText &&
              widget.text.toPlainText().contains('Ahmed added Milk'),
        ),
        findsOneWidget,
      );
    },
  );
}
