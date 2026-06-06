import 'package:flutter_test/flutter_test.dart';
import 'package:sawa/core/services/realtime_service.dart';

void main() {
  group('ConnectionStateModel', () {
    test('connected status reports isConnected', () {
      const state = ConnectionStateModel(
        status: ConnectionStatus.connected,
        lastConnectedAt: null,
      );

      expect(state.isConnected, true);
      expect(state.isDisconnected, false);
      expect(state.isReconnecting, false);
    });

    test('disconnected status reports isDisconnected', () {
      const state = ConnectionStateModel(status: ConnectionStatus.disconnected);

      expect(state.isConnected, false);
      expect(state.isDisconnected, true);
      expect(state.isReconnecting, false);
    });

    test('reconnecting status reports isReconnecting', () {
      const state = ConnectionStateModel(status: ConnectionStatus.reconnecting);

      expect(state.isConnected, false);
      expect(state.isDisconnected, false);
      expect(state.isReconnecting, true);
    });
  });

  group('PresencePayload', () {
    test('toMap produces correct format', () {
      const payload = PresencePayload(
        userId: 'user-1',
        displayName: 'Test User',
        avatarUrl: 'https://example.com/avatar.jpg',
      );

      final map = payload.toMap();

      expect(map['user_id'], 'user-1');
      expect(map['display_name'], 'Test User');
      expect(map['avatar_url'], 'https://example.com/avatar.jpg');
    });

    test('toMap handles null avatarUrl', () {
      const payload = PresencePayload(
        userId: 'user-1',
        displayName: 'Test User',
      );

      final map = payload.toMap();

      expect(map['avatar_url'], isNull);
    });
  });

  group('PresenceState', () {
    test('fromMap creates correct state', () {
      final map = {
        'user_id': 'user-1',
        'display_name': 'John Doe',
        'avatar_url': 'https://example.com/avatar.jpg',
      };

      final state = PresenceState.fromMap(map);

      expect(state.userId, 'user-1');
      expect(state.displayName, 'John Doe');
      expect(state.avatarUrl, 'https://example.com/avatar.jpg');
    });

    test('fromMap handles missing fields gracefully', () {
      final map = <String, dynamic>{};

      final state = PresenceState.fromMap(map);

      expect(state.userId, '');
      expect(state.displayName, '');
      expect(state.avatarUrl, isNull);
    });

    test('initials returns first letter of single name', () {
      final state = PresenceState(
        userId: 'user-1',
        displayName: 'John',
        joinedAt: DateTime(2026),
      );

      expect(state.initials, 'J');
    });

    test('initials returns first letters of two names', () {
      final state = PresenceState(
        userId: 'user-1',
        displayName: 'John Doe',
        joinedAt: DateTime(2026),
      );

      expect(state.initials, 'JD');
    });

    test('initials returns ? for empty name', () {
      final state = PresenceState(
        userId: 'user-1',
        displayName: '',
        joinedAt: DateTime(2026),
      );

      expect(state.initials, '?');
    });
  });
}
