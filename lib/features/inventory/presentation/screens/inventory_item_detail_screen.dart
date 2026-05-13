import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/inventory_provider.dart';
import '../../domain/usecases/delete_inventory_item_usecase.dart';
import '../../data/models/inventory_transaction_model.dart';

class InventoryItemDetailScreen extends ConsumerStatefulWidget {
  final String itemId;
  final String homeId;

  const InventoryItemDetailScreen({
    super.key,
    required this.itemId,
    required this.homeId,
  });

  @override
  ConsumerState<InventoryItemDetailScreen> createState() =>
      _InventoryItemDetailScreenState();
}

class _InventoryItemDetailScreenState
    extends ConsumerState<InventoryItemDetailScreen> {
  List<InventoryTransactionModel> _transactions = [];
  bool _loadingTransactions = true;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    final repo = ref.read(inventoryRepositoryProvider);
    final txns = await repo.getTransactions(inventoryItemId: widget.itemId);
    if (mounted) {
      setState(() {
        _transactions = txns;
        _loadingTransactions = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final itemAsync = ref.watch(inventoryItemByIdProvider(widget.itemId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل المنتج'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: itemAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('خطأ: $e')),
        data: (item) {
          if (item == null) {
            return const Center(child: Text('المنتج غير موجود'));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Item info card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      _infoRow('الكمية', _formatQuantity(item.quantity)),
                      if (item.minQuantity != null)
                        _infoRow('الحد الأدنى',
                            _formatQuantity(item.minQuantity!)),
                      if (item.notes != null && item.notes!.isNotEmpty)
                        _infoRow('ملاحظات', item.notes!),
                      _infoRow(
                          'تاريخ الإضافة', _formatDate(item.createdAt)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Transaction history
              Text(
                'سجل التغييرات',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (_loadingTransactions)
                const Center(child: CircularProgressIndicator())
              else if (_transactions.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('لا توجد تغييرات مسجلة'),
                  ),
                )
              else
                ...List.generate(_transactions.length, (i) {
                  final txn = _transactions[i];
                  return Card(
                    child: ListTile(
                      leading: Icon(
                        _getTransactionIcon(txn.changeReason),
                        color: _getTransactionColor(txn.changeReason),
                      ),
                      title: Text(
                        _getTransactionLabel(txn.changeReason),
                      ),
                      subtitle: Text(
                        '${_formatQuantity(txn.previousQuantity)} → ${_formatQuantity(txn.newQuantity)}',
                      ),
                      trailing: Text(
                        _formatDate(txn.createdAt),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _formatQuantity(double q) {
    if (q == q.roundToDouble() && q < 1000) {
      return q.toInt().toString();
    }
    return q.toStringAsFixed(1);
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day}/${date.month}/${date.year}';
  }

  IconData _getTransactionIcon(String reason) {
    switch (reason) {
      case 'initial_add':
        return Icons.add_circle;
      case 'manual_update':
        return Icons.edit;
      case 'shopping_restock':
        return Icons.shopping_cart;
      case 'zero_removal':
        return Icons.remove_circle;
      case 'delete':
        return Icons.delete;
      default:
        return Icons.change_history;
    }
  }

  Color _getTransactionColor(String reason) {
    switch (reason) {
      case 'initial_add':
        return Colors.green;
      case 'manual_update':
        return Colors.blue;
      case 'shopping_restock':
        return Colors.purple;
      case 'zero_removal':
        return Colors.orange;
      case 'delete':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getTransactionLabel(String reason) {
    switch (reason) {
      case 'initial_add':
        return 'إضافة أولية';
      case 'manual_update':
        return 'تعديل يدوي';
      case 'shopping_restock':
        return 'تجديد من التسوق';
      case 'zero_removal':
        return 'إزالة (صفر كمية)';
      case 'delete':
        return 'حذف';
      default:
        return reason;
    }
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف المنتج'),
        content: const Text('هل أنت متأكد من حذف هذا المنتج من المخزون؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final useCase = DeleteInventoryItemUseCase(
                  ref.read(inventoryRepositoryProvider),
                );
                await useCase(
                  itemId: widget.itemId,
                  homeId: widget.homeId,
                );
                ref.invalidate(inventoryItemsProvider(widget.homeId));
                if (context.mounted) Navigator.pop(context);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('خطأ في الحذف: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }
}
