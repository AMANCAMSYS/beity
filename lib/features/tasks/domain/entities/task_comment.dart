class TaskComment {
  final String id;
  final String taskId;
  final String content;
  final String createdBy;
  final DateTime? createdAt;

  const TaskComment({
    required this.id,
    required this.taskId,
    required this.content,
    required this.createdBy,
    this.createdAt,
  });

  TaskComment copyWith({
    String? id,
    String? taskId,
    String? content,
    String? createdBy,
    DateTime? createdAt,
  }) {
    return TaskComment(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      content: content ?? this.content,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
