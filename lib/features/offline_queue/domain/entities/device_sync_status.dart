enum DeviceSyncStatus {
  online,
  onlineWithPending,
  offline;

  @Deprecated('Use translationKey with context.translate() instead')
  String get displayName => translationKey;

  String get translationKey {
    return switch (this) {
      DeviceSyncStatus.online => 'sync_status_online',
      DeviceSyncStatus.onlineWithPending => 'sync_status_online_pending',
      DeviceSyncStatus.offline => 'sync_status_offline',
    };
  }

  bool get isOnline => this != DeviceSyncStatus.offline;
  bool get isOffline => this == DeviceSyncStatus.offline;
}
