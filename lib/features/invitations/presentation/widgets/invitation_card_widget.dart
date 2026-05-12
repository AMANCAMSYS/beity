import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../data/models/invitation_model.dart';
import '../../domain/entities/invitation.dart';
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
    final isExpired = invitation.isExpired;
    final isPending = invitation.isPending;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: _getStatusColor().withOpacity(0.1),
                  child: Icon(
                    _getStatusIcon(),
                    color: _getStatusColor(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        invitation.email ?? 'دعوة',
                        style: Theme.of(context).textTheme.titleMedium,
                        textDirection: TextDirection.ltr,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'الدور: ${_getRoleName()}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                        textDirection: TextDirection.rtl,
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(),
              ],
            ),
            if (invitation.createdAt != null) ...[
              const SizedBox(height: 8),
              Text(
                timeago.format(invitation.createdAt!, locale: 'ar'),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[500],
                    ),
                textDirection: TextDirection.rtl,
              ),
            ],
            if (isPending && !isOwner) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _declineInvitation(ref),
                      child: const Text('رفض'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _acceptInvitation(ref),
                      child: const Text('قبول'),
                    ),
                  ),
                ],
              ),
            ],
            if (isPending && isOwner) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _cancelInvitation(ref),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                  child: const Text('إلغاء الدعوة'),
                ),
              ),
            ],
          ],
        ),
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

  Widget _buildStatusChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _getStatusName(),
        style: TextStyle(
          color: _getStatusColor(),
          fontSize: 12,
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

  Future<void> _cancelInvitation(WidgetRef ref) async {
    try {
      await ref.read(invitationNotifierProvider.notifier).cancelInvitation(
            invitationId: invitation.id,
          );
    } catch (e) {
      // Error is handled by the provider
    }
  }
}
