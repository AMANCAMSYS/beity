import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sawa/core/services/sync_service.dart';
import 'package:sawa/features/tasks/data/datasources/task_local_datasource.dart';
import 'package:sawa/features/tasks/data/datasources/task_remote_datasource.dart';
import 'package:sawa/features/tasks/data/models/task_model.dart';
import 'package:sawa/features/tasks/data/repositories/task_repository_impl.dart';

class MockTaskRemoteDataSource extends Mock implements TaskRemoteDataSource {}

class MockTaskLocalDataSource extends Mock implements TaskLocalDataSource {}

class MockSyncService extends Mock implements SyncService {}

void main() {
  late MockTaskRemoteDataSource remoteDataSource;
  late MockTaskLocalDataSource localDataSource;
  late MockSyncService syncService;
  late List<Map<String, String>> sentNotifications;
  late TaskRepositoryImpl repository;

  setUp(() {
    remoteDataSource = MockTaskRemoteDataSource();
    localDataSource = MockTaskLocalDataSource();
    syncService = MockSyncService();
    sentNotifications = [];
    repository =
        TaskRepositoryImpl(remoteDataSource, localDataSource, syncService, ({
          required homeId,
          required actorId,
          required taskId,
          required targetUserId,
          required taskTitle,
        }) async {
          sentNotifications.add({
            'homeId': homeId,
            'actorId': actorId,
            'taskId': taskId,
            'targetUserId': targetUserId,
            'taskTitle': taskTitle,
          });
        }, () => 'actor-1');
  });

  group('task assignment push notifications', () {
    test(
      'sends notification when creating a task assigned to another user',
      () async {
        const task = TaskModel(
          id: 'task-1',
          homeId: 'home-1',
          title: 'Pay bills',
          assignedTo: 'target-1',
          createdBy: 'actor-1',
        );

        when(
          () => remoteDataSource.createTask(
            homeId: 'home-1',
            title: 'Pay bills',
            description: null,
            dueDate: null,
            categoryId: null,
            assignedTo: 'target-1',
            recurrenceType: null,
          ),
        ).thenAnswer((_) async => task);

        final result = await repository.createTask(
          homeId: 'home-1',
          title: 'Pay bills',
          assignedTo: 'target-1',
        );

        expect(result, task);
        expect(sentNotifications, [
          {
            'homeId': 'home-1',
            'actorId': 'actor-1',
            'taskId': 'task-1',
            'targetUserId': 'target-1',
            'taskTitle': 'Pay bills',
          },
        ]);
      },
    );

    test(
      'does not send notification when user assigns task to themselves',
      () async {
        const task = TaskModel(
          id: 'task-1',
          homeId: 'home-1',
          title: 'Pay bills',
          assignedTo: 'actor-1',
          createdBy: 'actor-1',
        );

        when(
          () => remoteDataSource.createTask(
            homeId: 'home-1',
            title: 'Pay bills',
            description: null,
            dueDate: null,
            categoryId: null,
            assignedTo: 'actor-1',
            recurrenceType: null,
          ),
        ).thenAnswer((_) async => task);

        await repository.createTask(
          homeId: 'home-1',
          title: 'Pay bills',
          assignedTo: 'actor-1',
        );

        expect(sentNotifications, isEmpty);
      },
    );

    test('does not resend notification when assignee did not change', () async {
      const previousTask = TaskModel(
        id: 'task-1',
        homeId: 'home-1',
        title: 'Pay bills',
        assignedTo: 'target-1',
        createdBy: 'actor-1',
      );
      const updatedTask = TaskModel(
        id: 'task-1',
        homeId: 'home-1',
        title: 'Pay bills today',
        assignedTo: 'target-1',
        createdBy: 'actor-1',
      );

      when(
        () => remoteDataSource.getTaskById(taskId: 'task-1'),
      ).thenAnswer((_) async => previousTask);
      when(
        () => remoteDataSource.updateTask(
          taskId: 'task-1',
          title: 'Pay bills today',
          description: null,
          dueDate: null,
          categoryId: null,
          assignedTo: 'target-1',
          recurrenceType: null,
        ),
      ).thenAnswer((_) async => updatedTask);

      await repository.updateTask(
        taskId: 'task-1',
        title: 'Pay bills today',
        assignedTo: 'target-1',
      );

      expect(sentNotifications, isEmpty);
    });

    test(
      'sends notification when task is reassigned to another user',
      () async {
        const previousTask = TaskModel(
          id: 'task-1',
          homeId: 'home-1',
          title: 'Pay bills',
          assignedTo: 'old-target',
          createdBy: 'actor-1',
        );
        const updatedTask = TaskModel(
          id: 'task-1',
          homeId: 'home-1',
          title: 'Pay bills',
          assignedTo: 'new-target',
          createdBy: 'actor-1',
        );

        when(
          () => remoteDataSource.getTaskById(taskId: 'task-1'),
        ).thenAnswer((_) async => previousTask);
        when(
          () => remoteDataSource.updateTaskAssignee(
            taskId: 'task-1',
            assignedTo: 'new-target',
          ),
        ).thenAnswer((_) async => updatedTask);

        await repository.updateTaskAssignee(
          taskId: 'task-1',
          assignedTo: 'new-target',
        );

        expect(sentNotifications.single['targetUserId'], 'new-target');
        expect(sentNotifications.single['taskTitle'], 'Pay bills');
      },
    );
  });
}
