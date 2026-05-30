import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:beity/app/theme/app_spacing.dart';
import 'package:beity/shared/widgets/design_system/beity_button.dart';
import 'package:beity/shared/widgets/design_system/beity_text_field.dart';
import 'package:beity/shared/widgets/design_system/beity_card.dart';
import 'package:beity/shared/widgets/design_system/beity_empty_state.dart';
import 'package:beity/shared/widgets/design_system/beity_snack_bar.dart';
import '../../../../core/utils/action_debouncer.dart';
import '../providers/shopping_items_provider.dart';
import '../providers/shopping_lists_provider.dart';
import '../../domain/usecases/update_item_usecase.dart';
import '../../../categories/presentation/providers/units_provider.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../../../../core/localization/app_localizations.dart';
import 'package:beity/core/errors/error_formatter.dart';
import '../../../categories/data/models/category_model.dart';
import '../../../categories/data/models/unit_model.dart';
import 'package:beity/core/utils/arabic_number_parser.dart';

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
      return Scaffold(
        appBar: AppBar(title: Text(context.translate('edit_item'))),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Get shopping list to obtain homeId
    final listAsync = ref.watch(shoppingListByIdProvider(widget.listId));
    
    return listAsync.when(
      data: (list) {
        if (list == null) {
          return Scaffold(
            appBar: AppBar(title: Text(context.translate('edit_item'))),
            body: Center(child: Text(context.translate('list_not_found'))),
          );
        }
        
        final homeId = list.homeId;
        final unitsAsync = ref.watch(unitsProvider(null));
        final categoriesAsync = ref.watch(categoriesProvider(homeId));
        
        return _buildScreen(context, unitsAsync, categoriesAsync);
      },
      loading: () {
        return Scaffold(
          appBar: AppBar(title: Text(context.translate('edit_item'))),
          body: const Center(child: CircularProgressIndicator()),
        );
      },
      error: (error, _) {
        return Scaffold(
          appBar: AppBar(title: Text(context.translate('edit_item'))),
          body: BeityEmptyState(
            title: context.translate('error_title'),
            message: error.toString(),
            icon: Icons.error_outline_rounded,
            isError: true,
            actionText: context.translate('retry'),
            onAction: () => ref.invalidate(shoppingListByIdProvider(widget.listId)),
          ),
        );
      },
    );
  }

  Widget _buildScreen(
    BuildContext context,
    AsyncValue<List<UnitModel>> unitsAsync,
    AsyncValue<List<CategoryModel>> categoriesAsync,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.translate('edit_item'), style: const TextStyle(fontWeight: FontWeight.bold)),
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
                    labelText: context.translate('item_name_required_label'),
                    prefixIcon: Icons.shopping_basket_outlined,
                    autofocus: true,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return context.translate('item_name_required_msg');
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
                          labelText: context.translate('quantity'),
                          prefixIcon: Icons.numbers,
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return context.translate('quantity_required');
                            }
                            final quantity = value.tryParseDouble();
                            if (quantity == null || quantity <= 0) {
                              return context.translate('quantity_invalid');
                            }
                            return null;
                          },
                        ),
                      ),
                      AppSpacing.gapMD,
                      Expanded(
                        child: unitsAsync.when(
                          data: (units) => DropdownButtonFormField<String>(
                            initialValue: _selectedUnitId,
                            decoration: InputDecoration(
                              labelText: context.translate('unit'),
                              prefixIcon: const Icon(Icons.straighten),
                              filled: true,
                              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            items: [
                              DropdownMenuItem(value: null, child: Text(context.translate('no_unit'))),
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
                          error: (e, s) => Text(context.translate('load_units_failed')),
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.gapLG,
                  BeityTextField(
                    controller: _priceController,
                    labelText: context.translate('price_optional'),
                    hintText: '0.00',
                    prefixIcon: Icons.attach_money,
                    suffixIcon: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      child: Text(context.translate('currency_symbol'), style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final price = value.tryParseDouble();
                        if (price == null || price < 0) {
                          return context.translate('price_invalid');
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
                      initialValue: _selectedCategoryId,
                      decoration: InputDecoration(
                        labelText: context.translate('category'),
                        prefixIcon: const Icon(Icons.category_outlined),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: [
                        DropdownMenuItem(value: null, child: Text(context.translate('no_category'))),
                        ...categories.map((category) => DropdownMenuItem(
                              value: category.id,
                              child: Text(category.name == 'Other' ? context.translate('other') : category.name),
                            )),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedCategoryId = value;
                        });
                      },
                    ),
                    loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    error: (e, s) => Text(context.translate('load_categories_failed')),
                  ),
                  AppSpacing.gapLG,
                  BeityTextField(
                    controller: _notesController,
                    labelText: context.translate('notes_optional'),
                    prefixIcon: Icons.notes_outlined,
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            AppSpacing.gapXXL,
            BeityButton(
              text: _isLoading 
                  ? context.translate('saving') 
                  : context.translate('save_changes'),
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
        quantity: _quantityController.text.parseDouble(),
        unitId: _selectedUnitId,
        categoryId: _selectedCategoryId,
        price: _priceController.text.isNotEmpty
            ? _priceController.text.parseDouble()
            : null,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );

      if (mounted) {
        BeitySnackBar.success(context, context.translate('item_updated_success'));
        Navigator.pop(context);
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
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
