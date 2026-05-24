import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:beity/app/theme/app_spacing.dart';
import 'package:beity/shared/widgets/design_system/beity_button.dart';
import 'package:beity/shared/widgets/design_system/beity_text_field.dart';
import 'package:beity/shared/widgets/design_system/beity_card.dart';
import '../../../homes/presentation/providers/homes_provider.dart';
import '../providers/task_providers.dart';
import '../widgets/recurrence_selector.dart';
import '../../../../core/utils/action_debouncer.dart';

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

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('يجب تسجيل الدخول أولاً')),
        );
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
        context.pop();
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

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final theme = Theme.of(context);
    final membersAsync = ref.watch(homeMembersProvider(widget.homeId));

    return Scaffold(
      appBar: AppBar(
        title: Text(isArabic ? 'إضافة مهمة' : 'Add Task', style: const TextStyle(fontWeight: FontWeight.bold)),
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
                    isArabic ? 'تفاصيل المهمة' : 'Task Details',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  AppSpacing.gapLG,
                  BeityTextField(
                    controller: _titleController,
                    labelText: isArabic ? 'عنوان المهمة' : 'Task Title',
                    hintText: isArabic ? 'ماذا يجب أن نفعل؟' : 'What needs to be done?',
                    prefixIcon: Icons.task_alt_rounded,
                    autofocus: true,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return isArabic ? 'الرجاء إدخال عنوان المهمة' : 'Please enter task title';
                      }
                      if (value.trim().length > 200) {
                        return isArabic ? 'العنوان طويل جداً' : 'Title is too long';
                      }
                      return null;
                    },
                  ),
                  AppSpacing.gapLG,
                  BeityTextField(
                    controller: _descriptionController,
                    labelText: isArabic ? 'الوصف (اختياري)' : 'Description (Optional)',
                    hintText: isArabic ? 'تفاصيل إضافية...' : 'Additional details...',
                    prefixIcon: Icons.notes_rounded,
                    maxLines: 3,
                    validator: (value) {
                      if (value != null && value.length > 2000) {
                        return isArabic ? 'الوصف طويل جداً' : 'Description is too long';
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
                    isArabic ? 'التوقيت والإسناد' : 'Timing & Assignment',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  AppSpacing.gapLG,
                  
                  // Date Picker
                  Text(
                    isArabic ? 'تاريخ الاستحقاق' : 'Due Date',
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
                                : (isArabic ? 'لم يتم التحديد' : 'Not specified'),
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
                        value: _selectedAssignedTo,
                        decoration: InputDecoration(
                          labelText: isArabic ? 'إسناد إلى' : 'Assign to',
                          prefixIcon: const Icon(Icons.person_outline_rounded),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                          ),
                        ),
                        items: [
                          DropdownMenuItem<String>(
                            value: null,
                            child: Text(isArabic ? 'غير مسند' : 'Unassigned'),
                          ),
                          ...members.map((member) => DropdownMenuItem<String>(
                                value: member.userId,
                                child: Text(member.userName ?? member.userEmail ?? (isArabic ? 'عضو' : 'Member')),
                              )),
                        ],
                        onChanged: (value) => setState(() => _selectedAssignedTo = value),
                      );
                    },
                    loading: () => const LinearProgressIndicator(),
                    error: (e, _) => Text(isArabic ? 'خطأ في تحميل الأعضاء' : 'Error loading members'),
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
              text: isArabic ? 'حفظ المهمة' : 'Save Task',
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
