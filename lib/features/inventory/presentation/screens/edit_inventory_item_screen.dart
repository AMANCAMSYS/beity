import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:beity/app/theme/app_spacing.dart';
import 'package:beity/app/theme/app_colors.dart';
import 'package:beity/shared/widgets/design_system/beity_button.dart';
import 'package:beity/shared/widgets/design_system/beity_text_field.dart';
import 'package:beity/shared/widgets/design_system/beity_card.dart';
import 'package:beity/core/utils/action_debouncer.dart';
import '../providers/inventory_provider.dart';
import '../widgets/quantity_adjuster_widget.dart';

class EditInventoryItemScreen extends ConsumerStatefulWidget {
  final String itemId;
  final String homeId;

  const EditInventoryItemScreen({
    super.key,
    required this.itemId,
    required this.homeId,
  });

  @override
  ConsumerState<EditInventoryItemScreen> createState() =>
      _EditInventoryItemScreenState();
}

class _EditInventoryItemScreenState
    extends ConsumerState<EditInventoryItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _minQuantityController = TextEditingController();
  final _notesController = TextEditingController();
  double _quantity = 0;
  double _originalQuantity = 0;
  String? _selectedUnitId;
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _itemNotFound = false;

  @override
  void initState() {
    super.initState();
    _loadItem();
  }

  Future<void> _loadItem() async {
    try {
      final repo = ref.read(inventoryRepositoryProvider);
      final item = await repo.getInventoryItemById(itemId: widget.itemId);
      if (!mounted) return;
      if (item != null) {
        setState(() {
          _nameController.text = item.name;
          _quantity = item.quantity;
          _originalQuantity = item.quantity;
          _selectedUnitId = item.unitId;
          if (item.minQuantity != null) {
            _minQuantityController.text = item.minQuantity.toString();
          }
          if (item.notes != null) {
            _notesController.text = item.notes!;
          }
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _itemNotFound = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _itemNotFound = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _minQuantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    setState(() => _isSubmitting = true);

    try {
      ActionDebouncer.execute(() async {
          final repo = ref.read(inventoryRepositoryProvider);
          final minQuantity = _minQuantityController.text.isNotEmpty
              ? double.tryParse(_minQuantityController.text)
              : null;
          final notesText = _notesController.text.trim();
          final fieldsToNull = <String>[];
          if (notesText.isEmpty) fieldsToNull.add('notes');

          await repo.updateInventoryItem(
            itemId: widget.itemId,
            name: _nameController.text.trim(),
            quantity: _quantity,
            minQuantity: minQuantity,
            notes: notesText.isNotEmpty ? notesText : null,
            fieldsToNull: fieldsToNull,
          );

          // Only log transaction if quantity actually changed
          if (_quantity != _originalQuantity) {
            await repo.createTransaction(
              inventoryItemId: widget.itemId,
              homeId: widget.homeId,
              previousQuantity: _originalQuantity,
              newQuantity: _quantity,
              changeReason: 'manual_update',
            );
          }

          ref.invalidate(inventoryItemsProvider(widget.homeId));

          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(isArabic ? 'تم تحديث المنتج' : 'Product updated successfully'),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isArabic ? 'خطأ: $e' : 'Error: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(isArabic ? 'تعديل المنتج' : 'Edit Product', style: const TextStyle(fontWeight: FontWeight.bold))),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_itemNotFound) {
      return Scaffold(
        appBar: AppBar(title: Text(isArabic ? 'تعديل المنتج' : 'Edit Product', style: const TextStyle(fontWeight: FontWeight.bold))),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xxl),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.error_outline_rounded, size: 64, color: theme.colorScheme.error),
                ),
                AppSpacing.gapLG,
                Text(
                  isArabic ? 'المنتج غير موجود' : 'Item not found',
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                AppSpacing.gapSM,
                Text(
                  isArabic ? 'قد يكون تم حذف هذا المنتج' : 'This product might have been deleted',
                  style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
                AppSpacing.gapXL,
                BeityButton(
                  text: isArabic ? 'العودة' : 'Go Back',
                  onPressed: () => Navigator.pop(context),
                  type: BeityButtonType.secondary,
                  width: 160,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isArabic ? 'تعديل المنتج' : 'Edit Product', style: const TextStyle(fontWeight: FontWeight.bold)),
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
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                        child: Icon(Icons.edit_document, color: theme.colorScheme.primary, size: 20),
                      ),
                      AppSpacing.gapMD,
                      Text(
                        isArabic ? 'تعديل البيانات' : 'Edit Details',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  AppSpacing.gapXL,

                  // Name field
                  BeityTextField(
                    controller: _nameController,
                    labelText: isArabic ? 'اسم المنتج' : 'Product Name',
                    prefixIcon: Icons.inventory_2_rounded,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return isArabic ? 'الرجاء إدخال اسم المنتج' : 'Please enter product name';
                      }
                      return null;
                    },
                  ),
                  AppSpacing.gapXL,

                  // Quantity adjuster section
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                      border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.1)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.numbers_rounded, size: 16, color: theme.colorScheme.onSurfaceVariant),
                            AppSpacing.gapSM,
                            Text(
                              isArabic ? 'تعديل الكمية الحالية' : 'Adjust Current Quantity',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        AppSpacing.gapLG,
                        QuantityAdjusterWidget(
                          quantity: _quantity,
                          unitId: _selectedUnitId,
                          onChanged: (newQty) {
                            setState(() => _quantity = newQty);
                          },
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.gapXL,

                  // Min quantity threshold
                  BeityTextField(
                    controller: _minQuantityController,
                    labelText: isArabic ? 'تنبيه نقص المخزون' : 'Low Stock Alert',
                    hintText: isArabic ? 'أقل كمية قبل التنبيه' : 'Min quantity for alert',
                    prefixIcon: Icons.notification_important_rounded,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  AppSpacing.gapLG,

                  // Notes
                  BeityTextField(
                    controller: _notesController,
                    labelText: isArabic ? 'ملاحظات إضافية' : 'Additional Notes',
                    prefixIcon: Icons.description_rounded,
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            AppSpacing.gapXXL,

            // Submit button
            BeityButton(
              text: isArabic ? 'حفظ التعديلات' : 'Save Changes',
              onPressed: _submit,
              isLoading: _isSubmitting,
              icon: Icons.check_rounded,
            ),
            AppSpacing.gapXXL,
          ],
        ),
      ),
    );
  }
}
