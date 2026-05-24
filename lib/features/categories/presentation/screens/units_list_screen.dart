import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/units_provider.dart';
import '../widgets/unit_card_widget.dart';

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
        title: const Text(
          'وحدات القياس',
          textDirection: TextDirection.rtl,
        ),
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
                _buildFilterChip(null, 'الكل'),
                const SizedBox(width: 8),
                _buildFilterChip('weight', 'وزن'),
                const SizedBox(width: 8),
                _buildFilterChip('volume', 'حجم'),
                const SizedBox(width: 8),
                _buildFilterChip('count', 'عدد'),
                const SizedBox(width: 8),
                _buildFilterChip('length', 'طول'),
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
                          'لا توجد وحدات',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                color: Colors.grey[600],
                              ),
                          textDirection: TextDirection.rtl,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'سيتم عرض وحدات القياس الافتراضية هنا',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                color: Colors.grey[500],
                              ),
                          textDirection: TextDirection.rtl,
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
                        size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      'حدث خطأ أثناء تحميل الوحدات',
                      textDirection: TextDirection.rtl,
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(unitsProvider),
                      child: const Text('إعادة المحاولة'),
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
