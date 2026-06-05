import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sawa/features/expenses/domain/entities/expense.dart';
import 'package:sawa/features/expenses/domain/repositories/expense_repository.dart';
import 'package:sawa/features/expenses/presentation/providers/expense_providers.dart';
import 'package:sawa/features/expenses/presentation/screens/expense_summary_screen.dart';
import 'package:sawa/core/localization/app_localizations.dart';
import 'package:sawa/features/categories/domain/entities/category.dart';
import 'package:sawa/features/categories/data/models/category_model.dart';
import 'package:sawa/features/categories/presentation/providers/categories_provider.dart';
import 'package:sawa/features/homes/data/models/home_member_model.dart';
import 'package:sawa/features/homes/presentation/providers/homes_provider.dart';
import 'package:sawa/core/services/sync_coordinator.dart';

class MockExpenseRepository extends Mock implements ExpenseRepository {}

class MockSyncCoordinator extends StateNotifier<SyncState>
    with Mock
    implements SyncCoordinator {
  MockSyncCoordinator() : super(SyncState(status: SyncStatus.idle));
}

void main() {
  late MockExpenseRepository mockRepository;
  late MockSyncCoordinator mockSyncCoordinator;

  setUp(() {
    mockRepository = MockExpenseRepository();
    mockSyncCoordinator = MockSyncCoordinator();

    // Default stubs
    when(
      () => mockRepository.isInitialSyncCompleted(homeId: any(named: 'homeId')),
    ).thenAnswer((_) async => true);

    when(
      () => mockSyncCoordinator.syncAll(
        any(),
        force: any(named: 'force'),
        targetDomain: any(named: 'targetDomain'),
      ),
    ).thenAnswer((_) async {});
  });

  Widget buildScreen({
    String homeId = 'home-123',
    Locale locale = const Locale('en'),
    List<Expense> expenses = const [],
    Stream<List<Expense>>? expensesStream,
    bool isSyncCompleted = true,
  }) {
    return ProviderScope(
      overrides: [
        expenseRepositoryProvider.overrideWithValue(mockRepository),
        syncCoordinatorProvider.overrideWith((ref) => mockSyncCoordinator),
        appLocalizationsProvider.overrideWithValue(AppLocalizations(locale)),
        categoriesByTypeProvider((
          homeId: homeId,
          type: 'expense',
        )).overrideWith(
          (ref) => Future.value([
            const CategoryModel(
              id: 'cat-food',
              homeId: 'home-123',
              name: 'cat-food',
              type: CategoryType.expense,
            ),
            const CategoryModel(
              id: 'cat-transport',
              homeId: 'home-123',
              name: 'cat-transport',
              type: CategoryType.expense,
            ),
          ]),
        ),
        homeMembersProvider(homeId).overrideWith(
          (ref) => Stream.value([
            HomeMemberModel(
              id: 'mem-1',
              homeId: 'home-123',
              userId: 'user-1',
              role: 'member',
              userName: 'user-1',
              joinedAt: DateTime(2026, 5, 27),
            ),
            HomeMemberModel(
              id: 'mem-2',
              homeId: 'home-123',
              userId: 'user-2',
              role: 'member',
              userName: 'user-2',
              joinedAt: DateTime(2026, 5, 27),
            ),
          ]),
        ),
        expensesProvider(homeId).overrideWith((ref) {
          if (expensesStream != null) return expensesStream;
          return Stream.value(expenses);
        }),
        initialSyncCompletedExpensesProvider(homeId).overrideWith((ref) {
          return Stream.value(isSyncCompleted);
        }),
      ],
      child: MaterialApp(
        locale: locale,
        home: ExpenseSummaryScreen(homeId: homeId),
      ),
    );
  }

  group('ExpenseSummaryScreen - Local-First Reactive Summary', () {
    final now = DateTime.now();
    final testDate = DateTime(now.year, now.month, 1);
    final testExpenses = [
      Expense(
        id: 'exp-1',
        homeId: 'home-123',
        amount: 5000, // 50.00
        description: 'Groceries',
        date: testDate,
        categoryId: 'cat-food',
        paidBy: 'user-1',
        convertedAmount: 5000,
        createdBy: 'user-1',
      ),
      Expense(
        id: 'exp-2',
        homeId: 'home-123',
        amount: 3000, // 30.00
        description: 'Transport',
        date: testDate,
        categoryId: 'cat-transport',
        paidBy: 'user-2',
        convertedAmount: 3000,
        createdBy: 'user-2',
      ),
    ];

    testWidgets('1. Opening ExpenseSummaryScreen does not call Supabase', (
      tester,
    ) async {
      await tester.pumpWidget(buildScreen(expenses: testExpenses));
      await tester.pumpAndSettle();

      // Verify data is displayed correctly from cache
      expect(find.text('Total Expenses'), findsOneWidget);
      expect(find.text('80.00 SAR'), findsOneWidget);
      expect(find.text('2 expenses'), findsOneWidget);

      // Verify that no remote Supabase method was called
      verifyNever(
        () => mockRepository.getExpenses(
          homeId: any(named: 'homeId'),
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
        ),
      );
    });

    testWidgets('2. Changing date or filters does not call Supabase', (
      tester,
    ) async {
      await tester.pumpWidget(buildScreen(expenses: testExpenses));
      await tester.pumpAndSettle();

      // Tap calendar popup to trigger range change
      await tester.tap(find.byIcon(Icons.calendar_today_rounded));
      await tester.pumpAndSettle();

      // Tap 'This Week'
      await tester.tap(find.text('This Week'));
      await tester.pumpAndSettle();

      // Verify no network call was made to repository.getExpenses
      verifyNever(
        () => mockRepository.getExpenses(
          homeId: any(named: 'homeId'),
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
        ),
      );
    });

    testWidgets('3. Adding local expense updates the summary reactively', (
      tester,
    ) async {
      final controller = StreamController<List<Expense>>();

      await tester.pumpWidget(buildScreen(expensesStream: controller.stream));

      // Initially emit 1 expense
      controller.add([testExpenses[0]]);
      await tester.pumpAndSettle();

      expect(find.text('50.00 SAR'), findsWidgets);
      expect(find.text('1 expenses'), findsOneWidget);

      // Dynamically emit a second expense (simulating local write/sync update)
      controller.add(testExpenses);
      await tester.pumpAndSettle();

      expect(find.text('80.00 SAR'), findsWidgets);
      expect(find.text('2 expenses'), findsOneWidget);

      controller.close();
    });

    testWidgets(
      '4. Pull to Refresh / Error Retry triggers Delta Sync for expenses only',
      (tester) async {
        // Simulate repository error to show retry button
        await tester.pumpWidget(
          buildScreen(expensesStream: Stream.error(Exception('Cache error'))),
        );
        await tester.pumpAndSettle();

        expect(find.text('Error occurred'), findsOneWidget);

        // Tap retry
        await tester.tap(find.text('Retry'));
        await tester.pumpAndSettle();

        // Verify SyncCoordinator was called with targetDomain: 'expenses' and force: true
        verify(
          () => mockSyncCoordinator.syncAll(
            'home-123',
            force: true,
            targetDomain: 'expenses',
          ),
        ).called(1);
      },
    );

    testWidgets(
      '5. Empty cache before initial sync shows Preparing/Loading state instead of empty state',
      (tester) async {
        await tester.pumpWidget(
          buildScreen(
            expenses: [],
            isSyncCompleted: false, // Initial sync NOT completed
          ),
        );
        await tester.pump();

        // Should show spinner instead of Empty State
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('No data for this period'), findsNothing);
      },
    );

    test('6. endDate includes full last day (inclusive 23:59:59)', () async {
      final container = ProviderContainer(
        overrides: [
          expensesProvider('home-123').overrideWith(
            (ref) => Stream.value([
              Expense(
                id: 'exp-late',
                homeId: 'home-123',
                amount: 1000,
                description: 'Late Night Dinner',
                // Late night of 2026-05-15 (e.g. 23:30)
                date: DateTime(2026, 5, 15, 23, 30),
                categoryId: 'cat-food',
                paidBy: 'user-1',
                convertedAmount: 1000,
                createdBy: 'user-1',
              ),
            ]),
          ),
        ],
      );

      final expensesSub = container.listen(
        expensesProvider('home-123'),
        (_, _) {},
        fireImmediately: true,
      );
      await container.pump();

      // Read the summary with endDate set to 2026-05-15 (but no time specified, i.e. 00:00:00)
      final summaryProvider = expenseSummaryProvider((
        homeId: 'home-123',
        startDate: DateTime(2026, 5, 15),
        endDate: DateTime(2026, 5, 15),
      ));
      final summarySub = container.listen(
        summaryProvider,
        (_, _) {},
        fireImmediately: true,
      );
      await container.pump();
      final summaryAsync = summarySub.read();

      expect(summaryAsync.hasValue, true);
      final summary = summaryAsync.value!;

      // The expense at 23:30 should be INCLUDED because endDate is inclusive of the whole day (23:59:59.999)
      expect(summary.expenseCount, 1);
      expect(summary.totalAmount, 1000);
      summarySub.close();
      expensesSub.close();
      container.dispose();
    });
  });
}
