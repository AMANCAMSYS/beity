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
}

/// SharedPreferences-based implementation of [TaskLocalDataSource].
class SharedPreferencesTaskLocalDataSource implements TaskLocalDataSource {
  String _getTasksKey(String homeId, String? assignedTo, bool activeOnly) =>
      'tasks_cache_${homeId}_${assignedTo ?? "all"}_$activeOnly';

  String _getStreamKey(String homeId, String? assignedTo, bool activeOnly) =>
      'cached_tasks_stream_${homeId}_${assignedTo ?? "all"}_$activeOnly';

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
}
