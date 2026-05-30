import 'package:flutter_test/flutter_test.dart';
import 'package:beity/features/expenses/domain/entities/balance.dart';

void main() {
  group('Balance', () {
    test('isSettled should be true when netAmount is 0', () {
      const balance = Balance(memberA: 'a', memberB: 'b', netAmount: 0);
      expect(balance.isSettled, isTrue);
    });

    test('memberAOwes should be true when netAmount is positive', () {
      const balance = Balance(memberA: 'a', memberB: 'b', netAmount: 500);
      expect(balance.memberAOwes, isTrue);
      expect(balance.memberBOwes, isFalse);
    });

    test('memberBOwes should be true when netAmount is negative', () {
      const balance = Balance(memberA: 'a', memberB: 'b', netAmount: -300);
      expect(balance.memberBOwes, isTrue);
      expect(balance.memberAOwes, isFalse);
    });

    test('getDebtor returns correct member', () {
      const balance = Balance(memberA: 'a', memberB: 'b', netAmount: 500);
      expect(balance.getDebtor(), 'a');
      expect(balance.getCreditor(), 'b');
    });

    test('getDebtor returns memberB when netAmount is negative', () {
      const balance = Balance(memberA: 'a', memberB: 'b', netAmount: -300);
      expect(balance.getDebtor(), 'b');
      expect(balance.getCreditor(), 'a');
    });

    test('absoluteAmount returns positive value', () {
      const balance = Balance(memberA: 'a', memberB: 'b', netAmount: -300);
      expect(balance.absoluteAmount, 300);
    });

    test('copyWith works correctly', () {
      const balance = Balance(memberA: 'a', memberB: 'b', netAmount: 500);
      final updated = balance.copyWith(netAmount: 0);
      expect(updated.isSettled, isTrue);
      expect(updated.memberA, 'a');
    });
  });
}
