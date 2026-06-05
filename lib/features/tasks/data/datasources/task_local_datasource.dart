import 'dart:convert';
import '../../../../core/services/shared_prefs_provider.dart';
import '../models/task_model.dart';

/// Abstract interface for local persistence of Tasks.
/// Supports future migration to Drift/SQLite, Hive, or Isar.
abstract class TaskLocalDataSource {
  Future<List<TaskModel>> getTasks({
    required String homeId,
    String? assignedTo,
    bool activeOnly = true,
  });

  Future<void> saveTasks({
    required String homeId,
    String? assignedTo,
    bool activeOnly = true,
    required List<TaskModel> tasks,
  });

  Future<List<TaskModel>> getTasksStreamCache({
    required String homeId,
    String? assignedTo,
    bool activeOnly = true,
  });

  Future<void> saveTasksStreamCache({
    required String homeId,
    String? assignedTo,
    bool activeOnly = true,
    required List<TaskModel> tasks,
  });

  Future<TaskModel?> getCachedTaskById(String taskId);

  Future<void> updateTaskInCaches(TaskModel task);
}

/// SharedPreferences-based implementation of [TaskLocalDataSource].
class SharedPreferencesTaskLocalDataSource implements TaskLocalDataSource {
  String _getTasksKey(String homeId, String? assignedTo, bool activeOnly) =>
      'tasks_cache_${homeId}_${assignedTo ?? "all"}_$activeOnly';

  String _getStreamKey(String homeId, String? assignedTo, bool activeOnly) =>
      'cached_tasks_stream_${homeId}_${assignedTo ?? "all"}_$activeOnly';

  bool _isTaskCacheKey(String key) =>
      key.startsWith('tasks_cache_') || key.startsWith('cached_tasks_stream_');

  @override
  Future<List<TaskModel>> getTasks({
    required String homeId,
    String? assignedTo,
    bool activeOnly = true,
  }) async {
    try {
      final prefs = AppPreferences.instance;
      final key = _getTasksKey(homeId, assignedTo, activeOnly);
      final jsonStr = prefs.getString(key);
      if (jsonStr == null) return [];

      final List<dynamic> list = jsonDecode(jsonStr);
      return list.map((json) => TaskModel.fromJson(json)).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> saveTasks({
    required String homeId,
    String? assignedTo,
    bool activeOnly = true,
    required List<TaskModel> tasks,
  }) async {
    try {
      final prefs = AppPreferences.instance;
      final key = _getTasksKey(homeId, assignedTo, activeOnly);
      final jsonStr = jsonEncode(tasks.map((t) => t.toJson()).toList());
      await prefs.setString(key, jsonStr);
    } catch (_) {}
  }

  @override
  Future<List<TaskModel>> getTasksStreamCache({
    required String homeId,
    String? assignedTo,
    bool activeOnly = true,
  }) async {
    try {
      final prefs = AppPreferences.instance;
      final key = _getStreamKey(homeId, assignedTo, activeOnly);
      final jsonStr = prefs.getString(key);
      if (jsonStr == null) return [];

      final List<dynamic> list = jsonDecode(jsonStr);
      return list.map((json) => TaskModel.fromJson(json)).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> saveTasksStreamCache({
    required String homeId,
    String? assignedTo,
    bool activeOnly = true,
    required List<TaskModel> tasks,
  }) async {
    try {
      final prefs = AppPreferences.instance;
      final key = _getStreamKey(homeId, assignedTo, activeOnly);
      final jsonStr = jsonEncode(tasks.map((t) => t.toJson()).toList());
      await prefs.setString(key, jsonStr);
    } catch (_) {}
  }

  @override
  Future<TaskModel?> getCachedTaskById(String taskId) async {
    try {
      final prefs = AppPreferences.instance;
      for (final key in prefs.getKeys().where(_isTaskCacheKey)) {
        final tasks = _readTasksForKey(key);
        for (final task in tasks) {
          if (task.id == taskId) return task;
        }
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<void> updateTaskInCaches(TaskModel task) async {
    try {
      final prefs = AppPreferences.instance;
      for (final key in prefs.getKeys().where(_isTaskCacheKey)) {
        final tasks = _readTasksForKey(key);
        final index = tasks.indexWhere((cached) => cached.id == task.id);
        if (index == -1) continue;

        tasks[index] = task;
        await prefs.setString(
          key,
          jsonEncode(tasks.map((t) => t.toJson()).toList()),
        );
      }
    } catch (_) {}
  }

  List<TaskModel> _readTasksForKey(String key) {
    try {
      final jsonStr = AppPreferences.instance.getString(key);
      if (jsonStr == null) return [];

      final List<dynamic> list = jsonDecode(jsonStr);
      return list.map((json) => TaskModel.fromJson(json)).toList();
    } catch (_) {
      return [];
    }
  }
}
