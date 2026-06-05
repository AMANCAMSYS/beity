import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sawa/features/shopping_mode/data/services/shopping_mode_session_recovery_service.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class QueryRecorder {
  final Map<String, dynamic> sessionUpdates = {};
  String? updatedSessionId;
  String? updatedUserId;
}

class FakeSupabaseQueryBuilder extends Fake implements SupabaseQueryBuilder {
  final String table;
  final QueryRecorder recorder;

  FakeSupabaseQueryBuilder(this.table, this.recorder);

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> select([
    String columns = '*',
  ]) {
    return FakePostgrestFilterBuilder(table, recorder);
  }

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> update(
    Map values, {
    Object? returning,
  }) {
    recorder.sessionUpdates.addAll(values.cast<String, dynamic>());
    return FakePostgrestFilterBuilder(table, recorder);
  }
}

class FakePostgrestFilterBuilder extends Fake
    implements PostgrestFilterBuilder<List<Map<String, dynamic>>> {
  final String table;
  final QueryRecorder recorder;

  FakePostgrestFilterBuilder(this.table, this.recorder);

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> eq(
    String column,
    Object value,
  ) {
    if (table == 'shopping_mode_sessions') {
      if (column == 'id') recorder.updatedSessionId = value as String;
      if (column == 'user_id') recorder.updatedUserId = value as String;
    }
    return this;
  }

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> filter(
    String column,
    String operator,
    Object? value,
  ) {
    return this;
  }

  @override
  Future<T> then<T>(
    FutureOr<T> Function(List<Map<String, dynamic>> value) onValue, {
    Function? onError,
  }) async {
    if (table == 'shopping_items') {
      return onValue([
        {'id': 'item-1'},
        {'id': 'item-2'},
      ]);
    }
    return onValue([]);
  }
}

void main() {
  test('recovers abandoned shopping mode session and clears marker', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final client = MockSupabaseClient();
    final recorder = QueryRecorder();

    when(() => client.from(any())).thenAnswer((invocation) {
      final table = invocation.positionalArguments.first as String;
      return FakeSupabaseQueryBuilder(table, recorder);
    });

    final service = ShoppingModeSessionRecoveryService(
      client: client,
      prefs: prefs,
    );

    await service.markSessionActive(
      sessionId: 'session-123',
      userId: 'user-123',
      listId: 'list-123',
      homeId: 'home-123',
      startedAt: DateTime(2026),
    );

    expect(service.getActiveSession('user-123')?.sessionId, 'session-123');

    await service.recoverAbandonedSession('user-123');

    expect(recorder.updatedSessionId, 'session-123');
    expect(recorder.updatedUserId, 'user-123');
    expect(recorder.sessionUpdates['items_purchased_count'], 2);
    expect(recorder.sessionUpdates['ended_at'], isA<String>());
    expect(service.getActiveSession('user-123'), isNull);
  });
}
