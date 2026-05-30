import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../providers/roles_provider.dart';
import '../widgets/role_selector_widget.dart';
import '../../../homes/data/models/home_member_model.dart';
import '../../../../core/localization/app_localizations.dart';

class ManageRolesScreen extends ConsumerStatefulWidget {
  final String homeId;
  final String homeName;

  const ManageRolesScreen({
    super.key,
    required this.homeId,
    required this.homeName,
  });

  @override
  ConsumerState<ManageRolesScreen> createState() => _ManageRolesScreenState();
}

class _ManageRolesScreenState extends ConsumerState<ManageRolesScreen> {
  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(homeMembersStreamProvider(widget.homeId));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.translate('manage_members'),
        ),
      ),
      body: membersAsync.when(
        data: (members) {
          if (members.isEmpty) {
            return Center(
              child: Text(
                context.translate('no_members'),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: members.length,
            itemBuilder: (context, index) {
              final member = members[index];
              return _buildMemberCard(member);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text(
            context.translate('error_occurred_with_details', arguments: {'error': error.toString()}),
          ),
        ),
      ),
    );
  }

  Widget _buildMemberCard(HomeMemberModel member) {
    final isOwner = member.role == 'owner';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              child: Text(
                (member.userName ?? 'U')[0].toUpperCase(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member.userName ?? context.translate('user'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    member.userEmail ?? '',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                    textDirection: TextDirection.ltr,
                  ),
                ],
              ),
            ),
            if (isOwner)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  context.translate('owner'),
                  style: const TextStyle(
                    color: AppColors.warning,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            else
              RoleSelectorWidget(
                currentRole: member.role,
                onChanged: (newRole) => _changeRole(member.userId, newRole),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _changeRole(String userId, String newRole) async {
    try {
      await ref.read(roleNotifierProvider.notifier).changeMemberRole(
            homeId: widget.homeId,
            userId: userId,
            newRole: newRole,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.translate('role_changed_success'),
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceAll('Exception: ', ''),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
