import 'package:flutter_test/flutter_test.dart';
import 'package:sawa/features/expenses/domain/usecases/split_expense.dart';

void main() {
  group('SplitExpense.calculateEqualSplits', () {
    test('should split 1000 equally among 4 members', () {
      final splits = SplitExpense.calculateEqualSplits(
        totalAmount: 1000,
        memberIds: ['a', 'b', 'c', 'd'],
        payerId: 'a',
      );

      expect(splits.length, 4);
      expect(splits.fold<int>(0, (sum, s) => sum + s.amount), 1000);
      // Each gets 250
      for (final s in splits) {
        expect(s.amount, 250);
      }
    });

    test('should give remainder to payer when not evenly divisible', () {
      final splits = SplitExpense.calculateEqualSplits(
        totalAmount: 1000,
        memberIds: ['a', 'b', 'c'],
        payerId: 'a',
      );

      expect(splits.length, 3);
      expect(splits.fold<int>(0, (sum, s) => sum + s.amount), 1000);
      // Payer gets the remainder
      final payerSplit = splits.firstWhere((s) => s.memberId == 'a');
      expect(payerSplit.amount, 334); // 333 + 1
    });

    test('should give remainder to first member if payer not in list', () {
      final splits = SplitExpense.calculateEqualSplits(
        totalAmount: 100,
        memberIds: ['b', 'c', 'd'],
        payerId: 'a',
      );

      expect(splits.length, 3);
      expect(splits.fold<int>(0, (sum, s) => sum + s.amount), 100);
      // First member gets remainder
      final firstSplit = splits.firstWhere((s) => s.memberId == 'b');
      expect(firstSplit.amount, 34); // 33 + 1
    });

    test('should return empty list for empty members', () {
      final splits = SplitExpense.calculateEqualSplits(
        totalAmount: 1000,
        memberIds: [],
        payerId: 'a',
      );

      expect(splits, isEmpty);
    });

    test('should handle single member', () {
      final splits = SplitExpense.calculateEqualSplits(
        totalAmount: 500,
        memberIds: ['a'],
        payerId: 'a',
      );

      expect(splits.length, 1);
      expect(splits.first.amount, 500);
    });
  });

  group('SplitExpense.calculateCustomSplits', () {
    test('should return splits matching the input map', () {
      final splits = SplitExpense.calculateCustomSplits(
        memberAmounts: {'a': 300, 'b': 200, 'c': 500},
      );

      expect(splits.length, 3);
      expect(splits.fold<int>(0, (sum, s) => sum + s.amount), 1000);
    });
  });

  group('SplitExpense.validateSplits', () {
    test('should return true when splits match total', () {
      final result = SplitExpense.validateSplits(
        totalAmount: 1000,
        splits: [(memberId: 'a', amount: 500), (memberId: 'b', amount: 500)],
      );

      expect(result, isTrue);
    });

    test('should return false when splits do not match total', () {
      final result = SplitExpense.validateSplits(
        totalAmount: 1000,
        splits: [(memberId: 'a', amount: 500), (memberId: 'b', amount: 300)],
      );

      expect(result, isFalse);
    });

    test('should return true for zero amount with no splits', () {
      final result = SplitExpense.validateSplits(totalAmount: 0, splits: []);

      expect(result, isTrue);
    });
  });
}
