import '../entities/task.dart';
import '../repositories/task_repository.dart';

class CreateTask {
  final TaskRepository _repository;

  CreateTask(this._repository);

  Future<Task> call(CreateTaskParams params) async {
    return _repository.createTask(
      homeId: params.homeId,
      title: params.title,
      description: params.description,
      dueDate: params.dueDate,
      categoryId: params.categoryId,
      assignedTo: params.assignedTo,
      recurrenceType: params.recurrenceType,
    );
  }
}

class CreateTaskParams {
  final String homeId;
  final String title;
  final String? description;
  final DateTime? dueDate;
  final String? categoryId;
  final String? assignedTo;
  final String? recurrenceType;

  const CreateTaskParams({
    required this.homeId,
    required this.title,
    this.description,
    this.dueDate,
    this.categoryId,
    this.assignedTo,
    this.recurrenceType,
  });
}
