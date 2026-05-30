import '../entities/expense_split.dart';
import '../repositories/expense_repository.dart';

class SplitExpense {
  final ExpenseRepository _repository;

  SplitExpense(this._repository);

  Future<List<ExpenseSplit>> call(SplitExpenseParams params) async {
    // Delete existing splits
    await _repository.deleteExpenseSplits(expenseId: params.expenseId);

    // If only one member, treat as personal expense (no splits)
    if (params.splits.length <= 1) {
      return [];
    }

    // Create new splits
    return _repository.createExpenseSplits(
      expenseId: params.expenseId,
      splits: params.splits,
    );
  }

  static List<({String memberId, int amount})> calculateEqualSplits({
    required int totalAmount,
    required List<String> memberIds,
    required String payerId,
  }) {
    if (memberIds.isEmpty) return [];

    final baseAmount = totalAmount ~/ memberIds.length;
    final remainder = totalAmount % memberIds.length;
    final remainderMember = memberIds.contains(payerId)
        ? payerId
        : memberIds.first;

    return memberIds.map((memberId) {
      final amount = memberId == remainderMember
          ? baseAmount + remainder
          : baseAmount;
      return (memberId: memberId, amount: amount);
    }).toList();
  }

  static List<({String memberId, int amount})> calculateCustomSplits({
    required Map<String, int> memberAmounts,
  }) {
    return memberAmounts.entries
        .map((entry) => (memberId: entry.key, amount: entry.value))
        .toList();
  }

  static bool validateSplits({
    required int totalAmount,
    required List<({String memberId, int amount})> splits,
  }) {
    final splitsTotal = splits.fold<int>(0, (sum, split) => sum + split.amount);
    return splitsTotal == totalAmount;
  }
}

class SplitExpenseParams {
  final String expenseId;
  final List<({String memberId, int amount})> splits;

  const SplitExpenseParams({required this.expenseId, required this.splits});
}
