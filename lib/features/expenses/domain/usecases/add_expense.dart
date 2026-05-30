import '../entities/expense.dart';
import '../repositories/expense_repository.dart';

class AddExpense {
  final ExpenseRepository _repository;

  AddExpense(this._repository);

  Future<Expense> call(AddExpenseParams params) async {
    return _repository.createExpense(
      homeId: params.homeId,
      amount: params.amount,
      description: params.description,
      date: params.date,
      categoryId: params.categoryId,
      paidBy: params.paidBy,
      shoppingListItemId: params.shoppingListItemId,
      currencyCode: params.currencyCode,
      convertedAmount: params.convertedAmount,
    );
  }
}

class AddExpenseParams {
  final String homeId;
  final int amount;
  final String description;
  final DateTime date;
  final String? categoryId;
  final String paidBy;
  final String? shoppingListItemId;
  final String currencyCode;
  final int convertedAmount;

  const AddExpenseParams({
    required this.homeId,
    required this.amount,
    required this.description,
    required this.date,
    this.categoryId,
    required this.paidBy,
    this.shoppingListItemId,
    this.currencyCode = 'TRY',
    required this.convertedAmount,
  });
}
