import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:beity/app/theme/app_spacing.dart';
import 'package:beity/app/theme/app_colors.dart';
import 'package:beity/shared/widgets/design_system/beity_button.dart';
import 'package:beity/shared/widgets/design_system/beity_text_field.dart';
import 'package:beity/shared/widgets/design_system/beity_card.dart';
import 'package:beity/core/utils/action_debouncer.dart';
import '../providers/inventory_provider.dart';
import '../../domain/usecases/add_inventory_item_usecase.dart';
import '../../data/models/inventory_item_model.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../../../categories/presentation/providers/units_provider.dart';

class AddInventoryItemScreen extends ConsumerStatefulWidget {
  final String homeId;

  const AddInventoryItemScreen({super.key, required this.homeId});

  @override
  ConsumerState<AddInventoryItemScreen> createState() =>
      _AddInventoryItemScreenState();
}

class _AddInventoryItemScreenState
    extends ConsumerState<AddInventoryItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _minQuantityController = TextEditingController();
  final _notesController = TextEditingController();
  String? _selectedUnitId;
  String? _selectedCategoryId;
  List<InventoryItemModel> _suggestions = [];
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _minQuantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _onNameChanged(String query) async {
    if (query.trim().length < 2) {
      if (_suggestions.isNotEmpty) {
        setState(() => _suggestions = []);
      }
      return;
    }
    final repo = ref.read(inventoryRepositoryProvider);
    final results = await repo.searchInventoryItems(
      homeId: widget.homeId,
      query: query,
    );
    if (mounted) {
      setState(() => _suggestions = results);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    setState(() => _isSubmitting = true);

    try {
      ActionDebouncer.execute(() async {
          final useCase = AddInventoryItemUseCase(
            ref.read(inventoryRepositoryProvider),
          );

          final name = _nameController.text.trim();
          final quantity = double.tryParse(_quantityController.text) ?? 1;
          final minQuantity = _minQuantityController.text.isNotEmpty
              ? double.tryParse(_minQuantityController.text)
              : null;
          final notes =
              _notesController.text.trim().isNotEmpty
                  ? _notesController.text.trim()
                  : null;

          await useCase(
            homeId: widget.homeId,
            name: name,
            quantity: quantity,
            unitId: _selectedUnitId,
            categoryId: _selectedCategoryId,
            minQuantity: minQuantity,
            notes: notes,
          );

          ref.invalidate(inventoryItemsProvider(widget.homeId));

          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(isArabic ? 'تمت إضافة "$name" إلى المخزون' : 'Added "$name" to inventory'),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
      );
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
    final categoriesAsync = ref.watch(categoriesProvider(widget.homeId));
    final unitsAsync = ref.watch(unitsProvider(null));
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(isArabic ? 'إضافة منتج' : 'Add Product', style: const TextStyle(fontWeight: FontWeight.bold)),
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
                        child: Icon(Icons.add_business_rounded, color: theme.colorScheme.primary, size: 20),
                      ),
                      AppSpacing.gapMD,
                      Text(
                        isArabic ? 'تفاصيل المنتج' : 'Product Details',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  AppSpacing.gapXL,

                  // Name field with suggestions
                  BeityTextField(
                    controller: _nameController,
                    labelText: isArabic ? 'اسم المنتج' : 'Product Name',
                    hintText: isArabic ? 'مثال: أرز، حليب، زيت' : 'e.g. Rice, Milk, Oil',
                    prefixIcon: Icons.inventory_2_rounded,
                    onChanged: _onNameChanged,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return isArabic ? 'الرجاء إدخال اسم المنتج' : 'Please enter product name';
                      }
                      return null;
                    },
                  ),
                  
                  if (_suggestions.isNotEmpty) ...[
                    AppSpacing.gapSM,
                    Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 200),
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: _suggestions.length,
                            separatorBuilder: (context, index) => Divider(height: 1, color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
                            itemBuilder: (context, index) {
                              final item = _suggestions[index];
                              return ListTile(
                                dense: true,
                                visualDensity: VisualDensity.compact,
                                title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                subtitle: item.notes != null ? Text(item.notes!, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11)) : null,
                                trailing: Icon(Icons.history_rounded, size: 14, color: theme.colorScheme.outline),
                                onTap: () {
                                  _nameController.text = item.name;
                                  if (item.quantity > 0) {
                                    _quantityController.text = _formatQuantityValue(item.quantity);
                                  }
                                  setState(() => _suggestions = []);
                                },
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                  AppSpacing.gapLG,

                  // Quantity
                  BeityTextField(
                    controller: _quantityController,
                    labelText: isArabic ? 'الكمية المتوفرة' : 'Available Quantity',
                    prefixIcon: Icons.numbers_rounded,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.isEmpty) return isArabic ? 'الرجاء إدخال الكمية' : 'Please enter quantity';
                      final q = double.tryParse(value);
                      if (q == null || q < 0) return isArabic ? 'الرجاء إدخال كمية صحيحة' : 'Please enter a valid quantity';
                      return null;
                    },
                  ),
                  AppSpacing.gapLG,

                  // Category dropdown
                  categoriesAsync.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (e, _) => Text(isArabic ? 'خطأ في تحميل التصنيفات: $e' : 'Error loading categories: $e', style: TextStyle(color: AppColors.error)),
                    data: (categories) => _buildDropdown(
                      label: isArabic ? 'التصنيف' : 'Category',
                      value: _selectedCategoryId,
                      hint: isArabic ? 'اختر تصنيفاً (اختياري)' : 'Select category (optional)',
                      icon: Icons.category_rounded,
                      items: [
                        DropdownMenuItem(
                          value: null,
                          child: Text(isArabic ? 'بدون تصنيف' : 'No Category'),
                        ),
                        ...categories.map((cat) => DropdownMenuItem(
                              value: cat.id,
                              child: Text(cat.name),
                            )),
                      ],
                      onChanged: (value) => setState(() => _selectedCategoryId = value),
                      theme: theme,
                      isArabic: isArabic,
                    ),
                  ),
                  AppSpacing.gapLG,

                  // Unit dropdown
                  unitsAsync.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (e, _) => Text(isArabic ? 'خطأ في تحميل الوحدات: $e' : 'Error loading units: $e', style: TextStyle(color: AppColors.error)),
                    data: (units) => _buildDropdown(
                      label: isArabic ? 'الوحدة' : 'Unit',
                      value: _selectedUnitId,
                      hint: isArabic ? 'اختر وحدة (اختياري)' : 'Select unit (optional)',
                      icon: Icons.straighten_rounded,
                      items: [
                        DropdownMenuItem(
                          value: null,
                          child: Text(isArabic ? 'بدون وحدة' : 'No Unit'),
                        ),
                        ...units.map((unit) => DropdownMenuItem(
                              value: unit.id,
                              child: Text('${unit.name} (${unit.symbol})'),
                            )),
                      ],
                      onChanged: (value) => setState(() => _selectedUnitId = value),
                      theme: theme,
                      isArabic: isArabic,
                    ),
                  ),
                  AppSpacing.gapLG,

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
                    hintText: isArabic ? 'مكان التخزين، العلامة التجارية...' : 'Storage location, brand...',
                    prefixIcon: Icons.description_rounded,
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            AppSpacing.gapXXL,

            // Submit button
            BeityButton(
              text: isArabic ? 'إضافة إلى المخزون' : 'Add to Inventory',
              onPressed: _submit,
              isLoading: _isSubmitting,
              icon: Icons.add_rounded,
            ),
            AppSpacing.gapXXL,
          ],
        ),
      ),
    );
  }

  String _formatQuantityValue(double q) {
    if (q == q.roundToDouble() && q < 1000) {
      return q.toInt().toString();
    }
    return q.toStringAsFixed(1);
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required String hint,
    required IconData icon,
    required List<DropdownMenuItem<String?>> items,
    required ValueChanged<String?> onChanged,
    required ThemeData theme,
    required bool isArabic,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.bold,
          ),
        ),
        AppSpacing.gapXS,
        DropdownButtonFormField<String?>(
          value: value,
          style: theme.textTheme.bodyLarge,
          icon: Icon(Icons.expand_more_rounded, color: theme.colorScheme.onSurfaceVariant),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 20),
            filled: true,
            fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              borderSide: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              borderSide: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
          ),
          items: items,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
