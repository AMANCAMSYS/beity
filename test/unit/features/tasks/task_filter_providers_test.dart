import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sawa/features/tasks/presentation/providers/task_filter_providers.dart';

void main() {
  group('TaskFilterNotifier', () {
    test('setDueDateFilter can clear the active due date filter', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(taskFilterProvider.notifier);

      notifier.setDueDateFilter('today');
      expect(container.read(taskFilterProvider).dueDateFilter, 'today');

      notifier.setDueDateFilter(null);
      expect(container.read(taskFilterProvider).dueDateFilter, isNull);
    });

    test('setAssignedTo and setStatus can clear nullable filters', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(taskFilterProvider.notifier);

      notifier.setAssignedTo('user-1');
      notifier.setStatus('completed');
      expect(container.read(taskFilterProvider).assignedTo, 'user-1');
      expect(container.read(taskFilterProvider).status, 'completed');

      notifier.setAssignedTo(null);
      notifier.setStatus(null);
      expect(container.read(taskFilterProvider).assignedTo, isNull);
      expect(container.read(taskFilterProvider).status, isNull);
    });
  });
}
