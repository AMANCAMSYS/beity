import '../entities/task.dart';
import '../repositories/task_repository.dart';

class AssignTask {
  final TaskRepository _repository;

  AssignTask(this._repository);

  Future<Task> call(AssignTaskParams params) async {
    return _repository.updateTask(
      taskId: params.taskId,
      assignedTo: params.assignedTo,
    );
  }
}

class AssignTaskParams {
  final String taskId;
  final String? assignedTo;

  const AssignTaskParams({required this.taskId, this.assignedTo});
}
