class NotificationPreferences {
  final String id;
  final String userId;
  final String homeId;
  final bool itemAdded;
  final bool itemCompleted;
  final bool lowStock;
  final bool expiryAlert;
  final bool expenseAdded;
  final bool taskAssigned;
  final bool taskDue;
  final DateTime createdAt;
  final DateTime updatedAt;

  const NotificationPreferences({
    required this.id,
    required this.userId,
    required this.homeId,
    this.itemAdded = true,
    this.itemCompleted = true,
    this.lowStock = true,
    this.expiryAlert = true,
    this.expenseAdded = true,
    this.taskAssigned = true,
    this.taskDue = true,
    required this.createdAt,
    required this.updatedAt,
  });

  NotificationPreferences copyWith({
    bool? itemAdded,
    bool? itemCompleted,
    bool? lowStock,
    bool? expiryAlert,
    bool? expenseAdded,
    bool? taskAssigned,
    bool? taskDue,
  }) {
    return NotificationPreferences(
      id: id,
      userId: userId,
      homeId: homeId,
      itemAdded: itemAdded ?? this.itemAdded,
      itemCompleted: itemCompleted ?? this.itemCompleted,
      lowStock: lowStock ?? this.lowStock,
      expiryAlert: expiryAlert ?? this.expiryAlert,
      expenseAdded: expenseAdded ?? this.expenseAdded,
      taskAssigned: taskAssigned ?? this.taskAssigned,
      taskDue: taskDue ?? this.taskDue,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
