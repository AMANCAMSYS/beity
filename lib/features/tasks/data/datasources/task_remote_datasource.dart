import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/task_model.dart';

class TaskRemoteDataSource {
  final SupabaseClient _client;

  TaskRemoteDataSource(this._client);

  Future<List<TaskModel>> getTasks({
    required String homeId,
    String? assignedTo,
    String? status,
    bool activeOnly = true,
  }) async {
    var query = _client
        .from('tasks')
        .select()
        .eq('home_id', homeId)
        .filter('deleted_at', 'is', null);

    if (activeOnly) {
      query = query.filter('archived_at', 'is', null);
    }
    if (assignedTo != null) {
      query = query.eq('assigned_to', assignedTo);
    }
    if (status != null) {
      query = query.eq('status', status);
    }

    final response = await query.order('created_at', ascending: false);
    return (response as List).map((json) => TaskModel.fromJson(json)).toList();
  }

  Future<TaskModel?> getTaskById({required String taskId}) async {
    final response = await _client
        .from('tasks')
        .select()
        .eq('id', taskId)
        .filter('deleted_at', 'is', null)
        .maybeSingle();

    if (response == null) return null;
    return TaskModel.fromJson(response);
  }

  Future<TaskModel> createTask({
    required String homeId,
    required String title,
    String? description,
    DateTime? dueDate,
    String? categoryId,
    String? assignedTo,
    String? recurrenceType,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('must_login_first');
    }

    final response = await _client
        .from('tasks')
        .insert({
          'home_id': homeId,
          'title': title,
          'description': description,
          'due_date': dueDate?.toIso8601String().split('T')[0],
          'category_id': categoryId,
          'assigned_to': assignedTo,
          'recurrence_type': recurrenceType,
          'created_by': user.id,
        })
        .select()
        .single();

    return TaskModel.fromJson(response);
  }

  Future<TaskModel> updateTask({
    required String taskId,
    String? title,
    String? description,
    DateTime? dueDate,
    String? categoryId,
    String? assignedTo,
    String? recurrenceType,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('must_login_first');
    }

    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
      'updated_by': user.id,
    };
    if (title != null) updates['title'] = title;
    if (description != null) updates['description'] = description;
    if (dueDate != null) {
      updates['due_date'] = dueDate.toIso8601String().split('T')[0];
    }
    if (categoryId != null) updates['category_id'] = categoryId;
    if (assignedTo != null) updates['assigned_to'] = assignedTo;
    if (recurrenceType != null) updates['recurrence_type'] = recurrenceType;

    final response = await _client
        .from('tasks')
        .update(updates)
        .eq('id', taskId)
        .select()
        .single();

    return TaskModel.fromJson(response);
  }

  Future<TaskModel> updateTaskAssignee({
    required String taskId,
    required String? assignedTo,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('must_login_first');
    }

    final response = await _client
        .from('tasks')
        .update({
          'assigned_to': assignedTo,
          'updated_at': DateTime.now().toIso8601String(),
          'updated_by': user.id,
        })
        .eq('id', taskId)
        .select()
        .single();

    return TaskModel.fromJson(response);
  }

  Future<void> deleteTask({required String taskId}) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('must_login_first');
    }

    await _client
        .from('tasks')
        .update({
          'deleted_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
          'updated_by': user.id,
        })
        .eq('id', taskId);
  }

  Future<TaskModel> completeTask({required String taskId}) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('must_login_first');
    }

    final response = await _client
        .from('tasks')
        .update({
          'status': 'completed',
          'completed_by': user.id,
          'completed_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
          'updated_by': user.id,
        })
        .eq('id', taskId)
        .select()
        .single();

    return TaskModel.fromJson(response);
  }

  Future<TaskModel> uncompleteTask({required String taskId}) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('must_login_first');
    }

    final response = await _client
        .from('tasks')
        .update({
          'status': 'incomplete',
          'completed_by': null,
          'completed_at': null,
          'updated_at': DateTime.now().toIso8601String(),
          'updated_by': user.id,
        })
        .eq('id', taskId)
        .select()
        .single();

    return TaskModel.fromJson(response);
  }

  Future<String?> createNextRecurringTask({required String taskId}) async {
    try {
      final response = await _client.rpc(
        'create_next_recurring_task',
        params: {'p_task_id': taskId},
      );
      return response as String?;
    } catch (_) {
      // RPC does not exist yet; recurring tasks not supported in current schema
      return null;
    }
  }

  Future<void> archiveOldCompletedTasks() async {
    await _client.rpc('auto_archive_completed_tasks');
  }

  Stream<List<TaskModel>> watchTasks({
    required String homeId,
    String? assignedTo,
    bool activeOnly = true,
  }) {
    return _client
        .from('tasks')
        .stream(primaryKey: ['id'])
        .eq('home_id', homeId)
        .order('created_at', ascending: false)
        .map(
          (response) => response
              .map((json) => TaskModel.fromJson(json))
              .where(
                (task) =>
                    task.deletedAt == null &&
                    (!activeOnly || task.archivedAt == null) &&
                    (assignedTo == null || task.assignedTo == assignedTo),
              )
              .toList(),
        );
  }
}
