import 'package:sawa/core/local_database/app_database.dart';
import 'package:sawa/core/local_database/daos/shopping_mode_sessions_dao.dart';
import 'package:sawa/core/local_database/local_database_service.dart';
import 'package:sawa/features/offline_queue/data/datasources/drift_queue_datasource.dart';
import 'package:sawa/features/offline_queue/domain/entities/action_type.dart';
import 'package:sawa/features/offline_queue/domain/entities/entity_type.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/shopping_mode_session_model.dart';
import 'shopping_mode_repository.dart';

class SupabaseShoppingModeRepository implements ShoppingModeRepository {
  final SupabaseClient _client;
  final ShoppingModeSessionsDao _sessionsDao;
  final DriftQueueDataSource _queueDataSource;

  SupabaseShoppingModeRepository(
    this._client, {
    ShoppingModeSessionsDao? sessionsDao,
    DriftQueueDataSource? queueDataSource,
  }) : _sessionsDao =
           sessionsDao ??
           ShoppingModeSessionsDao(LocalDatabaseService.instance),
       _queueDataSource = queueDataSource ?? DriftQueueDataSource();

  @override
  Future<ShoppingModeSessionModel?> getActiveSession({
    required String userId,
    required String listId,
  }) async {
    final local = await _sessionsDao.getActiveSession(
      userId: userId,
      listId: listId,
    );
    if (local != null) return local;

    try {
      final response = await _client
          .from('shopping_mode_sessions')
          .select()
          .eq('user_id', userId)
          .eq('shopping_list_id', listId)
          .filter('ended_at', 'is', null)
          .maybeSingle();

      if (response == null) return null;
      final session = ShoppingModeSessionModel.fromJson(response);
      await _sessionsDao.upsertSession(session);
      return session;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<ShoppingModeSessionModel> startSession({
    required String listId,
    required String userId,
    required String homeId,
    required int itemsTotalCount,
  }) async {
    final now = DateTime.now();
    final localSession = ShoppingModeSessionModel(
      id: const Uuid().v4(),
      shoppingListId: listId,
      userId: userId,
      homeId: homeId,
      startedAt: now,
      itemsTotalCount: itemsTotalCount,
      createdAt: now,
      updatedAt: now,
    );
    await _sessionsDao.upsertSession(
      localSession,
      localState: localStatePendingCreate,
    );

    try {
      final response = await _client
          .from('shopping_mode_sessions')
          .upsert({
            'id': localSession.id,
            'shopping_list_id': listId,
            'user_id': userId,
            'home_id': homeId,
            'started_at': now.toIso8601String(),
            'items_total_count': itemsTotalCount,
          }, onConflict: 'id')
          .select()
          .single();

      final serverSession = ShoppingModeSessionModel.fromJson(response);
      await _sessionsDao.upsertSession(serverSession);
      return serverSession;
    } catch (_) {
      await _queueDataSource.enqueueAction(
        actionType: ActionType.startShoppingModeSession,
        entityType: EntityType.shoppingModeSession,
        entityId: localSession.id,
        homeId: homeId,
        payload: {
          'id': localSession.id,
          'shopping_list_id': listId,
          'user_id': userId,
          'home_id': homeId,
          'started_at': now.toIso8601String(),
          'items_total_count': itemsTotalCount,
          'items_purchased_count': 0,
        },
      );
      return localSession;
    }
  }

  @override
  Future<ShoppingModeSessionModel> endSession({
    required String sessionId,
    required int itemsPurchasedCount,
  }) async {
    final endedAt = DateTime.now();
    final localSession = await _sessionsDao.endSessionLocally(
      sessionId: sessionId,
      itemsPurchasedCount: itemsPurchasedCount,
      endedAt: endedAt,
    );

    try {
      final response = await _client
          .from('shopping_mode_sessions')
          .update({
            'ended_at': endedAt.toIso8601String(),
            'items_purchased_count': itemsPurchasedCount,
          })
          .eq('id', sessionId)
          .select()
          .single();

      final serverSession = ShoppingModeSessionModel.fromJson(response);
      await _sessionsDao.upsertSession(serverSession);
      return serverSession;
    } catch (_) {
      if (localSession == null) rethrow;

      final homeId = localSession.homeId;
      await _queueDataSource.enqueueAction(
        actionType: ActionType.endShoppingModeSession,
        entityType: EntityType.shoppingModeSession,
        entityId: sessionId,
        homeId: homeId,
        payload: {
          'id': sessionId,
          'home_id': homeId,
          'ended_at': endedAt.toIso8601String(),
          'items_purchased_count': itemsPurchasedCount,
        },
      );
      return localSession;
    }
  }
}
