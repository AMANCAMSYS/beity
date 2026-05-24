import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:beity/app/theme/app_spacing.dart';
import 'package:beity/app/theme/app_colors.dart';
import 'package:beity/shared/widgets/design_system/beity_card.dart';
import 'package:beity/shared/widgets/design_system/beity_button.dart';
import 'package:beity/core/utils/action_debouncer.dart';
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

    return BeityCard(
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
                      invitation.email ?? 'دعوة',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textDirection: TextDirection.ltr,
                    ),
                    AppSpacing.gapXXS,
                    Text(
                      'الدور: ${_getRoleName()}',
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
                  timeago.format(invitation.createdAt!, locale: 'ar'),
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
                    child: BeityButton(
                      onPressed: () => ActionDebouncer.execute(() => _declineInvitation(ref)),
                      text: 'رفض',
                      type: BeityButtonType.secondary,
                    ),
                  ),
                  AppSpacing.gapMD,
                  Expanded(
                    child: BeityButton(
                      onPressed: () => ActionDebouncer.execute(() => _acceptInvitation(ref)),
                      text: 'قبول',
                      type: BeityButtonType.primary,
                    ),
                  ),
                ],
              )
            else
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => ActionDebouncer.execute(() => _cancelInvitation(ref, context)),
                  icon: const Icon(Icons.cancel_outlined, color: Color(0xFFEF5350), size: 18),
                  label: const Text(
                    'إلغاء الدعوة',
                    style: TextStyle(
                      color: Color(0xFFEF5350),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0x7FEF5350), width: 1.2),
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
        return Colors.orange;
      case InvitationStatus.accepted:
        return Colors.green;
      case InvitationStatus.expired:
        return Colors.grey;
      case InvitationStatus.cancelled:
        return Colors.red;
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
        _getStatusName(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: _getStatusColor(),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _getStatusName() {
    switch (invitation.status) {
      case InvitationStatus.pending:
        return 'معلقة';
      case InvitationStatus.accepted:
        return 'مقبولة';
      case InvitationStatus.expired:
        return 'منتهية';
      case InvitationStatus.cancelled:
        return 'ملغاة';
    }
  }

  String _getRoleName() {
    switch (invitation.role) {
      case 'admin':
        return 'مدير';
      case 'member':
        return 'عضو';
      case 'viewer':
        return 'مشاهد';
      default:
        return invitation.role;
    }
  }

  Future<void> _acceptInvitation(WidgetRef ref) async {
    try {
      await ref.read(invitationNotifierProvider.notifier).acceptInvitation(
            token: invitation.token,
          );
      // Invalidate homes list so the new home appears
      ref.invalidate(userHomesProvider);
    } catch (e) {
      // Error is handled by the provider
    }
  }

  Future<void> _declineInvitation(WidgetRef ref) async {
    try {
      await ref.read(invitationNotifierProvider.notifier).declineInvitation(
            token: invitation.token,
          );
    } catch (e) {
      // Error is handled by the provider
    }
  }

  Future<void> _cancelInvitation(WidgetRef ref, BuildContext context) async {
    debugPrint('Cancelling invitation: ${invitation.id} for ${invitation.email}');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إلغاء الدعوة؟', textDirection: TextDirection.rtl),
        content: Text(
          'هل أنت متأكد من إلغاء دعوة ${invitation.email}؟',
          textDirection: TextDirection.rtl,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('تراجع'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('إلغاء الدعوة'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(invitationNotifierProvider.notifier).cancelInvitation(
              invitationId: invitation.id,
            );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم إلغاء الدعوة بنجاح', textDirection: TextDirection.rtl),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        debugPrint('Error cancelling invitation: $e');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('فشل إلغاء الدعوة: ${e.toString()}', textDirection: TextDirection.rtl),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
