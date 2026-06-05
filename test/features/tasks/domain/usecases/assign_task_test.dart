import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sawa/features/tasks/domain/repositories/task_repository.dart';
import 'package:sawa/features/tasks/domain/usecases/assign_task.dart';
import 'package:sawa/features/tasks/domain/entities/task.dart';

class MockTaskRepository extends Mock implements TaskRepository {}

void main() {
  late MockTaskRepository mockRepository;
  late AssignTask useCase;

  setUp(() {
    mockRepository = MockTaskRepository();
    useCase = AssignTask(mockRepository);
  });

  group('AssignTask', () {
    const testTask = Task(
      id: 'task-123',
      homeId: 'home-123',
      title: 'تنظيف المطبخ',
      status: 'incomplete',
      createdBy: 'user-123',
    );

    test('should assign task to member', () async {
      final assignedTask = testTask.copyWith(assignedTo: 'user-456');

      when(() => mockRepository.updateTask(
            taskId: 'task-123',
            assignedTo: 'user-456',
          )).thenAnswer((_) async => assignedTask);

      final result = await useCase(const AssignTaskParams(
        taskId: 'task-123',
        assignedTo: 'user-456',
      ));

      expect(result.assignedTo, 'user-456');
      verify(() => mockRepository.updateTask(
            taskId: 'task-123',
            assignedTo: 'user-456',
          )).called(1);
    });

    test('should unassign task when null is passed', () async {

      when(() => mockRepository.updateTask(
            taskId: 'task-123',
            assignedTo: null,
          )).thenAnswer((_) async => testTask);

      final result = await useCase(const AssignTaskParams(
        taskId: 'task-123',
        assignedTo: null,
      ));

      expect(result.assignedTo, null);
    });

    test('should reassign task to different member', () async {
      final assignedTask = testTask.copyWith(assignedTo: 'user-456');
      final reassignedTask = assignedTask.copyWith(assignedTo: 'user-789');

      when(() => mockRepository.updateTask(
            taskId: 'task-123',
            assignedTo: 'user-789',
          )).thenAnswer((_) async => reassignedTask);

      final result = await useCase(const AssignTaskParams(
        taskId: 'task-123',
        assignedTo: 'user-789',
      ));

      expect(result.assignedTo, 'user-789');
    });
  });
}
