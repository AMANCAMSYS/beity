import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sawa/core/local_database/app_database.dart';
import 'package:sawa/core/local_database/daos/shopping_mode_sessions_dao.dart';
import 'package:sawa/core/local_database/local_database_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/shared_prefs_provider.dart';
import '../../../../core/services/supabase_service.dart';
import '../models/shopping_mode_session_model.dart';

class ActiveShoppingModeSessionRecord {
  final String sessionId;
  final String userId;
  final String listId;
  final String homeId;
  final DateTime startedAt;

  const ActiveShoppingModeSessionRecord({
    required this.sessionId,
    required this.userId,
    required this.listId,
    required this.homeId,
    required this.startedAt,
  });

  factory ActiveShoppingModeSessionRecord.fromJson(Map<String, dynamic> json) {
    return ActiveShoppingModeSessionRecord(
      sessionId: json['session_id'] as String,
      userId: json['user_id'] as String,
      listId: json['list_id'] as String,
      homeId: json['home_id'] as String,
      startedAt: DateTime.parse(json['started_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'session_id': sessionId,
    'user_id': userId,
    'list_id': listId,
    'home_id': homeId,
    'started_at': startedAt.toIso8601String(),
  };
}

class ShoppingModeSessionRecoveryService {
  final SupabaseClient _client;
  final SharedPreferences _prefs;
  final ShoppingModeSessionsDao? _sessionsDao;

  ShoppingModeSessionRecoveryService({
    required SupabaseClient client,
    required SharedPreferences prefs,
    ShoppingModeSessionsDao? sessionsDao,
  }) : _client = client,
       _prefs = prefs,
       _sessionsDao = sessionsDao;

  String _key(String userId) => 'active_shopping_mode_session:$userId';

  Future<void> markSessionActive({
    required String sessionId,
    required String userId,
    required String listId,
    required String homeId,
    required DateTime startedAt,
  }) async {
    final record = ActiveShoppingModeSessionRecord(
      sessionId: sessionId,
      userId: userId,
      listId: listId,
      homeId: homeId,
      startedAt: startedAt,
    );
    await _prefs.setString(_key(userId), jsonEncode(record.toJson()));
  }

  Future<void> clearActiveSession(String userId) async {
    await _prefs.remove(_key(userId));
  }

  ActiveShoppingModeSessionRecord? getActiveSession(String userId) {
    final raw = _prefs.getString(_key(userId));
    if (raw == null || raw.isEmpty) return null;

    try {
      return ActiveShoppingModeSessionRecord.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> recoverAbandonedSession(String userId) async {
    final record =
        await _getLocalActiveSessionRecord(userId) ?? getActiveSession(userId);
    if (record == null || record.userId != userId) return;

    final endedAt = DateTime.now();
    final purchasedCount = await _getPurchasedItemsCount(record.listId);

    try {
      await _client
          .from('shopping_mode_sessions')
          .update({
            'ended_at': endedAt.toIso8601String(),
            'items_purchased_count': purchasedCount,
          })
          .eq('id', record.sessionId)
          .eq('user_id', userId)
          .filter('ended_at', 'is', null);

      await _sessionsDao?.endSessionLocally(
        sessionId: record.sessionId,
        itemsPurchasedCount: purchasedCount,
        endedAt: endedAt,
        localState: localStateSynced,
      );
      await clearActiveSession(userId);
    } catch (_) {
      await _sessionsDao?.endSessionLocally(
        sessionId: record.sessionId,
        itemsPurchasedCount: purchasedCount,
        endedAt: endedAt,
      );
      // Keep the marker so the next launch can retry recovery.
    }
  }

  Future<ActiveShoppingModeSessionRecord?> _getLocalActiveSessionRecord(
    String userId,
  ) async {
    final sessionsDao = _sessionsDao;
    if (sessionsDao == null) return null;

    try {
      final session = await sessionsDao.getActiveSessionForUser(userId);
      if (session == null) return null;
      return _recordFromSession(session);
    } catch (_) {
      return null;
    }
  }

  ActiveShoppingModeSessionRecord _recordFromSession(
    ShoppingModeSessionModel session,
  ) {
    return ActiveShoppingModeSessionRecord(
      sessionId: session.id,
      userId: session.userId,
      listId: session.shoppingListId,
      homeId: session.homeId,
      startedAt: session.startedAt,
    );
  }

  Future<int> _getPurchasedItemsCount(String listId) async {
    try {
      final response = await _client
          .from('shopping_items')
          .select('id')
          .eq('list_id', listId)
          .eq('status', 'completed')
          .filter('deleted_at', 'is', null);
      return (response as List).length;
    } catch (_) {
      return 0;
    }
  }
}

final shoppingModeSessionRecoveryServiceProvider =
    Provider<ShoppingModeSessionRecoveryService>((ref) {
      return ShoppingModeSessionRecoveryService(
        client: SupabaseService.client,
        prefs: ref.watch(sharedPrefsProvider),
        sessionsDao: ShoppingModeSessionsDao(LocalDatabaseService.instance),
      );
    });
