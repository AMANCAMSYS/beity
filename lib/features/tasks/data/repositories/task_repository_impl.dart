import '../../../../core/services/sync_service.dart';
import '../../../../core/services/local_cache_notifier.dart';
import '../../domain/entities/task.dart';
import '../../domain/repositories/task_repository.dart';
import '../datasources/task_remote_datasource.dart';
import '../datasources/task_local_datasource.dart';

class TaskRepositoryImpl implements TaskRepository {
  final TaskRemoteDataSource _remoteDataSource;
  final TaskLocalDataSource _localDataSource;
  final SyncService _syncService;

  TaskRepositoryImpl(
    this._remoteDataSource,
    this._localDataSource,
    this._syncService,
  );

  @override
  Future<List<Task>> getTasks({
    required String homeId,
    String? assignedTo,
    String? status,
    bool activeOnly = true,
  }) async {
    // 1. Try to load from local cache first (Instant perceived loading)
    final cached = await _localDataSource.getTasks(
      homeId: homeId,
      assignedTo: assignedTo,
      activeOnly: activeOnly,
    );
    if (cached.isNotEmpty) {
      return cached;
    }

    // 2. Fallback to remote fetch only if cache is completely empty (first run)
    try {
      final tasks = await _remoteDataSource.getTasks(
        homeId: homeId,
        assignedTo: assignedTo,
        status: status,
        activeOnly: activeOnly,
      );

      // Save to local cache
      await _localDataSource.saveTasks(
        homeId: homeId,
        assignedTo: assignedTo,
        activeOnly: activeOnly,
        tasks: tasks,
      );

      // Also update general stream cache for watching tasks
      if (assignedTo == null && status == null && activeOnly == true) {
        await _localDataSource.saveTasksStreamCache(
          homeId: homeId,
          assignedTo: null,
          activeOnly: true,
          tasks: tasks,
        );
      }

      return tasks;
    } catch (e) {
      // Return empty if offline and first fetch fails
      return [];
    }
  }

  @override
  Future<Task?> getTaskById({
    required String taskId,
  }) async {
    // Read from remote (detail pages can be fetch on demand or local-first later)
    return _remoteDataSource.getTaskById(taskId: taskId);
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
    return _remoteDataSource.createTask(
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
    return _remoteDataSource.updateTask(
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
  Future<Task> updateTaskAssignee({
    required String taskId,
    required String? assignedTo,
  }) async {
    return _remoteDataSource.updateTaskAssignee(
      taskId: taskId,
      assignedTo: assignedTo,
    );
  }

  @override
  Future<void> deleteTask({
    required String taskId,
  }) async {
    return _remoteDataSource.deleteTask(taskId: taskId);
  }

  @override
  Future<Task> completeTask({
    required String taskId,
  }) async {
    return _remoteDataSource.completeTask(taskId: taskId);
  }

  @override
  Future<Task> uncompleteTask({
    required String taskId,
  }) async {
    return _remoteDataSource.uncompleteTask(taskId: taskId);
  }

  @override
  Future<String?> createNextRecurringTask({
    required String taskId,
  }) async {
    return _remoteDataSource.createNextRecurringTask(taskId: taskId);
  }

  @override
  Future<void> archiveOldCompletedTasks() async {
    return _remoteDataSource.archiveOldCompletedTasks();
  }

  @override
  Stream<List<Task>> watchTasks({
    required String homeId,
    String? assignedTo,
    bool activeOnly = true,
  }) async* {
    // Helper function to read the stream cache
    Future<List<Task>> loadCache() async {
      return _localDataSource.getTasksStreamCache(
        homeId: homeId,
        assignedTo: assignedTo,
        activeOnly: activeOnly,
      );
    }

    // 1. Emit cached tasks instantly (0 network requests, instant perceived loading)
    yield await loadCache();

    // 2. React to local cache updates from background sync or local alterations
    await for (final event in LocalCacheNotifier.stream) {
      if (event.homeId == homeId && event.entityType == 'tasks') {
        yield await loadCache();
      }
    }
  }

  @override
  Future<void> syncTasksWithServer(String homeId) async {
    try {
      final serverUpdates = await _syncService.getServerLastUpdates(homeId);
      final serverTasksMaxUpdate = serverUpdates['tasks'];

      if (serverTasksMaxUpdate != null) {
        final localSyncTime = _syncService.getLocalSyncTime(homeId, 'tasks');
        final cachedTasks = await _localDataSource.getTasksStreamCache(
          homeId: homeId,
          assignedTo: null,
          activeOnly: true,
        );
        final isCacheEmpty = cachedTasks.isEmpty;

        // Delta Sync check: Only pull if the server has newer updates OR local cache is empty!
        if (isCacheEmpty || serverTasksMaxUpdate.isAfter(localSyncTime)) {
          final tasks = await _remoteDataSource.getTasks(
            homeId: homeId,
            assignedTo: null,
            status: null,
            activeOnly: true,
          );

          // 1. Save pulled tasks into the local stream cache
          await _localDataSource.saveTasksStreamCache(
            homeId: homeId,
            assignedTo: null,
            activeOnly: true,
            tasks: tasks,
          );

          // 2. Save pulled tasks into standard filtered cache
          await _localDataSource.saveTasks(
            homeId: homeId,
            assignedTo: null,
            activeOnly: true,
            tasks: tasks,
          );

          // 3. Update the local sync time
          DateTime maxTs = DateTime.fromMillisecondsSinceEpoch(0);
          for (final t in tasks) {
            if (t.updatedAt != null && t.updatedAt!.isAfter(maxTs)) {
              maxTs = t.updatedAt!;
            }
            if (t.createdAt != null && t.createdAt!.isAfter(maxTs)) {
              maxTs = t.createdAt!;
            }
          }
          if (maxTs.year > 1970) {
            await _syncService.updateLocalSyncTime(homeId, 'tasks', maxTs);
          } else {
            await _syncService.updateLocalSyncTime(homeId, 'tasks', DateTime.now());
          }

          // 4. Notify all reactive UI streams that tasks cache changed
          LocalCacheNotifier.notify(homeId, 'tasks');
        }
      }
    } catch (_) {
      // Absorb sync failures so other parallel sync domains can continue
      rethrow;
    }
  }
}
