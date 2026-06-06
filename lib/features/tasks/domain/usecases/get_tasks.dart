import '../entities/task.dart';
import '../repositories/task_repository.dart';

class GetTasks {
  final TaskRepository _repository;

  GetTasks(this._repository);

  Stream<List<Task>> watchTasks(WatchTasksParams params) {
    return _repository.watchTasks(
      homeId: params.homeId,
      assignedTo: params.assignedTo,
      activeOnly: params.activeOnly,
    );
  }

  Future<List<Task>> call(GetTasksParams params) async {
    final tasks = await _repository.getTasks(
      homeId: params.homeId,
      assignedTo: params.assignedTo,
      status: params.status,
      activeOnly: params.activeOnly,
    );

    // Apply client-side filtering
    var filtered = tasks;

    if (params.dueDateFilter != null) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      switch (params.dueDateFilter) {
        case 'today':
          filtered = filtered.where((t) => t.isDueToday).toList();
          break;
        case 'this_week':
          final weekEnd = today.add(Duration(days: 7 - now.weekday));
          filtered = filtered.where((t) {
            if (t.dueDate == null) return false;
            return t.dueDate!.isAfter(
                  today.subtract(const Duration(days: 1)),
                ) &&
                t.dueDate!.isBefore(weekEnd.add(const Duration(days: 1)));
          }).toList();
          break;
        case 'overdue':
          filtered = filtered.where((t) => t.isOverdue).toList();
          break;
      }
    }

    // Apply sorting
    if (params.sortBy != null) {
      filtered.sort((a, b) {
        int comparison;
        switch (params.sortBy) {
          case 'due_date':
            if (a.dueDate == null && b.dueDate == null) {
              comparison = 0;
            } else if (a.dueDate == null) {
              comparison = 1;
            } else if (b.dueDate == null) {
              comparison = -1;
            } else {
              comparison = a.dueDate!.compareTo(b.dueDate!);
            }
            break;
          case 'created_at':
          default:
            final aDate = a.createdAt ?? DateTime(2000);
            final bDate = b.createdAt ?? DateTime(2000);
            comparison = aDate.compareTo(bDate);
            break;
        }
        return params.sortAscending == true ? comparison : -comparison;
      });
    }

    return filtered;
  }
}

class WatchTasksParams {
  final String homeId;
  final String? assignedTo;
  final bool activeOnly;

  const WatchTasksParams({
    required this.homeId,
    this.assignedTo,
    this.activeOnly = true,
  });
}

class GetTasksParams {
  final String homeId;
  final String? assignedTo;
  final String? status;
  final bool activeOnly;
  final String? dueDateFilter;
  final String? sortBy;
  final bool? sortAscending;

  const GetTasksParams({
    required this.homeId,
    this.assignedTo,
    this.status,
    this.activeOnly = true,
    this.dueDateFilter,
    this.sortBy,
    this.sortAscending,
  });
}
