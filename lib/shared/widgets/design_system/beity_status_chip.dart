import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';

class BeityStatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  final bool compact;

  const BeityStatusChip({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.compact = false,
  });

  factory BeityStatusChip.success(String label, {IconData? icon, bool compact = false}) {
    return BeityStatusChip(label: label, color: AppColors.success, icon: icon ?? Icons.check_circle, compact: compact);
  }

  factory BeityStatusChip.warning(String label, {IconData? icon, bool compact = false}) {
    return BeityStatusChip(label: label, color: AppColors.warning, icon: icon ?? Icons.warning, compact: compact);
  }

  factory BeityStatusChip.error(String label, {IconData? icon, bool compact = false}) {
    return BeityStatusChip(label: label, color: AppColors.error, icon: icon ?? Icons.error, compact: compact);
  }

  factory BeityStatusChip.info(String label, {IconData? icon, bool compact = false}) {
    return BeityStatusChip(label: label, color: AppColors.info, icon: icon ?? Icons.info, compact: compact);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 10,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: compact ? 12 : 14, color: color),
            SizedBox(width: compact ? 2 : 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: compact ? 10 : 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
