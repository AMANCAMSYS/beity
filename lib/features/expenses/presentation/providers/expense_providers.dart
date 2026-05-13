import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/datasources/expense_remote_datasource.dart';
import '../../data/repositories/expense_repository_impl.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/expense_split.dart';
import '../../domain/repositories/expense_repository.dart';

final expenseRemoteDataSourceProvider = Provider<ExpenseRemoteDataSource>((ref) {
  final client = Supabase.instance.client;
  return ExpenseRemoteDataSource(client);
});

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  final dataSource = ref.watch(expenseRemoteDataSourceProvider);
  return ExpenseRepositoryImpl(dataSource);
});

final expensesProvider =
    StreamProvider.family<List<Expense>, String>((ref, homeId) {
  final repository = ref.watch(expenseRepositoryProvider);
  return repository.watchExpenses(homeId: homeId);
});

final expenseByIdProvider =
    FutureProvider.family<Expense?, String>((ref, expenseId) async {
  final repository = ref.watch(expenseRepositoryProvider);
  return repository.getExpenseById(expenseId: expenseId);
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
