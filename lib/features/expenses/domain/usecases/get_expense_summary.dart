import '../repositories/expense_repository.dart';

class GetExpenseSummary {
  final ExpenseRepository _repository;

  GetExpenseSummary(this._repository);

  Future<ExpenseSummary> call(GetExpenseSummaryParams params) async {
    final expenses = await _repository.getExpenses(
      homeId: params.homeId,
      startDate: params.startDate,
      endDate: params.endDate,
    );

    final totalAmount =
        expenses.fold<int>(0, (sum, expense) => sum + expense.convertedAmount);

    final categoryBreakdown = <String, int>{};
    final memberBreakdown = <String, int>{};

    for (final expense in expenses) {
      // Category breakdown
      final categoryId = expense.categoryId ?? 'uncategorized';
      categoryBreakdown[categoryId] =
          (categoryBreakdown[categoryId] ?? 0) + expense.convertedAmount;

      // Member breakdown
      memberBreakdown[expense.paidBy] =
          (memberBreakdown[expense.paidBy] ?? 0) + expense.convertedAmount;
    }

    return ExpenseSummary(
      totalAmount: totalAmount,
      expenseCount: expenses.length,
      categoryBreakdown: categoryBreakdown,
      memberBreakdown: memberBreakdown,
    );
  }
}

class GetExpenseSummaryParams {
  final String homeId;
  final DateTime? startDate;
  final DateTime? endDate;

  const GetExpenseSummaryParams({
    required this.homeId,
    this.startDate,
    this.endDate,
  });
}

class ExpenseSummary {
  final int totalAmount;
  final int expenseCount;
  final Map<String, int> categoryBreakdown;
  final Map<String, int> memberBreakdown;

  const ExpenseSummary({
    required this.totalAmount,
    required this.expenseCount,
    required this.categoryBreakdown,
    required this.memberBreakdown,
  });

  double get averageExpense =>
      expenseCount > 0 ? totalAmount / expenseCount : 0;

  Map<String, double> get categoryPercentages {
    if (totalAmount == 0) return {};
    return categoryBreakdown.map(
      (key, value) => MapEntry(key, (value / totalAmount) * 100),
    );
  }
}
