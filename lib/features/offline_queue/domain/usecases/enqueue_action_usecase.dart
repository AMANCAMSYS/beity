import '../../data/repositories/offline_queue_repository.dart';
import '../entities/action_type.dart';
import '../entities/entity_type.dart';
import '../entities/queue_entry.dart';

class EnqueueActionUseCase {
  final OfflineQueueRepository repository;

  EnqueueActionUseCase(this.repository);

  Future<void> execute({
    required ActionType actionType,
    required EntityType entityType,
    required String entityId,
    String? homeId,
    MutationScope scope = MutationScope.home,
    required Map<String, dynamic> payload,
  }) async {
    await repository.enqueueAction(
      actionType: actionType,
      entityType: entityType,
      entityId: entityId,
      homeId: homeId,
      scope: scope,
      payload: payload,
    );
  }
}
