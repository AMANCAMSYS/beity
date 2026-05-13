import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/expense_model.dart';
import '../models/expense_split_model.dart';

class ExpenseRemoteDataSource {
  final SupabaseClient _client;

  ExpenseRemoteDataSource(this._client);

  Future<List<ExpenseModel>> getExpenses({
    required String homeId,
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
    String? memberId,
  }) async {
    var query = _client
        .from('expenses')
        .select()
        .eq('home_id', homeId)
        .filter('deleted_at', 'is', null);

    if (startDate != null) {
      query = query.gte('date', startDate.toIso8601String().split('T')[0]);
    }
    if (endDate != null) {
      query = query.lte('date', endDate.toIso8601String().split('T')[0]);
    }
    if (categoryId != null) {
      query = query.eq('category_id', categoryId);
    }
    if (memberId != null) {
      query = query.eq('paid_by', memberId);
    }

    final response = await query.order('date', ascending: false);
    return (response as List)
        .map((json) => ExpenseModel.fromJson(json))
        .toList();
  }

  Future<ExpenseModel?> getExpenseById({
    required String expenseId,
  }) async {
    final response = await _client
        .from('expenses')
        .select()
        .eq('id', expenseId)
        .filter('deleted_at', 'is', null)
        .maybeSingle();

    if (response == null) return null;
    return ExpenseModel.fromJson(response);
  }

  Future<ExpenseModel> createExpense({
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
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('يجب تسجيل الدخول أولاً');
    }

    final response = await _client
        .from('expenses')
        .insert({
          'home_id': homeId,
          'amount': amount,
          'description': description,
          'date': date.toIso8601String().split('T')[0],
          'category_id': categoryId,
          'paid_by': paidBy,
          'shopping_list_item_id': shoppingListItemId,
          'currency_code': currencyCode,
          'converted_amount': convertedAmount,
          'created_by': user.id,
        })
        .select()
        .single();

    return ExpenseModel.fromJson(response);
  }

  Future<ExpenseModel> updateExpense({
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
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('يجب تسجيل الدخول أولاً');
    }

    final updates = <String, dynamic>{};
    if (amount != null) updates['amount'] = amount;
    if (description != null) updates['description'] = description;
    if (date != null) updates['date'] = date.toIso8601String().split('T')[0];
    if (categoryId != null) updates['category_id'] = categoryId;
    if (paidBy != null) updates['paid_by'] = paidBy;
    if (shoppingListItemId != null) {
      updates['shopping_list_item_id'] = shoppingListItemId;
    }
    if (currencyCode != null) updates['currency_code'] = currencyCode;
    if (convertedAmount != null) updates['converted_amount'] = convertedAmount;

    final response = await _client
        .from('expenses')
        .update(updates)
        .eq('id', expenseId)
        .select()
        .single();

    return ExpenseModel.fromJson(response);
  }

  Future<void> deleteExpense({
    required String expenseId,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('يجب تسجيل الدخول أولاً');
    }

    await _client
        .from('expenses')
        .update({
          'deleted_at': DateTime.now().toIso8601String(),
          'status': 'cancelled',
        })
        .eq('id', expenseId);
  }

  Future<List<ExpenseSplitModel>> getExpenseSplits({
    required String expenseId,
  }) async {
    final response = await _client
        .from('expense_splits')
        .select()
        .eq('expense_id', expenseId);

    return (response as List)
        .map((json) => ExpenseSplitModel.fromJson(json))
        .toList();
  }

  Future<List<ExpenseSplitModel>> createExpenseSplits({
    required String expenseId,
    required List<({String memberId, int amount})> splits,
  }) async {
    final inserts = splits
        .map((split) => {
              'expense_id': expenseId,
              'member_id': split.memberId,
              'amount': split.amount,
            })
        .toList();

    final response =
        await _client.from('expense_splits').insert(inserts).select();

    return (response as List)
        .map((json) => ExpenseSplitModel.fromJson(json))
        .toList();
  }

  Future<void> deleteExpenseSplits({
    required String expenseId,
  }) async {
    await _client
        .from('expense_splits')
        .delete()
        .eq('expense_id', expenseId);
  }

  Future<int> getExpenseTotal({
    required String homeId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    var query = _client
        .from('expenses')
        .select('converted_amount')
        .eq('home_id', homeId)
        .eq('status', 'active')
        .filter('deleted_at', 'is', null);

    if (startDate != null) {
      query = query.gte('date', startDate.toIso8601String().split('T')[0]);
    }
    if (endDate != null) {
      query = query.lte('date', endDate.toIso8601String().split('T')[0]);
    }

    final response = await query;
    return (response as List)
        .fold<int>(0, (sum, json) => sum + (json['converted_amount'] as int));
  }

  Stream<List<ExpenseModel>> watchExpenses({
    required String homeId,
  }) {
    return _client
        .from('expenses')
        .stream(primaryKey: ['id'])
        .eq('home_id', homeId)
        .order('date', ascending: false)
        .map((response) => response
            .map((json) => ExpenseModel.fromJson(json))
            .where((expense) => expense.deletedAt == null)
            .toList());
  }
}
