import '../../domain/entities/inventory_transaction.dart';

class InventoryTransactionModel extends InventoryTransaction {
  const InventoryTransactionModel({
    required super.id,
    required super.inventoryItemId,
    required super.homeId,
    required super.previousQuantity,
    required super.newQuantity,
    required super.changeReason,
    required super.changedBy,
    super.createdAt,
  });

  factory InventoryTransactionModel.fromJson(Map<String, dynamic> json) {
    return InventoryTransactionModel(
      id: json['id'] as String? ?? '',
      inventoryItemId: json['inventory_item_id'] as String? ?? '',
      homeId: json['home_id'] as String? ?? '',
      previousQuantity: (json['previous_quantity'] as num?)?.toDouble() ?? 0,
      newQuantity: (json['new_quantity'] as num?)?.toDouble() ?? 0,
      changeReason: json['change_reason'] as String? ?? '',
      changedBy: json['changed_by'] as String? ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'inventory_item_id': inventoryItemId,
      'home_id': homeId,
      'previous_quantity': previousQuantity,
      'new_quantity': newQuantity,
      'change_reason': changeReason,
      'changed_by': changedBy,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'inventory_item_id': inventoryItemId,
      'home_id': homeId,
      'previous_quantity': previousQuantity,
      'new_quantity': newQuantity,
      'change_reason': changeReason,
      'changed_by': changedBy,
    };
  }
}
