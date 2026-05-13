class InventoryTransaction {
  final String id;
  final String inventoryItemId;
  final String homeId;
  final double previousQuantity;
  final double newQuantity;
  final String changeReason;
  final String changedBy;
  final DateTime? createdAt;

  const InventoryTransaction({
    required this.id,
    required this.inventoryItemId,
    required this.homeId,
    required this.previousQuantity,
    required this.newQuantity,
    required this.changeReason,
    required this.changedBy,
    this.createdAt,
  });

  double get quantityDelta => newQuantity - previousQuantity;
}
