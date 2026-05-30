import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:beity/features/homes/presentation/providers/homes_provider.dart';
import 'package:beity/features/home/presentation/screens/home_screen.dart';
import 'package:beity/features/homes/presentation/screens/onboarding_screen.dart';
import 'package:beity/core/localization/app_localizations.dart';
import 'package:beity/core/services/shared_prefs_provider.dart';
import 'package:beity/core/services/initial_data_hydration_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:beity/features/homes/data/repositories/home_repository.dart';
import 'package:beity/features/homes/data/repositories/home_local_data_source.dart';
import 'package:beity/core/services/sync_coordinator.dart';

class MockHomeRepository extends Mock implements HomeRepository {}
class MockHomeLocalDataSource extends Mock implements HomeLocalDataSource {}
class MockSyncCoordinator extends StateNotifier<SyncState> with Mock implements SyncCoordinator {
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
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await AppPreferences.init();
  });

  testWidgets('HomeScreen should render loading state initially', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          hasHomesProvider.overrideWith((ref) => const Stream<bool>.empty()),
          appLocalizationsProvider.overrideWithValue(AppLocalizations(const Locale('en', 'US'))),
          initialDataHydrationServiceProvider.overrideWith(
            (ref) => FakeHydrationService(HydrationState(status: HydrationStatus.success)),
          ),
        ],
        child: const MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('HomeScreen should render empty state when no homes exist', (tester) async {
    final localizations = AppLocalizations(const Locale('en', 'US'));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          hasHomesProvider.overrideWith((ref) => Stream.value(false)),
          appLocalizationsProvider.overrideWithValue(localizations),
          initialDataHydrationServiceProvider.overrideWith(
            (ref) => FakeHydrationService(HydrationState(status: HydrationStatus.success)),
          ),
        ],
        child: const MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify OnboardingScreen is rendered when no homes exist
    expect(find.byType(OnboardingScreen), findsOneWidget);
  });
}
