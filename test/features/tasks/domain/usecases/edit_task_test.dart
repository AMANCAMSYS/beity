import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:beity/features/tasks/domain/repositories/task_repository.dart';
import 'package:beity/features/tasks/domain/usecases/edit_task.dart';
import 'package:beity/features/tasks/domain/entities/task.dart';

class MockTaskRepository extends Mock implements TaskRepository {}

void main() {
  late MockTaskRepository mockRepository;
  late EditTask useCase;

  setUp(() {
    mockRepository = MockTaskRepository();
    useCase = EditTask(mockRepository);
  });

  group('EditTask', () {
    final originalTask = Task(
      id: 'task-123',
      homeId: 'home-123',
      title: 'تنظيف المطبخ',
      description: 'الوصف الأصلي',
      status: 'incomplete',
      createdBy: 'user-123',
    );

    test('should update task title', () async {
      final updatedTask = originalTask.copyWith(title: 'تنظيف الحمام');

      when(() => mockRepository.updateTask(
            taskId: 'task-123',
            title: 'تنظيف الحمام',
          )).thenAnswer((_) async => updatedTask);

      final result = await useCase(EditTaskParams(
        taskId: 'task-123',
        title: 'تنظيف الحمام',
      ));

      expect(result.title, 'تنظيف الحمام');
    });

    test('should update task description', () async {
      final updatedTask =
          originalTask.copyWith(description: 'وصف جديد');

      when(() => mockRepository.updateTask(
            taskId: 'task-123',
            description: 'وصف جديد',
          )).thenAnswer((_) async => updatedTask);

      final result = await useCase(EditTaskParams(
        taskId: 'task-123',
        description: 'وصف جديد',
      ));

      expect(result.description, 'وصف جديد');
    });

    test('should update task due date', () async {
      final newDueDate = DateTime(2026, 6, 1);
      final updatedTask = originalTask.copyWith(dueDate: newDueDate);

      when(() => mockRepository.updateTask(
            taskId: 'task-123',
            dueDate: newDueDate,
          )).thenAnswer((_) async => updatedTask);

      final result = await useCase(EditTaskParams(
        taskId: 'task-123',
        dueDate: newDueDate,
      ));

      expect(result.dueDate, newDueDate);
    });

    test('should update task assignee', () async {
      final updatedTask = originalTask.copyWith(assignedTo: 'user-456');

      when(() => mockRepository.updateTask(
            taskId: 'task-123',
            assignedTo: 'user-456',
          )).thenAnswer((_) async => updatedTask);

      final result = await useCase(EditTaskParams(
        taskId: 'task-123',
        assignedTo: 'user-456',
      ));

      expect(result.assignedTo, 'user-456');
    });

    test('should update task recurrence', () async {
      final updatedTask = originalTask.copyWith(recurrenceType: 'monthly');

      when(() => mockRepository.updateTask(
            taskId: 'task-123',
            recurrenceType: 'monthly',
          )).thenAnswer((_) async => updatedTask);

      final result = await useCase(EditTaskParams(
        taskId: 'task-123',
        recurrenceType: 'monthly',
      ));

      expect(result.recurrenceType, 'monthly');
      expect(result.isRecurring, true);
    });

    test('should disable recurrence by setting null', () async {
      final recurringTask =
          originalTask.copyWith(recurrenceType: 'weekly');

      when(() => mockRepository.updateTask(
            taskId: 'task-123',
            recurrenceType: null,
          )).thenAnswer((_) async => originalTask);

      final result = await useCase(EditTaskParams(
        taskId: 'task-123',
        recurrenceType: null,
      ));

      expect(result.isRecurring, false);
    });
  });
}
