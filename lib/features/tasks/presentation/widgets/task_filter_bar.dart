import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/task_filter_providers.dart';

class TaskFilterBar extends ConsumerWidget {
  const TaskFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(taskFilterProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          FilterChip(
            label: const Text('اليوم'),
            selected: filter.dueDateFilter == 'today',
            onSelected: (selected) {
              ref.read(taskFilterProvider.notifier).setDueDateFilter(
                    selected ? 'today' : null,
                  );
            },
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('هذا الأسبوع'),
            selected: filter.dueDateFilter == 'this_week',
            onSelected: (selected) {
              ref.read(taskFilterProvider.notifier).setDueDateFilter(
                    selected ? 'this_week' : null,
                  );
            },
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('متأخرة'),
            selected: filter.dueDateFilter == 'overdue',
            onSelected: (selected) {
              ref.read(taskFilterProvider.notifier).setDueDateFilter(
                    selected ? 'overdue' : null,
                  );
            },
          ),
          const Spacer(),
          if (filter.dueDateFilter != null ||
              filter.status != null ||
              filter.assignedTo != null)
            TextButton(
              onPressed: () {
                ref.read(taskFilterProvider.notifier).clearFilters();
              },
              child: const Text('مسح الفلاتر'),
            ),
        ],
      ),
    );
  }
}
