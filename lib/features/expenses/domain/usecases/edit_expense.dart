import '../entities/expense.dart';
import '../repositories/expense_repository.dart';

class EditExpense {
  final ExpenseRepository _repository;

  EditExpense(this._repository);

  Future<Expense> call(EditExpenseParams params) async {
    return _repository.updateExpense(
      expenseId: params.expenseId,
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

class EditExpenseParams {
  final String expenseId;
  final int? amount;
  final String? description;
  final DateTime? date;
  final String? categoryId;
  final String? paidBy;
  final String? shoppingListItemId;
  final String? currencyCode;
  final int? convertedAmount;

  const EditExpenseParams({
    required this.expenseId,
    this.amount,
    this.description,
    this.date,
    this.categoryId,
    this.paidBy,
    this.shoppingListItemId,
    this.currencyCode,
    this.convertedAmount,
  });
}
