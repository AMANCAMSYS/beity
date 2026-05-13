import '../../domain/entities/shopping_mode_session.dart';

class ShoppingModeSessionModel extends ShoppingModeSession {
  const ShoppingModeSessionModel({
    required super.id,
    required super.shoppingListId,
    required super.userId,
    required super.homeId,
    required super.startedAt,
    super.endedAt,
    super.itemsPurchasedCount = 0,
    super.itemsTotalCount = 0,
    super.createdAt,
    super.updatedAt,
  });

  factory ShoppingModeSessionModel.fromJson(Map<String, dynamic> json) {
    return ShoppingModeSessionModel(
      id: json['id'] as String,
      shoppingListId: json['shopping_list_id'] as String,
      userId: json['user_id'] as String,
      homeId: json['home_id'] as String,
      startedAt: DateTime.parse(json['started_at'] as String),
      endedAt: json['ended_at'] != null
          ? DateTime.parse(json['ended_at'] as String)
          : null,
      itemsPurchasedCount: json['items_purchased_count'] as int? ?? 0,
      itemsTotalCount: json['items_total_count'] as int? ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shopping_list_id': shoppingListId,
      'user_id': userId,
      'home_id': homeId,
      'started_at': startedAt.toIso8601String(),
      'ended_at': endedAt?.toIso8601String(),
      'items_purchased_count': itemsPurchasedCount,
      'items_total_count': itemsTotalCount,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'shopping_list_id': shoppingListId,
      'user_id': userId,
      'home_id': homeId,
      'items_total_count': itemsTotalCount,
    };
  }
}
