import '../../domain/entities/task.dart';
import '../../domain/repositories/task_repository.dart';
import '../datasources/task_remote_datasource.dart';

class TaskRepositoryImpl implements TaskRepository {
  final TaskRemoteDataSource _dataSource;

  TaskRepositoryImpl(this._dataSource);

  @override
  Future<List<Task>> getTasks({
    required String homeId,
    String? assignedTo,
    String? status,
    bool activeOnly = true,
  }) async {
    return _dataSource.getTasks(
      homeId: homeId,
      assignedTo: assignedTo,
      status: status,
      activeOnly: activeOnly,
    );
  }

  @override
  Future<Task?> getTaskById({
    required String taskId,
  }) async {
    return _dataSource.getTaskById(taskId: taskId);
  }

  @override
  Future<Task> createTask({
    required String homeId,
    required String title,
    String? description,
    DateTime? dueDate,
    String? categoryId,
    String? assignedTo,
    String? recurrenceType,
  }) async {
    return _dataSource.createTask(
      homeId: homeId,
      title: title,
      description: description,
      dueDate: dueDate,
      categoryId: categoryId,
      assignedTo: assignedTo,
      recurrenceType: recurrenceType,
    );
  }

  @override
  Future<Task> updateTask({
    required String taskId,
    String? title,
    String? description,
    DateTime? dueDate,
    String? categoryId,
    String? assignedTo,
    String? recurrenceType,
  }) async {
    return _dataSource.updateTask(
      taskId: taskId,
      title: title,
      description: description,
      dueDate: dueDate,
      categoryId: categoryId,
      assignedTo: assignedTo,
      recurrenceType: recurrenceType,
    );
  }

  @override
  Future<void> deleteTask({
    required String taskId,
  }) async {
    return _dataSource.deleteTask(taskId: taskId);
  }

  @override
  Future<Task> completeTask({
    required String taskId,
  }) async {
    return _dataSource.completeTask(taskId: taskId);
  }

  @override
  Future<Task> uncompleteTask({
    required String taskId,
  }) async {
    return _dataSource.uncompleteTask(taskId: taskId);
  }

  @override
  Future<String?> createNextRecurringTask({
    required String taskId,
  }) async {
    return _dataSource.createNextRecurringTask(taskId: taskId);
  }

  @override
  Future<void> archiveOldCompletedTasks() async {
    return _dataSource.archiveOldCompletedTasks();
  }

  @override
  Stream<List<Task>> watchTasks({
    required String homeId,
    String? assignedTo,
    bool activeOnly = true,
  }) {
    return _dataSource.watchTasks(
      homeId: homeId,
      assignedTo: assignedTo,
      activeOnly: activeOnly,
    );
  }
}
