import '../repositories/expense_repository.dart';

class DeleteExpense {
  final ExpenseRepository _repository;

  DeleteExpense(this._repository);

  Future<void> call(DeleteExpenseParams params) async {
    return _repository.deleteExpense(expenseId: params.expenseId);
  }
}

class DeleteExpenseParams {
  final String expenseId;

  const DeleteExpenseParams({required this.expenseId});
}
