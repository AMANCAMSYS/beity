import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/activity_log.dart';
import '../providers/activity_logs_provider.dart';
import 'package:beity/core/localization/app_localizations.dart';

class ActivityFilterWidget extends ConsumerWidget {
  final String homeId;

  const ActivityFilterWidget({super.key, required this.homeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(activityFilterProvider);
    final actorsAsync = ref.watch(activityActorsProvider(homeId));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Actor filter dropdown
          actorsAsync.when(
            data: (actors) => DropdownButtonFormField<String>(
              initialValue: filter.actorId,
              decoration: InputDecoration(
                labelText: context.translate('member'),
                hintText: context.translate('all_members'),
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                isDense: true,
              ),
              items: [
                DropdownMenuItem<String>(
                  value: null,
                  child: Text(context.translate('all_members')),
                ),
                ...actors.map(
                  (actor) => DropdownMenuItem<String>(
                    value: actor.userId,
                    child: Text(actor.displayName ?? context.translate('user_label')),
                  ),
                ),
              ],
              onChanged: (value) {
                ref.read(activityFilterProvider.notifier).setActor(value);
              },
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 8),
          // Action type chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(
                  context,
                  ref,
                  label: context.translate('shopping_lists'),
                  icon: Icons.list_alt,
                  actions: [
                    ActionType.listCreated,
                    ActionType.listRenamed,
                    ActionType.listArchived,
                    ActionType.listDeleted,
                  ],
                  selectedActions: filter.actionTypes,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  context,
                  ref,
                  label: context.translate('products'),
                  icon: Icons.shopping_cart_outlined,
                  actions: [
                    ActionType.itemAdded,
                    ActionType.itemUpdated,
                    ActionType.itemPurchased,
                    ActionType.itemUnpurchased,
                    ActionType.itemDeleted,
                  ],
                  selectedActions: filter.actionTypes,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  context,
                  ref,
                  label: context.translate('purchases'),
                  icon: Icons.check_circle_outline,
                  actions: [ActionType.itemPurchased],
                  selectedActions: filter.actionTypes,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  context,
                  ref,
                  label: context.translate('members'),
                  icon: Icons.people_outline,
                  actions: [
                    ActionType.memberJoined,
                    ActionType.memberRemoved,
                    ActionType.memberRoleChanged,
                    ActionType.invitationAccepted,
                  ],
                  selectedActions: filter.actionTypes,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context,
    WidgetRef ref, {
    required String label,
    required IconData icon,
    required List<ActionType> actions,
    List<ActionType>? selectedActions,
  }) {
    final isSelected =
        selectedActions != null &&
        selectedActions.isNotEmpty &&
        actions.every((a) => selectedActions.contains(a));

    return FilterChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          ref.read(activityFilterProvider.notifier).setActionTypes(actions);
        } else {
          ref.read(activityFilterProvider.notifier).setActionTypes(null);
        }
      },
      selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
      checkmarkColor: Theme.of(context).primaryColor,
    );
  }
}
