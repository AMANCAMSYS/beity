import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:beity/features/tasks/domain/repositories/task_repository.dart';
import 'package:beity/features/tasks/domain/usecases/create_task.dart';
import 'package:beity/features/tasks/domain/entities/task.dart';

class MockTaskRepository extends Mock implements TaskRepository {}

void main() {
  late MockTaskRepository mockRepository;
  late CreateTask useCase;

  setUp(() {
    mockRepository = MockTaskRepository();
    useCase = CreateTask(mockRepository);
  });

  group('CreateTask', () {
    final testTask = Task(
      id: 'task-123',
      homeId: 'home-123',
      title: 'تنظيف المطبخ',
      description: 'تنظيف المطبخ بالتفصيل',
      status: 'incomplete',
      createdBy: 'user-123',
      createdAt: DateTime(2026, 5, 13),
    );

    test('should create task with title only', () async {
      when(() => mockRepository.createTask(
            homeId: 'home-123',
            title: 'تنظيف المطبخ',
          )).thenAnswer((_) async => testTask);

      final result = await useCase(CreateTaskParams(
        homeId: 'home-123',
        title: 'تنظيف المطبخ',
      ));

      expect(result, testTask);
      expect(result.title, 'تنظيف المطبخ');
      expect(result.status, 'incomplete');
      verify(() => mockRepository.createTask(
            homeId: 'home-123',
            title: 'تنظيف المطبخ',
          )).called(1);
    });

    test('should create task with all optional fields', () async {
      final dueDate = DateTime(2026, 5, 20);
      final fullTask = testTask.copyWith(
        description: 'تنظيف المطبخ بالتفصيل',
        dueDate: dueDate,
        categoryId: 'cat-456',
        assignedTo: 'user-456',
        recurrenceType: 'weekly',
      );

      when(() => mockRepository.createTask(
            homeId: 'home-123',
            title: 'تنظيف المطبخ',
            description: 'تنظيف المطبخ بالتفصيل',
            dueDate: dueDate,
            categoryId: 'cat-456',
            assignedTo: 'user-456',
            recurrenceType: 'weekly',
          )).thenAnswer((_) async => fullTask);

      final result = await useCase(CreateTaskParams(
        homeId: 'home-123',
        title: 'تنظيف المطبخ',
        description: 'تنظيف المطبخ بالتفصيل',
        dueDate: dueDate,
        categoryId: 'cat-456',
        assignedTo: 'user-456',
        recurrenceType: 'weekly',
      ));

      expect(result.description, 'تنظيف المطبخ بالتفصيل');
      expect(result.dueDate, dueDate);
      expect(result.categoryId, 'cat-456');
      expect(result.assignedTo, 'user-456');
      expect(result.recurrenceType, 'weekly');
    });

    test('should create task with due date', () async {
      final dueDate = DateTime(2026, 5, 20);
      final taskWithDueDate = testTask.copyWith(dueDate: dueDate);

      when(() => mockRepository.createTask(
            homeId: 'home-123',
            title: 'تنظيف المطبخ',
            dueDate: dueDate,
          )).thenAnswer((_) async => taskWithDueDate);

      final result = await useCase(CreateTaskParams(
        homeId: 'home-123',
        title: 'تنظيف المطبخ',
        dueDate: dueDate,
      ));

      expect(result.dueDate, dueDate);
    });

    test('should create recurring task', () async {
      final recurringTask = testTask.copyWith(recurrenceType: 'daily');

      when(() => mockRepository.createTask(
            homeId: 'home-123',
            title: 'تنظيف المطبخ',
            recurrenceType: 'daily',
          )).thenAnswer((_) async => recurringTask);

      final result = await useCase(CreateTaskParams(
        homeId: 'home-123',
        title: 'تنظيف المطبخ',
        recurrenceType: 'daily',
      ));

      expect(result.isRecurring, true);
      expect(result.recurrenceType, 'daily');
    });
  });
}
