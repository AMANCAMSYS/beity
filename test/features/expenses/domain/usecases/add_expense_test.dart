import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:beity/features/expenses/domain/repositories/expense_repository.dart';
import 'package:beity/features/expenses/domain/usecases/add_expense.dart';
import 'package:beity/features/expenses/domain/entities/expense.dart';

class MockExpenseRepository extends Mock implements ExpenseRepository {}

void main() {
  late MockExpenseRepository mockRepository;
  late AddExpense useCase;

  setUp(() {
    mockRepository = MockExpenseRepository();
    useCase = AddExpense(mockRepository);
  });

  group('AddExpense', () {
    final testDate = DateTime(2026, 5, 13);
    final testExpense = Expense(
      id: 'test-id',
      homeId: 'home-123',
      amount: 10000, // $100.00
      description: 'Groceries',
      date: testDate,
      paidBy: 'user-123',
      convertedAmount: 10000,
      createdBy: 'user-123',
    );

    test('should create expense successfully', () async {
      when(() => mockRepository.createExpense(
            homeId: 'home-123',
            amount: 10000,
            description: 'Groceries',
            date: testDate,
            paidBy: 'user-123',
            convertedAmount: 10000,
          )).thenAnswer((_) async => testExpense);

      final result = await useCase(AddExpenseParams(
        homeId: 'home-123',
        amount: 10000,
        description: 'Groceries',
        date: testDate,
        paidBy: 'user-123',
        convertedAmount: 10000,
      ));

      expect(result, testExpense);
      verify(() => mockRepository.createExpense(
            homeId: 'home-123',
            amount: 10000,
            description: 'Groceries',
            date: testDate,
            paidBy: 'user-123',
            convertedAmount: 10000,
          )).called(1);
    });

    test('should pass category when provided', () async {
      when(() => mockRepository.createExpense(
            homeId: 'home-123',
            amount: 10000,
            description: 'Groceries',
            date: testDate,
            categoryId: 'cat-456',
            paidBy: 'user-123',
            convertedAmount: 10000,
          )).thenAnswer((_) async => testExpense.copyWith(categoryId: 'cat-456'));

      final result = await useCase(AddExpenseParams(
        homeId: 'home-123',
        amount: 10000,
        description: 'Groceries',
        date: testDate,
        categoryId: 'cat-456',
        paidBy: 'user-123',
        convertedAmount: 10000,
      ));

      expect(result.categoryId, 'cat-456');
    });

    test('should pass shopping list item when provided', () async {
      when(() => mockRepository.createExpense(
            homeId: 'home-123',
            amount: 10000,
            description: 'Groceries',
            date: testDate,
            paidBy: 'user-123',
            shoppingListItemId: 'item-789',
            convertedAmount: 10000,
          )).thenAnswer(
              (_) async => testExpense.copyWith(shoppingListItemId: 'item-789'));

      final result = await useCase(AddExpenseParams(
        homeId: 'home-123',
        amount: 10000,
        description: 'Groceries',
        date: testDate,
        paidBy: 'user-123',
        shoppingListItemId: 'item-789',
        convertedAmount: 10000,
      ));

      expect(result.shoppingListItemId, 'item-789');
    });
  });
}
