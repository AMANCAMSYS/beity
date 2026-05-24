import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../homes/presentation/providers/homes_provider.dart';
import '../providers/task_providers.dart';
import '../widgets/recurrence_selector.dart';
import '../widgets/comment_thread.dart';
import '../../../../core/utils/action_debouncer.dart';
import '../../../../shared/widgets/design_system/beity_empty_state.dart';
import '../../../../shared/widgets/design_system/beity_button.dart';

class TaskDetailScreen extends ConsumerStatefulWidget {
  final String taskId;
  final String homeId;

  const TaskDetailScreen({
    super.key,
    required this.taskId,
    required this.homeId,
  });

  @override
  ConsumerState<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends ConsumerState<TaskDetailScreen> {
  bool _isLoading = false;
  bool _isEditing = false;

  // Edit state
  final _editTitleController = TextEditingController();
  final _editDescriptionController = TextEditingController();
  DateTime? _editDueDate;
  String? _editRecurrenceType;
  String? _editAssignedTo;

  @override
  void dispose() {
    _editTitleController.dispose();
    _editDescriptionController.dispose();
    super.dispose();
  }

  void _startEditing(dynamic task) {
    _editTitleController.text = task.title;
    _editDescriptionController.text = task.description ?? '';
    _editDueDate = task.dueDate;
    _editRecurrenceType = task.recurrenceType;
    _editAssignedTo = task.assignedTo;
    setState(() {
      _isEditing = true;
    });
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
    });
  }

  Future<void> _saveEditing() async {
    if (_editTitleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('عنوان المهمة مطلوب')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final repository = ref.read(taskRepositoryProvider);
      await repository.updateTask(
        taskId: widget.taskId,
        title: _editTitleController.text.trim(),
        description: _editDescriptionController.text.trim().isNotEmpty
            ? _editDescriptionController.text.trim()
            : null,
        dueDate: _editDueDate,
        recurrenceType: _editRecurrenceType,
      );
      await repository.updateTaskAssignee(
        taskId: widget.taskId,
        assignedTo: _editAssignedTo,
      );
      ref.invalidate(taskByIdProvider);
      ref.invalidate(tasksProvider);
      setState(() {
        _isEditing = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _toggleComplete() async {
    final task = await ref.read(taskRepositoryProvider).getTaskById(
          taskId: widget.taskId,
        );
    if (task == null) return;

    setState(() => _isLoading = true);

    try {
      final repository = ref.read(taskRepositoryProvider);
      if (task.isCompleted) {
        await repository.uncompleteTask(taskId: widget.taskId);
      } else {
        await repository.completeTask(taskId: widget.taskId);
        if (task.isRecurring) {
          await repository.createNextRecurringTask(taskId: widget.taskId);
        }
      }
      ref.invalidate(tasksProvider);
      ref.invalidate(taskByIdProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteTask() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف المهمة'),
        content: const Text('هل أنت متأكد من حذف هذه المهمة؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        final repository = ref.read(taskRepositoryProvider);
        await repository.deleteTask(taskId: widget.taskId);
        ref.invalidate(tasksProvider);
        if (mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('خطأ: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<void> _selectEditDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _editDueDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _editDueDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final taskAsync = ref.watch(taskByIdProvider(widget.taskId));
    final membersAsync = ref.watch(homeMembersProvider(widget.homeId));

    // Build member name map
    final memberNames = <String, String>{};
    membersAsync.whenData((members) {
      for (final member in members) {
        memberNames[member.userId] =
            member.userName ?? member.userEmail ?? 'عضو';
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل المهمة'),
        actions: [
          if (!_isEditing)
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    taskAsync.whenData((task) {
                      if (task != null) _startEditing(task);
                    });
                    break;
                  case 'delete':
                    _deleteTask();
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit),
                      SizedBox(width: 8),
                      Text('تعديل'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('حذف', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: taskAsync.when(
        data: (task) {
          if (task == null) {
            return const BeityEmptyState(
              title: 'المهمة غير موجودة',
              message: 'عذراً، لا يمكن العثور على تفاصيل هذه المهمة حالياً',
              icon: Icons.task_alt_rounded,
            );
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_isEditing) ...[
                  // Edit mode
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: _editTitleController,
                          decoration: const InputDecoration(
                            labelText: 'عنوان المهمة',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _editDescriptionController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'الوصف',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ListTile(
                          title: const Text('تاريخ الاستحقاق'),
                          subtitle: Text(
                            _editDueDate != null
                                ? '${_editDueDate!.day}/${_editDueDate!.month}/${_editDueDate!.year}'
                                : 'لم يتم تحديد تاريخ',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_editDueDate != null)
                                IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    setState(() {
                                      _editDueDate = null;
                                    });
                                  },
                                ),
                              const Icon(Icons.calendar_today),
                            ],
                          ),
                          onTap: _selectEditDueDate,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: Colors.grey.shade400),
                          ),
                        ),
                        const SizedBox(height: 16),
                        RecurrenceSelector(
                          selectedRecurrence: _editRecurrenceType,
                          onChanged: (value) {
                            setState(() {
                              _editRecurrenceType = value;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        membersAsync.when(
                          data: (members) {
                            return DropdownButtonFormField<String>(
                              initialValue: _editAssignedTo,
                              decoration: const InputDecoration(
                                labelText: 'إسناد إلى',
                                border: OutlineInputBorder(),
                              ),
                              items: [
                                const DropdownMenuItem<String>(
                                  value: null,
                                  child: Text('غير مسند'),
                                ),
                                ...members.map((member) =>
                                    DropdownMenuItem<String>(
                                      value: member.userId,
                                      child: Text(member.userName ??
                                          member.userEmail ??
                                          'عضو'),
                                    )),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _editAssignedTo = value;
                                });
                              },
                            );
                          },
                          loading: () =>
                              const CircularProgressIndicator(),
                          error: (e, _) =>
                              Text('خطأ في تحميل الأعضاء: $e'),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _cancelEditing,
                                child: const Text('إلغاء'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : () => ActionDebouncer.execute(_saveEditing),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2),
                                      )
                                    : const Text('حفظ'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // View mode
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                task.title,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                      decoration: task.isCompleted
                                          ? TextDecoration.lineThrough
                                          : null,
                                    ),
                              ),
                            ),
                            if (task.isRecurring)
                              Chip(
                                avatar: const Icon(Icons.repeat, size: 16),
                                label: Text(
                                  task.recurrenceType == 'daily'
                                      ? 'يومياً'
                                      : task.recurrenceType == 'weekly'
                                          ? 'أسبوعياً'
                                          : 'شهرياً',
                                ),
                              ),
                          ],
                        ),
                        if (task.description != null &&
                            task.description!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            task.description!,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                        const SizedBox(height: 16),
                        if (task.assignedTo != null)
                          ListTile(
                            leading: const Icon(Icons.person),
                            title: const Text('مسند إلى'),
                            subtitle: Text(
                              memberNames[task.assignedTo] ?? 'عضو',
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                        if (task.dueDate != null) ...[
                          const SizedBox(height: 8),
                          ListTile(
                            leading: const Icon(Icons.calendar_today),
                            title: const Text('تاريخ الاستحقاق'),
                            subtitle: Text(
                              '${task.dueDate!.day}/${task.dueDate!.month}/${task.dueDate!.year}',
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                        ],
                        if (task.isCompleted) ...[
                          const SizedBox(height: 8),
                          ListTile(
                            leading: const Icon(Icons.check_circle,
                                color: Colors.green),
                            title: const Text('تم الإكمال'),
                            subtitle: Text(
                              task.completedAt != null
                                  ? '${task.completedAt!.day}/${task.completedAt!.month}/${task.completedAt!.year}'
                                  : '',
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : () => ActionDebouncer.execute(_toggleComplete),
                            icon: Icon(
                              task.isCompleted
                                  ? Icons.undo
                                  : Icons.check_circle,
                            ),
                            label: Text(
                              task.isCompleted
                                  ? 'إرجاع المهمة'
                                  : 'إكمال المهمة',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: task.isCompleted
                                  ? Colors.orange
                                  : Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const Divider(),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: CommentThread(taskId: widget.taskId),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => BeityEmptyState(
          title: 'عذراً، حدث خطأ',
          message: error.toString(),
          icon: Icons.error_outline_rounded,
          isError: true,
          actionText: 'إعادة المحاولة',
          onActionPressed: () => ref.invalidate(taskByIdProvider(widget.taskId)),
        ),
      ),
    );
  }
}
