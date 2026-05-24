import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:beity/features/tasks/domain/repositories/task_repository.dart';
import 'package:beity/features/tasks/domain/usecases/complete_task.dart';
import 'package:beity/features/tasks/domain/entities/task.dart';

class MockTaskRepository extends Mock implements TaskRepository {}

void main() {
  late MockTaskRepository mockRepository;
  late CompleteTask completeTask;
  late UncompleteTask uncompleteTask;

  setUp(() {
    mockRepository = MockTaskRepository();
    completeTask = CompleteTask(mockRepository);
    uncompleteTask = UncompleteTask(mockRepository);
  });

  group('CompleteTask', () {
    final incompleteTask = Task(
      id: 'task-123',
      homeId: 'home-123',
      title: 'تنظيف المطبخ',
      status: 'incomplete',
      createdBy: 'user-123',
    );

    final completedTask = incompleteTask.copyWith(
      status: 'completed',
      completedBy: 'user-123',
      completedAt: DateTime(2026, 5, 13),
    );

    test('should complete task successfully', () async {
      when(() => mockRepository.completeTask(taskId: 'task-123'))
          .thenAnswer((_) async => completedTask);

      final result = await completeTask(CompleteTaskParams(taskId: 'task-123'));

      expect(result.isCompleted, true);
      expect(result.completedBy, 'user-123');
      verify(() => mockRepository.completeTask(taskId: 'task-123')).called(1);
    });

    test('should create next recurring task when task is recurring', () async {
      final recurringTask = incompleteTask.copyWith(recurrenceType: 'weekly');
      final completedRecurringTask = recurringTask.copyWith(
        status: 'completed',
        completedBy: 'user-123',
        completedAt: DateTime(2026, 5, 13),
      );

      when(() => mockRepository.completeTask(taskId: 'task-123'))
          .thenAnswer((_) async => completedRecurringTask);
      when(() => mockRepository.createNextRecurringTask(taskId: 'task-123'))
          .thenAnswer((_) async => 'new-task-456');

      final result = await completeTask(CompleteTaskParams(taskId: 'task-123'));

      expect(result.isCompleted, true);
      verify(() => mockRepository.createNextRecurringTask(taskId: 'task-123'))
          .called(1);
    });

    test('should not create next task when task is not recurring', () async {
      when(() => mockRepository.completeTask(taskId: 'task-123'))
          .thenAnswer((_) async => completedTask);

      await completeTask(CompleteTaskParams(taskId: 'task-123'));

      verifyNever(
          () => mockRepository.createNextRecurringTask(taskId: 'task-123'));
    });
  });

  group('UncompleteTask', () {
    final completedTask = Task(
      id: 'task-123',
      homeId: 'home-123',
      title: 'تنظيف المطبخ',
      status: 'completed',
      completedBy: 'user-123',
      completedAt: DateTime(2026, 5, 13),
      createdBy: 'user-123',
    );

    final uncompletedTask = completedTask.copyWith(
      status: 'incomplete',
      completedBy: null,
      completedAt: null,
    );

    test('should uncomplete task successfully', () async {
      when(() => mockRepository.uncompleteTask(taskId: 'task-123'))
          .thenAnswer((_) async => completedTask.copyWith(
                status: 'incomplete',
              ));

      final result =
          await uncompleteTask(UncompleteTaskParams(taskId: 'task-123'));

      expect(result.isIncomplete, true);
    });
  });
}
