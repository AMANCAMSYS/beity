import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sawa/app/theme/app_spacing.dart';
import 'package:sawa/app/theme/app_colors.dart';
import 'package:sawa/shared/widgets/design_system/sawa_card.dart';
import '../../data/models/home_member_model.dart';
import 'package:sawa/core/localization/app_localizations.dart';

class MemberCardWidget extends StatelessWidget {
  final HomeMemberModel member;
  final VoidCallback? onRemove;
  final bool isCurrentUserOwner;

  const MemberCardWidget({
    super.key,
    required this.member,
    this.onRemove,
    this.isCurrentUserOwner = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOwner = member.role == 'owner';
    final isAdmin = member.role == 'admin';

    return SawaCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: isOwner
                ? AppColors.warning.withValues(alpha: 0.1)
                : isAdmin
                ? AppColors.primary.withValues(alpha: 0.1)
                : theme.colorScheme.surfaceContainerHighest,
            child: Icon(
              isOwner
                  ? Icons.star_rounded
                  : isAdmin
                  ? Icons.admin_panel_settings_rounded
                  : Icons.person_rounded,
              color: isOwner
                  ? AppColors.warning
                  : isAdmin
                  ? AppColors.primary
                  : theme.colorScheme.onSurfaceVariant,
              size: 28,
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
                        member.userName ?? context.translate('guest_user'),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isOwner)
                      _buildBadge(
                        context,
                        context.translate('role_owner'),
                        AppColors.warning,
                        Icons.star_rounded,
                      )
                    else if (isAdmin)
                      _buildBadge(
                        context,
                        context.translate('role_admin'),
                        AppColors.primary,
                        Icons.admin_panel_settings_rounded,
                      ),
                    if (isCurrentUserOwner && !isOwner && onRemove != null) ...[
                      AppSpacing.gapXS,
                      GestureDetector(
                        onTap: onRemove,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.remove_circle_outline_rounded,
                            size: 18,
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                AppSpacing.gapXXS,
                Text(
                  _getRoleName(context, member.role),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                AppSpacing.gapXXS,
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 12,
                      color: theme.colorScheme.outline,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      context.translate(
                        'joined_date',
                        arguments: {
                          'date': DateFormat(
                            'yyyy/MM/dd',
                            Localizations.localeOf(context).languageCode,
                          ).format(member.joinedAt),
                        },
                      ),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(
    BuildContext context,
    String label,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _getRoleName(BuildContext context, String role) {
    switch (role) {
      case 'owner':
        return context.translate('role_owner');
      case 'admin':
        return context.translate('role_admin');
      case 'member':
        return context.translate('role_member');
      case 'viewer':
        return context.translate('role_viewer');
      default:
        return role;
    }
  }
}
