import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:beity/app/theme/app_spacing.dart';
import 'package:beity/shared/widgets/design_system/beity_card.dart';
import 'package:beity/shared/widgets/design_system/beity_button.dart';
import 'package:beity/shared/widgets/design_system/beity_empty_state.dart';
import 'package:beity/core/utils/action_debouncer.dart';
import '../providers/homes_provider.dart';
import '../widgets/member_card_widget.dart';
import '../../../invitations/presentation/providers/invitations_provider.dart';
import '../../../invitations/presentation/widgets/invitation_card_widget.dart';

class HomeMembersScreen extends ConsumerWidget {
  final String homeId;

  const HomeMembersScreen({super.key, required this.homeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(homeMembersProvider(homeId));
    final homeAsync = ref.watch(userHomesProvider);
    final invitationsAsync = ref.watch(homeInvitationsStreamProvider(homeId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('أعضاء المنزل'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.admin_panel_settings_rounded),
            tooltip: 'إدارة الأدوار',
            onPressed: () {
              final homes = homeAsync.valueOrNull ?? [];
              final home = homes.where((h) => h.id == homeId).firstOrNull;
              final homeName = home?.name ?? 'المنزل';
              context.push('/homes/$homeId/roles', extra: homeName);
            },
          ),
          IconButton(
            icon: const Icon(Icons.mail_outline_rounded),
            tooltip: 'دعوات هذا المنزل',
            onPressed: () => context.push('/homes/$homeId/invitations'),
          ),
        ],
      ),
      body: membersAsync.when(
        data: (members) {
          final pendingInvitations = invitationsAsync.when(
            data: (invitations) => invitations.where((inv) => inv.isPending).toList(),
            loading: () => [],
            error: (_, __) => [],
          );

          if (members.isEmpty && pendingInvitations.isEmpty) {
            return _buildEmptyState(context, ref, homeAsync);
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
                        'الدعوات المعلقة',
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
                      'الأعضاء النشطون',
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
                  child: MemberCardWidget(member: member),
                )),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => BeityEmptyState(
          title: 'حدث خطأ في تحميل الأعضاء',
          message: error.toString(),
          icon: Icons.error_outline_rounded,
          isError: true,
          actionText: 'إعادة المحاولة',
          onActionPressed: () => ref.invalidate(homeMembersProvider(homeId)),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final homes = homeAsync.valueOrNull ?? [];
          final home = homes.where((h) => h.id == homeId).firstOrNull;
          final homeName = home?.name ?? 'المنزل';
          context.push('/homes/$homeId/invitations/send', extra: homeName);
        },
        label: const Text('دعوة عضو'),
        icon: const Icon(Icons.person_add_rounded),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref, AsyncValue<List<dynamic>> homeAsync) {
    return BeityEmptyState(
      title: 'لا يوجد أعضاء آخرون',
      message: 'ابدأ بدعوة أفراد عائلتك لمشاركتك في إدارة المنزل والتسوق.',
      icon: Icons.group_add_outlined,
      actionText: 'إرسال أول دعوة',
      onActionPressed: () {
        final homes = homeAsync.valueOrNull ?? [];
        final home = homes.where((h) => h.id == homeId).firstOrNull;
        final homeName = home?.name ?? 'المنزل';
        context.push('/homes/$homeId/invitations/send', extra: homeName);
      },
    );
  }
}
