import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Feature Flag Route Guards', () {
    test('disabled features route to placeholder or are blocked', () {
      final router = FakeFeatureFlagRouter();

      // Disabled routes
      expect(router.navigate('/inventory'), '/disabled_feature');
      expect(router.navigate('/expenses'), '/disabled_feature');
      expect(router.navigate('/tasks'), '/disabled_feature');
      expect(router.navigate('/ai'), '/disabled_feature');

      // Enabled routes
      expect(router.navigate('/shopping'), '/shopping');
      expect(router.navigate('/homes'), '/homes');
    });
  });
}

class FakeFeatureFlagRouter {
  final Map<String, bool> featureFlags = {
    'shopping': true,
    'homes': true,
    'inventory': false,
    'expenses': false,
    'tasks': false,
    'ai': false,
  };

  String navigate(String path) {
    final route = path.replaceAll('/', '');

    if (featureFlags.containsKey(route) && !featureFlags[route]!) {
      return '/disabled_feature';
    }

    return path;
  }
}
