import '../../domain/entities/device_sync_status.dart';
import '../datasources/connectivity_datasource.dart';
import 'connectivity_repository.dart';

class SupabaseConnectivityRepository implements ConnectivityRepository {
  final ConnectivityDataSource dataSource;

  SupabaseConnectivityRepository(this.dataSource);

  @override
  Future<DeviceSyncStatus> getCurrentStatus() {
    return dataSource.getCurrentStatus();
  }

  @override
  Stream<DeviceSyncStatus> get statusStream {
    return dataSource.statusStream;
  }

  @override
  Future<bool> isServerReachable() {
    return dataSource.isServerReachable();
  }
}
