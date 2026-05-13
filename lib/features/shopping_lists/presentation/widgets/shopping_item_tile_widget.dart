import 'package:flutter/material.dart';
import '../../domain/entities/shopping_item.dart';
import '../../../offline_queue/presentation/widgets/pending_sync_indicator.dart';
import '../../../../core/accessibility/semantics_helpers.dart';

class ShoppingItemTileWidget extends StatefulWidget {
  final ShoppingItem item;
  final VoidCallback? onTap;
  final VoidCallback? onTogglePurchased;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final DateTime? highlightUntil;
  final bool showPendingIndicator;

  const ShoppingItemTileWidget({
    super.key,
    required this.item,
    this.onTap,
    this.onTogglePurchased,
    this.onEdit,
    this.onDelete,
    this.highlightUntil,
    this.showPendingIndicator = false,
  });

  @override
  State<ShoppingItemTileWidget> createState() => _ShoppingItemTileWidgetState();
}

class _ShoppingItemTileWidgetState extends State<ShoppingItemTileWidget>
    with SingleTickerProviderStateMixin {
  AnimationController? _highlightController;
  Animation<Color?>? _highlightAnimation;

  @override
  void initState() {
    super.initState();
    _initHighlightIfNeeded();
  }

  @override
  void didUpdateWidget(ShoppingItemTileWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.highlightUntil != oldWidget.highlightUntil) {
      _initHighlightIfNeeded();
    }
  }

  void _initHighlightIfNeeded() {
    if (widget.highlightUntil != null &&
        widget.highlightUntil!.isAfter(DateTime.now())) {
      _highlightController?.dispose();
      _highlightController = AnimationController(
        duration: const Duration(seconds: 3),
        vsync: this,
      );
      _highlightAnimation = ColorTween(
        begin: Colors.yellow.withValues(alpha: 0.3),
        end: Colors.transparent,
      ).animate(CurvedAnimation(
        parent: _highlightController!,
        curve: Curves.easeOut,
      ));
      _highlightController!.forward();
    } else {
      _highlightController?.dispose();
      _highlightController = null;
      _highlightAnimation = null;
    }
  }

  @override
  void dispose() {
    _highlightController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tile = Dismissible(
      key: Key(widget.item.id),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.blue,
        child: const Icon(
          Icons.edit,
          color: Colors.white,
        ),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        color: Colors.red,
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          widget.onEdit?.call();
          return false;
        } else {
          return await _showDeleteConfirmation(context);
        }
      },
      child: Semantics(
        label: AccessibilityHelpers.shoppingItemLabel(
          name: widget.item.name,
          quantity: widget.item.quantity,
          unit: widget.item.unit,
          isPurchased: widget.item.isPurchased,
        ),
        button: true,
        child: ListTile(
          onTap: widget.onTap,
          leading: Semantics(
            button: true,
            label: AccessibilityHelpers.markAsPurchasedLabel(
              itemName: widget.item.name,
              currentlyPurchased: widget.item.isPurchased,
            ),
            child: GestureDetector(
              onTap: widget.onTogglePurchased,
              child: Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: widget.item.isPurchased ? Colors.green : Colors.grey,
                      width: 2,
                    ),
                    color: widget.item.isPurchased ? Colors.green : Colors.transparent,
                  ),
                  child: widget.item.isPurchased
                      ? const Icon(
                          Icons.check,
                          size: 18,
                          color: Colors.white,
                        )
                      : null,
                ),
              ),
            ),
          ),
        title: Text(
          widget.item.name,
          style: TextStyle(
            decoration: widget.item.isPurchased ? TextDecoration.lineThrough : null,
            color: widget.item.isPurchased ? Colors.grey : null,
          ),
        ),
        subtitle: _buildSubtitle(context),
        trailing: _buildTrailing(context),
        ),
      ),
    );

    if (_highlightAnimation != null && _highlightController != null) {
      return AnimatedBuilder(
        animation: _highlightController!,
        builder: (context, child) {
          return Container(
            color: _highlightAnimation!.value,
            child: child,
          );
        },
        child: tile,
      );
    }

    return tile;
  }

  Widget? _buildSubtitle(BuildContext context) {
    final parts = <String>[];

    if (widget.item.quantity != 1) {
      parts.add('${widget.item.quantity}');
    }

    if (widget.item.notes != null && widget.item.notes!.isNotEmpty) {
      parts.add(widget.item.notes!);
    }

    if (widget.item.isPurchased && widget.item.purchasedAt != null) {
      parts.add('تم الشراء');
    }

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

  Widget? _buildTrailing(BuildContext context) {
    if (widget.showPendingIndicator) {
      return const PendingSyncIndicator();
    }
    if (widget.item.hasPrice) {
      return Text(
        widget.item.formattedPrice,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      );
    }
    return null;
  }

  Future<bool?> _showDeleteConfirmation(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف المنتج'),
        content: Text('هل أنت متأكد من حذف "${widget.item.name}"؟'),
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
