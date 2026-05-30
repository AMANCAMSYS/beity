import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../providers/units_provider.dart';
import '../widgets/unit_card_widget.dart';
import 'package:beity/core/localization/app_localizations.dart';

class UnitsListScreen extends ConsumerStatefulWidget {
  const UnitsListScreen({super.key});

  @override
  ConsumerState<UnitsListScreen> createState() => _UnitsListScreenState();
}

class _UnitsListScreenState extends ConsumerState<UnitsListScreen> {
  String? _selectedType;

  @override
  Widget build(BuildContext context) {
    final unitsAsync = ref.watch(unitsProvider(_selectedType));

    return Scaffold(
      appBar: AppBar(
        title: Text(context.translate('units')),
        actions: [
          IconButton(
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
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.straighten,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          context.translate('no_units'),
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          context.translate('default_units_desc'),
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                color: Colors.grey[500],
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
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
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: AppColors.error),
                    const SizedBox(height: 16),
                    Text(
                      context.translate('error_loading_units_msg'),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(unitsProvider),
                      child: Text(context.translate('retry')),
                    ),
                  ],
                ),
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
