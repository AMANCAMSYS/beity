import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:beity/app/theme/app_spacing.dart';
import 'package:beity/app/theme/app_colors.dart';
import 'package:beity/shared/widgets/design_system/beity_button.dart';
import 'package:beity/shared/widgets/design_system/beity_text_field.dart';
import 'package:beity/shared/widgets/design_system/beity_card.dart';
import 'package:beity/shared/widgets/design_system/beity_empty_state.dart';
import '../../../../core/utils/action_debouncer.dart';
import '../providers/shopping_items_provider.dart';
import '../providers/shopping_lists_provider.dart';
import '../widgets/item_suggestions_widget.dart';
import '../../domain/usecases/add_item_usecase.dart';
import '../../../categories/presentation/providers/units_provider.dart';
import '../../../categories/presentation/providers/categories_provider.dart';

class AddItemScreen extends ConsumerStatefulWidget {
  final String listId;

  const AddItemScreen({
    super.key,
    required this.listId,
  });

  @override
  ConsumerState<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends ConsumerState<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _priceController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedUnitId;
  String? _selectedCategoryId;
  bool _isLoading = false;
  String _nameQuery = '';
  List<AutocompleteSuggestion> _suggestions = [];

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onNameChanged);
  }

  void _onNameChanged() {
    final query = _nameController.text;
    if (query != _nameQuery) {
      setState(() {
        _nameQuery = query;
      });
      _fetchSuggestions(query);
    }
  }

  Future<void> _fetchSuggestions(String query) async {
    if (query.trim().length < 2) {
      setState(() => _suggestions = []);
      return;
    }

    final listAsync = ref.read(shoppingListByIdProvider(widget.listId));
    final list = listAsync.valueOrNull;
    if (list == null) return;

    final repository = ref.read(shoppingItemRepositoryProvider);
    final results = await repository.getAutocompleteSuggestions(
      homeId: list.homeId,
      query: query,
    );

    if (mounted) {
      setState(() => _suggestions = results);
    }
  }

  @override
  void dispose() {
    _nameController.removeListener(_onNameChanged);
    _nameController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final listAsync = ref.watch(shoppingListByIdProvider(widget.listId));

    return listAsync.when(
      data: (list) {
        if (list == null) {
          final isArabic = Localizations.localeOf(context).languageCode == 'ar';
          return Scaffold(
            appBar: AppBar(title: Text(isArabic ? 'إضافة منتج' : 'Add Item')),
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
          appBar: AppBar(title: Text(isArabic ? 'إضافة منتج' : 'Add Item')),
          body: const Center(child: CircularProgressIndicator()),
        );
      },
      error: (error, _) {
        final isArabic = Localizations.localeOf(context).languageCode == 'ar';
        return Scaffold(
          appBar: AppBar(title: Text(isArabic ? 'إضافة منتج' : 'Add Item')),
          body: BeityEmptyState(
            title: isArabic ? 'حدث خطأ' : 'An error occurred',
            message: error.toString(),
            icon: Icons.error_outline_rounded,
            isError: true,
            actionText: isArabic ? 'إعادة المحاولة' : 'Try Again',
            onActionPressed: () => ref.invalidate(shoppingListByIdProvider(widget.listId)),
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
        title: Text(isArabic ? 'إضافة منتج' : 'Add Item', style: const TextStyle(fontWeight: FontWeight.bold)),
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
                    hintText: isArabic ? 'مثال: حليب، خبز، تفاح' : 'e.g. Milk, Bread, Apples',
                    prefixIcon: Icons.shopping_basket_outlined,
                    autofocus: true,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return isArabic ? 'اسم المنتج مطلوب' : 'Item name is required';
                      }
                      return null;
                    },
                  ),
                  ItemSuggestionsWidget(
                    suggestions: _suggestions,
                    query: _nameQuery,
                    onSuggestionTap: (suggestion) {
                      _nameController.text = suggestion.name;
                      _quantityController.text =
                          suggestion.quantity == suggestion.quantity.roundToDouble()
                              ? suggestion.quantity.toInt().toString()
                              : suggestion.quantity.toStringAsFixed(1);
                      setState(() {
                        _nameQuery = suggestion.name;
                        _suggestions = [];
                      });
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
                              DropdownMenuItem(
                                  value: null, child: Text(isArabic ? 'بدون وحدة' : 'No Unit')),
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
                        DropdownMenuItem(
                            value: null, child: Text(isArabic ? 'بدون تصنيف' : 'No Category')),
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
                    hintText: isArabic ? 'مثال: نوع معين، حجم كبير' : 'e.g. Specific brand, large size',
                    prefixIcon: Icons.notes_outlined,
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            AppSpacing.gapXXL,
            BeityButton(
              text: _isLoading 
                  ? (isArabic ? 'جاري الإضافة...' : 'Adding...') 
                  : (isArabic ? 'إضافة المنتج' : 'Add Item'),
              icon: Icons.add_rounded,
              isLoading: _isLoading,
              onPressed: () => ActionDebouncer.execute(() => _saveItem(skipDuplicateCheck: false)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveItem({required bool skipDuplicateCheck}) async {
    if (!_formKey.currentState!.validate()) return;

    final listAsync = ref.read(shoppingListByIdProvider(widget.listId));
    final list = listAsync.valueOrNull;
    if (list == null) return;

    setState(() => _isLoading = true);

    try {
      final repository = ref.read(shoppingItemRepositoryProvider);
      final useCase = AddItemUseCase(repository);

      await useCase(
        listId: widget.listId,
        homeId: list.homeId,
        name: _nameController.text,
        quantity: double.parse(_quantityController.text),
        unitId: _selectedUnitId,
        categoryId: _selectedCategoryId,
        price: _priceController.text.isNotEmpty
            ? double.parse(_priceController.text)
            : null,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        skipDuplicateCheck: skipDuplicateCheck,
      );

      if (mounted) {
        Navigator.pop(context);
      }
    } on DuplicateItemException catch (e) {
      if (mounted) {
        final isArabic = Localizations.localeOf(context).languageCode == 'ar';
        final shouldAdd = await _showDuplicateWarning(e.itemName, isArabic);
        if (shouldAdd == true && mounted) {
          await _saveItem(skipDuplicateCheck: true);
        }
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
        setState(() => _isLoading = false);
      }
    }
  }

  Future<bool?> _showDuplicateWarning(String itemName, bool isArabic) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isArabic ? 'منتج مكرر' : 'Duplicate Item', textAlign: TextAlign.center),
        titleTextStyle: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
        content: Text(
          isArabic 
              ? '"$itemName" موجود بالفعل في القائمة. هل تريد إضافته مرة أخرى؟'
              : '"$itemName" is already in the list. Do you want to add it again?',
          textAlign: TextAlign.center,
        ),
        actions: [
          Row(
            children: [
                Expanded(
                child: BeityButton(
                  onPressed: () => Navigator.pop(context, false),
                  text: isArabic ? 'إلغاء' : 'Cancel',
                  type: BeityButtonType.secondary,
                ),
              ),
              AppSpacing.gapMD,
              Expanded(
                child: BeityButton(
                  onPressed: () => Navigator.pop(context, true),
                  text: isArabic ? 'إضافة' : 'Add',
                  type: BeityButtonType.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
