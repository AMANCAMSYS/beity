import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:beity/app/theme/app_spacing.dart';
import 'package:beity/shared/widgets/design_system/beity_button.dart';
import 'package:beity/shared/widgets/design_system/beity_text_field.dart';
import 'package:beity/shared/widgets/design_system/beity_card.dart';
import 'package:beity/shared/widgets/design_system/beity_empty_state.dart';
import '../../../../core/utils/action_debouncer.dart';
import '../providers/shopping_items_provider.dart';
import '../providers/shopping_lists_provider.dart';
import '../../domain/usecases/update_item_usecase.dart';
import '../../../categories/presentation/providers/units_provider.dart';
import '../../../categories/presentation/providers/categories_provider.dart';

class EditItemScreen extends ConsumerStatefulWidget {
  final String listId;
  final String itemId;

  const EditItemScreen({
    super.key,
    required this.listId,
    required this.itemId,
  });

  @override
  ConsumerState<EditItemScreen> createState() => _EditItemScreenState();
}

class _EditItemScreenState extends ConsumerState<EditItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  final _notesController = TextEditingController();
  
  String? _selectedUnitId;
  String? _selectedCategoryId;
  bool _isLoading = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _loadItem();
  }

  Future<void> _loadItem() async {
    final repository = ref.read(shoppingItemRepositoryProvider);
    final item = await repository.getShoppingItemById(itemId: widget.itemId);
    
    if (item != null && mounted) {
      setState(() {
        _nameController.text = item.name;
        _quantityController.text = item.quantity == item.quantity.roundToDouble()
            ? item.quantity.toInt().toString()
            : item.quantity.toStringAsFixed(1);
        _priceController.text = item.price?.toString() ?? '';
        _notesController.text = item.notes ?? '';
        _selectedUnitId = item.unitId;
        _selectedCategoryId = item.categoryId;
        _isInitialized = true;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      final isArabic = Localizations.localeOf(context).languageCode == 'ar';
      return Scaffold(
        appBar: AppBar(title: Text(isArabic ? 'تعديل المنتج' : 'Edit Item')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Get shopping list to obtain homeId
    final listAsync = ref.watch(shoppingListByIdProvider(widget.listId));
    
    return listAsync.when(
      data: (list) {
        if (list == null) {
          final isArabic = Localizations.localeOf(context).languageCode == 'ar';
          return Scaffold(
            appBar: AppBar(title: Text(isArabic ? 'تعديل المنتج' : 'Edit Item')),
            body: Center(child: Text(isArabic ? 'القائمة غير موجودة' : 'List not found')),
          );
        }
        
        final homeId = list.homeId;
        final unitsAsync = ref.watch(unitsProvider(null));
        final categoriesAsync = ref.watch(categoriesProvider(homeId));
        
        return _buildScreen(context, unitsAsync, categoriesAsync);
      },
      loading: () {
        final isArabic = Localizations.localeOf(context).languageCode == 'ar';
        return Scaffold(
          appBar: AppBar(title: Text(isArabic ? 'تعديل المنتج' : 'Edit Item')),
          body: const Center(child: CircularProgressIndicator()),
        );
      },
      error: (error, _) {
        final isArabic = Localizations.localeOf(context).languageCode == 'ar';
        return Scaffold(
          appBar: AppBar(title: Text(isArabic ? 'تعديل المنتج' : 'Edit Item')),
          body: BeityEmptyState(
            title: isArabic ? 'حدث خطأ' : 'An error occurred',
            message: error.toString(),
            icon: Icons.error_outline_rounded,
            isError: true,
            actionText: isArabic ? 'إعادة المحاولة' : 'Try Again',
            onAction: () => ref.invalidate(shoppingListByIdProvider(widget.listId)),
          ),
        );
      },
    );
  }

  Widget _buildScreen(
    BuildContext context,
    AsyncValue<List<dynamic>> unitsAsync,
    AsyncValue<List<dynamic>> categoriesAsync,
  ) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(isArabic ? 'تعديل المنتج' : 'Edit Item', style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            BeityCard(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BeityTextField(
                    controller: _nameController,
                    labelText: isArabic ? 'اسم المنتج *' : 'Item Name *',
                    prefixIcon: Icons.shopping_basket_outlined,
                    autofocus: true,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return isArabic ? 'اسم المنتج مطلوب' : 'Item name is required';
                      }
                      return null;
                    },
                  ),
                  AppSpacing.gapLG,
                  Row(
                    children: [
                      Expanded(
                        child: BeityTextField(
                          controller: _quantityController,
                          labelText: isArabic ? 'الكمية' : 'Quantity',
                          prefixIcon: Icons.numbers,
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return isArabic ? 'الكمية مطلوبة' : 'Quantity is required';
                            }
                            final quantity = double.tryParse(value);
                            if (quantity == null || quantity <= 0) {
                              return isArabic ? 'الكمية غير صالحة' : 'Invalid quantity';
                            }
                            return null;
                          },
                        ),
                      ),
                      AppSpacing.gapMD,
                      Expanded(
                        child: unitsAsync.when(
                          data: (units) => DropdownButtonFormField<String>(
                            value: _selectedUnitId,
                            decoration: InputDecoration(
                              labelText: isArabic ? 'الوحدة' : 'Unit',
                              prefixIcon: const Icon(Icons.straighten),
                              filled: true,
                              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            items: [
                              DropdownMenuItem(value: null, child: Text(isArabic ? 'بدون وحدة' : 'No Unit')),
                              ...units.map((unit) => DropdownMenuItem(
                                    value: unit.id,
                                    child: Text('${unit.name} (${unit.symbol})'),
                                  )),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedUnitId = value;
                              });
                            },
                          ),
                          loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                          error: (_, __) => Text(isArabic ? 'خطأ في تحميل الوحدات' : 'Error loading units'),
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.gapLG,
                  BeityTextField(
                    controller: _priceController,
                    labelText: isArabic ? 'السعر (اختياري)' : 'Price (Optional)',
                    hintText: '0.00',
                    prefixIcon: Icons.attach_money,
                    suffixIcon: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      child: Text(isArabic ? 'ر.س' : 'SAR', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final price = double.tryParse(value);
                        if (price == null || price < 0) {
                          return isArabic ? 'السعر غير صالح' : 'Invalid price';
                        }
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            AppSpacing.gapLG,
            BeityCard(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  categoriesAsync.when(
                    data: (categories) => DropdownButtonFormField<String>(
                      value: _selectedCategoryId,
                      decoration: InputDecoration(
                        labelText: isArabic ? 'التصنيف' : 'Category',
                        prefixIcon: const Icon(Icons.category_outlined),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: [
                        DropdownMenuItem(value: null, child: Text(isArabic ? 'بدون تصنيف' : 'No Category')),
                        ...categories.map((category) => DropdownMenuItem(
                              value: category.id,
                                child: Text(category.name == 'Other' ? (isArabic ? 'أخرى' : 'Other') : category.name),
                            )),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedCategoryId = value;
                        });
                      },
                    ),
                    loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    error: (_, __) => Text(isArabic ? 'خطأ في تحميل التصنيفات' : 'Error loading categories'),
                  ),
                  AppSpacing.gapLG,
                  BeityTextField(
                    controller: _notesController,
                    labelText: isArabic ? 'ملاحظات (اختياري)' : 'Notes (Optional)',
                    prefixIcon: Icons.notes_outlined,
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            AppSpacing.gapXXL,
            BeityButton(
              text: _isLoading 
                  ? (isArabic ? 'جاري الحفظ...' : 'Saving...') 
                  : (isArabic ? 'حفظ التعديلات' : 'Save Changes'),
              icon: Icons.save_rounded,
              isLoading: _isLoading,
              onPressed: () => ActionDebouncer.execute(_saveItem),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final repository = ref.read(shoppingItemRepositoryProvider);
      final useCase = UpdateItemUseCase(repository);
      
      await useCase(
        itemId: widget.itemId,
        name: _nameController.text,
        quantity: double.parse(_quantityController.text),
        unitId: _selectedUnitId,
        categoryId: _selectedCategoryId,
        price: _priceController.text.isNotEmpty
            ? double.parse(_priceController.text)
            : null,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        final isArabic = Localizations.localeOf(context).languageCode == 'ar';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${isArabic ? 'خطأ' : 'Error'}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
