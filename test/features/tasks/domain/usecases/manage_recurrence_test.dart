import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:beity/features/tasks/domain/repositories/task_repository.dart';
import 'package:beity/features/tasks/domain/usecases/manage_recurrence.dart';
import 'package:beity/features/tasks/domain/entities/task.dart';

class MockTaskRepository extends Mock implements TaskRepository {}

void main() {
  late MockTaskRepository mockRepository;
  late ManageRecurrence useCase;

  setUp(() {
    mockRepository = MockTaskRepository();
    useCase = ManageRecurrence(mockRepository);
  });

  group('ManageRecurrence', () {
    const testTask = Task(
      id: 'task-123',
      homeId: 'home-123',
      title: 'تنظيف المطبخ',
      status: 'incomplete',
      createdBy: 'user-123',
    );

    test('should set daily recurrence', () async {
      final recurringTask = testTask.copyWith(recurrenceType: 'daily');

      when(() => mockRepository.updateTask(
            taskId: 'task-123',
            recurrenceType: 'daily',
          )).thenAnswer((_) async => recurringTask);

      final result = await useCase.setRecurrence(const SetRecurrenceParams(
        taskId: 'task-123',
        recurrenceType: 'daily',
      ));

      expect(result.recurrenceType, 'daily');
      expect(result.isRecurring, true);
    });

    test('should set weekly recurrence', () async {
      final recurringTask = testTask.copyWith(recurrenceType: 'weekly');

      when(() => mockRepository.updateTask(
            taskId: 'task-123',
            recurrenceType: 'weekly',
          )).thenAnswer((_) async => recurringTask);

      final result = await useCase.setRecurrence(const SetRecurrenceParams(
        taskId: 'task-123',
        recurrenceType: 'weekly',
      ));

      expect(result.recurrenceType, 'weekly');
    });

    test('should set monthly recurrence', () async {
      final recurringTask = testTask.copyWith(recurrenceType: 'monthly');

      when(() => mockRepository.updateTask(
            taskId: 'task-123',
            recurrenceType: 'monthly',
          )).thenAnswer((_) async => recurringTask);

      final result = await useCase.setRecurrence(const SetRecurrenceParams(
        taskId: 'task-123',
        recurrenceType: 'monthly',
      ));

      expect(result.recurrenceType, 'monthly');
    });

    test('should disable recurrence', () async {
      when(() => mockRepository.updateTask(
            taskId: 'task-123',
            recurrenceType: null,
          )).thenAnswer((_) async => testTask);

      final result = await useCase
          .disableRecurrence(const DisableRecurrenceParams(taskId: 'task-123'));

      expect(result.isRecurring, false);
    });
  });
}
