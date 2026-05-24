import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Task Recurrence and Filtering', () {
    test('completing a recurring task creates exactly one next task', () {
      final task = {
        'id': 'task_1',
        'title': 'Water plants',
        'is_recurring': true,
        'recurrence_rule': 'FREQ=WEEKLY',
        'due_date': DateTime(2023, 10, 1).toIso8601String(),
        'status': 'pending'
      };

      final createdTasks = completeTask(task);

      expect(createdTasks.length, 1);
      expect(createdTasks.first['title'], 'Water plants');
      expect(createdTasks.first['status'], 'pending');
      // Should be 7 days later
      expect(DateTime.parse(createdTasks.first['due_date'] as String).difference(DateTime.parse(task['due_date'] as String)).inDays, 7);
    });

    test('archived tasks are excluded from active list', () {
      final tasks = [
        {'id': '1', 'status': 'pending', 'is_archived': false},
        {'id': '2', 'status': 'completed', 'is_archived': true},
        {'id': '3', 'status': 'completed', 'is_archived': false},
      ];

      final activeTasks = tasks.where((t) => t['is_archived'] != true).toList();
      
      expect(activeTasks.length, 2);
      expect(activeTasks.any((t) => t['id'] == '2'), false);
    });
  });
}

// Dummy implementation
List<Map<String, dynamic>> completeTask(Map<String, dynamic> task) {
  task['status'] = 'completed';
  if (task['is_recurring'] == true && task['recurrence_rule'] == 'FREQ=WEEKLY') {
    return [
      {
        'id': 'task_2',
        'title': task['title'],
        'is_recurring': true,
        'recurrence_rule': task['recurrence_rule'],
        'due_date': DateTime.parse(task['due_date']).add(const Duration(days: 7)).toIso8601String(),
        'status': 'pending',
      }
    ];
  }
  return [];
}
