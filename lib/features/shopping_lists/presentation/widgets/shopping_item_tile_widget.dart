import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../shared/widgets/design_system/beity_dialog.dart';
import '../../domain/entities/shopping_item.dart';
import '../../../offline_queue/presentation/widgets/pending_sync_indicator.dart';
import '../../../../core/accessibility/semantics_helpers.dart';
import 'package:flutter/services.dart';

class ShoppingItemTileWidget extends StatefulWidget {
  final ShoppingItem item;
  final String? unitName;
  final VoidCallback? onTap;
  final VoidCallback? onTogglePurchased;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onDelete;
  final DateTime? highlightUntil;
  final bool showPendingIndicator;
  final bool isCompact;
  final bool hapticsEnabled;
  final bool soundsEnabled;

  const ShoppingItemTileWidget({
    super.key,
    required this.item,
    this.unitName,
    this.onTap,
    this.onTogglePurchased,
    this.onEdit,
    this.onDelete,
    this.highlightUntil,
    this.showPendingIndicator = false,
    this.isCompact = false,
    this.hapticsEnabled = true,
    this.soundsEnabled = true,
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
    final theme = Theme.of(context);
    final tile = Dismissible(
      key: Key(widget.item.id),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.info,
        child: const Icon(
          Icons.edit,
          color: Colors.white,
        ),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        color: AppColors.error,
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          if (widget.hapticsEnabled) HapticFeedback.lightImpact();
          widget.onEdit?.call();
          return false;
        } else {
          if (widget.hapticsEnabled) HapticFeedback.lightImpact();
          return _showDeleteConfirmation(context);
        }
      },
      child: Semantics(
        label: AccessibilityHelpers.shoppingItemLabel(
          name: widget.item.name,
          quantity: widget.item.quantity,
          unit: widget.unitName,
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
            child: InkResponse(
              onTap: () {
                if (widget.hapticsEnabled) HapticFeedback.selectionClick();
                if (widget.soundsEnabled) SystemSound.play(SystemSoundType.click);
                widget.onTogglePurchased?.call();
              },
              radius: widget.isCompact ? 18 : 22,
              splashColor: AppColors.success.withValues(alpha: 0.2),
              highlightColor: Colors.transparent,
              child: Container(
                width: widget.isCompact ? 36 : 44,
                height: widget.isCompact ? 36 : 44,
                alignment: Alignment.center,
                child: Container(
                  width: widget.isCompact ? 24 : 28,
                  height: widget.isCompact ? 24 : 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: widget.item.isPurchased
                          ? AppColors.success
                          : AppColors.textHintFor(theme.brightness),
                      width: 2,
                    ),
                    color: widget.item.isPurchased
                        ? AppColors.success
                        : Colors.transparent,
                  ),
                  child: widget.item.isPurchased
                      ? const Icon(Icons.check, size: 18, color: Colors.white)
                      : null,
                ),
              ),
            ),
          ),
        title: Text(
          widget.item.name,
          style: TextStyle(
            decoration: widget.item.isPurchased ? TextDecoration.lineThrough : null,
            color: widget.item.isPurchased
                ? AppColors.textSecondaryFor(theme.brightness)
                : null,
          ),
        ),
        subtitle: _buildSubtitle(context),
        trailing: _buildTrailing(context),
        dense: widget.isCompact,
        contentPadding: widget.isCompact 
            ? const EdgeInsets.symmetric(horizontal: 16, vertical: -4)
            : const EdgeInsets.symmetric(horizontal: 16),
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
    final theme = Theme.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final parts = <String>[];

    if (widget.item.quantity != 1 || widget.unitName != null) {
      final qty = widget.item.quantity == widget.item.quantity.roundToDouble()
          ? widget.item.quantity.toInt().toString()
          : widget.item.quantity.toStringAsFixed(1);
      parts.add(widget.unitName != null ? '$qty ${widget.unitName}' : qty);
    }

    if (widget.item.notes != null && widget.item.notes!.isNotEmpty) {
      parts.add(widget.item.notes!);
    }

    if (widget.item.isPurchased && widget.item.purchasedAt != null) {
      parts.add(isArabic ? 'تم الشراء' : 'Purchased');
    }

    if (parts.isEmpty) return null;

    return Text(
      parts.join(' • '),
      style: theme.textTheme.bodySmall?.copyWith(
        color: AppColors.textSecondaryFor(theme.brightness),
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
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return BeityDialog.show(
      context,
      title: isArabic ? 'حذف المنتج' : 'Delete Item',
      message: isArabic
          ? 'هل أنت متأكد من حذف "${widget.item.name}"؟'
          : 'Are you sure you want to delete "${widget.item.name}"?',
      confirmText: isArabic ? 'حذف' : 'Delete',
      cancelText: isArabic ? 'إلغاء' : 'Cancel',
      isDestructive: true,
      icon: Icons.delete_outline_rounded,
    );
  }
}
