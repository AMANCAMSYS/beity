import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sawa/core/localization/app_localizations.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:sawa/app/theme/app_spacing.dart';
import 'package:sawa/app/theme/app_colors.dart';
import 'package:sawa/shared/widgets/design_system/sawa_card.dart';
import 'package:sawa/shared/widgets/design_system/sawa_button.dart';
import 'package:sawa/core/services/app_logger.dart';
import 'package:sawa/core/utils/action_debouncer.dart';
import '../../data/models/invitation_model.dart';
import '../../domain/entities/invitation.dart';
import '../../../homes/presentation/providers/homes_provider.dart';
import '../providers/invitations_provider.dart';

class InvitationCardWidget extends ConsumerWidget {
  final InvitationModel invitation;
  final bool isOwner;

  const InvitationCardWidget({
    super.key,
    required this.invitation,
    this.isOwner = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isPending = invitation.isPending;

    return SawaCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: _getStatusColor().withValues(alpha: 0.1),
                child: Icon(
                  _getStatusIcon(),
                  color: _getStatusColor(),
                  size: 20,
                ),
              ),
              AppSpacing.gapMD,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      invitation.email ?? context.translate('invitation'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textDirection: TextDirection.ltr,
                    ),
                    AppSpacing.gapXXS,
                    Text(
                      '${context.translate('role_label')}: ${_getRoleName(context)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusChip(context),
            ],
          ),
          if (invitation.createdAt != null) ...[
            AppSpacing.gapSM,
            Row(
              children: [
                Icon(
                  Icons.access_time_rounded,
                  size: 12,
                  color: theme.colorScheme.outline,
                ),
                const SizedBox(width: 4),
                Text(
                  timeago.format(
                    invitation.createdAt!,
                    locale: Localizations.localeOf(context).languageCode,
                  ),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
          ],
          if (isPending) ...[
            AppSpacing.gapLG,
            if (!isOwner)
              Row(
                children: [
                  Expanded(
                    child: SawaButton(
                      onPressed: () => ActionDebouncer.execute(
                        () => _declineInvitation(ref),
                      ),
                      text: context.translate('reject'),
                      type: SawaButtonType.secondary,
                    ),
                  ),
                  AppSpacing.gapMD,
                  Expanded(
                    child: SawaButton(
                      onPressed: () =>
                          ActionDebouncer.execute(() => _acceptInvitation(ref)),
                      text: context.translate('accept'),
                      type: SawaButtonType.primary,
                    ),
                  ),
                ],
              )
            else
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => ActionDebouncer.execute(
                    () => _cancelInvitation(ref, context),
                  ),
                  icon: const Icon(
                    Icons.cancel_outlined,
                    color: Color(0xFFEF5350),
                    size: 18,
                  ),
                  label: Text(
                    context.translate('cancel_invitation'),
                    style: const TextStyle(
                      color: Color(0xFFEF5350),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                      color: Color(0x7FEF5350),
                      width: 1.2,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    backgroundColor: const Color(0x0AEF5350),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Color _getStatusColor() {
    switch (invitation.status) {
      case InvitationStatus.pending:
        return AppColors.warning;
      case InvitationStatus.accepted:
        return AppColors.success;
      case InvitationStatus.expired:
        return AppColors.textHintLight;
      case InvitationStatus.cancelled:
        return AppColors.error;
    }
  }

  IconData _getStatusIcon() {
    switch (invitation.status) {
      case InvitationStatus.pending:
        return Icons.hourglass_empty;
      case InvitationStatus.accepted:
        return Icons.check_circle;
      case InvitationStatus.expired:
        return Icons.access_time;
      case InvitationStatus.cancelled:
        return Icons.cancel;
    }
  }

  Widget _buildStatusChip(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor().withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Text(
        _getStatusName(context),
        style: theme.textTheme.labelSmall?.copyWith(
          color: _getStatusColor(),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _getStatusName(BuildContext context) {
    switch (invitation.status) {
      case InvitationStatus.pending:
        return context.translate('invitation_status_pending');
      case InvitationStatus.accepted:
        return context.translate('invitation_status_accepted');
      case InvitationStatus.expired:
        return context.translate('invitation_status_expired');
      case InvitationStatus.cancelled:
        return context.translate('invitation_status_cancelled');
    }
  }

  String _getRoleName(BuildContext context) {
    switch (invitation.role) {
      case 'admin':
        return context.translate('admin');
      case 'member':
        return context.translate('member');
      case 'viewer':
        return context.translate('viewer');
      default:
        return invitation.role;
    }
  }

  Future<void> _acceptInvitation(WidgetRef ref) async {
    try {
      await ref
          .read(invitationNotifierProvider.notifier)
          .acceptInvitation(token: invitation.token);
      // Invalidate homes list so the new home appears
      ref.invalidate(userHomesProvider);
    } catch (e) {
      // Error is handled by the provider
    }
  }

  Future<void> _declineInvitation(WidgetRef ref) async {
    try {
      await ref
          .read(invitationNotifierProvider.notifier)
          .declineInvitation(token: invitation.token);
    } catch (e) {
      // Error is handled by the provider
    }
  }

  Future<void> _cancelInvitation(
    WidgetRef ref,
    BuildContext outerContext,
  ) async {
    AppLogger.i(
      'Cancelling invitation: ${invitation.id} for ${invitation.email}',
    );
    final confirmed = await showDialog<bool>(
      context: outerContext,
      builder: (context) => AlertDialog(
        title: Text(
          outerContext.translate('cancel_invitation_question'),
          textDirection: Directionality.of(outerContext),
        ),
        content: Text(
          outerContext.translate(
            'cancel_invitation_confirm',
            arguments: {'email': invitation.email ?? ''},
          ),
          textDirection: Directionality.of(outerContext),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.translate('undo')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(context.translate('cancel_invitation')),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref
            .read(invitationNotifierProvider.notifier)
            .cancelInvitation(invitationId: invitation.id);
        if (outerContext.mounted) {
          ScaffoldMessenger.of(outerContext).showSnackBar(
            SnackBar(
              content: Text(
                outerContext.translate('invitation_cancelled_success'),
                textDirection: Directionality.of(outerContext),
              ),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        AppLogger.i('Error cancelling invitation: $e');
        if (outerContext.mounted) {
          ScaffoldMessenger.of(outerContext).showSnackBar(
            SnackBar(
              content: Text(
                outerContext.translate(
                  'invitation_cancel_failed',
                  arguments: {'error': e.toString()},
                ),
                textDirection: Directionality.of(outerContext),
              ),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }
}
