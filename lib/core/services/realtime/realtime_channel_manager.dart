import 'package:supabase_flutter/supabase_flutter.dart';
import '../app_logger.dart';

class RealtimeChannelManager {
  final SupabaseClient _client;
  RealtimeChannel? _channel;
  String? _currentHomeId;

  RealtimeChannelManager(this._client);

  String? get currentHomeId => _currentHomeId;

  void subscribeToHome(
    String homeId,
    void Function(String table, PostgresChangePayload payload) onEvent,
  ) {
    if (homeId.isEmpty) return;
    if (_currentHomeId == homeId) return;

    unsubscribe();

    _currentHomeId = homeId;

    _channel = _client.channel('realtime_sync:$homeId');

    _channel!.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'shopping_lists',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'home_id',
        value: homeId,
      ),
      callback: (payload) => onEvent('shopping_lists', payload),
    );

    _channel!.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'shopping_items',
      callback: (payload) => onEvent('shopping_items', payload),
    );

    _channel!.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'tasks',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'home_id',
        value: homeId,
      ),
      callback: (payload) => onEvent('tasks', payload),
    );

    _channel!.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'expenses',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'home_id',
        value: homeId,
      ),
      callback: (payload) => onEvent('expenses', payload),
    );

    _channel!.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'inventory_items',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'home_id',
        value: homeId,
      ),
      callback: (payload) => onEvent('inventory_items', payload),
    );

    _channel!.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'categories',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'home_id',
        value: homeId,
      ),
      callback: (payload) => onEvent('categories', payload),
    );

    _channel!.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'home_members',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'home_id',
        value: homeId,
      ),
      callback: (payload) => onEvent('home_members', payload),
    );

    _channel!.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'notifications',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'home_id',
        value: homeId,
      ),
      callback: (payload) => onEvent('notifications', payload),
    );

    _channel!.subscribe();
  }

  void unsubscribe() {
    if (_channel != null) {
      try {
        _client.removeChannel(_channel!);
      } catch (e) {
        AppLogger.i('[RealtimeSync] removeChannel failed: $e');
      }
      _channel = null;
    }
    _currentHomeId = null;
  }
}
