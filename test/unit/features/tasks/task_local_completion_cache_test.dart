import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sawa/core/services/shared_prefs_provider.dart';
import 'package:sawa/features/tasks/data/datasources/task_local_datasource.dart';
import 'package:sawa/features/tasks/data/models/task_model.dart';

void main() {
  group('Task local completion cache', () {
    late SharedPreferencesTaskLocalDataSource dataSource;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await AppPreferences.init();
      dataSource = SharedPreferencesTaskLocalDataSource();
    });

    test('TaskModel copyWithModel clears completion fields', () {
      final completedAt = DateTime(2026, 1, 1, 10);
      final task = TaskModel(
        id: 'task-1',
        homeId: 'home-1',
        title: 'Clean kitchen',
        status: 'completed',
        completedBy: 'user-1',
        completedAt: completedAt,
        createdBy: 'user-1',
      );

      final updated = task.copyWithModel(
        status: 'incomplete',
        completedBy: null,
        completedAt: null,
      );

      expect(updated.status, 'incomplete');
      expect(updated.completedBy, isNull);
      expect(updated.completedAt, isNull);
    });

    test('updateTaskInCaches updates regular and stream caches', () async {
      final task = TaskModel(
        id: 'task-1',
        homeId: 'home-1',
        title: 'Clean kitchen',
        status: 'incomplete',
        createdBy: 'user-1',
        createdAt: DateTime(2026, 1, 1),
      );

      await dataSource.saveTasks(homeId: 'home-1', tasks: [task]);
      await dataSource.saveTasksStreamCache(homeId: 'home-1', tasks: [task]);

      final completed = task.copyWithModel(
        status: 'completed',
        completedAt: DateTime(2026, 1, 1, 12),
      );
      await dataSource.updateTaskInCaches(completed);

      final regularCache = await dataSource.getTasks(homeId: 'home-1');
      final streamCache = await dataSource.getTasksStreamCache(
        homeId: 'home-1',
      );

      expect(regularCache.single.isCompleted, isTrue);
      expect(streamCache.single.isCompleted, isTrue);
      expect(streamCache.single.completedAt, isNotNull);
    });
  });
}
