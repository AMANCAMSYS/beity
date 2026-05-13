import '../../domain/entities/device_sync_status.dart';

abstract class ConnectivityRepository {
  Future<DeviceSyncStatus> getCurrentStatus();

  Stream<DeviceSyncStatus> get statusStream;

  Future<bool> isServerReachable();
}
