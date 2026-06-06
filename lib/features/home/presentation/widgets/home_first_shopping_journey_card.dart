import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/home_route_paths.dart';
import '../../../../app/router/shopping_route_paths.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../shared/widgets/design_system/sawa_button.dart';
import '../../../../shared/widgets/design_system/sawa_card.dart';
import '../../../homes/presentation/providers/homes_provider.dart';
import '../../../onboarding/data/onboarding_storage.dart';
import '../../../onboarding/presentation/providers/app_tour_target_registry.dart';
import '../../../shopping_lists/data/models/shopping_list_model.dart';
import '../../../shopping_lists/presentation/providers/shopping_lists_provider.dart';

enum _JourneyStage { createList, addItem, invite, shoppingMode }

enum _StepState { done, active, pending }

class HomeFirstShoppingJourneyCard extends ConsumerWidget {
  final String homeId;
  final ShoppingListModel? activeList;

  const HomeFirstShoppingJourneyCard({
    super.key,
    required this.homeId,
    this.activeList,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!OnboardingStorage.shouldShowFirstShoppingJourney(homeId)) {
      return const SizedBox.shrink();
    }

    final summariesAsync = activeList == null
        ? null
        : ref.watch(shoppingListSummariesProvider(homeId));
    if (activeList != null &&
        summariesAsync != null &&
        summariesAsync.isLoading &&
        !summariesAsync.hasValue) {
      return const SizedBox.shrink();
    }

    final membersAsync = ref.watch(homeMembersProvider(homeId));
    final activeMemberCount =
        membersAsync.value
            ?.where(
              (member) => member.status == 'active' && member.deletedAt == null,
            )
            .length ??
        1;

    final summary = activeList == null
        ? null
        : summariesAsync?.value?[activeList!.id];
    final hasList = activeList != null;
    final hasItems = (summary?.total ?? 0) > 0;
    final hasSharedMember = activeMemberCount > 1;
    final stage = _resolveStage(
      hasList: hasList,
      hasItems: hasItems,
      hasSharedMember: hasSharedMember,
    );

    final card = SawaCard(
      key: AppTourTargetRegistry.firstShoppingJourneyKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(stage: stage),
          AppSpacing.gapLG,
          _StepList(
            createListState: _stateFor(stage, _JourneyStage.createList),
            addItemState: _stateFor(stage, _JourneyStage.addItem),
            inviteState: _stateFor(stage, _JourneyStage.invite),
            shoppingModeState: _stateFor(stage, _JourneyStage.shoppingMode),
          ),
          AppSpacing.gapLG,
          _Actions(stage: stage, homeId: homeId, activeList: activeList),
        ],
      ),
    );

    if (activeList == null) return card;
    return Column(children: [card, AppSpacing.gapLG]);
  }

  _JourneyStage _resolveStage({
    required bool hasList,
    required bool hasItems,
    required bool hasSharedMember,
  }) {
    if (!hasList) return _JourneyStage.createList;
    if (!hasItems) return _JourneyStage.addItem;
    if (!hasSharedMember) return _JourneyStage.invite;
    return _JourneyStage.shoppingMode;
  }

  _StepState _stateFor(_JourneyStage current, _JourneyStage step) {
    if (step.index < current.index) return _StepState.done;
    if (step == current) return _StepState.active;
    return _StepState.pending;
  }
}

class _Header extends StatelessWidget {
  final _JourneyStage stage;

  const _Header({required this.stage});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Icon(
            Icons.route_rounded,
            color: theme.colorScheme.primary,
            size: 24,
          ),
        ),
        AppSpacing.gapLG,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.translate('first_shopping_journey_title'),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              AppSpacing.gapXS,
              Text(
                context.translate(_hintKeyFor(stage)),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _hintKeyFor(_JourneyStage stage) {
    switch (stage) {
      case _JourneyStage.createList:
        return 'first_shopping_journey_create_list_hint';
      case _JourneyStage.addItem:
        return 'first_shopping_journey_add_item_hint';
      case _JourneyStage.invite:
        return 'first_shopping_journey_invite_hint';
      case _JourneyStage.shoppingMode:
        return 'first_shopping_journey_shopping_mode_hint';
    }
  }
}

class _StepList extends StatelessWidget {
  final _StepState createListState;
  final _StepState addItemState;
  final _StepState inviteState;
  final _StepState shoppingModeState;

  const _StepList({
    required this.createListState,
    required this.addItemState,
    required this.inviteState,
    required this.shoppingModeState,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _JourneyStep(
          label: context.translate('create_first_list'),
          icon: Icons.playlist_add_rounded,
          state: createListState,
        ),
        _JourneyStep(
          label: context.translate('add_first_item'),
          icon: Icons.add_shopping_cart_rounded,
          state: addItemState,
        ),
        _JourneyStep(
          label: context.translate('invite_member'),
          icon: Icons.person_add_alt_rounded,
          state: inviteState,
        ),
        _JourneyStep(
          label: context.translate('shopping_mode'),
          icon: Icons.shopping_bag_rounded,
          state: shoppingModeState,
          isLast: true,
        ),
      ],
    );
  }
}

class _JourneyStep extends StatelessWidget {
  final String label;
  final IconData icon;
  final _StepState state;
  final bool isLast;

  const _JourneyStep({
    required this.label,
    required this.icon,
    required this.state,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = switch (state) {
      _StepState.done => AppColors.success,
      _StepState.active => theme.colorScheme.primary,
      _StepState.pending => theme.colorScheme.onSurfaceVariant.withValues(
        alpha: 0.45,
      ),
    };

    return Row(
      children: [
        Column(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(color: color.withValues(alpha: 0.45)),
              ),
              child: Icon(
                state == _StepState.done ? Icons.check_rounded : icon,
                color: color,
                size: 17,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 18,
                color: color.withValues(alpha: 0.22),
              ),
          ],
        ),
        AppSpacing.gapMD,
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 18),
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: state == _StepState.active
                    ? FontWeight.w800
                    : FontWeight.w600,
                color: state == _StepState.pending
                    ? theme.colorScheme.onSurfaceVariant
                    : theme.colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Actions extends StatelessWidget {
  final _JourneyStage stage;
  final String homeId;
  final ShoppingListModel? activeList;

  const _Actions({
    required this.stage,
    required this.homeId,
    required this.activeList,
  });

  @override
  Widget build(BuildContext context) {
    final primary = SawaButton(
      text: context.translate(_primaryTextKey),
      icon: _primaryIcon,
      fullWidth: true,
      onPressed: () => _handlePrimary(context),
    );

    if (stage != _JourneyStage.invite || activeList == null) {
      return primary;
    }

    return Column(
      children: [
        primary,
        AppSpacing.gapSM,
        SawaButton(
          text: context.translate('first_shopping_journey_skip_invite'),
          icon: Icons.shopping_bag_rounded,
          type: SawaButtonType.text,
          fullWidth: true,
          onPressed: () => _startShoppingMode(context, completeJourney: true),
        ),
      ],
    );
  }

  String get _primaryTextKey {
    switch (stage) {
      case _JourneyStage.createList:
        return 'create_first_list';
      case _JourneyStage.addItem:
        return 'add_first_item';
      case _JourneyStage.invite:
        return 'send_first_invitation';
      case _JourneyStage.shoppingMode:
        return 'start_shopping';
    }
  }

  IconData get _primaryIcon {
    switch (stage) {
      case _JourneyStage.createList:
        return Icons.playlist_add_rounded;
      case _JourneyStage.addItem:
        return Icons.add_shopping_cart_rounded;
      case _JourneyStage.invite:
        return Icons.person_add_alt_rounded;
      case _JourneyStage.shoppingMode:
        return Icons.shopping_bag_rounded;
    }
  }

  void _handlePrimary(BuildContext context) {
    switch (stage) {
      case _JourneyStage.createList:
        context.push(ShoppingRoutePaths.create, extra: homeId);
        return;
      case _JourneyStage.addItem:
        final list = activeList;
        if (list == null) return;
        context.push(ShoppingRoutePaths.addItem(list.id, homeId: homeId));
        return;
      case _JourneyStage.invite:
        context.push(HomeRoutePaths.sendInvitation(homeId));
        return;
      case _JourneyStage.shoppingMode:
        _startShoppingMode(context, completeJourney: true);
        return;
    }
  }

  Future<void> _startShoppingMode(
    BuildContext context, {
    required bool completeJourney,
  }) async {
    final list = activeList;
    if (list == null) return;
    if (completeJourney) {
      await OnboardingStorage.markFirstShoppingJourneyCompleted(homeId);
    }
    if (!context.mounted) return;
    context.push(
      ShoppingRoutePaths.shoppingMode(list.id),
      extra: {'homeId': homeId, 'listName': list.name},
    );
  }
}
