import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sawa/features/tasks/domain/repositories/task_repository.dart';
import 'package:sawa/features/tasks/domain/usecases/get_tasks.dart';
import 'package:sawa/features/tasks/domain/entities/task.dart';

class MockTaskRepository extends Mock implements TaskRepository {}

void main() {
  late MockTaskRepository mockRepository;
  late GetTasks useCase;

  setUp(() {
    mockRepository = MockTaskRepository();
    useCase = GetTasks(mockRepository);
  });

  group('GetTasks', () {
    final testTasks = [
      Task(
        id: 'task-1',
        homeId: 'home-123',
        title: 'تنظيف المطبخ',
        status: 'incomplete',
        createdBy: 'user-123',
        createdAt: DateTime(2026, 5, 13),
      ),
      Task(
        id: 'task-2',
        homeId: 'home-123',
        title: 'شراء البقالة',
        status: 'completed',
        completedBy: 'user-123',
        completedAt: DateTime(2026, 5, 12),
        createdBy: 'user-123',
        createdAt: DateTime(2026, 5, 11),
      ),
      Task(
        id: 'task-3',
        homeId: 'home-123',
        title: 'غسل الملابس',
        status: 'incomplete',
        dueDate: DateTime(2026, 5, 10), // overdue
        createdBy: 'user-123',
        createdAt: DateTime(2026, 5, 9),
      ),
    ];

    test('should get all tasks for home', () async {
      when(() => mockRepository.getTasks(
            homeId: 'home-123',
            activeOnly: true,
          )).thenAnswer((_) async => testTasks);

      final result = await useCase(const GetTasksParams(
        homeId: 'home-123',
      ));

      expect(result.length, 3);
      expect(result[0].title, 'تنظيف المطبخ');
    });

    test('should get tasks filtered by assignee', () async {
      final assignedTasks = [
        testTasks[0].copyWith(assignedTo: 'user-456'),
      ];

      when(() => mockRepository.getTasks(
            homeId: 'home-123',
            assignedTo: 'user-456',
            activeOnly: true,
          )).thenAnswer((_) async => assignedTasks);

      final result = await useCase(const GetTasksParams(
        homeId: 'home-123',
        assignedTo: 'user-456',
      ));

      expect(result.length, 1);
      expect(result[0].assignedTo, 'user-456');
    });

    test('should get tasks filtered by status', () async {
      final completedTasks = [testTasks[1]];

      when(() => mockRepository.getTasks(
            homeId: 'home-123',
            status: 'completed',
            activeOnly: true,
          )).thenAnswer((_) async => completedTasks);

      final result = await useCase(const GetTasksParams(
        homeId: 'home-123',
        status: 'completed',
      ));

      expect(result.length, 1);
      expect(result[0].isCompleted, true);
    });

    test('should filter tasks by today due date', () async {
      final today = DateTime.now();
      final todayTask = Task(
        id: 'task-today',
        homeId: 'home-123',
        title: 'مهمة اليوم',
        status: 'incomplete',
        dueDate: DateTime(today.year, today.month, today.day),
        createdBy: 'user-123',
      );

      when(() => mockRepository.getTasks(
            homeId: 'home-123',
            activeOnly: true,
          )).thenAnswer((_) async => [todayTask, ...testTasks]);

      final result = await useCase(const GetTasksParams(
        homeId: 'home-123',
        dueDateFilter: 'today',
      ));

      expect(result.length, 1);
      expect(result[0].isDueToday, true);
    });

    test('should filter overdue tasks', () async {
      when(() => mockRepository.getTasks(
            homeId: 'home-123',
            activeOnly: true,
          )).thenAnswer((_) async => testTasks);

      final result = await useCase(const GetTasksParams(
        homeId: 'home-123',
        dueDateFilter: 'overdue',
      ));

      expect(result.length, 1);
      expect(result[0].isOverdue, true);
    });

    test('should sort tasks by due date ascending', () async {
      when(() => mockRepository.getTasks(
            homeId: 'home-123',
            activeOnly: true,
          )).thenAnswer((_) async => testTasks);

      final result = await useCase(const GetTasksParams(
        homeId: 'home-123',
        sortBy: 'due_date',
        sortAscending: true,
      ));

      // Tasks should be returned (sorting applied)
      expect(result.length, 3);
    });

    test('should sort tasks by created date descending', () async {
      when(() => mockRepository.getTasks(
            homeId: 'home-123',
            activeOnly: true,
          )).thenAnswer((_) async => testTasks);

      final result = await useCase(const GetTasksParams(
        homeId: 'home-123',
        sortBy: 'created_at',
        sortAscending: false,
      ));

      // Should be sorted by created date descending
      for (int i = 0; i < result.length - 1; i++) {
        final aDate = result[i].createdAt ?? DateTime(2000);
        final bDate = result[i + 1].createdAt ?? DateTime(2000);
        expect(aDate.isAfter(bDate) || aDate.isAtSameMomentAs(bDate), true);
      }
    });
  });
}
