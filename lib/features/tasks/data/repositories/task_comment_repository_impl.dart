import '../../domain/entities/task_comment.dart';
import '../../domain/repositories/task_comment_repository.dart';
import '../datasources/task_comment_remote_datasource.dart';

class TaskCommentRepositoryImpl implements TaskCommentRepository {
  final TaskCommentRemoteDataSource _dataSource;

  TaskCommentRepositoryImpl(this._dataSource);

  @override
  Future<List<TaskComment>> getComments({required String taskId}) async {
    return _dataSource.getComments(taskId: taskId);
  }

  @override
  Future<TaskComment> addComment({
    required String taskId,
    required String content,
  }) async {
    return _dataSource.addComment(taskId: taskId, content: content);
  }

  @override
  Future<void> deleteComment({required String commentId}) async {
    return _dataSource.deleteComment(commentId: commentId);
  }

  @override
  Stream<List<TaskComment>> watchComments({required String taskId}) {
    return _dataSource.watchComments(taskId: taskId);
  }
}
