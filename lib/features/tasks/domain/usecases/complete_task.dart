import '../entities/task.dart';
import '../repositories/task_repository.dart';

class CompleteTask {
  final TaskRepository _repository;

  CompleteTask(this._repository);

  Future<Task> call(CompleteTaskParams params) async {
    final task = await _repository.completeTask(taskId: params.taskId);

    if (task.isRecurring) {
      await _repository.createNextRecurringTask(taskId: params.taskId);
    }

    return task;
  }
}

class UncompleteTask {
  final TaskRepository _repository;

  UncompleteTask(this._repository);

  Future<Task> call(UncompleteTaskParams params) async {
    return _repository.uncompleteTask(taskId: params.taskId);
  }
}

class CompleteTaskParams {
  final String taskId;

  const CompleteTaskParams({required this.taskId});
}

class UncompleteTaskParams {
  final String taskId;

  const UncompleteTaskParams({required this.taskId});
}
