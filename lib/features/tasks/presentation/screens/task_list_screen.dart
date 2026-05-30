import 'package:beity/shared/widgets/design_system/beity_snack_bar.dart';
import 'package:beity/core/services/supabase_service.dart';
import 'package:beity/shared/widgets/design_system/beity_empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:beity/core/utils/action_debouncer.dart';
import '../../../homes/presentation/providers/homes_provider.dart';
import '../providers/task_providers.dart';
import '../providers/task_filter_providers.dart';
import '../widgets/task_card.dart';
import '../widgets/task_tabs.dart';
import 'package:beity/core/localization/app_localizations.dart';
import 'package:beity/core/errors/error_formatter.dart';

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
  final _quickTaskController = TextEditingController();
  bool _isQuickAdding = false;

  String? get _currentUserId =>
      SupabaseService.client.auth.currentUser?.id;

  @override
  void dispose() {
    _quickTaskController.dispose();
    super.dispose();
  }

  Future<void> _submitQuickTask() async {
    final title = _quickTaskController.text.trim();
    if (title.isEmpty) return;

    setState(() => _isQuickAdding = true);
    try {
      final repository = ref.read(taskRepositoryProvider);
      await repository.createTask(
        homeId: widget.homeId,
        title: title,
        description: '',
        dueDate: null,
        assignedTo: null,
      );

      _quickTaskController.clear();
      ref.invalidate(tasksProvider);

      if (mounted) {
        BeitySnackBar.success(context, context.translate('task_created_success'));
      }
    } catch (e) {
      if (mounted) {
        BeitySnackBar.error(
          context,
          '${context.translate('error')}: ${ErrorFormatter.format(e, context)}',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isQuickAdding = false);
      }
    }
  }

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
            member.userName ?? member.userEmail ?? context.translate('member');
      }
    });

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(context.translate('tasks'), style: const TextStyle(fontWeight: FontWeight.bold)),
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
                child: Text(context.translate('due_date_earliest')),
              ),
              CheckedPopupMenuItem<String>(
                value: 'due_date_desc',
                checked: filter.sortBy == TaskSortBy.dueDate &&
                    filter.sortOrder == TaskSortOrder.descending,
                child: Text(context.translate('due_date_latest')),
              ),
              CheckedPopupMenuItem<String>(
                value: 'created_asc',
                checked: filter.sortBy == TaskSortBy.createdAt &&
                    filter.sortOrder == TaskSortOrder.ascending,
                child: Text(context.translate('created_oldest')),
              ),
              CheckedPopupMenuItem<String>(
                value: 'created_desc',
                checked: filter.sortBy == TaskSortBy.createdAt &&
                    filter.sortOrder == TaskSortOrder.descending,
                child: Text(context.translate('created_newest')),
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
          // ── Quick Task Addition Field ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _quickTaskController,
                    decoration: InputDecoration(
                      hintText: context.translate('add_quick_task'),
                      prefixIcon: const Icon(Icons.playlist_add_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    onSubmitted: (_) => _submitQuickTask(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _isQuickAdding ? null : _submitQuickTask,
                  icon: _isQuickAdding
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.send_rounded),
                ),
              ],
            ),
          ),
          // ── Segmented Due Date Filters ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: SegmentedButton<String>(
              segments: [
                ButtonSegment(
                  value: 'today',
                  icon: const Icon(Icons.today_rounded),
                  label: Text(context.translate('today')),
                ),
                ButtonSegment(
                  value: 'this_week',
                  icon: const Icon(Icons.date_range_rounded),
                  label: Text(context.translate('this_week')),
                ),
                ButtonSegment(
                  value: 'all',
                  icon: const Icon(Icons.select_all_rounded),
                  label: Text(context.translate('all')),
                ),
              ],
              selected: {filter.dueDateFilter ?? 'all'},
              showSelectedIcon: false,
              onSelectionChanged: (selection) {
                final selected = selection.first;
                ref.read(taskFilterProvider.notifier).setDueDateFilter(
                      selected == 'all' ? null : selected,
                    );
              },
            ),
          ),
          const SizedBox(height: 8),
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
                        ? context.translate('no_tasks_assigned')
                        : context.translate('no_tasks_found'),
                    message: context.translate('add_task_guideline'),
                    icon: Icons.task_alt_rounded,
                    actionText: context.translate('add_task'),
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
                          context.translate('in_progress_count', arguments: {'count': incompleteTasks.length.toString()}),
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
                              if (context.mounted) {
                                BeitySnackBar.success(
                                  context,
                                  context.translate('task_completed_success'),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                BeitySnackBar.error(
                                  context,
                                  '${context.translate('error_occurred')}: ${ErrorFormatter.format(e, context)}',
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
                          context.translate('completed_count', arguments: {'count': completedTasks.length.toString()}),
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
                              if (context.mounted) {
                                BeitySnackBar.success(
                                  context,
                                  context.translate('task_uncompleted_success'),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                BeitySnackBar.error(
                                  context,
                                  '${context.translate('error_occurred')}: ${ErrorFormatter.format(e, context)}',
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
                title: context.translate('error_occurred'),
                message: error.toString(),
                icon: Icons.error_outline_rounded,
                isError: true,
                actionText: context.translate('retry'),
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
