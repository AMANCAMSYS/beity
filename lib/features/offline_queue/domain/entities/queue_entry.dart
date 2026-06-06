import 'package:uuid/uuid.dart';
import 'action_type.dart';
import 'entity_type.dart';
import 'sync_status.dart';

enum MutationScope {
  home,
  user,
  global;

  @Deprecated('Use translationKey with context.translate() instead')
  String get displayName => translationKey;

  String get translationKey => 'mutation_scope_$name';
}

class QueueEntry {
  final int? id;
  final ActionType actionType;
  final EntityType entityType;
  final String entityId;
  final String? homeId;
  final MutationScope scope;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final SyncStatus syncStatus;
  final int retryCount;
  final DateTime? lastRetryAt;
  final String? errorMessage;
  final String idempotencyKey;

  QueueEntry({
    this.id,
    required this.actionType,
    required this.entityType,
    required this.entityId,
    this.homeId,
    this.scope = MutationScope.home,
    required this.payload,
    required this.createdAt,
    this.syncStatus = SyncStatus.pending,
    this.retryCount = 0,
    this.lastRetryAt,
    this.errorMessage,
    String? idempotencyKey,
  }) : idempotencyKey = idempotencyKey ?? const Uuid().v4();

  QueueEntry copyWith({
    int? id,
    ActionType? actionType,
    EntityType? entityType,
    String? entityId,
    String? homeId,
    MutationScope? scope,
    Map<String, dynamic>? payload,
    DateTime? createdAt,
    SyncStatus? syncStatus,
    int? retryCount,
    DateTime? lastRetryAt,
    String? errorMessage,
    String? idempotencyKey,
  }) {
    return QueueEntry(
      id: id ?? this.id,
      actionType: actionType ?? this.actionType,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      homeId: homeId ?? this.homeId,
      scope: scope ?? this.scope,
      payload: payload ?? this.payload,
      createdAt: createdAt ?? this.createdAt,
      syncStatus: syncStatus ?? this.syncStatus,
      retryCount: retryCount ?? this.retryCount,
      lastRetryAt: lastRetryAt ?? this.lastRetryAt,
      errorMessage: errorMessage ?? this.errorMessage,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
    );
  }

  bool get isPending => syncStatus == SyncStatus.pending;
  bool get isSyncing => syncStatus == SyncStatus.syncing;
  bool get isFailed => syncStatus == SyncStatus.failed;

  static const int maxRetries = 5;

  bool get canRetry => isFailed && retryCount < maxRetries;
  bool get hasExhaustedRetries => retryCount >= maxRetries;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'actionType': actionType.index,
      'entityType': entityType.index,
      'entityId': entityId,
      'homeId': homeId,
      'scope': scope.name,
      'payload': payload,
      'createdAt': createdAt.toIso8601String(),
      'syncStatus': syncStatus.index,
      'retryCount': retryCount,
      'lastRetryAt': lastRetryAt?.toIso8601String(),
      'errorMessage': errorMessage,
      'idempotencyKey': idempotencyKey,
    };
  }

  factory QueueEntry.fromJson(Map<String, dynamic> json) {
    return QueueEntry(
      id: json['id'] as int?,
      actionType: ActionType.values[json['actionType'] as int],
      entityType: EntityType.values[json['entityType'] as int],
      entityId: json['entityId'] as String,
      homeId: json['homeId'] as String?,
      scope: _parseScope(json['scope'] as String?),
      payload: json['payload'] as Map<String, dynamic>,
      createdAt: DateTime.parse(json['createdAt'] as String),
      syncStatus: SyncStatus.values[json['syncStatus'] as int],
      retryCount: json['retryCount'] as int? ?? 0,
      lastRetryAt: json['lastRetryAt'] != null
          ? DateTime.parse(json['lastRetryAt'] as String)
          : null,
      errorMessage: json['errorMessage'] as String?,
      idempotencyKey: json['idempotencyKey'] as String? ?? const Uuid().v4(),
    );
  }

  static MutationScope _parseScope(String? value) {
    if (value == null) return MutationScope.home;
    for (final s in MutationScope.values) {
      if (s.name == value) return s;
    }
    return MutationScope.home;
  }
}
