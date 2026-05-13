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

  bool get isOnline => this != DeviceSyncStatus.offline;
  bool get isOffline => this == DeviceSyncStatus.offline;
}
