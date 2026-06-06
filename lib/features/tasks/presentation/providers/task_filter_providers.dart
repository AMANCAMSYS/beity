import 'package:flutter_riverpod/flutter_riverpod.dart';

enum TaskSortBy { dueDate, createdAt }

enum TaskSortOrder { ascending, descending }

const Object _unset = Object();

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
    Object? assignedTo = _unset,
    Object? status = _unset,
    Object? dueDateFilter = _unset,
    TaskSortBy? sortBy,
    TaskSortOrder? sortOrder,
  }) {
    return TaskFilterState(
      assignedTo: assignedTo == _unset
          ? this.assignedTo
          : assignedTo as String?,
      status: status == _unset ? this.status : status as String?,
      dueDateFilter: dueDateFilter == _unset
          ? this.dueDateFilter
          : dueDateFilter as String?,
      sortBy: sortBy ?? this.sortBy,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}

class TaskFilterNotifier extends Notifier<TaskFilterState> {
  @override
  TaskFilterState build() {
    return const TaskFilterState();
  }

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
    NotifierProvider<TaskFilterNotifier, TaskFilterState>(() {
      return TaskFilterNotifier();
    });
