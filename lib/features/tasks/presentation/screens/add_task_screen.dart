import 'package:beity/core/services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:beity/app/theme/app_spacing.dart';
import 'package:beity/features/settings/presentation/providers/app_settings_provider.dart';
import 'package:beity/shared/widgets/design_system/beity_button.dart';
import 'package:beity/shared/widgets/design_system/beity_text_field.dart';
import 'package:beity/shared/widgets/design_system/beity_card.dart';
import 'package:beity/shared/widgets/design_system/beity_snack_bar.dart';
import '../../../homes/presentation/providers/homes_provider.dart';
import '../providers/task_providers.dart';
import '../widgets/recurrence_selector.dart';
import '../../../../core/utils/action_debouncer.dart';
import 'package:beity/core/localization/app_localizations.dart';
import 'package:beity/core/errors/error_formatter.dart';

class AddTaskScreen extends ConsumerStatefulWidget {
  final String homeId;

  const AddTaskScreen({
    super.key,
    required this.homeId,
  });

  @override
  ConsumerState<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends ConsumerState<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _selectedDueDate;
  String? _selectedCategoryId;
  String? _selectedAssignedTo;
  String? _selectedRecurrenceType;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDueDate = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final user = SupabaseService.client.auth.currentUser;
    if (user == null) {
      if (mounted) {
        BeitySnackBar.warning(context, context.translate('must_login_first'));
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      final repository = ref.read(taskRepositoryProvider);
      await repository.createTask(
        homeId: widget.homeId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        dueDate: _selectedDueDate,
        categoryId: _selectedCategoryId,
        assignedTo: _selectedAssignedTo,
        recurrenceType: _selectedRecurrenceType,
      );

      if (mounted) {
        final hapticEnabled = ref.read(appSettingsProvider).hapticFeedback;
        if (hapticEnabled) {
          HapticFeedback.mediumImpact();
        }
        BeitySnackBar.success(context, context.translate('task_created_success'));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        BeitySnackBar.error(
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final membersAsync = ref.watch(homeMembersProvider(widget.homeId));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(context.translate('add_task'), style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            BeityCard(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.translate('task_details'),
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  AppSpacing.gapLG,
                  BeityTextField(
                    controller: _titleController,
                    labelText: context.translate('task_title'),
                    hintText: context.translate('task_title_hint'),
                    prefixIcon: Icons.task_alt_rounded,
                    autofocus: true,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return context.translate('please_enter_task_title');
                      }
                      if (value.trim().length > 200) {
                        return context.translate('title_too_long');
                      }
                      return null;
                    },
                  ),
                  AppSpacing.gapLG,
                  BeityTextField(
                    controller: _descriptionController,
                    labelText: context.translate('description_optional'),
                    hintText: context.translate('additional_details_placeholder'),
                    prefixIcon: Icons.notes_rounded,
                    maxLines: 3,
                    validator: (value) {
                      if (value != null && value.length > 2000) {
                        return context.translate('description_too_long');
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            AppSpacing.gapLG,

            BeityCard(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.translate('timing_assignment'),
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  AppSpacing.gapLG,
                  
                  // Date Picker
                  Text(
                    context.translate('due_date'),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  AppSpacing.gapSM,
                  InkWell(
                    onTap: _selectDueDate,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today_rounded, size: 20, color: theme.colorScheme.primary),
                          AppSpacing.gapMD,
                          Text(
                            _selectedDueDate != null
                                ? '${_selectedDueDate!.day}/${_selectedDueDate!.month}/${_selectedDueDate!.year}'
                                : context.translate('not_specified'),
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: _selectedDueDate != null ? FontWeight.bold : FontWeight.normal,
                              color: _selectedDueDate != null ? null : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const Spacer(),
                          if (_selectedDueDate != null)
                            IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () => setState(() => _selectedDueDate = null),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                        ],
                      ),
                    ),
                  ),
                  AppSpacing.gapLG,

                  // Assignee dropdown
                  membersAsync.when(
                    data: (members) {
                      return DropdownButtonFormField<String>(
                        initialValue: _selectedAssignedTo,
                        decoration: InputDecoration(
                          labelText: context.translate('assign_to'),
                          prefixIcon: const Icon(Icons.person_outline_rounded),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                          ),
                        ),
                        items: [
                          DropdownMenuItem<String>(
                            value: null,
                            child: Text(context.translate('unassigned')),
                          ),
                          ...members.map((member) => DropdownMenuItem<String>(
                                value: member.userId,
                                child: Text(member.userName ?? member.userEmail ?? context.translate('member')),
                              )),
                        ],
                        onChanged: (value) => setState(() => _selectedAssignedTo = value),
                      );
                    },
                    loading: () => const LinearProgressIndicator(),
                    error: (e, _) => Text(context.translate('error_occurred')),
                  ),
                ],
              ),
            ),
            AppSpacing.gapLG,

            BeityCard(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: RecurrenceSelector(
                selectedRecurrence: _selectedRecurrenceType,
                onChanged: (value) => setState(() => _selectedRecurrenceType = value),
              ),
            ),
            AppSpacing.gapXXL,

            BeityButton(
              text: context.translate('save_task'),
              icon: Icons.check_rounded,
              isLoading: _isLoading,
              onPressed: () => ActionDebouncer.execute(_submit),
            ),
          ],
        ),
      ),
    );
  }
}
