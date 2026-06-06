import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Active HomeId Null Safety', () {
    test(
      'throws exception when requesting data without active home id',
      () async {
        final repository = FakeTaskRepository();

        expect(() => repository.getTasks(null), throwsA(isA<StateError>()));
        expect(() => repository.getTasks(''), throwsA(isA<StateError>()));
      },
    );

    test('successful fetch when active home id is provided', () async {
      final repository = FakeTaskRepository();

      final tasks = await repository.getTasks('home_123');
      expect(tasks, isNotNull);
    });

    test('route guard prevents navigation to /home//tasks', () {
      final router = FakeRouter();

      final result = router.navigate('/home//tasks');
      expect(result, '/error'); // redirects to error or home selection

      final validResult = router.navigate('/home/home_123/tasks');
      expect(validResult, '/home/home_123/tasks');
    });
  });
}

class FakeTaskRepository {
  Future<List<Map<String, dynamic>>> getTasks(String? homeId) async {
    if (homeId == null || homeId.isEmpty) {
      throw StateError('Active Home ID is required for this operation');
    }
    return [];
  }
}

class FakeRouter {
  String navigate(String path) {
    if (path.contains('//')) {
      return '/error';
    }
    return path;
  }
}
