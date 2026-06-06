import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sawa/features/expenses/domain/repositories/expense_repository.dart';
import 'package:sawa/features/expenses/domain/usecases/edit_expense.dart';
import 'package:sawa/features/expenses/domain/entities/expense.dart';

class MockExpenseRepository extends Mock implements ExpenseRepository {}

void main() {
  late MockExpenseRepository mockRepository;
  late EditExpense useCase;

  setUp(() {
    mockRepository = MockExpenseRepository();
    useCase = EditExpense(mockRepository);
  });

  group('EditExpense', () {
    final testDate = DateTime(2026, 5, 13);
    final existingExpense = Expense(
      id: 'expense-123',
      homeId: 'home-123',
      amount: 10000,
      description: 'Groceries',
      date: testDate,
      paidBy: 'user-123',
      convertedAmount: 10000,
      createdBy: 'user-123',
    );

    test('should update expense amount', () async {
      final updatedExpense = existingExpense.copyWith(amount: 15000);

      when(
        () => mockRepository.updateExpense(
          expenseId: 'expense-123',
          amount: 15000,
        ),
      ).thenAnswer((_) async => updatedExpense);

      final result = await useCase(
        const EditExpenseParams(expenseId: 'expense-123', amount: 15000),
      );

      expect(result.amount, 15000);
      verify(
        () => mockRepository.updateExpense(
          expenseId: 'expense-123',
          amount: 15000,
        ),
      ).called(1);
    });

    test('should update expense description', () async {
      final updatedExpense = existingExpense.copyWith(
        description: 'Weekly groceries',
      );

      when(
        () => mockRepository.updateExpense(
          expenseId: 'expense-123',
          description: 'Weekly groceries',
        ),
      ).thenAnswer((_) async => updatedExpense);

      final result = await useCase(
        const EditExpenseParams(
          expenseId: 'expense-123',
          description: 'Weekly groceries',
        ),
      );

      expect(result.description, 'Weekly groceries');
    });

    test('should update expense category', () async {
      final updatedExpense = existingExpense.copyWith(categoryId: 'cat-456');

      when(
        () => mockRepository.updateExpense(
          expenseId: 'expense-123',
          categoryId: 'cat-456',
        ),
      ).thenAnswer((_) async => updatedExpense);

      final result = await useCase(
        const EditExpenseParams(
          expenseId: 'expense-123',
          categoryId: 'cat-456',
        ),
      );

      expect(result.categoryId, 'cat-456');
    });
  });
}
