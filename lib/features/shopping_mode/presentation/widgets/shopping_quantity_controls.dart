import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ShoppingQuantityControls extends StatelessWidget {
  final double quantity;
  final String? unit;
  final ValueChanged<double> onChanged;

  const ShoppingQuantityControls({
    super.key,
    required this.quantity,
    this.unit,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildButton(
            context,
            icon: Icons.remove,
            onTap: () {
              if (quantity > 1) {
                HapticFeedback.lightImpact();
                onChanged(quantity - 1);
              }
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              _formatQuantity(quantity),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _buildButton(
            context,
            icon: Icons.add,
            onTap: () {
              HapticFeedback.lightImpact();
              onChanged(quantity + 1);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return IconButton(
      onPressed: onTap,
      iconSize: 20,
      color: theme.colorScheme.primary,
      style: IconButton.styleFrom(
        backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
        padding: EdgeInsets.zero,
        minimumSize: const Size(40, 40),
        maximumSize: const Size(40, 40),
      ),
      icon: Icon(icon),
    );
  }

  String _formatQuantity(double qty) {
    return qty == qty.roundToDouble() ? qty.toInt().toString() : qty.toStringAsFixed(1);
  }
}
