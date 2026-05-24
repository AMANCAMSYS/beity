import '../../domain/entities/notification_preference.dart';

class NotificationPreferencesModel {
  final String id;
  final String userId;
  final String homeId;
  final bool itemAdded;
  final bool itemCompleted;
  final bool lowStock;
  final bool expiryAlert;
  final bool expenseAdded;
  final bool taskDue;
  final DateTime createdAt;
  final DateTime updatedAt;

  const NotificationPreferencesModel({
    required this.id,
    required this.userId,
    required this.homeId,
    this.itemAdded = true,
    this.itemCompleted = true,
    this.lowStock = true,
    this.expiryAlert = true,
    this.expenseAdded = true,
    this.taskDue = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NotificationPreferencesModel.fromJson(Map<String, dynamic> json) {
    return NotificationPreferencesModel(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      homeId: json['home_id'] as String? ?? '',
      itemAdded: json['item_added'] as bool? ?? true,
      itemCompleted: json['item_completed'] as bool? ?? true,
      lowStock: json['low_stock'] as bool? ?? true,
      expiryAlert: json['expiry_alert'] as bool? ?? true,
      expenseAdded: json['expense_added'] as bool? ?? true,
      taskDue: json['task_due'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'home_id': homeId,
      'item_added': itemAdded,
      'item_completed': itemCompleted,
      'low_stock': lowStock,
      'expiry_alert': expiryAlert,
      'expense_added': expenseAdded,
      'task_due': taskDue,
    };
  }

  NotificationPreferences toEntity() {
    return NotificationPreferences(
      id: id,
      userId: userId,
      homeId: homeId,
      itemAdded: itemAdded,
      itemCompleted: itemCompleted,
      lowStock: lowStock,
      expiryAlert: expiryAlert,
      expenseAdded: expenseAdded,
      taskDue: taskDue,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  factory NotificationPreferencesModel.fromEntity(NotificationPreferences entity) {
    return NotificationPreferencesModel(
      id: entity.id,
      userId: entity.userId,
      homeId: entity.homeId,
      itemAdded: entity.itemAdded,
      itemCompleted: entity.itemCompleted,
      lowStock: entity.lowStock,
      expiryAlert: entity.expiryAlert,
      expenseAdded: entity.expenseAdded,
      taskDue: entity.taskDue,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}
