import 'dart:convert';
import '../../../../core/services/shared_prefs_provider.dart';
import '../models/expense_model.dart';

/// Abstract interface for local persistence of Expenses.
/// Prepares SAWA for SQLite/Drift/Isar migrations.
abstract class ExpenseLocalDataSource {
  Future<List<ExpenseModel>> getExpenses({
    required String homeId,
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
    String? memberId,
  });

  Future<void> saveExpenses({
    required String homeId,
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
    String? memberId,
    required List<ExpenseModel> expenses,
  });

  Future<List<ExpenseModel>> getExpensesStreamCache({required String homeId});

  Future<void> saveExpensesStreamCache({
    required String homeId,
    required List<ExpenseModel> expenses,
  });

  Future<void> setInitialSyncCompleted({
    required String homeId,
    required bool completed,
  });
  Future<bool> isInitialSyncCompleted({required String homeId});
}

/// SharedPreferences-based implementation of [ExpenseLocalDataSource].
class SharedPreferencesExpenseLocalDataSource
    implements ExpenseLocalDataSource {
  String _getExpensesKey(
    String homeId,
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
    String? memberId,
  ) {
    final startStr = startDate?.toIso8601String() ?? 'null';
    final endStr = endDate?.toIso8601String() ?? 'null';
    return 'cached_expenses_${homeId}_${startStr}_${endStr}_${categoryId ?? "null"}_${memberId ?? "null"}';
  }

  String _getStreamKey(String homeId) => 'cached_expenses_stream_$homeId';

  @override
  Future<List<ExpenseModel>> getExpenses({
    required String homeId,
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
    String? memberId,
  }) async {
    try {
      final prefs = AppPreferences.instance;
      final key = _getExpensesKey(
        homeId,
        startDate,
        endDate,
        categoryId,
        memberId,
      );
      final jsonStr = prefs.getString(key);
      if (jsonStr == null) return [];

      final List<dynamic> list = jsonDecode(jsonStr);
      return list.map((json) => ExpenseModel.fromJson(json)).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> saveExpenses({
    required String homeId,
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
    String? memberId,
    required List<ExpenseModel> expenses,
  }) async {
    try {
      final prefs = AppPreferences.instance;
      final key = _getExpensesKey(
        homeId,
        startDate,
        endDate,
        categoryId,
        memberId,
      );
      final jsonStr = jsonEncode(expenses.map((e) => e.toJson()).toList());
      await prefs.setString(key, jsonStr);
    } catch (_) {}
  }

  @override
  Future<List<ExpenseModel>> getExpensesStreamCache({
    required String homeId,
  }) async {
    try {
      final prefs = AppPreferences.instance;
      final key = _getStreamKey(homeId);
      final jsonStr = prefs.getString(key);
      if (jsonStr == null) return [];

      final List<dynamic> list = jsonDecode(jsonStr);
      return list.map((json) => ExpenseModel.fromJson(json)).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> saveExpensesStreamCache({
    required String homeId,
    required List<ExpenseModel> expenses,
  }) async {
    try {
      final prefs = AppPreferences.instance;
      final key = _getStreamKey(homeId);
      final jsonStr = jsonEncode(expenses.map((e) => e.toJson()).toList());
      await prefs.setString(key, jsonStr);
    } catch (_) {}
  }

  @override
  Future<void> setInitialSyncCompleted({
    required String homeId,
    required bool completed,
  }) async {
    try {
      final prefs = AppPreferences.instance;
      await prefs.setBool(
        'initial_sync_completed_expenses_home_$homeId',
        completed,
      );
    } catch (_) {}
  }

  @override
  Future<bool> isInitialSyncCompleted({required String homeId}) async {
    try {
      final prefs = AppPreferences.instance;
      return prefs.getBool('initial_sync_completed_expenses_home_$homeId') ??
          false;
    } catch (_) {
      return false;
    }
  }
}
