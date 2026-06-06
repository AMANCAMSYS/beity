import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/task_comment_model.dart';

class TaskCommentRemoteDataSource {
  final SupabaseClient _client;

  TaskCommentRemoteDataSource(this._client);

  Future<List<TaskCommentModel>> getComments({required String taskId}) async {
    final response = await _client
        .from('task_comments')
        .select()
        .eq('task_id', taskId)
        .order('created_at', ascending: true);

    return (response as List)
        .map((json) => TaskCommentModel.fromJson(json))
        .toList();
  }

  Future<TaskCommentModel> addComment({
    required String taskId,
    required String content,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('must_login_first');
    }

    final response = await _client
        .from('task_comments')
        .insert({'task_id': taskId, 'content': content, 'created_by': user.id})
        .select()
        .single();

    return TaskCommentModel.fromJson(response);
  }

  Future<void> deleteComment({required String commentId}) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('must_login_first');
    }

    await _client
        .from('task_comments')
        .delete()
        .eq('id', commentId)
        .eq('created_by', user.id);
  }

  Stream<List<TaskCommentModel>> watchComments({required String taskId}) {
    return _client
        .from('task_comments')
        .stream(primaryKey: ['id'])
        .eq('task_id', taskId)
        .order('created_at', ascending: true)
        .map(
          (response) =>
              response.map((json) => TaskCommentModel.fromJson(json)).toList(),
        );
  }
}
