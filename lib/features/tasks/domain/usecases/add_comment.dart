import '../entities/task_comment.dart';
import '../repositories/task_comment_repository.dart';

class AddComment {
  final TaskCommentRepository _repository;

  AddComment(this._repository);

  Future<TaskComment> call(AddCommentParams params) async {
    return _repository.addComment(
      taskId: params.taskId,
      content: params.content,
    );
  }
}

class AddCommentParams {
  final String taskId;
  final String content;

  const AddCommentParams({required this.taskId, required this.content});
}
