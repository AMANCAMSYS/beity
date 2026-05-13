import '../../domain/entities/task.dart';

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
    String? description,
    DateTime? dueDate,
    String? categoryId,
    String? assignedTo,
    String? status,
    String? recurrenceType,
    String? completedBy,
    DateTime? completedAt,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    DateTime? archivedAt,
  }) {
    return TaskModel(
      id: id ?? this.id,
      homeId: homeId ?? this.homeId,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      categoryId: categoryId ?? this.categoryId,
      assignedTo: assignedTo ?? this.assignedTo,
      status: status ?? this.status,
      recurrenceType: recurrenceType ?? this.recurrenceType,
      completedBy: completedBy ?? this.completedBy,
      completedAt: completedAt ?? this.completedAt,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      archivedAt: archivedAt ?? this.archivedAt,
    );
  }
}
