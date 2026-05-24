import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Expense Split Calculations', () {
    test('equal split with single member', () {
      final amount = 100.0;
      final members = ['user1'];
      final splits = calculateEqualSplit(amount, members);
      expect(splits['user1'], 100.0);
    });

    test('equal split with multiple members', () {
      final amount = 100.0;
      final members = ['user1', 'user2', 'user3'];
      final splits = calculateEqualSplit(amount, members);
      // 100 / 3 = 33.333... rounded to 2 decimals is 33.33
      // Total is 99.99, remainder 0.01 added to first member
      expect(splits['user1'], 33.34);
      expect(splits['user2'], 33.33);
      expect(splits['user3'], 33.33);
    });

    test('equal split with zero members throws exception or returns empty', () {
      final amount = 100.0;
      final members = <String>[];
      expect(() => calculateEqualSplit(amount, members), throwsArgumentError);
    });

    test('percentage split', () {
      final amount = 1000.0;
      final percentages = {'user1': 50.0, 'user2': 30.0, 'user3': 20.0};
      final splits = calculatePercentageSplit(amount, percentages);
      expect(splits['user1'], 500.0);
      expect(splits['user2'], 300.0);
      expect(splits['user3'], 200.0);
    });

    test('percentage split rounding', () {
      final amount = 100.0;
      final percentages = {'user1': 33.33, 'user2': 33.33, 'user3': 33.34};
      final splits = calculatePercentageSplit(amount, percentages);
      expect(splits['user1'], 33.33);
      expect(splits['user2'], 33.33);
      expect(splits['user3'], 33.34);
    });

    test('custom split validates total', () {
      final amount = 100.0;
      final customSplits = {'user1': 60.0, 'user2': 50.0};
      expect(() => validateCustomSplit(amount, customSplits), throwsArgumentError);
    });

    test('exclude cancelled expenses from total', () {
      final expenses = [
        {'id': 1, 'amount': 100.0, 'status': 'completed'},
        {'id': 2, 'amount': 50.0, 'status': 'cancelled'},
      ];
      final total = calculateActiveTotal(expenses);
      expect(total, 100.0);
    });
  });
}

// Dummy implementations to be replaced by actual implementations
Map<String, double> calculateEqualSplit(double amount, List<String> members) {
  if (members.isEmpty) throw ArgumentError('Members cannot be empty');
  double base = (amount / members.length * 100).roundToDouble() / 100;
  Map<String, double> splits = {};
  double currentTotal = 0;
  for (var i = 0; i < members.length; i++) {
    splits[members[i]] = base;
    currentTotal += base;
  }
  double diff = amount - currentTotal;
  if (diff != 0) {
    splits[members[0]] = double.parse((splits[members[0]]! + diff).toStringAsFixed(2));
  }
  return splits;
}

Map<String, double> calculatePercentageSplit(double amount, Map<String, double> percentages) {
  Map<String, double> splits = {};
  double totalPercentage = percentages.values.fold(0, (sum, p) => sum + p);
  if (totalPercentage < 99.99 || totalPercentage > 100.01) {
      throw ArgumentError('Percentages must add up to 100');
  }
  double currentTotal = 0;
  List<String> keys = percentages.keys.toList();
  for (var i = 0; i < keys.length; i++) {
    double value = (amount * (percentages[keys[i]]! / 100) * 100).roundToDouble() / 100;
    splits[keys[i]] = value;
    currentTotal += value;
  }
  double diff = amount - currentTotal;
  if (diff != 0 && keys.isNotEmpty) {
      splits[keys[0]] = double.parse((splits[keys[0]]! + diff).toStringAsFixed(2));
  }
  return splits;
}

void validateCustomSplit(double amount, Map<String, double> splits) {
  double total = splits.values.fold(0, (sum, s) => sum + s);
  if ((total - amount).abs() > 0.01) {
    throw ArgumentError('Splits must equal total amount');
  }
}

double calculateActiveTotal(List<Map<String, dynamic>> expenses) {
  return expenses
      .where((e) => e['status'] != 'cancelled')
      .fold(0.0, (sum, e) => sum + (e['amount'] as double));
}
