import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'app_logger.dart';

enum ConnectionStatus { connected, disconnected, reconnecting }

class ConnectionStateModel {
  final ConnectionStatus status;
  final DateTime? lastConnectedAt;

  const ConnectionStateModel({required this.status, this.lastConnectedAt});

  bool get isConnected => status == ConnectionStatus.connected;
  bool get isDisconnected => status == ConnectionStatus.disconnected;
  bool get isReconnecting => status == ConnectionStatus.reconnecting;
}

class PresencePayload {
  final String userId;
  final String displayName;
  final String? avatarUrl;

  const PresencePayload({
    required this.userId,
    required this.displayName,
    this.avatarUrl,
  });

  Map<String, dynamic> toMap() => {
    'user_id': userId,
    'display_name': displayName,
    'avatar_url': avatarUrl,
  };
}

class PresenceState {
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final DateTime joinedAt;

  const PresenceState({
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    required this.joinedAt,
  });

  factory PresenceState.fromMap(Map<String, dynamic> map) {
    return PresenceState(
      userId: map['user_id'] as String? ?? '',
      displayName: map['display_name'] as String? ?? '',
      avatarUrl: map['avatar_url'] as String?,
      joinedAt: DateTime.now(),
    );
  }

  String get initials {
    final parts = displayName.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    if (displayName.isNotEmpty) {
      return displayName[0].toUpperCase();
    }
    return '?';
  }
}

// Offline queue types removed

class RealtimeService {
  final SupabaseClient _client;
  final Connectivity _connectivity = Connectivity();

  final Map<String, RealtimeChannel> _channels = {};
  final Map<String, StreamController<Map<String, PresenceState>>>
  _presenceControllers = {};

  final StreamController<ConnectionStateModel> _connectionController =
      StreamController<ConnectionStateModel>.broadcast();

  DateTime? _lastConnectedAt;
  StreamSubscription? _connectivitySubscription;
  bool _isDisposed = false;

  RealtimeService(this._client) {
    _initConnectionMonitoring();
  }

  bool get isDisposed => _isDisposed;

  Stream<ConnectionStateModel> get connectionState =>
      _connectionController.stream;

  DateTime? get lastConnectedAt => _lastConnectedAt;

  void _initConnectionMonitoring() {
    _connectionController.add(
      const ConnectionStateModel(status: ConnectionStatus.connected),
    );
    _lastConnectedAt = DateTime.now();

    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
      results,
    ) {
      if (_isDisposed) return;

      final hasConnection =
          results.isNotEmpty &&
          !results.every((r) => r == ConnectivityResult.none);

      if (hasConnection) {
        _connectionController.add(
          ConnectionStateModel(
            status: ConnectionStatus.reconnecting,
            lastConnectedAt: _lastConnectedAt,
          ),
        );

        Future.delayed(const Duration(seconds: 2), () {
          if (!_isDisposed && !_connectionController.isClosed) {
            _lastConnectedAt = DateTime.now();
            _connectionController.add(
              ConnectionStateModel(
                status: ConnectionStatus.connected,
                lastConnectedAt: _lastConnectedAt,
              ),
            );
          }
        });
      } else {
        _connectionController.add(
          const ConnectionStateModel(status: ConnectionStatus.disconnected),
        );
      }
    });
  }

  Stream<Map<String, PresenceState>> watchPresence({
    required String channelName,
    required PresencePayload userPayload,
  }) {
    if (_isDisposed) return const Stream.empty();

    if (_presenceControllers.containsKey(channelName)) {
      return _presenceControllers[channelName]!.stream;
    }

    final controller = StreamController<Map<String, PresenceState>>.broadcast();
    _presenceControllers[channelName] = controller;

    final channel = _client.channel(channelName);

    channel.onPresenceSync((_) {
      if (_isDisposed) return;
      final stateMap = <String, PresenceState>{};

      try {
        final dynamic rawState = channel.presenceState();

        if (rawState is Map) {
          final map = Map<String, dynamic>.from(rawState);
          map.forEach((key, value) {
            if (value is List && value.isNotEmpty) {
              final first = value.first;
              if (first != null) {
                final Map<String, dynamic> data = {};
                try {
                  final dynamic json = (first as dynamic).toJson();
                  if (json is Map) {
                    json.forEach((k, v) => data[k.toString()] = v);
                  }
                } catch (e) {
                  AppLogger.i(
                    '[RealtimeService] Failed to parse presence JSON: $e',
                  );
                  if (first is Map) {
                    first.forEach((k, v) => data[k.toString()] = v);
                  }
                }
                if (data.containsKey('user_id')) {
                  final ps = PresenceState.fromMap(data);
                  stateMap[ps.userId] = ps;
                }
              }
            }
          });
        }
      } catch (e) {
        AppLogger.i('[RealtimeService] Failed to read presence state: $e');
      }

      controller.add(stateMap);
    });

    channel.onPresenceJoin((_) {});
    channel.onPresenceLeave((_) {});
    channel.subscribe();

    Future.delayed(const Duration(milliseconds: 500), () {
      if (!_isDisposed) {
        channel.track(userPayload.toMap());
      }
    });

    _channels[channelName] = channel;

    return controller.stream;
  }

  void joinPresence({
    required String channelName,
    required PresencePayload userPayload,
  }) {
    final channel = _channels[channelName];
    if (channel != null) {
      channel.track(userPayload.toMap());
    }
  }

  void leavePresence({required String channelName}) {
    final channel = _channels[channelName];
    if (channel != null) {
      channel.untrack();
    }
  }

  Future<void> unsubscribeChannel(String key) async {
    final channel = _channels.remove(key);
    if (channel != null) {
      try {
        await channel.unsubscribe();
      } catch (e) {
        AppLogger.i('[RealtimeService] Failed to unsubscribe channel $key: $e');
      }
    }

    final presenceController = _presenceControllers.remove(key);
    if (presenceController != null && !presenceController.isClosed) {
      await presenceController.close();
    }
  }

  Future<void> disposeAll() async {
    _isDisposed = true;

    await _connectivitySubscription?.cancel();
    _connectivitySubscription = null;

    for (final channel in _channels.values) {
      try {
        await channel.unsubscribe();
      } catch (e) {
        AppLogger.i(
          '[RealtimeService] Failed to unsubscribe realtime channel: $e',
        );
      }
    }
    _channels.clear();

    for (final controller in _presenceControllers.values) {
      if (!controller.isClosed) {
        await controller.close();
      }
    }
    _presenceControllers.clear();

    if (!_connectionController.isClosed) {
      await _connectionController.close();
    }
  }
}
