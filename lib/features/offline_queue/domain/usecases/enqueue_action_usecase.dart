import '../../data/repositories/offline_queue_repository.dart';
import '../entities/action_type.dart';
import '../entities/entity_type.dart';

class EnqueueActionUseCase {
  final OfflineQueueRepository repository;

  EnqueueActionUseCase(this.repository);

  Future<void> execute({
    required ActionType actionType,
    required EntityType entityType,
    required String entityId,
    required String homeId,
    required Map<String, dynamic> payload,
  }) async {
    await repository.enqueueAction(
      actionType: actionType,
      entityType: entityType,
      entityId: entityId,
      homeId: homeId,
      payload: payload,
    );
  }
}
