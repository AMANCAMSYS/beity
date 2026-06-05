import '../../../../core/services/sync_service.dart';
import '../../../../core/services/local_cache_notifier.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/supabase_service.dart';
import '../../domain/entities/task.dart';
import '../../domain/repositories/task_repository.dart';
import '../datasources/task_remote_datasource.dart';
import '../datasources/task_local_datasource.dart';
import '../models/task_model.dart';

typedef TaskAssignmentNotifier =
    Future<void> Function({
      required String homeId,
      required String actorId,
      required String taskId,
      required String targetUserId,
      required String taskTitle,
    });

typedef CurrentUserIdReader = String? Function();

class TaskRepositoryImpl implements TaskRepository {
  final TaskRemoteDataSource _remoteDataSource;
  final TaskLocalDataSource _localDataSource;
  final SyncService _syncService;
  final TaskAssignmentNotifier _taskAssignmentNotifier;
  final CurrentUserIdReader _currentUserIdReader;

  TaskRepositoryImpl(
    this._remoteDataSource,
    this._localDataSource,
    this._syncService, [
    TaskAssignmentNotifier? taskAssignmentNotifier,
    CurrentUserIdReader? currentUserIdReader,
  ]) : _taskAssignmentNotifier =
           taskAssignmentNotifier ??
           NotificationService.sendTaskAssignedNotification,
       _currentUserIdReader =
           currentUserIdReader ??
           (() => SupabaseService.client.auth.currentUser?.id);

  Future<void> _notifyTaskAssignedIfNeeded({
    required Task task,
    String? previousAssignee,
  }) async {
    final targetUserId = task.assignedTo;
    final actorId = _currentUserIdReader();
    if (targetUserId == null ||
        targetUserId.isEmpty ||
        actorId == null ||
        targetUserId == actorId ||
        targetUserId == previousAssignee) {
      return;
    }

    await _taskAssignmentNotifier(
      homeId: task.homeId,
      actorId: actorId,
      taskId: task.id,
      targetUserId: targetUserId,
      taskTitle: task.title,
    );
  }

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
  Future<Task?> getTaskById({required String taskId}) async {
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
    final task = await _remoteDataSource.createTask(
      homeId: homeId,
      title: title,
      description: description,
      dueDate: dueDate,
      categoryId: categoryId,
      assignedTo: assignedTo,
      recurrenceType: recurrenceType,
    );
    await _notifyTaskAssignedIfNeeded(task: task);
    return task;
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
    Task? previousTask;
    if (assignedTo != null) {
      try {
        previousTask = await _remoteDataSource.getTaskById(taskId: taskId);
      } catch (_) {}
    }
    final task = await _remoteDataSource.updateTask(
      taskId: taskId,
      title: title,
      description: description,
      dueDate: dueDate,
      categoryId: categoryId,
      assignedTo: assignedTo,
      recurrenceType: recurrenceType,
    );
    if (assignedTo != null) {
      await _notifyTaskAssignedIfNeeded(
        task: task,
        previousAssignee: previousTask?.assignedTo,
      );
    }
    return task;
  }

  @override
  Future<Task> updateTaskAssignee({
    required String taskId,
    required String? assignedTo,
  }) async {
    Task? previousTask;
    try {
      previousTask = await _remoteDataSource.getTaskById(taskId: taskId);
    } catch (_) {}
    final task = await _remoteDataSource.updateTaskAssignee(
      taskId: taskId,
      assignedTo: assignedTo,
    );
    await _notifyTaskAssignedIfNeeded(
      task: task,
      previousAssignee: previousTask?.assignedTo,
    );
    return task;
  }

  @override
  Future<void> deleteTask({required String taskId}) async {
    return _remoteDataSource.deleteTask(taskId: taskId);
  }

  @override
  Future<Task> completeTask({required String taskId}) async {
    return _updateCompletionState(taskId: taskId, isCompleted: true);
  }

  @override
  Future<Task> uncompleteTask({required String taskId}) async {
    return _updateCompletionState(taskId: taskId, isCompleted: false);
  }

  @override
  Future<String?> createNextRecurringTask({required String taskId}) async {
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
      final cached = await _localDataSource.getTasksStreamCache(
        homeId: homeId,
        assignedTo: null,
        activeOnly: activeOnly,
      );

      if (assignedTo == null) return cached;

      return cached.where((task) => task.assignedTo == assignedTo).toList();
    }

    // 1. Emit cached tasks instantly (0 network requests, instant perceived loading)
    final initialCache = await loadCache();
    yield initialCache;

    if (initialCache.isEmpty) {
      try {
        final tasks = await _remoteDataSource.getTasks(
          homeId: homeId,
          assignedTo: null,
          status: null,
          activeOnly: activeOnly,
        );
        await _localDataSource.saveTasksStreamCache(
          homeId: homeId,
          assignedTo: null,
          activeOnly: activeOnly,
          tasks: tasks,
        );
        await _localDataSource.saveTasks(
          homeId: homeId,
          assignedTo: null,
          activeOnly: activeOnly,
          tasks: tasks,
        );
        yield await loadCache();
      } catch (_) {
        // Keep the instant empty state if offline or the refresh fails.
      }
    }

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
            await _syncService.updateLocalSyncTime(
              homeId,
              'tasks',
              DateTime.now(),
            );
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

  Future<Task> _updateCompletionState({
    required String taskId,
    required bool isCompleted,
  }) async {
    final cachedTask = await _localDataSource.getCachedTaskById(taskId);
    TaskModel? optimisticTask;

    if (cachedTask != null) {
      final now = DateTime.now();
      optimisticTask = cachedTask.copyWithModel(
        status: isCompleted ? 'completed' : 'incomplete',
        completedAt: isCompleted ? now : null,
        completedBy: isCompleted ? _currentUserIdReader() : null,
        updatedAt: now,
      );
      await _localDataSource.updateTaskInCaches(optimisticTask);
      LocalCacheNotifier.notify(cachedTask.homeId, 'tasks');
    }

    try {
      final serverTask = isCompleted
          ? await _remoteDataSource.completeTask(taskId: taskId)
          : await _remoteDataSource.uncompleteTask(taskId: taskId);
      await _localDataSource.updateTaskInCaches(serverTask);
      LocalCacheNotifier.notify(serverTask.homeId, 'tasks');
      return serverTask;
    } catch (_) {
      if (cachedTask != null && optimisticTask != null) {
        await _localDataSource.updateTaskInCaches(cachedTask);
        LocalCacheNotifier.notify(cachedTask.homeId, 'tasks');
      }
      rethrow;
    }
  }
}
