import '../repositories/task_repository.dart';

class ArchiveTask {
  final TaskRepository _repository;

  ArchiveTask(this._repository);

  Future<void> call(ArchiveTaskParams params) async {
    return _repository.deleteTask(taskId: params.taskId);
  }
}

class ArchiveTaskParams {
  final String taskId;

  const ArchiveTaskParams({required this.taskId});
}
