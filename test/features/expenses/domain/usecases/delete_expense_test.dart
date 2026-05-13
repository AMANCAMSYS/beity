import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:beity/features/expenses/domain/repositories/expense_repository.dart';
import 'package:beity/features/expenses/domain/usecases/delete_expense.dart';

class MockExpenseRepository extends Mock implements ExpenseRepository {}

void main() {
  late MockExpenseRepository mockRepository;
  late DeleteExpense useCase;

  setUp(() {
    mockRepository = MockExpenseRepository();
    useCase = DeleteExpense(mockRepository);
  });

  group('DeleteExpense', () {
    test('should soft delete expense', () async {
      when(() => mockRepository.deleteExpense(
            expenseId: 'expense-123',
          )).thenAnswer((_) async {});

      await useCase(DeleteExpenseParams(
        expenseId: 'expense-123',
      ));

      verify(() => mockRepository.deleteExpense(
            expenseId: 'expense-123',
          )).called(1);
    });

    test('should throw when expense not found', () async {
      when(() => mockRepository.deleteExpense(
            expenseId: 'non-existent',
          )).thenThrow(Exception('Expense not found'));

      expect(
        () => useCase(DeleteExpenseParams(expenseId: 'non-existent')),
        throwsException,
      );
    });
  });
}
