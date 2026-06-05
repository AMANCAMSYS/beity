import '../../domain/entities/task.dart';

const Object _taskModelUnchanged = Object();

class TaskModel extends Task {
  const TaskModel({
    required super.id,
    required super.homeId,
    required super.title,
    super.description,
    super.dueDate,
    super.categoryId,
    super.assignedTo,
    super.status = 'incomplete',
    super.recurrenceType,
    super.completedBy,
    super.completedAt,
    required super.createdBy,
    super.createdAt,
    super.updatedAt,
    super.deletedAt,
    super.archivedAt,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] as String,
      homeId: json['home_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'] as String)
          : null,
      categoryId: json['category_id'] as String?,
      assignedTo: json['assigned_to'] as String?,
      status: json['status'] as String? ?? 'incomplete',
      recurrenceType: json['recurrence_type'] as String?,
      completedBy: json['completed_by'] as String?,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      createdBy: json['created_by'] as String,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'] as String)
          : null,
      archivedAt: json['archived_at'] != null
          ? DateTime.parse(json['archived_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'home_id': homeId,
      'title': title,
      'description': description,
      'due_date': dueDate?.toIso8601String().split('T')[0],
      'category_id': categoryId,
      'assigned_to': assignedTo,
      'status': status,
      'recurrence_type': recurrenceType,
      'completed_by': completedBy,
      'completed_at': completedAt?.toIso8601String(),
      'created_by': createdBy,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
      'archived_at': archivedAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'home_id': homeId,
      'title': title,
      'description': description,
      'due_date': dueDate?.toIso8601String().split('T')[0],
      'category_id': categoryId,
      'assigned_to': assignedTo,
      'recurrence_type': recurrenceType,
      'created_by': createdBy,
    };
  }

  TaskModel copyWithModel({
    String? id,
    String? homeId,
    String? title,
    Object? description = _taskModelUnchanged,
    Object? dueDate = _taskModelUnchanged,
    Object? categoryId = _taskModelUnchanged,
    Object? assignedTo = _taskModelUnchanged,
    String? status,
    Object? recurrenceType = _taskModelUnchanged,
    Object? completedBy = _taskModelUnchanged,
    Object? completedAt = _taskModelUnchanged,
    String? createdBy,
    DateTime? createdAt,
    Object? updatedAt = _taskModelUnchanged,
    Object? deletedAt = _taskModelUnchanged,
    Object? archivedAt = _taskModelUnchanged,
  }) {
    return TaskModel(
      id: id ?? this.id,
      homeId: homeId ?? this.homeId,
      title: title ?? this.title,
      description: identical(description, _taskModelUnchanged)
          ? this.description
          : description as String?,
      dueDate: identical(dueDate, _taskModelUnchanged)
          ? this.dueDate
          : dueDate as DateTime?,
      categoryId: identical(categoryId, _taskModelUnchanged)
          ? this.categoryId
          : categoryId as String?,
      assignedTo: identical(assignedTo, _taskModelUnchanged)
          ? this.assignedTo
          : assignedTo as String?,
      status: status ?? this.status,
      recurrenceType: identical(recurrenceType, _taskModelUnchanged)
          ? this.recurrenceType
          : recurrenceType as String?,
      completedBy: identical(completedBy, _taskModelUnchanged)
          ? this.completedBy
          : completedBy as String?,
      completedAt: identical(completedAt, _taskModelUnchanged)
          ? this.completedAt
          : completedAt as DateTime?,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: identical(updatedAt, _taskModelUnchanged)
          ? this.updatedAt
          : updatedAt as DateTime?,
      deletedAt: identical(deletedAt, _taskModelUnchanged)
          ? this.deletedAt
          : deletedAt as DateTime?,
      archivedAt: identical(archivedAt, _taskModelUnchanged)
          ? this.archivedAt
          : archivedAt as DateTime?,
    );
  }
}
