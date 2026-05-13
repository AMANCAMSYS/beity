import 'package:flutter_riverpod/flutter_riverpod.dart';

enum TaskSortBy { dueDate, createdAt }
enum TaskSortOrder { ascending, descending }

class TaskFilterState {
  final String? assignedTo;
  final String? status;
  final String? dueDateFilter;
  final TaskSortBy sortBy;
  final TaskSortOrder sortOrder;

  const TaskFilterState({
    this.assignedTo,
    this.status,
    this.dueDateFilter,
    this.sortBy = TaskSortBy.createdAt,
    this.sortOrder = TaskSortOrder.descending,
  });

  TaskFilterState copyWith({
    String? assignedTo,
    String? status,
    String? dueDateFilter,
    TaskSortBy? sortBy,
    TaskSortOrder? sortOrder,
  }) {
    return TaskFilterState(
      assignedTo: assignedTo ?? this.assignedTo,
      status: status ?? this.status,
      dueDateFilter: dueDateFilter ?? this.dueDateFilter,
      sortBy: sortBy ?? this.sortBy,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}

class TaskFilterNotifier extends StateNotifier<TaskFilterState> {
  TaskFilterNotifier() : super(const TaskFilterState());

  void setAssignedTo(String? assignedTo) {
    state = state.copyWith(assignedTo: assignedTo);
  }

  void setStatus(String? status) {
    state = state.copyWith(status: status);
  }

  void setDueDateFilter(String? filter) {
    state = state.copyWith(dueDateFilter: filter);
  }

  void setSortBy(TaskSortBy sortBy) {
    state = state.copyWith(sortBy: sortBy);
  }

  void setSortOrder(TaskSortOrder sortOrder) {
    state = state.copyWith(sortOrder: sortOrder);
  }

  void clearFilters() {
    state = const TaskFilterState();
  }
}

final taskFilterProvider =
    StateNotifierProvider<TaskFilterNotifier, TaskFilterState>((ref) {
  return TaskFilterNotifier();
});
