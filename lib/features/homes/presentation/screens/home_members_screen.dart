import 'package:flutter/material.dart';
import 'package:beity/core/services/supabase_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:beity/app/theme/app_spacing.dart';
import 'package:beity/app/theme/app_colors.dart';
import 'package:beity/shared/widgets/design_system/beity_empty_state.dart';
import '../providers/homes_provider.dart';
import '../../data/models/home_model.dart';
import '../widgets/member_card_widget.dart';
import '../../domain/usecases/remove_member_with_balance_check.dart';
import '../../../invitations/presentation/providers/invitations_provider.dart';
import '../../../invitations/presentation/widgets/invitation_card_widget.dart';
import 'package:beity/core/localization/app_localizations.dart';

class HomeMembersScreen extends ConsumerWidget {
  final String homeId;

  const HomeMembersScreen({super.key, required this.homeId});

  Future<void> _showRemoveConfirmation(
    BuildContext context,
    WidgetRef ref,
    String memberName,
    String userId,
  ) async {
    final theme = Theme.of(context);
    final removeUseCase = ref.read(removeMemberWithBalanceCheckProvider);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.translate('remove_member')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.translate('remove_member_confirm_msg', arguments: {'name': memberName})),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_rounded,
                    color: AppColors.warning,
                    size: 20,
                  ),
                  AppSpacing.gapSM,
                  Expanded(
                    child: Text(
                      context.translate('remove_member_warning_msg'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.warning,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.translate('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(context.translate('remove')),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final result = await removeUseCase(
          RemoveMemberParams(homeId: homeId, userId: userId),
        );

        if (!result.success && result.hasUnsettledBalances) {
          if (context.mounted) {
            final forceRemove = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(context.translate('unsettled_balances')),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.translate('unsettled_balances_msg', arguments: {'name': memberName}),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      context.translate('remove_anyway_question'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(context.translate('cancel')),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.error,
                    ),
                    child: Text(context.translate('remove_anyway')),
                  ),
                ],
              ),
            );

            if (forceRemove == true && context.mounted) {
              await removeUseCase(
                RemoveMemberParams(
                  homeId: homeId,
                  userId: userId,
                  force: true,
                ),
              );
              ref.invalidate(homeMembersProvider(homeId));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      context.translate('member_removed_success', arguments: {'name': memberName}),
                    ),
                  ),
                );
              }
            }
          }
        } else {
          ref.invalidate(homeMembersProvider(homeId));
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  context.translate('member_removed_success', arguments: {'name': memberName}),
                ),
              ),
            );
          }
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                context.translate('remove_member_failed', arguments: {'error': e.toString()}),
              ),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(homeMembersProvider(homeId));
    final homes = ref.watch(cachedUserHomesProvider);
    final invitationsAsync = ref.watch(homeInvitationsStreamProvider(homeId));
    final theme = Theme.of(context);
    final currentUserId = SupabaseService.client.auth.currentUser?.id;

    final home = homes.where((h) => h.id == homeId).firstOrNull;
    final isCurrentUserOwner = home?.ownerId == currentUserId;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.translate('home_members')),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.admin_panel_settings_rounded),
            tooltip: context.translate('manage_roles'),
            onPressed: () {
              final homeName = home?.name ?? context.translate('homes');
              context.push('/homes/$homeId/roles', extra: homeName);
            },
          ),
          IconButton(
            icon: const Icon(Icons.mail_outline_rounded),
            tooltip: context.translate('home_invitations'),
            onPressed: () => context.push('/homes/$homeId/invitations'),
          ),
        ],
      ),
      body: membersAsync.when(
        data: (members) {
          final pendingInvitations = invitationsAsync.when(
            data: (invitations) => invitations.where((inv) => inv.isPending).toList(),
            loading: () => [],
            error: (err, stack) => [],
          );

          if (members.isEmpty && pendingInvitations.isEmpty) {
            return _buildEmptyState(context, ref, homes);
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(homeMembersProvider(homeId));
              ref.invalidate(homeInvitationsStreamProvider(homeId));
              ref.invalidate(homeInvitationsProvider(homeId));
            },
            color: theme.colorScheme.primary,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                // Pending Invitations Section
                if (pendingInvitations.isNotEmpty) ...[
                  Row(
                    children: [
                      Icon(Icons.mail_rounded, size: 20, color: theme.colorScheme.tertiary),
                      AppSpacing.gapSM,
                      Text(
                        context.translate('pending_invitations'),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.tertiary,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.tertiary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                        ),
                        child: Text(
                          pendingInvitations.length.toString(),
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.tertiary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.gapMD,
                  ...pendingInvitations.map((invitation) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: InvitationCardWidget(
                      invitation: invitation,
                      isOwner: true,
                    ),
                  )),
                  AppSpacing.gapLG,
                  Divider(color: theme.colorScheme.outlineVariant),
                  AppSpacing.gapLG,
                ],
                
                // Active Members Section
                Row(
                  children: [
                    Icon(Icons.people_rounded, size: 20, color: theme.colorScheme.primary),
                    AppSpacing.gapSM,
                    Text(
                      context.translate('active_members'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                AppSpacing.gapMD,
                ...members.map((member) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: MemberCardWidget(
                    member: member,
                    isCurrentUserOwner: isCurrentUserOwner,
                    onRemove: isCurrentUserOwner &&
                            member.role != 'owner'
                        ? () => _showRemoveConfirmation(
                              context,
                              ref,
                              member.userName ?? context.translate('this_member'),
                              member.userId,
                            )
                        : null,
                  ),
                )),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => BeityEmptyState(
          title: context.translate('load_members_failed'),
          message: error.toString(),
          icon: Icons.error_outline_rounded,
          isError: true,
          actionText: context.translate('retry'),
          onAction: () => ref.invalidate(homeMembersProvider(homeId)),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final homeName = home?.name ?? context.translate('homes');
          context.push('/homes/$homeId/invitations/send', extra: homeName);
        },
        label: Text(context.translate('invite_member')),
        icon: const Icon(Icons.person_add_rounded),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref, List<HomeModel> homes) {
    return BeityEmptyState(
      title: context.translate('no_other_members'),
      message: context.translate('no_other_members_desc'),
      icon: Icons.group_add_outlined,
      actionText: context.translate('send_first_invitation'),
      onAction: () {
        final home = homes.where((h) => h.id == homeId).firstOrNull;
        final homeName = home?.name ?? context.translate('homes');
        context.push('/homes/$homeId/invitations/send', extra: homeName);
      },
    );
  }
}
