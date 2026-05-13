import '../entities/task_comment.dart';

abstract class TaskCommentRepository {
  Future<List<TaskComment>> getComments({
    required String taskId,
  });

  Future<TaskComment> addComment({
    required String taskId,
    required String content,
  });

  Future<void> deleteComment({
    required String commentId,
  });

  Stream<List<TaskComment>> watchComments({
    required String taskId,
  });
}
