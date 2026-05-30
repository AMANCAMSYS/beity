import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:beity/core/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:beity/core/services/sync_service.dart';
import 'package:beity/core/services/local_cache_notifier.dart';
import '../../data/datasources/expense_remote_datasource.dart';
import '../../data/repositories/expense_repository_impl.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/expense_split.dart';
import '../../domain/repositories/expense_repository.dart';
import '../../domain/usecases/get_expense_summary.dart';
import '../../data/datasources/expense_local_datasource.dart';

final expenseRemoteDataSourceProvider = Provider<ExpenseRemoteDataSource>((ref) {
  final client = SupabaseService.client;
  return ExpenseRemoteDataSource(client);
});

final expenseLocalDataSourceProvider = Provider<ExpenseLocalDataSource>((ref) {
  return SharedPreferencesExpenseLocalDataSource();
});

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  final dataSource = ref.watch(expenseRemoteDataSourceProvider);
  final localDataSource = ref.watch(expenseLocalDataSourceProvider);
  final syncService = ref.watch(syncServiceProvider);
  return ExpenseRepositoryImpl(dataSource, localDataSource, syncService);
});

final expensesProvider =
    StreamProvider.autoDispose.family<List<Expense>, String>((ref, homeId) {
  if (homeId.isEmpty) {
    return Stream.value([]);
  }
  final repository = ref.watch(expenseRepositoryProvider);
  return repository.watchExpenses(homeId: homeId);
});

final expenseByIdProvider =
    FutureProvider.family<Expense?, String>((ref, expenseId) async {
  final repository = ref.watch(expenseRepositoryProvider);
  return repository.getCachedExpenseById(expenseId: expenseId);
});

final expenseSplitsProvider =
    FutureProvider.family<List<ExpenseSplit>, String>((ref, expenseId) async {
  final repository = ref.watch(expenseRepositoryProvider);
  return repository.getExpenseSplits(expenseId: expenseId);
});

final expenseTotalProvider =
    FutureProvider.family<int, ({String homeId, DateTime? startDate, DateTime? endDate})>(
        (ref, params) async {
  final repository = ref.watch(expenseRepositoryProvider);
  return repository.getExpenseTotal(
    homeId: params.homeId,
    startDate: params.startDate,
    endDate: params.endDate,
  );
});

final initialSyncCompletedExpensesProvider = StreamProvider.autoDispose.family<bool, String>((ref, homeId) async* {
  final repository = ref.watch(expenseRepositoryProvider);
  yield await repository.isInitialSyncCompleted(homeId: homeId);
  
  await for (final event in LocalCacheNotifier.stream) {
    if (event.homeId == homeId && event.entityType == 'expenses') {
      yield await repository.isInitialSyncCompleted(homeId: homeId);
    }
  }
});

final expenseSummaryProvider = Provider.autoDispose.family<AsyncValue<ExpenseSummary>, ({String homeId, DateTime? startDate, DateTime? endDate})>((ref, params) {
  final expensesAsync = ref.watch(expensesProvider(params.homeId));
  
  return expensesAsync.when(
    data: (expenses) {
      final filteredExpenses = expenses.where((e) {
        if (params.startDate != null) {
          final startOfDay = DateTime(params.startDate!.year, params.startDate!.month, params.startDate!.day);
          if (e.date.isBefore(startOfDay)) return false;
        }
        if (params.endDate != null) {
          final endOfDay = DateTime(params.endDate!.year, params.endDate!.month, params.endDate!.day, 23, 59, 59, 999);
          if (e.date.isAfter(endOfDay)) return false;
        }
        return true;
      }).toList();
      
      final totalAmount = filteredExpenses.fold<int>(0, (sum, expense) => sum + expense.convertedAmount);
      final categoryBreakdown = <String, int>{};
      final memberBreakdown = <String, int>{};

      for (final expense in filteredExpenses) {
        final categoryId = expense.categoryId ?? 'uncategorized';
        categoryBreakdown[categoryId] = (categoryBreakdown[categoryId] ?? 0) + expense.convertedAmount;
        memberBreakdown[expense.paidBy] = (memberBreakdown[expense.paidBy] ?? 0) + expense.convertedAmount;
      }

      return AsyncValue.data(ExpenseSummary(
        totalAmount: totalAmount,
        expenseCount: filteredExpenses.length,
        categoryBreakdown: categoryBreakdown,
        memberBreakdown: memberBreakdown,
      ));
    },
    loading: () => const AsyncValue.loading(),
    error: (err, stack) => AsyncValue.error(err, stack),
  );
});
