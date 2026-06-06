enum SyncStatus {
  pending,
  syncing,
  failed;

  @Deprecated('Use translationKey with context.translate() instead')
  String get displayName => translationKey;

  String get translationKey => 'sync_status_$name';
}
