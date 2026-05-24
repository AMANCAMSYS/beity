import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:beity/app/theme/app_spacing.dart';
import 'package:beity/app/theme/app_colors.dart';
import 'package:beity/shared/widgets/design_system/beity_card.dart';
import '../../data/models/home_member_model.dart';

class MemberCardWidget extends StatelessWidget {
  final HomeMemberModel member;

  const MemberCardWidget({super.key, required this.member});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOwner = member.role == 'owner';
    final isAdmin = member.role == 'admin';

    return BeityCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: isOwner
                ? Colors.amber.withValues(alpha: 0.1)
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
                  ? Colors.amber
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
                        member.userName ?? 'مستخدم',
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
                        'مالك',
                        Colors.amber,
                        Icons.star_rounded,
                      )
                    else if (isAdmin)
                      _buildBadge(
                        context,
                        'مشرف',
                        AppColors.primary,
                        Icons.admin_panel_settings_rounded,
                      ),
                  ],
                ),
                AppSpacing.gapXXS,
                Text(
                  _getRoleName(member.role),
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
                      'انضم: ${DateFormat('yyyy/MM/dd', 'ar').format(member.joinedAt)}',
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

  String _getRoleName(String role) {
    switch (role) {
      case 'owner':
        return 'مالك';
      case 'admin':
        return 'مشرف';
      case 'member':
        return 'عضو';
      case 'viewer':
        return 'مشاهد';
      default:
        return role;
    }
  }
}
