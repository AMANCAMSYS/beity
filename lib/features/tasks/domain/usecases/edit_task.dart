import '../entities/task.dart';
import '../repositories/task_repository.dart';

class EditTask {
  final TaskRepository _repository;

  EditTask(this._repository);

  Future<Task> call(EditTaskParams params) async {
    return _repository.updateTask(
      taskId: params.taskId,
      title: params.title,
      description: params.description,
      dueDate: params.dueDate,
      categoryId: params.categoryId,
      assignedTo: params.assignedTo,
      recurrenceType: params.recurrenceType,
    );
  }
}

class EditTaskParams {
  final String taskId;
  final String? title;
  final String? description;
  final DateTime? dueDate;
  final String? categoryId;
  final String? assignedTo;
  final String? recurrenceType;

  const EditTaskParams({
    required this.taskId,
    this.title,
    this.description,
    this.dueDate,
    this.categoryId,
    this.assignedTo,
    this.recurrenceType,
  });
}
