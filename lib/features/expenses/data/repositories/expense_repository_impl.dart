import '../../domain/entities/expense.dart';
import '../../domain/entities/expense_split.dart';
import '../../domain/repositories/expense_repository.dart';
import '../datasources/expense_remote_datasource.dart';

class ExpenseRepositoryImpl implements ExpenseRepository {
  final ExpenseRemoteDataSource _dataSource;

  ExpenseRepositoryImpl(this._dataSource);

  @override
  Future<List<Expense>> getExpenses({
    required String homeId,
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
    String? memberId,
  }) async {
    return _dataSource.getExpenses(
      homeId: homeId,
      startDate: startDate,
      endDate: endDate,
      categoryId: categoryId,
      memberId: memberId,
    );
  }

  @override
  Future<Expense?> getExpenseById({
    required String expenseId,
  }) async {
    return _dataSource.getExpenseById(expenseId: expenseId);
  }

  @override
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
  }) async {
    return _dataSource.createExpense(
      homeId: homeId,
      amount: amount,
      description: description,
      date: date,
      categoryId: categoryId,
      paidBy: paidBy,
      shoppingListItemId: shoppingListItemId,
      currencyCode: currencyCode,
      convertedAmount: convertedAmount,
    );
  }

  @override
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
  }) async {
    return _dataSource.updateExpense(
      expenseId: expenseId,
      amount: amount,
      description: description,
      date: date,
      categoryId: categoryId,
      paidBy: paidBy,
      shoppingListItemId: shoppingListItemId,
      currencyCode: currencyCode,
      convertedAmount: convertedAmount,
    );
  }

  @override
  Future<void> deleteExpense({
    required String expenseId,
  }) async {
    return _dataSource.deleteExpense(expenseId: expenseId);
  }

  @override
  Future<List<ExpenseSplit>> getExpenseSplits({
    required String expenseId,
  }) async {
    return _dataSource.getExpenseSplits(expenseId: expenseId);
  }

  @override
  Future<List<ExpenseSplit>> createExpenseSplits({
    required String expenseId,
    required List<({String memberId, int amount})> splits,
  }) async {
    return _dataSource.createExpenseSplits(
      expenseId: expenseId,
      splits: splits,
    );
  }

  @override
  Future<void> deleteExpenseSplits({
    required String expenseId,
  }) async {
    return _dataSource.deleteExpenseSplits(expenseId: expenseId);
  }

  @override
  Future<int> getExpenseTotal({
    required String homeId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return _dataSource.getExpenseTotal(
      homeId: homeId,
      startDate: startDate,
      endDate: endDate,
    );
  }

  @override
  Stream<List<Expense>> watchExpenses({
    required String homeId,
  }) {
    return _dataSource.watchExpenses(homeId: homeId);
  }
}
