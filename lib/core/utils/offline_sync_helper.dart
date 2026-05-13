import 'dart:async';

enum SyncStatus {
  idle,
  syncing,
  success,
  error,
}

class OfflineSyncHelper {
  final StreamController<SyncStatus> _statusController =
      StreamController<SyncStatus>.broadcast();
  
  SyncStatus _currentStatus = SyncStatus.idle;
  bool _isOnline = true;

  OfflineSyncHelper();

  Stream<SyncStatus> get syncStatusStream => _statusController.stream;
  SyncStatus get currentStatus => _currentStatus;
  bool get isOnline => _isOnline;

  void setOnlineStatus(bool online) {
    final wasOnline = _isOnline;
    _isOnline = online;
    
    if (!wasOnline && _isOnline) {
      _onConnectionRestored();
    }
  }

  void _onConnectionRestored() {
    _updateStatus(SyncStatus.syncing);
    // Trigger sync logic here
    Future.delayed(const Duration(seconds: 1), () {
      _updateStatus(SyncStatus.success);
    });
  }

  void _updateStatus(SyncStatus status) {
    _currentStatus = status;
    _statusController.add(status);
  }

  Future<bool> checkConnectivity() async {
    return _isOnline;
  }

  void dispose() {
    _statusController.close();
  }
}
