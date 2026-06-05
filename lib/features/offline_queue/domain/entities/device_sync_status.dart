enum DeviceSyncStatus {
  online,
  onlineWithPending,
  offline;

  String get displayName {
    switch (this) {
      case DeviceSyncStatus.online:
        return 'Online';
      case DeviceSyncStatus.onlineWithPending:
        return 'Online (Pending)';
      case DeviceSyncStatus.offline:
        return 'Offline';
    }
  }

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
