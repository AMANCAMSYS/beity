import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:beity/features/tasks/domain/repositories/task_repository.dart';
import 'package:beity/features/tasks/domain/usecases/archive_task.dart';

class MockTaskRepository extends Mock implements TaskRepository {}

void main() {
  late MockTaskRepository mockRepository;
  late ArchiveTask useCase;

  setUp(() {
    mockRepository = MockTaskRepository();
    useCase = ArchiveTask(mockRepository);
  });

  group('ArchiveTask', () {
    test('should archive task successfully', () async {
      when(() => mockRepository.deleteTask(taskId: 'task-123'))
          .thenAnswer((_) async {});

      await useCase(const ArchiveTaskParams(taskId: 'task-123'));

      verify(() => mockRepository.deleteTask(taskId: 'task-123')).called(1);
    });

    test('should call repository delete task method', () async {
      when(() => mockRepository.deleteTask(taskId: 'task-456'))
          .thenAnswer((_) async {});

      await useCase(const ArchiveTaskParams(taskId: 'task-456'));

      verify(() => mockRepository.deleteTask(taskId: 'task-456')).called(1);
    });
  });
}
