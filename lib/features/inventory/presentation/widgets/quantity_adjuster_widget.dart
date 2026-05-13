import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class QuantityAdjusterWidget extends StatelessWidget {
  final double quantity;
  final String? unitId;
  final ValueChanged<double> onChanged;

  const QuantityAdjusterWidget({
    super.key,
    required this.quantity,
    this.unitId,
    required this.onChanged,
  });

  double get _step {
    // Fractional units (kg, liters) use 0.5 step; whole units use 1
    // This will be refined with actual unit data
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StepButton(
          icon: Icons.remove,
          onTap: () {
            HapticFeedback.lightImpact();
            final newQty = (quantity - _step).clamp(0.0, double.infinity);
            onChanged(newQty);
          },
        ),
        SizedBox(
          width: 64,
          child: Text(
            _formatQuantity(quantity),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        _StepButton(
          icon: Icons.add,
          onTap: () {
            HapticFeedback.lightImpact();
            onChanged(quantity + _step);
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
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _StepButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: Material(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Icon(icon, size: 24),
        ),
      ),
    );
  }
}
