import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('أعضاء المنزل'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            tooltip: 'دعوة عضو',
            onPressed: () {
              final homes = homeAsync.valueOrNull ?? [];
              final home = homes.where((h) => h.id == homeId).firstOrNull;
              final homeName = home?.name ?? 'المنزل';
              context.push('/homes/$homeId/invitations/send', extra: homeName);
            },
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
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'لا يوجد أعضاء',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      final homes = homeAsync.valueOrNull ?? [];
                      final home = homes.where((h) => h.id == homeId).firstOrNull;
                      final homeName = home?.name ?? 'المنزل';
                      context.push('/homes/$homeId/invitations/send', extra: homeName);
                    },
                    icon: const Icon(Icons.person_add),
                    label: const Text('دعوة عضو'),
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Pending Invitations Section
              if (pendingInvitations.isNotEmpty) ...[
                Text(
                  'الدعوات المعلقة',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 8),
                ...pendingInvitations.map((invitation) => InvitationCardWidget(
                  invitation: invitation,
                  isOwner: true,
                )),
                const Divider(height: 32),
              ],
              
              // Active Members Section
              Text(
                'الأعضاء النشطون',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...members.map((member) => MemberCardWidget(member: member)),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'حدث خطأ: ${error.toString()}',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final homes = homeAsync.valueOrNull ?? [];
          final home = homes.where((h) => h.id == homeId).firstOrNull;
          final homeName = home?.name ?? 'المنزل';
          context.push('/homes/$homeId/invitations/send', extra: homeName);
        },
        tooltip: 'دعوة عضو',
        child: const Icon(Icons.person_add),
      ),
    );
  }
}
