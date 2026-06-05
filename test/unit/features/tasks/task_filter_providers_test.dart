import 'package:flutter_test/flutter_test.dart';
import 'package:sawa/features/tasks/presentation/providers/task_filter_providers.dart';

void main() {
  group('TaskFilterNotifier', () {
    test('setDueDateFilter can clear the active due date filter', () {
      final notifier = TaskFilterNotifier();

      notifier.setDueDateFilter('today');
      expect(notifier.state.dueDateFilter, 'today');

      notifier.setDueDateFilter(null);
      expect(notifier.state.dueDateFilter, isNull);
    });

    test('setAssignedTo and setStatus can clear nullable filters', () {
      final notifier = TaskFilterNotifier();

      notifier.setAssignedTo('user-1');
      notifier.setStatus('completed');
      expect(notifier.state.assignedTo, 'user-1');
      expect(notifier.state.status, 'completed');

      notifier.setAssignedTo(null);
      notifier.setStatus(null);
      expect(notifier.state.assignedTo, isNull);
      expect(notifier.state.status, isNull);
    });
  });
}
