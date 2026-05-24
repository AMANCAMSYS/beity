import 'package:beity/app/theme/app_spacing.dart';
import 'package:beity/app/theme/app_colors.dart';
import 'package:beity/shared/widgets/design_system/beity_button.dart';
import 'package:beity/shared/widgets/design_system/beity_card.dart';
import 'package:beity/shared/widgets/design_system/beity_empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:beity/core/utils/action_debouncer.dart';
import '../../../homes/presentation/providers/homes_provider.dart';
import '../../../home/presentation/widgets/app_drawer.dart';
import '../providers/task_providers.dart';
import '../providers/task_filter_providers.dart';
import '../widgets/task_card.dart';
import '../widgets/task_tabs.dart';
import '../widgets/task_filter_bar.dart';

class TaskListScreen extends ConsumerStatefulWidget {
  final String homeId;

  const TaskListScreen({
    super.key,
    required this.homeId,
  });

  @override
  ConsumerState<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends ConsumerState<TaskListScreen> {
  int _currentTab = 0;

  String? get _currentUserId =>
      Supabase.instance.client.auth.currentUser?.id;

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(
      tasksProvider((
        homeId: widget.homeId,
        assignedTo: _currentTab == 0 ? _currentUserId : null,
      )),
    );
    final membersAsync = ref.watch(homeMembersProvider(widget.homeId));
    final filter = ref.watch(taskFilterProvider);

    // Build member name map
    final memberNames = <String, String>{};
    membersAsync.whenData((members) {
      for (final member in members) {
        memberNames[member.userId] =
            member.userName ?? member.userEmail ?? 'عضو';
      }
    });

    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final theme = Theme.of(context);

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: Text(isArabic ? 'المهام' : 'Tasks', style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort_rounded),
            onSelected: (value) {
              final notifier = ref.read(taskFilterProvider.notifier);
              switch (value) {
                case 'due_date_asc':
                  notifier.setSortBy(TaskSortBy.dueDate);
                  notifier.setSortOrder(TaskSortOrder.ascending);
                  break;
                case 'due_date_desc':
                  notifier.setSortBy(TaskSortBy.dueDate);
                  notifier.setSortOrder(TaskSortOrder.descending);
                  break;
                case 'created_asc':
                  notifier.setSortBy(TaskSortBy.createdAt);
                  notifier.setSortOrder(TaskSortOrder.ascending);
                  break;
                case 'created_desc':
                  notifier.setSortBy(TaskSortBy.createdAt);
                  notifier.setSortOrder(TaskSortOrder.descending);
                  break;
              }
            },
            itemBuilder: (context) => [
              CheckedPopupMenuItem<String>(
                value: 'due_date_asc',
                checked: filter.sortBy == TaskSortBy.dueDate &&
                    filter.sortOrder == TaskSortOrder.ascending,
                child: Text(isArabic ? 'تاريخ الاستحقاق (أولاً)' : 'Due Date (Earliest)'),
              ),
              CheckedPopupMenuItem<String>(
                value: 'due_date_desc',
                checked: filter.sortBy == TaskSortBy.dueDate &&
                    filter.sortOrder == TaskSortOrder.descending,
                child: Text(isArabic ? 'تاريخ الاستحقاق (آخراً)' : 'Due Date (Latest)'),
              ),
              CheckedPopupMenuItem<String>(
                value: 'created_asc',
                checked: filter.sortBy == TaskSortBy.createdAt &&
                    filter.sortOrder == TaskSortOrder.ascending,
                child: Text(isArabic ? 'تاريخ الإنشاء (الأقدم)' : 'Created (Oldest)'),
              ),
              CheckedPopupMenuItem<String>(
                value: 'created_desc',
                checked: filter.sortBy == TaskSortBy.createdAt &&
                    filter.sortOrder == TaskSortOrder.descending,
                child: Text(isArabic ? 'تاريخ الإنشاء (الأحدث)' : 'Created (Newest)'),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.archive_outlined),
            onPressed: () => ActionDebouncer.execute(() async {
              context.push('/home/${widget.homeId}/tasks/archived');
            }),
          ),
        ],
      ),
      body: Column(
        children: [
          TaskTabs(
            currentTab: _currentTab,
            onTabChanged: (index) {
              setState(() {
                _currentTab = index;
              });
            },
          ),
          const TaskFilterBar(),
          Expanded(
            child: tasksAsync.when(
              data: (tasks) {
                // Apply client-side filters
                var filteredTasks = tasks;

                if (filter.dueDateFilter != null) {
                  final now = DateTime.now();
                  final today = DateTime(now.year, now.month, now.day);

                  switch (filter.dueDateFilter) {
                    case 'today':
                      filteredTasks =
                          filteredTasks.where((t) => t.isDueToday).toList();
                      break;
                    case 'this_week':
                      final weekEnd =
                          today.add(Duration(days: 7 - now.weekday));
                      filteredTasks = filteredTasks.where((t) {
                        if (t.dueDate == null) return false;
                        return t.dueDate!.isAfter(
                                today.subtract(const Duration(days: 1))) &&
                            t.dueDate!.isBefore(
                                weekEnd.add(const Duration(days: 1)));
                      }).toList();
                      break;
                    case 'overdue':
                      filteredTasks =
                          filteredTasks.where((t) => t.isOverdue).toList();
                      break;
                  }
                }

                // Apply sorting
                filteredTasks.sort((a, b) {
                  int comparison;
                  if (filter.sortBy == TaskSortBy.dueDate) {
                    if (a.dueDate == null && b.dueDate == null) {
                      comparison = 0;
                    } else if (a.dueDate == null) {
                      comparison = 1;
                    } else if (b.dueDate == null) {
                      comparison = -1;
                    } else {
                      comparison = a.dueDate!.compareTo(b.dueDate!);
                    }
                  } else {
                    final aDate = a.createdAt ?? DateTime(2000);
                    final bDate = b.createdAt ?? DateTime(2000);
                    comparison = aDate.compareTo(bDate);
                  }
                  return filter.sortOrder == TaskSortOrder.ascending
                      ? comparison
                      : -comparison;
                });

                if (filteredTasks.isEmpty) {
                  return BeityEmptyState(
                    title: _currentTab == 0
                        ? (isArabic ? 'لا توجد مهام مسندة إليك' : 'No tasks assigned to you')
                        : (isArabic ? 'لا توجد مهام' : 'No tasks found'),
                    message: isArabic ? 'اضغط على الزر لإضافة مهمة جديدة' : 'Tap the button to add a new task',
                    icon: Icons.task_alt_rounded,
                    actionText: isArabic ? 'إضافة مهمة' : 'Add Task',
                    onAction: () => ActionDebouncer.execute(() => context.push('/home/${widget.homeId}/tasks/add')),
                  );
                }

                final incompleteTasks =
                    filteredTasks.where((t) => t.isIncomplete).toList();
                final completedTasks =
                    filteredTasks.where((t) => t.isCompleted).toList();

                return ListView(
                  children: [
                    if (incompleteTasks.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Text(
                          'قيد التنفيذ (${incompleteTasks.length})',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: Colors.grey.shade600,
                                  ),
                        ),
                      ),
                      ...incompleteTasks.map(
                        (task) => TaskCard(
                          task: task,
                          assigneeName: task.assignedTo != null
                              ? memberNames[task.assignedTo]
                              : null,
                          onTap: () => ActionDebouncer.execute(() async {
                            context.push(
                              '/home/${widget.homeId}/tasks/${task.id}',
                            );
                          }),
                          onComplete: () => ActionDebouncer.execute(() async {
                            try {
                              final repository =
                                  ref.read(taskRepositoryProvider);
                              await repository.completeTask(taskId: task.id);
                              if (task.isRecurring) {
                                await repository.createNextRecurringTask(
                                    taskId: task.id);
                              }
                              ref.invalidate(tasksProvider);
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('خطأ: $e')),
                                );
                              }
                            }
                          }),
                        ),
                      ),
                    ],
                    if (completedTasks.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Text(
                          'مكتملة (${completedTasks.length})',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: Colors.grey.shade600,
                                  ),
                        ),
                      ),
                      ...completedTasks.map(
                        (task) => TaskCard(
                          task: task,
                          assigneeName: task.assignedTo != null
                              ? memberNames[task.assignedTo]
                              : null,
                          onTap: () => ActionDebouncer.execute(() async {
                            context.push(
                              '/home/${widget.homeId}/tasks/${task.id}',
                            );
                          }),
                          onComplete: () => ActionDebouncer.execute(() async {
                            try {
                              final repository =
                                  ref.read(taskRepositoryProvider);
                              await repository.uncompleteTask(taskId: task.id);
                              ref.invalidate(tasksProvider);
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('خطأ: $e')),
                                );
                              }
                            }
                          }),
                        ),
                      ),
                    ],
                  ],
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (error, _) => BeityEmptyState(
                title: isArabic ? 'عذراً، حدث خطأ' : 'Oops, something went wrong',
                message: error.toString(),
                icon: Icons.error_outline_rounded,
                isError: true,
                actionText: isArabic ? 'إعادة المحاولة' : 'Try Again',
                onAction: () => ref.invalidate(tasksProvider),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => ActionDebouncer.execute(() => context.push('/home/${widget.homeId}/tasks/add')),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}
