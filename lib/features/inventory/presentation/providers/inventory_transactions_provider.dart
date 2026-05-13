import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/inventory_transaction_model.dart';
import 'inventory_provider.dart';

final inventoryTransactionsProvider = StreamProvider.family<
    List<InventoryTransactionModel>, String>((ref, itemId) {
  final repository = ref.watch(inventoryRepositoryProvider);
  return repository.watchTransactions(inventoryItemId: itemId);
});

final inventoryTransactionsListProvider = FutureProvider.family<
    List<InventoryTransactionModel>, String>((ref, itemId) async {
  final repository = ref.watch(inventoryRepositoryProvider);
  return repository.getTransactions(inventoryItemId: itemId);
});
