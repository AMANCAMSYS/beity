import '../entities/expense.dart';
import '../entities/expense_split.dart';

abstract class ExpenseRepository {
  Future<List<Expense>> getExpenses({
    required String homeId,
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
    String? memberId,
  });

  Future<Expense?> getExpenseById({
    required String expenseId,
  });

  Future<Expense> createExpense({
    required String homeId,
    required int amount,
    required String description,
    required DateTime date,
    String? categoryId,
    required String paidBy,
    String? shoppingListItemId,
    String currencyCode = 'SAR',
    required int convertedAmount,
  });

  Future<Expense> updateExpense({
    required String expenseId,
    int? amount,
    String? description,
    DateTime? date,
    String? categoryId,
    String? paidBy,
    String? shoppingListItemId,
    String? currencyCode,
    int? convertedAmount,
  });

  Future<void> deleteExpense({
    required String expenseId,
  });

  Future<List<ExpenseSplit>> getExpenseSplits({
    required String expenseId,
  });

  Future<List<ExpenseSplit>> createExpenseSplits({
    required String expenseId,
    required List<({String memberId, int amount})> splits,
  });

  Future<void> deleteExpenseSplits({
    required String expenseId,
  });

  Future<int> getExpenseTotal({
    required String homeId,
    DateTime? startDate,
    DateTime? endDate,
  });

  Stream<List<Expense>> watchExpenses({
    required String homeId,
  });
}
