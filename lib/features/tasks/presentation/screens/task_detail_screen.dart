import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sawa/core/services/supabase_service.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../homes/presentation/providers/homes_provider.dart';
import '../../domain/entities/task.dart';
import '../providers/task_providers.dart';
import '../widgets/comment_thread.dart';
import '../../../../core/utils/action_debouncer.dart';
import '../../../../shared/widgets/design_system/sawa_empty_state.dart';
import '../../../../shared/widgets/design_system/sawa_loading_state.dart';
import '../../../../shared/widgets/design_system/sawa_snack_bar.dart';
import '../../../../shared/widgets/design_system/sawa_text_field.dart';
import 'package:sawa/core/localization/app_localizations.dart';
import 'package:sawa/core/errors/error_formatter.dart';
import '../../../../core/providers/permissions_provider.dart';
import 'package:sawa/features/settings/presentation/providers/app_settings_provider.dart';

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
  final _editTitleFocusNode = FocusNode();
  final _editDescriptionFocusNode = FocusNode();
  DateTime? _editDueDate;
  String? _editRecurrenceType;
  String? _editAssignedTo;

  @override
  void dispose() {
    _editTitleController.dispose();
    _editDescriptionController.dispose();
    _editTitleFocusNode.dispose();
    _editDescriptionFocusNode.dispose();
    super.dispose();
  }

  void _startEditing(Task task) {
    _editTitleController.text = task.title;
    _editDescriptionController.text = task.description ?? '';
    _editDueDate = task.dueDate;
    _editRecurrenceType = task.recurrenceType;
    _editAssignedTo = task.assignedTo;
    setState(() {
      _isEditing = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _editTitleFocusNode.requestFocus();
    });
  }

  void _cancelEditing() {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _isEditing = false;
    });
  }

  Future<void> _saveEditing() async {
    if (_editTitleController.text.trim().isEmpty) {
      if (mounted) {
        SawaSnackBar.warning(
          context,
          context.translate('please_enter_task_title'),
        );
      }
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();

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
      if (mounted) {
        final hapticEnabled = ref.read(appSettingsProvider).hapticFeedback;
        if (hapticEnabled) {
          HapticFeedback.lightImpact();
        }
        SawaSnackBar.success(
          context,
          context.translate('task_updated_success'),
        );
        setState(() {
          _isEditing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        SawaSnackBar.error(
          context,
          '${context.translate('error_occurred')}: ${ErrorFormatter.format(e, context)}',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _toggleComplete() async {
    final task = await ref
        .read(taskRepositoryProvider)
        .getTaskById(taskId: widget.taskId);
    if (task == null) return;

    setState(() => _isLoading = true);

    try {
      final repository = ref.read(taskRepositoryProvider);
      final hapticEnabled = ref.read(appSettingsProvider).hapticFeedback;
      if (task.isCompleted) {
        if (hapticEnabled) {
          HapticFeedback.lightImpact();
        }
        await repository.uncompleteTask(taskId: widget.taskId);
        if (mounted) {
          SawaSnackBar.success(
            context,
            context.translate('task_uncompleted_success'),
          );
        }
      } else {
        if (hapticEnabled) {
          HapticFeedback.mediumImpact();
        }
        await repository.completeTask(taskId: widget.taskId);
        if (task.isRecurring) {
          await repository.createNextRecurringTask(taskId: widget.taskId);
        }
        if (mounted) {
          SawaSnackBar.success(
            context,
            context.translate('task_completed_success'),
          );
        }
      }
      ref.invalidate(tasksProvider);
      ref.invalidate(taskByIdProvider);
    } catch (e) {
      if (mounted) {
        SawaSnackBar.error(
          context,
          '${context.translate('error_occurred')}: ${ErrorFormatter.format(e, context)}',
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
        title: Text(context.translate('delete_task')),
        content: Text(context.translate('delete_task_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.translate('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(context.translate('delete')),
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
          final hapticEnabled = ref.read(appSettingsProvider).hapticFeedback;
          if (hapticEnabled) {
            HapticFeedback.mediumImpact();
          }
          SawaSnackBar.success(
            context,
            context.translate('task_deleted_success'),
          );
          context.pop();
        }
      } catch (e) {
        if (mounted) {
          SawaSnackBar.error(
            context,
            '${context.translate('error_occurred')}: ${ErrorFormatter.format(e, context)}',
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
    FocusManager.instance.primaryFocus?.unfocus();
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
    final permissions = ref.watch(
      currentHomePermissionsProvider(widget.homeId),
    );
    final canManage = permissions.canEdit;

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
        title: Text(context.translate('task_details')),
        actions: [
          if (!_isEditing && canManage)
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
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      const Icon(Icons.edit),
                      const SizedBox(width: 8),
                      Text(context.translate('edit')),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      const Icon(Icons.delete, color: AppColors.error),
                      const SizedBox(width: 8),
                      Text(
                        context.translate('delete'),
                        style: const TextStyle(color: AppColors.error),
                      ),
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
            return SawaEmptyState(
              title: context.translate('task_not_found'),
              message: context.translate('task_not_found_desc'),
              icon: Icons.task_alt_rounded,
            );
          }

          return SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
                        SawaTextField(
                          controller: _editTitleController,
                          focusNode: _editTitleFocusNode,
                          labelText: context.translate('task_title'),
                          prefixIcon: Icons.task_alt_rounded,
                          textInputAction: TextInputAction.next,
                          onSubmitted: (_) =>
                              _editDescriptionFocusNode.requestFocus(),
                        ),
                        const SizedBox(height: 16),
                        SawaTextField(
                          controller: _editDescriptionController,
                          focusNode: _editDescriptionFocusNode,
                          labelText: context.translate('description_optional'),
                          prefixIcon: Icons.notes_rounded,
                          maxLines: 3,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) =>
                              ActionDebouncer.execute(_saveEditing),
                        ),
                        const SizedBox(height: 16),
                        ListTile(
                          title: Text(context.translate('due_date')),
                          subtitle: Text(
                            _editDueDate != null
                                ? '${_editDueDate!.day}/${_editDueDate!.month}/${_editDueDate!.year}'
                                : context.translate('not_specified'),
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
                        /*
                        const SizedBox(height: 16),
                        RecurrenceSelector(
                          selectedRecurrence: _editRecurrenceType,
                          onChanged: (value) {
                            setState(() {
                              _editRecurrenceType = value;
                            });
                          },
                        ),
                        */
                        const SizedBox(height: 16),
                        membersAsync.when(
                          data: (members) {
                            final currentUserId =
                                SupabaseService.client.auth.currentUser?.id;
                            final activeMembers = members
                                .where(
                                  (m) =>
                                      m.status == 'active' &&
                                      m.userId != currentUserId,
                                )
                                .toList();
                            return DropdownButtonFormField<String>(
                              initialValue: _editAssignedTo,
                              decoration: InputDecoration(
                                labelText: context.translate('assign_to'),
                                border: const OutlineInputBorder(),
                              ),
                              items: [
                                DropdownMenuItem<String>(
                                  value: null,
                                  child: Text(context.translate('unassigned')),
                                ),
                                if (currentUserId != null)
                                  DropdownMenuItem<String>(
                                    value: currentUserId,
                                    child: Text(
                                      context.translate('assign_to_me'),
                                    ),
                                  ),
                                ...activeMembers.map(
                                  (member) => DropdownMenuItem<String>(
                                    value: member.userId,
                                    child: Text(
                                      member.userName ??
                                          member.userEmail ??
                                          context.translate('member'),
                                    ),
                                  ),
                                ),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _editAssignedTo = value;
                                });
                              },
                            );
                          },
                          loading: () => const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          error: (e, _) =>
                              Text(context.translate('error_occurred')),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _cancelEditing,
                                child: Text(context.translate('cancel')),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _isLoading
                                    ? null
                                    : () =>
                                          ActionDebouncer.execute(_saveEditing),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(context.translate('save')),
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
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(
                                      decoration: task.isCompleted
                                          ? TextDecoration.lineThrough
                                          : null,
                                    ),
                              ),
                            ),
                            if (task.isRecurring && task.recurrenceType != null)
                              Chip(
                                avatar: const Icon(Icons.repeat, size: 16),
                                label: Text(
                                  context.translate(task.recurrenceType!),
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
                            title: Text(context.translate('assign_to')),
                            subtitle: Text(
                              memberNames[task.assignedTo] ??
                                  context.translate('member'),
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
                            title: Text(context.translate('due_date')),
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
                            leading: const Icon(
                              Icons.check_circle,
                              color: AppColors.success,
                            ),
                            title: Text(context.translate('completed')),
                            subtitle: Text(
                              [
                                if (task.completedBy != null)
                                  context.translate(
                                    'completed_by_name',
                                    arguments: {
                                      'name':
                                          memberNames[task.completedBy] ??
                                          context.translate('member'),
                                    },
                                  ),
                                if (task.completedAt != null)
                                  '${task.completedAt!.day}/${task.completedAt!.month}/${task.completedAt!.year}',
                              ].join('\n'),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        if (canManage)
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _isLoading
                                  ? null
                                  : () => ActionDebouncer.execute(
                                      _toggleComplete,
                                    ),
                              icon: Icon(
                                task.isCompleted
                                    ? Icons.undo
                                    : Icons.check_circle,
                              ),
                              label: Text(
                                task.isCompleted
                                    ? context.translate('undo_task')
                                    : context.translate('complete_task'),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: task.isCompleted
                                    ? AppColors.warning
                                    : AppColors.success,
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
        loading: () => SawaLoadingState(
          message: context.translate('loading_task_details'),
        ),
        error: (error, _) => SawaEmptyState(
          title: context.translate('error_occurred'),
          message: ErrorFormatter.format(error, context),
          icon: Icons.error_outline_rounded,
          isError: true,
          actionText: context.translate('retry'),
          onAction: () => ref.invalidate(taskByIdProvider(widget.taskId)),
        ),
      ),
    );
  }
}
