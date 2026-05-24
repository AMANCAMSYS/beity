import '../entities/task.dart';

abstract class TaskRepository {
  Future<List<Task>> getTasks({
    required String homeId,
    String? assignedTo,
    String? status,
    bool activeOnly = true,
  });

  Future<Task?> getTaskById({
    required String taskId,
  });

  Future<Task> createTask({
    required String homeId,
    required String title,
    String? description,
    DateTime? dueDate,
    String? categoryId,
    String? assignedTo,
    String? recurrenceType,
  });

  Future<Task> updateTask({
    required String taskId,
    String? title,
    String? description,
    DateTime? dueDate,
    String? categoryId,
    String? assignedTo,
    String? recurrenceType,
  });

  Future<Task> updateTaskAssignee({
    required String taskId,
    required String? assignedTo,
  });

  Future<void> deleteTask({
    required String taskId,
  });

  Future<Task> completeTask({
    required String taskId,
  });

  Future<Task> uncompleteTask({
    required String taskId,
  });

  Future<String?> createNextRecurringTask({
    required String taskId,
  });

  Future<void> archiveOldCompletedTasks();

  Stream<List<Task>> watchTasks({
    required String homeId,
    String? assignedTo,
    bool activeOnly = true,
  });
}
