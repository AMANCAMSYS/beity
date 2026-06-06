import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/units_provider.dart';
import '../widgets/unit_card_widget.dart';
import 'package:sawa/shared/widgets/design_system/sawa_empty_state.dart';
import 'package:sawa/core/localization/app_localizations.dart';
import 'package:sawa/features/onboarding/presentation/providers/app_tour_controller.dart';
import 'package:sawa/features/onboarding/presentation/providers/app_tour_target_registry.dart';

class UnitsListScreen extends ConsumerStatefulWidget {
  const UnitsListScreen({super.key});

  @override
  ConsumerState<UnitsListScreen> createState() => _UnitsListScreenState();
}

class _UnitsListScreenState extends ConsumerState<UnitsListScreen> {
  String? _selectedType;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(appTourControllerProvider.notifier).maybeStartUnitsTour(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final unitsAsync = ref.watch(unitsProvider(_selectedType));

    return Scaffold(
      appBar: AppBar(
        title: Text(context.translate('units')),
        actions: [
          IconButton(
            key: AppTourTargetRegistry.unitsAddKey,
            icon: const Icon(Icons.add),
            onPressed: () {
              context.push('/units/create');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Type filter
          SingleChildScrollView(
            key: AppTourTargetRegistry.unitsFilterKey,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildFilterChip(null, context.translate('all')),
                const SizedBox(width: 8),
                _buildFilterChip('weight', context.translate('weight')),
                const SizedBox(width: 8),
                _buildFilterChip('volume', context.translate('volume')),
                const SizedBox(width: 8),
                _buildFilterChip('count', context.translate('count')),
                const SizedBox(width: 8),
                _buildFilterChip('length', context.translate('length')),
              ],
            ),
          ),
          // Units list
          Expanded(
            child: unitsAsync.when(
              data: (units) {
                if (units.isEmpty) {
                  return SawaEmptyState(
                    title: context.translate('no_units'),
                    message: context.translate('default_units_desc'),
                    icon: Icons.straighten,
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: units.length,
                  itemBuilder: (context, index) {
                    final unit = units[index];
                    return UnitCardWidget(unit: unit);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => SawaEmptyState(
                title: context.translate('error_occurred'),
                message: error.toString(),
                icon: Icons.error_outline_rounded,
                isError: true,
                actionText: context.translate('retry'),
                onAction: () => ref.invalidate(unitsProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String? type, String label) {
    final isSelected = _selectedType == type;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedType = selected ? type : null;
        });
      },
    );
  }
}
