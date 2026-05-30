import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:beity/features/expenses/domain/repositories/expense_repository.dart';
import 'package:beity/features/expenses/domain/usecases/get_expense_summary.dart';
import 'package:beity/features/expenses/domain/entities/expense.dart';

class MockExpenseRepository extends Mock implements ExpenseRepository {}

void main() {
  late MockExpenseRepository mockRepository;
  late GetExpenseSummary useCase;

  setUp(() {
    mockRepository = MockExpenseRepository();
    useCase = GetExpenseSummary(mockRepository);
  });

  group('GetExpenseSummary', () {
    final testDate = DateTime(2026, 5, 15);
    final startDate = DateTime(2026, 5, 1);
    final endDate = DateTime(2026, 5, 31);

    final testExpenses = [
      Expense(
        id: 'exp-1',
        homeId: 'home-123',
        amount: 5000,
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
        amount: 3000,
        description: 'Transport',
        date: testDate,
        categoryId: 'cat-transport',
        paidBy: 'user-2',
        convertedAmount: 3000,
        createdBy: 'user-2',
      ),
      Expense(
        id: 'exp-3',
        homeId: 'home-123',
        amount: 2000,
        description: 'Snacks',
        date: testDate,
        categoryId: 'cat-food',
        paidBy: 'user-1',
        convertedAmount: 2000,
        createdBy: 'user-1',
      ),
    ];

    test('should return correct total amount', () async {
      when(() => mockRepository.getExpenses(
            homeId: 'home-123',
            startDate: startDate,
            endDate: endDate,
          )).thenAnswer((_) async => testExpenses);

      final result = await useCase(GetExpenseSummaryParams(
        homeId: 'home-123',
        startDate: startDate,
        endDate: endDate,
      ));

      expect(result.totalAmount, 10000);
    });

    test('should return correct expense count', () async {
      when(() => mockRepository.getExpenses(
            homeId: 'home-123',
            startDate: startDate,
            endDate: endDate,
          )).thenAnswer((_) async => testExpenses);

      final result = await useCase(GetExpenseSummaryParams(
        homeId: 'home-123',
        startDate: startDate,
        endDate: endDate,
      ));

      expect(result.expenseCount, 3);
    });

    test('should return correct category breakdown', () async {
      when(() => mockRepository.getExpenses(
            homeId: 'home-123',
            startDate: startDate,
            endDate: endDate,
          )).thenAnswer((_) async => testExpenses);

      final result = await useCase(GetExpenseSummaryParams(
        homeId: 'home-123',
        startDate: startDate,
        endDate: endDate,
      ));

      expect(result.categoryBreakdown['cat-food'], 7000);
      expect(result.categoryBreakdown['cat-transport'], 3000);
    });

    test('should return correct member breakdown', () async {
      when(() => mockRepository.getExpenses(
            homeId: 'home-123',
            startDate: startDate,
            endDate: endDate,
          )).thenAnswer((_) async => testExpenses);

      final result = await useCase(GetExpenseSummaryParams(
        homeId: 'home-123',
        startDate: startDate,
        endDate: endDate,
      ));

      expect(result.memberBreakdown['user-1'], 7000);
      expect(result.memberBreakdown['user-2'], 3000);
    });

    test('should calculate correct average expense', () async {
      when(() => mockRepository.getExpenses(
            homeId: 'home-123',
            startDate: startDate,
            endDate: endDate,
          )).thenAnswer((_) async => testExpenses);

      final result = await useCase(GetExpenseSummaryParams(
        homeId: 'home-123',
        startDate: startDate,
        endDate: endDate,
      ));

      expect(result.averageExpense, closeTo(3333.33, 0.01));
    });

    test('should return correct category percentages', () async {
      when(() => mockRepository.getExpenses(
            homeId: 'home-123',
            startDate: startDate,
            endDate: endDate,
          )).thenAnswer((_) async => testExpenses);

      final result = await useCase(GetExpenseSummaryParams(
        homeId: 'home-123',
        startDate: startDate,
        endDate: endDate,
      ));

      expect(result.categoryPercentages['cat-food'], 70.0);
      expect(result.categoryPercentages['cat-transport'], 30.0);
    });

    test('should handle empty expenses list', () async {
      when(() => mockRepository.getExpenses(
            homeId: 'home-123',
            startDate: startDate,
            endDate: endDate,
          )).thenAnswer((_) async => []);

      final result = await useCase(GetExpenseSummaryParams(
        homeId: 'home-123',
        startDate: startDate,
        endDate: endDate,
      ));

      expect(result.totalAmount, 0);
      expect(result.expenseCount, 0);
      expect(result.categoryBreakdown, isEmpty);
      expect(result.memberBreakdown, isEmpty);
      expect(result.averageExpense, 0);
      expect(result.categoryPercentages, isEmpty);
    });

    test('should categorize expenses without category as uncategorized', () async {
      final expensesWithoutCategory = [
        Expense(
          id: 'exp-1',
          homeId: 'home-123',
          amount: 5000,
          description: 'Misc',
          date: testDate,
          paidBy: 'user-1',
          convertedAmount: 5000,
          createdBy: 'user-1',
        ),
      ];

      when(() => mockRepository.getExpenses(
            homeId: 'home-123',
            startDate: startDate,
            endDate: endDate,
          )).thenAnswer((_) async => expensesWithoutCategory);

      final result = await useCase(GetExpenseSummaryParams(
        homeId: 'home-123',
        startDate: startDate,
        endDate: endDate,
      ));

      expect(result.categoryBreakdown.containsKey('uncategorized'), true);
      expect(result.categoryBreakdown['uncategorized'], 5000);
    });

    test('should work without date filters', () async {
      when(() => mockRepository.getExpenses(
            homeId: 'home-123',
          )).thenAnswer((_) async => testExpenses);

      final result = await useCase(const GetExpenseSummaryParams(
        homeId: 'home-123',
      ));

      expect(result.totalAmount, 10000);
      expect(result.expenseCount, 3);
    });
  });
}
