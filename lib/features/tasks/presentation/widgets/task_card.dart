import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sawa/app/theme/app_spacing.dart';
import 'package:sawa/app/theme/app_colors.dart';
import 'package:sawa/shared/widgets/design_system/sawa_card.dart';
import '../../domain/entities/task.dart';
import 'package:sawa/core/localization/app_localizations.dart';

class TaskCard extends StatefulWidget {
  final Task task;
  final VoidCallback? onTap;
  final Future<void> Function()? onComplete;
  final String? assigneeName;
  final String? completedByName;
  final bool hapticsEnabled;
  final bool soundsEnabled;

  const TaskCard({
    super.key,
    required this.task,
    this.onTap,
    this.onComplete,
    this.assigneeName,
    this.completedByName,
    this.hapticsEnabled = true,
    this.soundsEnabled = true,
  });

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard> {
  bool? _optimisticCompleted;
  bool _isProcessing = false;

  bool get _isCompleted => _optimisticCompleted ?? widget.task.isCompleted;

  @override
  void didUpdateWidget(TaskCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final taskIdentityChanged = oldWidget.task.id != widget.task.id;
    final completionStateChanged =
        oldWidget.task.isCompleted != widget.task.isCompleted;

    if (taskIdentityChanged || completionStateChanged) {
      _optimisticCompleted = null;
      _isProcessing = false;
    }
  }

  Color _getDueDateColor() {
    if (widget.task.isOverdue) return AppColors.error;
    if (widget.task.isDueToday) return AppColors.warning;
    return AppColors.textHintLight;
  }

  String _getDueDateText(BuildContext context) {
    if (widget.task.dueDate == null) return '';
    final now = DateTime.now();
    final due = widget.task.dueDate!;
    final difference = due.difference(now).inDays;

    if (widget.task.isOverdue) return context.translate('overdue');
    if (widget.task.isDueToday) return context.translate('today');
    if (difference == 1) return context.translate('tomorrow');
    return '${due.day}/${due.month}/${due.year}';
  }

  String _getRecurrenceText(BuildContext context) {
    switch (widget.task.recurrenceType) {
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

  Future<void> _handleCompleteTap() async {
    if (_isProcessing || widget.onComplete == null) return;

    final willBeCompleted = !_isCompleted;
    if (widget.hapticsEnabled) {
      if (willBeCompleted) {
        HapticFeedback.mediumImpact();
      } else {
        HapticFeedback.selectionClick();
      }
    }
    if (widget.soundsEnabled) {
      SystemSound.play(SystemSoundType.click);
    }

    setState(() {
      _optimisticCompleted = willBeCompleted;
      _isProcessing = true;
    });

    final tappedTaskId = widget.task.id;
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted || widget.task.id != tappedTaskId) return;

    try {
      await widget.onComplete!();
    } catch (_) {
      if (mounted) {
        setState(() {
          _optimisticCompleted = null;
          _isProcessing = false;
        });
      }
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SawaCard(
      onTap: widget.onTap,
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
                color: _isCompleted
                    ? AppColors.success.withValues(alpha: 0.5)
                    : (widget.task.isOverdue
                          ? AppColors.error
                          : AppColors.primary),
                borderRadius: const BorderRadiusDirectional.only(
                  topStart: Radius.circular(AppSpacing.radiusLg),
                  bottomStart: Radius.circular(AppSpacing.radiusLg),
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
                        value: _isCompleted,
                        onChanged: widget.onComplete != null
                            ? (_) => _handleCompleteTap()
                            : null,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusSm,
                          ),
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
                            widget.task.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              decoration: _isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: _isCompleted
                                  ? theme.colorScheme.outline
                                  : null,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (widget.task.description != null &&
                              widget.task.description!.isNotEmpty) ...[
                            AppSpacing.gapXXS,
                            Text(
                              widget.task.description!,
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
                              if (widget.task.assignedTo != null &&
                                  widget.assigneeName != null)
                                _buildInfoTag(
                                  context,
                                  Icons.person_rounded,
                                  widget.assigneeName!,
                                  theme.colorScheme.onSurfaceVariant,
                                ),
                              if (widget.task.assignedTo == null &&
                                  widget.task.isCompleted &&
                                  widget.completedByName != null)
                                _buildInfoTag(
                                  context,
                                  Icons.verified_rounded,
                                  context.translate(
                                    'completed_by_name',
                                    arguments: {
                                      'name': widget.completedByName!,
                                    },
                                  ),
                                  AppColors.success,
                                  isBold: true,
                                ),
                              if (widget.task.dueDate != null)
                                _buildInfoTag(
                                  context,
                                  Icons.calendar_today_rounded,
                                  _getDueDateText(context),
                                  _getDueDateColor(),
                                  isBold:
                                      widget.task.isOverdue ||
                                      widget.task.isDueToday,
                                ),
                              if (widget.task.isRecurring)
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
                    if (_isCompleted)
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
