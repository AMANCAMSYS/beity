import '../entities/task.dart';
import '../repositories/task_repository.dart';

class ManageRecurrence {
  final TaskRepository _repository;

  ManageRecurrence(this._repository);

  Future<Task> setRecurrence(SetRecurrenceParams params) async {
    return _repository.updateTask(
      taskId: params.taskId,
      recurrenceType: params.recurrenceType,
    );
  }

  Future<Task> disableRecurrence(DisableRecurrenceParams params) async {
    return _repository.updateTask(
      taskId: params.taskId,
      recurrenceType: null,
    );
  }
}

class SetRecurrenceParams {
  final String taskId;
  final String recurrenceType;

  const SetRecurrenceParams({
    required this.taskId,
    required this.recurrenceType,
  });
}

class DisableRecurrenceParams {
  final String taskId;

  const DisableRecurrenceParams({required this.taskId});
}
