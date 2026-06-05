import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../shared/widgets/design_system/sawa_dialog.dart';
import '../../domain/entities/shopping_item.dart';
import '../../../offline_queue/presentation/widgets/pending_sync_indicator.dart';
import '../../../../core/accessibility/semantics_helpers.dart';
import '../../../../core/localization/app_localizations.dart';
import 'package:flutter/services.dart';

class ShoppingItemTileWidget extends StatefulWidget {
  final ShoppingItem item;
  final String? unitName;
  final VoidCallback? onTap;
  final VoidCallback? onTogglePurchased;
  final VoidCallback? onEdit;
  final VoidCallback? onQuantityTap;
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
    this.onQuantityTap,
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
  bool? _optimisticPurchased;
  bool _isProcessing = false;

  bool get _isPurchased => _optimisticPurchased ?? widget.item.isPurchased;

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
    final itemIdentityChanged = oldWidget.item.id != widget.item.id;
    final purchaseStateChanged =
        oldWidget.item.isPurchased != widget.item.isPurchased;

    if (itemIdentityChanged || purchaseStateChanged) {
      _optimisticPurchased = null;
      _isProcessing = false;
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
      _highlightAnimation =
          ColorTween(
            begin: Colors.yellow.withValues(alpha: 0.3),
            end: Colors.transparent,
          ).animate(
            CurvedAnimation(
              parent: _highlightController!,
              curve: Curves.easeOut,
            ),
          );
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

  bool get _hasPartialPurchase =>
      widget.item.purchasedQuantity > 0 &&
      widget.item.purchasedQuantity < widget.item.quantity &&
      !_isPurchased;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tile = Dismissible(
      key: Key(widget.item.id),
      background: Container(
        alignment: AlignmentDirectional.centerStart,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        color: AppColors.info,
        child: const Icon(Icons.edit, color: Colors.white),
      ),
      secondaryBackground: Container(
        alignment: AlignmentDirectional.centerEnd,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        color: AppColors.error,
        child: const Icon(Icons.delete, color: Colors.white),
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
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          widget.onDelete?.call();
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
              currentlyPurchased: _isPurchased,
            ),
            child: InkResponse(
              onTap: _isProcessing
                  ? null
                  : () {
                      final tappedItemId = widget.item.id;
                      final willBePurchased = !_isPurchased;
                      if (widget.hapticsEnabled) {
                        if (willBePurchased) {
                          HapticFeedback.mediumImpact();
                        } else {
                          HapticFeedback.selectionClick();
                        }
                      }
                      if (widget.soundsEnabled) {
                        SystemSound.play(SystemSoundType.click);
                      }
                      setState(() {
                        _optimisticPurchased = willBePurchased;
                        _isProcessing = true;
                      });
                      Future.delayed(const Duration(milliseconds: 500), () {
                        if (mounted && widget.item.id == tappedItemId) {
                          widget.onTogglePurchased?.call();
                        }
                      });
                    },
              radius: widget.isCompact ? 18 : 22,
              splashColor: AppColors.success.withValues(alpha: 0.2),
              highlightColor: Colors.transparent,
              child: _buildLeadingIcon(theme),
            ),
          ),
          title: Text(
            widget.item.name,
            style: TextStyle(
              decoration: _isPurchased ? TextDecoration.lineThrough : null,
              color: _isPurchased
                  ? theme.colorScheme.onSurface.withValues(alpha: 0.5)
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
          return Container(color: _highlightAnimation!.value, child: child);
        },
        child: tile,
      );
    }

    return tile;
  }

  Widget _buildLeadingIcon(ThemeData theme) {
    final size = widget.isCompact ? 24.0 : 28.0;
    final containerSize = widget.isCompact ? 36.0 : 44.0;

    if (_hasPartialPurchase) {
      final progress = widget.item.purchasedQuantity / widget.item.quantity;
      return Container(
        width: containerSize,
        height: containerSize,
        alignment: Alignment.center,
        child: SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
              ),
              SizedBox(
                width: size,
                height: size,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 2.5,
                  backgroundColor: Colors.transparent,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.warning,
                  ),
                ),
              ),
              Text(
                '½',
                style: TextStyle(
                  fontSize: size * 0.38,
                  fontWeight: FontWeight.bold,
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      width: containerSize,
      height: containerSize,
      alignment: Alignment.center,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: _isPurchased
                ? AppColors.success
                : AppColors.textHintFor(theme.brightness),
            width: 2,
          ),
          color: _isPurchased ? AppColors.success : Colors.transparent,
        ),
        child: _isPurchased
            ? const Icon(Icons.check, size: 18, color: Colors.white)
            : null,
      ),
    );
  }

  Widget? _buildSubtitle(BuildContext context) {
    final theme = Theme.of(context);
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

    if (_isPurchased && widget.item.purchasedAt != null) {
      parts.add(context.translate('purchased'));
    }

    Widget? badge;
    if (_hasPartialPurchase) {
      final qty = widget.item.quantity == widget.item.quantity.roundToDouble()
          ? widget.item.quantity.toInt().toString()
          : widget.item.quantity.toStringAsFixed(1);

      final purchasedQty =
          widget.item.purchasedQuantity ==
              widget.item.purchasedQuantity.roundToDouble()
          ? widget.item.purchasedQuantity.toInt().toString()
          : widget.item.purchasedQuantity.toStringAsFixed(1);

      final text = context.translate(
        'bought_of_total',
        arguments: {
          'bought': purchasedQty,
          'total': widget.unitName != null ? '$qty ${widget.unitName}' : qty,
        },
      );

      badge = Container(
        margin: const EdgeInsets.only(top: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.pie_chart_outline,
              size: 12,
              color: AppColors.warning,
            ),
            const SizedBox(width: 6),
            Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.warning,
              ),
            ),
          ],
        ),
      );
    }

    if (parts.isEmpty && badge == null) return null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (parts.isNotEmpty)
          Text(
            parts.join(' • '),
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondaryFor(theme.brightness),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ?badge,
      ],
    );
  }

  Widget? _buildTrailing(BuildContext context) {
    if (widget.showPendingIndicator) {
      return const PendingSyncIndicator();
    }

    final theme = Theme.of(context);
    final hasPrice = widget.item.hasPrice;
    final canEditQuantity = widget.item.quantity > 1;

    if (!hasPrice && !canEditQuantity) return null;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (canEditQuantity)
          IconButton(
            icon: Icon(
              Icons.pie_chart_outline,
              size: 20,
              color: theme.colorScheme.primary,
            ),
            onPressed: widget.onQuantityTap,
            tooltip: context.translate('partially_purchased'),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        if (canEditQuantity && hasPrice) const SizedBox(width: 12),
        if (hasPrice)
          Text(
            widget.item.formattedPrice,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
      ],
    );
  }

  Future<bool?> _showDeleteConfirmation(BuildContext context) {
    return SawaDialog.show(
      context,
      title: context.translate('delete_item_title'),
      message: context.translate(
        'delete_item_message',
        arguments: {'name': widget.item.name},
      ),
      confirmText: context.translate('delete'),
      cancelText: context.translate('cancel'),
      isDestructive: true,
      icon: Icons.delete_outline_rounded,
    );
  }
}
