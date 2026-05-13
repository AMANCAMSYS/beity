import '../../data/repositories/offline_queue_repository.dart';

class GetPendingCountUseCase {
  final OfflineQueueRepository repository;

  GetPendingCountUseCase(this.repository);

  Future<int> execute(String homeId) {
    return repository.getPendingCount(homeId);
  }
}
