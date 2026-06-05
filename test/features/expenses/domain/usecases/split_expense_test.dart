import 'package:sawa/features/expenses/domain/usecases/split_expense.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SplitExpense', () {
    test('calculates equal splits and assigns remainder to payer', () {
      final splits = SplitExpense.calculateEqualSplits(
        totalAmount: 10000,
        memberIds: ['user1', 'user2', 'user3'],
        payerId: 'user2',
      );

      expect(splits, [
        (memberId: 'user1', amount: 3333),
        (memberId: 'user2', amount: 3334),
        (memberId: 'user3', amount: 3333),
      ]);
      expect(splits.fold<int>(0, (sum, split) => sum + split.amount), 10000);
    });

    test('returns empty splits for empty members', () {
      final splits = SplitExpense.calculateEqualSplits(
        totalAmount: 10000,
        memberIds: const [],
        payerId: 'user1',
      );

      expect(splits, isEmpty);
    });

    test(
      'assigns remainder to first selected member when payer is excluded',
      () {
        final splits = SplitExpense.calculateEqualSplits(
          totalAmount: 10001,
          memberIds: ['user1', 'user3'],
          payerId: 'user2',
        );

        expect(splits, [
          (memberId: 'user1', amount: 5001),
          (memberId: 'user3', amount: 5000),
        ]);
        expect(splits.fold<int>(0, (sum, split) => sum + split.amount), 10001);
      },
    );

    test('builds custom splits from member amounts', () {
      final splits = SplitExpense.calculateCustomSplits(
        memberAmounts: {'user1': 7000, 'user2': 3000},
      );

      expect(splits, [
        (memberId: 'user1', amount: 7000),
        (memberId: 'user2', amount: 3000),
      ]);
    });

    test('validates split totals exactly in cents', () {
      expect(
        SplitExpense.validateSplits(
          totalAmount: 10000,
          splits: const [
            (memberId: 'user1', amount: 5000),
            (memberId: 'user2', amount: 5000),
          ],
        ),
        isTrue,
      );

      expect(
        SplitExpense.validateSplits(
          totalAmount: 10000,
          splits: const [
            (memberId: 'user1', amount: 4999),
            (memberId: 'user2', amount: 5000),
          ],
        ),
        isFalse,
      );
    });
  });
}
