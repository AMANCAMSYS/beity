import 'dart:convert';
import '../../../../core/services/shared_prefs_provider.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/expense_split.dart';
import '../../domain/repositories/expense_repository.dart';
import '../datasources/expense_remote_datasource.dart';
import '../datasources/expense_local_datasource.dart';
import '../models/expense_model.dart';
import '../../../../core/services/sync_service.dart';
import '../../../../core/services/local_cache_notifier.dart';

class ExpenseRepositoryImpl implements ExpenseRepository {
  final ExpenseRemoteDataSource _remoteDataSource;
  final ExpenseLocalDataSource _localDataSource;
  final SyncService _syncService;

  ExpenseRepositoryImpl(
    this._remoteDataSource,
    this._localDataSource,
    this._syncService,
  );

  @override
  Future<List<Expense>> getExpenses({
    required String homeId,
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
    String? memberId,
  }) async {
    final allExpenses = await _localDataSource.getExpensesStreamCache(homeId: homeId);
    return allExpenses.where((e) {
      if (startDate != null) {
        final startOfDay = DateTime(startDate.year, startDate.month, startDate.day);
        if (e.date.isBefore(startOfDay)) return false;
      }
      if (endDate != null) {
        final endOfDay = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59, 999);
        if (e.date.isAfter(endOfDay)) return false;
      }
      if (categoryId != null && e.categoryId != categoryId) return false;
      if (memberId != null && e.paidBy != memberId) return false;
      return true;
    }).toList();
  }

  @override
  Future<Expense?> getExpenseById({
    required String expenseId,
  }) async {
    return getCachedExpenseById(expenseId: expenseId);
  }

  @override
  Future<Expense?> getCachedExpenseById({
    required String expenseId,
  }) async {
    try {
      final prefs = AppPreferences.instance;
      final keys = prefs.getKeys();
      for (final key in keys) {
        if (key.startsWith('cached_expenses_stream_')) {
          final jsonStr = prefs.getString(key);
          if (jsonStr != null) {
            final List<dynamic> list = jsonDecode(jsonStr) as List<dynamic>;
            for (final dynamic item in list) {
              if (item is Map<String, dynamic> && item['id'] == expenseId) {
                return ExpenseModel.fromJson(item);
              }
            }
          }
        }
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<Expense> createExpense({
    required String homeId,
    required int amount,
    required String description,
    required DateTime date,
    String? categoryId,
    required String paidBy,
    String? shoppingListItemId,
    String currencyCode = 'SAR',
    required int convertedAmount,
  }) async {
    return _remoteDataSource.createExpense(
      homeId: homeId,
      amount: amount,
      description: description,
      date: date,
      categoryId: categoryId,
      paidBy: paidBy,
      shoppingListItemId: shoppingListItemId,
      currencyCode: currencyCode,
      convertedAmount: convertedAmount,
    );
  }

  @override
  Future<Expense> createExpenseWithSplits({
    required String homeId,
    required int amount,
    required String description,
    required DateTime date,
    String? categoryId,
    required String paidBy,
    String? shoppingListItemId,
    String currencyCode = 'TRY',
    required int convertedAmount,
    List<({String memberId, int amount})> splits = const [],
  }) async {
    return _remoteDataSource.createExpenseWithSplits(
      homeId: homeId,
      amount: amount,
      description: description,
      date: date,
      categoryId: categoryId,
      paidBy: paidBy,
      shoppingListItemId: shoppingListItemId,
      currencyCode: currencyCode,
      convertedAmount: convertedAmount,
      splits: splits,
    );
  }

  @override
  Future<Expense> updateExpense({
    required String expenseId,
    int? amount,
    String? description,
    DateTime? date,
    String? categoryId,
    String? paidBy,
    String? shoppingListItemId,
    String? currencyCode,
    int? convertedAmount,
  }) async {
    return _remoteDataSource.updateExpense(
      expenseId: expenseId,
      amount: amount,
      description: description,
      date: date,
      categoryId: categoryId,
      paidBy: paidBy,
      shoppingListItemId: shoppingListItemId,
      currencyCode: currencyCode,
      convertedAmount: convertedAmount,
    );
  }

  @override
  Future<void> deleteExpense({
    required String expenseId,
  }) async {
    return _remoteDataSource.deleteExpense(expenseId: expenseId);
  }

  @override
  Future<List<ExpenseSplit>> getExpenseSplits({
    required String expenseId,
  }) async {
    return _remoteDataSource.getExpenseSplits(expenseId: expenseId);
  }

  @override
  Future<List<ExpenseSplit>> createExpenseSplits({
    required String expenseId,
    required List<({String memberId, int amount})> splits,
  }) async {
    return _remoteDataSource.createExpenseSplits(
      expenseId: expenseId,
      splits: splits,
    );
  }

  @override
  Future<void> deleteExpenseSplits({
    required String expenseId,
  }) async {
    return _remoteDataSource.deleteExpenseSplits(expenseId: expenseId);
  }

  @override
  Future<int> getExpenseTotal({
    required String homeId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final expenses = await getExpenses(
      homeId: homeId,
      startDate: startDate,
      endDate: endDate,
    );
    return expenses.fold<int>(0, (sum, e) => sum + e.convertedAmount);
  }

  @override
  Stream<List<Expense>> watchExpenses({
    required String homeId,
  }) async* {
    // 1. Emit cached expenses instantly (0 network requests, instant perceived loading)
    yield await _localDataSource.getExpensesStreamCache(homeId: homeId);

    // 2. React to local cache updates from background sync or local alterations
    await for (final event in LocalCacheNotifier.stream) {
      if (event.homeId == homeId && event.entityType == 'expenses') {
        yield await _localDataSource.getExpensesStreamCache(homeId: homeId);
      }
    }
  }

  @override
  Future<void> syncExpensesWithServer(String homeId) async {
    try {
      final serverUpdates = await _syncService.getServerLastUpdates(homeId);
      final serverExpensesMaxUpdate = serverUpdates['expenses'];

      if (serverExpensesMaxUpdate != null) {
        final localSyncTime = _syncService.getLocalSyncTime(homeId, 'expenses');
        final cachedExpenses = await _localDataSource.getExpensesStreamCache(homeId: homeId);
        final isCacheEmpty = cachedExpenses.isEmpty;

        // Delta Sync check: Only pull if the server has newer updates OR local cache is empty!
        if (isCacheEmpty || serverExpensesMaxUpdate.isAfter(localSyncTime)) {
          final expenses = await _remoteDataSource.getExpenses(homeId: homeId);

          // 1. Save pulled expenses into the local stream cache
          await _localDataSource.saveExpensesStreamCache(homeId: homeId, expenses: expenses);

          // 2. Save pulled expenses into standard filtered cache
          await _localDataSource.saveExpenses(
            homeId: homeId,
            startDate: null,
            endDate: null,
            categoryId: null,
            memberId: null,
            expenses: expenses,
          );

          // 3. Update the local sync time
          DateTime maxTs = DateTime.fromMillisecondsSinceEpoch(0);
          for (final e in expenses) {
            if (e.updatedAt != null && e.updatedAt!.isAfter(maxTs)) {
              maxTs = e.updatedAt!;
            }
            if (e.createdAt != null && e.createdAt!.isAfter(maxTs)) {
              maxTs = e.createdAt!;
            }
          }
          if (maxTs.year > 1970) {
            await _syncService.updateLocalSyncTime(homeId, 'expenses', maxTs);
          } else {
            await _syncService.updateLocalSyncTime(homeId, 'expenses', DateTime.now());
          }

          // 4. Notify reactive streams that expenses cache changed
          LocalCacheNotifier.notify(homeId, 'expenses');
        }
        await _localDataSource.setInitialSyncCompleted(homeId: homeId, completed: true);
      }
    } catch (_) {
      rethrow;
    }
  }

  @override
  Future<bool> isInitialSyncCompleted({required String homeId}) async {
    return _localDataSource.isInitialSyncCompleted(homeId: homeId);
  }

  @override
  Future<void> setInitialSyncCompleted({required String homeId, required bool completed}) async {
    await _localDataSource.setInitialSyncCompleted(homeId: homeId, completed: completed);
    LocalCacheNotifier.notify(homeId, 'expenses');
  }

  @override
  Future<void> syncExpenseByIdIfMissing({required String expenseId}) async {
    final cached = await getCachedExpenseById(expenseId: expenseId);
    if (cached == null) {
      try {
        final remote = await _remoteDataSource.getExpenseById(expenseId: expenseId);
        if (remote != null) {
          final cachedExpenses = List<ExpenseModel>.from(
            await _localDataSource.getExpensesStreamCache(homeId: remote.homeId),
          );
          if (!cachedExpenses.any((e) => e.id == remote.id)) {
            cachedExpenses.add(remote);
            await _localDataSource.saveExpensesStreamCache(
              homeId: remote.homeId,
              expenses: cachedExpenses,
            );
            LocalCacheNotifier.notify(remote.homeId, 'expenses');
          }
        }
      } catch (_) {}
    }
  }
}
