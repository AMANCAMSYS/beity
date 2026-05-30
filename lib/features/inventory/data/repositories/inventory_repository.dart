import '../models/inventory_item_model.dart';
import '../models/inventory_transaction_model.dart';

abstract class InventoryRepository {
  // Inventory Items
  Future<List<InventoryItemModel>> getInventoryItems({
    required String homeId,
  });

  Future<InventoryItemModel?> getInventoryItemById({
    required String itemId,
  });

  Future<InventoryItemModel> createInventoryItem({
    required String homeId,
    required String name,
    double quantity = 0,
    String? unitId,
    String? categoryId,
    double? minQuantity,
    String? notes,
  });

  Future<InventoryItemModel> updateInventoryItem({
    required String itemId,
    String? name,
    double? quantity,
    String? unitId,
    String? categoryId,
    double? minQuantity,
    String? notes,
    List<String> fieldsToNull = const [],
  });

  Future<void> deleteInventoryItem({
    required String itemId,
  });

  Future<InventoryItemModel?> findDuplicateItem({
    required String homeId,
    required String name,
    String? unitId,
  });

  Future<List<InventoryItemModel>> searchInventoryItems({
    required String homeId,
    required String query,
    int limit = 10,
  });

  Stream<List<InventoryItemModel>> watchInventoryItems({
    required String homeId,
  });

  // Inventory Transactions
  Future<InventoryTransactionModel> createTransaction({
    required String inventoryItemId,
    required String homeId,
    required double previousQuantity,
    required double newQuantity,
    required String changeReason,
  });

  Future<List<InventoryTransactionModel>> getTransactions({
    required String inventoryItemId,
    int limit = 50,
  });

  Stream<List<InventoryTransactionModel>> watchTransactions({
    required String inventoryItemId,
  });

  Future<void> syncInventoryWithServer(String homeId);
}
