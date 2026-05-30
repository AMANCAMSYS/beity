import 'package:flutter/material.dart';
import 'package:beity/app/theme/app_spacing.dart';
import 'package:beity/app/theme/app_colors.dart';
import 'package:beity/shared/widgets/design_system/beity_card.dart';
import '../../domain/entities/task.dart';
import 'package:beity/core/localization/app_localizations.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback? onTap;
  final VoidCallback? onComplete;
  final String? assigneeName;

  const TaskCard({
    super.key,
    required this.task,
    this.onTap,
    this.onComplete,
    this.assigneeName,
  });

  Color _getDueDateColor() {
    if (task.isOverdue) return AppColors.error;
    if (task.isDueToday) return AppColors.warning;
    return AppColors.textHintLight;
  }

  String _getDueDateText(BuildContext context) {
    if (task.dueDate == null) return '';
    final now = DateTime.now();
    final due = task.dueDate!;
    final difference = due.difference(now).inDays;

    if (task.isOverdue) return context.translate('overdue');
    if (task.isDueToday) return context.translate('today');
    if (difference == 1) return context.translate('tomorrow');
    return '${due.day}/${due.month}/${due.year}';
  }

  String _getRecurrenceText(BuildContext context) {
    switch (task.recurrenceType) {
      case 'daily':
        return context.translate('daily');
      case 'weekly':
        return context.translate('weekly');
      case 'monthly':
        return context.translate('monthly');
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return BeityCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Indicator Stripe
            Container(
              width: 6,
              decoration: BoxDecoration(
                color: task.isCompleted
                    ? AppColors.success.withValues(alpha: 0.5)
                    : (task.isOverdue ? AppColors.error : AppColors.primary),
                borderRadius: isArabic
                    ? const BorderRadius.only(
                        topRight: Radius.circular(AppSpacing.radiusLg),
                        bottomRight: Radius.circular(AppSpacing.radiusLg),
                      )
                    : const BorderRadius.only(
                        topLeft: Radius.circular(AppSpacing.radiusLg),
                        bottomLeft: Radius.circular(AppSpacing.radiusLg),
                      ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    // Completion Checkbox
                    Transform.scale(
                      scale: 1.1,
                      child: Checkbox(
                        value: task.isCompleted,
                        onChanged: onComplete != null ? (_) => onComplete!() : null,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                        ),
                        activeColor: AppColors.success,
                      ),
                    ),
                    AppSpacing.gapSM,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            task.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                              color: task.isCompleted ? theme.colorScheme.outline : null,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (task.description != null && task.description!.isNotEmpty) ...[
                            AppSpacing.gapXXS,
                            Text(
                              task.description!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                          AppSpacing.gapSM,
                          Wrap(
                            spacing: AppSpacing.md,
                            runSpacing: AppSpacing.xxs,
                            children: [
                              if (task.assignedTo != null && assigneeName != null)
                                _buildInfoTag(
                                  context,
                                  Icons.person_rounded,
                                  assigneeName!,
                                  theme.colorScheme.onSurfaceVariant,
                                ),
                              if (task.dueDate != null)
                                _buildInfoTag(
                                  context,
                                  Icons.calendar_today_rounded,
                                  _getDueDateText(context),
                                  _getDueDateColor(),
                                  isBold: task.isOverdue || task.isDueToday,
                                ),
                              if (task.isRecurring)
                                _buildInfoTag(
                                  context,
                                  Icons.repeat_rounded,
                                  _getRecurrenceText(context),
                                  theme.colorScheme.primary,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (task.isCompleted)
                      Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.success.withValues(alpha: 0.7),
                        size: 24,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTag(
    BuildContext context,
    IconData icon,
    String text,
    Color color, {
    bool isBold = false,
  }) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: theme.textTheme.labelSmall?.copyWith(
            color: color,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
