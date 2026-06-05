enum SyncStatus {
  pending,
  syncing,
  failed;

  String get displayName {
    switch (this) {
      case SyncStatus.pending:
        return 'Pending';
      case SyncStatus.syncing:
        return 'Syncing';
      case SyncStatus.failed:
        return 'Failed';
    }
  }

  String get translationKey => 'sync_status_$name';
}
