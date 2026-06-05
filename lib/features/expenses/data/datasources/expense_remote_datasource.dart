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

  Future<ExpenseModel?> getExpenseById({required String expenseId}) async {
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
    String currencyCode = 'TRY',
    required int convertedAmount,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('must_login_first');
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

  Future<ExpenseModel> createExpenseWithSplits({
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
    final response = await _client.rpc(
      'create_expense_with_splits',
      params: {
        'p_home_id': homeId,
        'p_amount': amount,
        'p_description': description,
        'p_date': date.toIso8601String().split('T')[0],
        'p_paid_by': paidBy,
        'p_converted_amount': convertedAmount,
        'p_category_id': categoryId,
        'p_shopping_list_item_id': shoppingListItemId,
        'p_currency_code': currencyCode,
        'p_splits': splits
            .map(
              (split) => {'member_id': split.memberId, 'amount': split.amount},
            )
            .toList(),
      },
    );

    return ExpenseModel.fromJson(Map<String, dynamic>.from(response as Map));
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
      throw Exception('must_login_first');
    }

    final updates = <String, dynamic>{'updated_by': user.id};
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

  Future<void> deleteExpense({required String expenseId}) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('must_login_first');
    }

    await _client
        .from('expenses')
        .update({
          'deleted_at': DateTime.now().toIso8601String(),
          'status': 'cancelled',
          'updated_by': user.id,
          'cancelled_by': user.id,
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
        .map(
          (split) => {
            'expense_id': expenseId,
            'member_id': split.memberId,
            'amount': split.amount,
          },
        )
        .toList();

    final response = await _client
        .from('expense_splits')
        .insert(inserts)
        .select();

    return (response as List)
        .map((json) => ExpenseSplitModel.fromJson(json))
        .toList();
  }

  Future<void> deleteExpenseSplits({required String expenseId}) async {
    await _client.from('expense_splits').delete().eq('expense_id', expenseId);
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
    return (response as List<dynamic>).fold<int>(
      0,
      (sum, json) {
        final map = json as Map<String, dynamic>;
        return sum + (map['converted_amount'] as int);
      },
    );
  }

  Stream<List<ExpenseModel>> watchExpenses({required String homeId}) {
    return _client
        .from('expenses')
        .stream(primaryKey: ['id'])
        .eq('home_id', homeId)
        .order('date', ascending: false)
        .map(
          (response) => response
              .map((json) => ExpenseModel.fromJson(json))
              .where((expense) => expense.deletedAt == null)
              .toList(),
        );
  }
}
