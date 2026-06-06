import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sawa/core/localization/app_localizations.dart';
import 'package:sawa/shared/widgets/design_system/sawa_button.dart';
import 'package:sawa/shared/widgets/design_system/sawa_empty_state.dart';
import '../../../../core/services/initial_data_hydration_service.dart';

class NoActiveHomeWidget extends ConsumerWidget {
  const NoActiveHomeWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hydration = ref.watch(initialDataHydrationServiceProvider);

    if (hydration.status == HydrationStatus.hydratingData ||
        hydration.status == HydrationStatus.hydratingHomes) {
      return Scaffold(
        appBar: AppBar(title: Text(context.translate('app_name'))),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(context.translate('app_name'))),
      body: Column(
        children: [
          Expanded(
            child: SawaEmptyState(
              title: context.translate('no_active_home'),
              message: context.translate('select_or_create_home'),
              icon: Icons.home_outlined,
              actionText: context.translate('manage_homes'),
              onAction: () => context.push('/homes'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: SawaButton(
              onPressed: () => context.push('/homes/create'),
              text: context.translate('create_home_button'),
              icon: Icons.add,
              type: SawaButtonType.outline,
              fullWidth: true,
            ),
          ),
        ],
      ),
    );
  }
}
