class Task {
  final String id;
  final String homeId;
  final String title;
  final String? description;
  final DateTime? dueDate;
  final String? categoryId;
  final String? assignedTo;
  final String status; // 'incomplete' or 'completed'
  final String? recurrenceType; // 'daily', 'weekly', 'monthly'
  final String? completedBy;
  final DateTime? completedAt;
  final String createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
  final DateTime? archivedAt;

  const Task({
    required this.id,
    required this.homeId,
    required this.title,
    this.description,
    this.dueDate,
    this.categoryId,
    this.assignedTo,
    this.status = 'incomplete',
    this.recurrenceType,
    this.completedBy,
    this.completedAt,
    required this.createdBy,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.archivedAt,
  });

  bool get isCompleted => status == 'completed';
  bool get isIncomplete => status == 'incomplete';
  bool get isRecurring => recurrenceType != null;
  bool get isDeleted => deletedAt != null;
  bool get isArchived => archivedAt != null;
  bool get isOverdue =>
      dueDate != null && !isCompleted && dueDate!.isBefore(DateTime.now());
  bool get isDueToday =>
      dueDate != null &&
      dueDate!.year == DateTime.now().year &&
      dueDate!.month == DateTime.now().month &&
      dueDate!.day == DateTime.now().day;

  Task copyWith({
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
    return Task(
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
