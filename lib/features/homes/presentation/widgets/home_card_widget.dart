import 'package:flutter/material.dart';

import 'package:beity/app/theme/app_spacing.dart';
import 'package:beity/app/theme/app_colors.dart';
import 'package:beity/shared/widgets/design_system/beity_card.dart';
import '../../domain/entities/home_type.dart';
import '../../data/models/home_model.dart';

class HomeCardWidget extends StatelessWidget {
  final HomeModel home;
  final bool isActive;
  final VoidCallback? onTap;

  const HomeCardWidget({
    super.key,
    required this.home,
    this.isActive = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final homeType = HomeType.fromValue(home.type);
    final theme = Theme.of(context);

    return BeityCard(
      onTap: onTap,
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      variant: isActive ? BeityCardVariant.outlined : BeityCardVariant.elevated,
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(
              _getIconForType(homeType),
              color: isActive ? AppColors.primary : theme.colorScheme.onSurfaceVariant,
              size: 32,
            ),
          ),
          AppSpacing.gapMD,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        home.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isActive)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                        ),
                        child: Text(
                          'نشط',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                AppSpacing.gapXXS,
                Text(
                  homeType.arabicName,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios_rounded,
            size: 14,
            color: theme.colorScheme.outline,
          ),
        ],
      ),
    );
  }

  IconData _getIconForType(HomeType type) {
    switch (type) {
      case HomeType.family:
        return Icons.family_restroom_rounded;
      case HomeType.couple:
        return Icons.favorite_rounded;
      case HomeType.sharedHouse:
        return Icons.people_rounded;
      case HomeType.studentHousing:
        return Icons.school_rounded;
      case HomeType.singleUser:
        return Icons.person_rounded;
      case HomeType.office:
        return Icons.business_rounded;
    }
  }
}
