import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../domain/entities/inventory_item.dart';
import 'low_stock_badge.dart';

class InventoryItemTile extends StatelessWidget {
  final InventoryItem item;
  final String? unitName;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onQuantityIncrement;
  final VoidCallback? onQuantityDecrement;

  const InventoryItemTile({
    super.key,
    required this.item,
    this.unitName,
    this.onTap,
    this.onDelete,
    this.onQuantityIncrement,
    this.onQuantityDecrement,
  });

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Dismissible(
      key: Key(item.id),
      background: Container(
        alignment: isRtl ? Alignment.centerLeft : Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) => _showDeleteConfirmation(context),
      onDismissed: (_) => onDelete?.call(),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        title: Row(
          children: [
            Expanded(
              child: Text(
                item.name,
                style: const TextStyle(fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (item.isLowStock) ...[
              const SizedBox(width: 8),
              const LowStockBadge(),
            ],
          ],
        ),
        subtitle: _buildSubtitle(context),
        trailing: _buildQuantityControls(context),
      ),
    );
  }

  Widget? _buildSubtitle(BuildContext context) {
    final parts = <String>[];
    if (unitName != null) parts.add(unitName!);
    if (item.notes != null && item.notes!.isNotEmpty) parts.add(item.notes!);
    if (parts.isEmpty) return null;

    return Text(
      parts.join(' • '),
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildQuantityControls(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _QuantityButton(
          icon: Icons.remove,
          onTap: () {
            HapticFeedback.lightImpact();
            onQuantityDecrement?.call();
          },
        ),
        SizedBox(
          width: 48,
          child: Text(
            _formatQuantity(item.quantity),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        _QuantityButton(
          icon: Icons.add,
          onTap: () {
            HapticFeedback.lightImpact();
            onQuantityIncrement?.call();
          },
        ),
      ],
    );
  }

  String _formatQuantity(double q) {
    if (q == q.roundToDouble() && q < 1000) {
      return q.toInt().toString();
    }
    return q.toStringAsFixed(1);
  }

  Future<bool?> _showDeleteConfirmation(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف المنتج'),
        content: Text('هل أنت متأكد من حذف "${item.name}" من المخزون؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
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

class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _QuantityButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: Material(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Icon(icon, size: 20),
        ),
      ),
    );
  }
}
