import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sawa/app/theme/app_spacing.dart';
import 'package:sawa/shared/widgets/design_system/sawa_button.dart';
import 'package:sawa/shared/widgets/design_system/sawa_text_field.dart';
import 'package:sawa/shared/widgets/design_system/sawa_card.dart';
import 'package:sawa/shared/widgets/design_system/sawa_empty_state.dart';
import 'package:sawa/shared/widgets/design_system/sawa_snack_bar.dart';
import '../../../../core/utils/action_debouncer.dart';
import '../providers/shopping_items_provider.dart';
import '../providers/shopping_lists_provider.dart';
import '../../domain/usecases/update_item_usecase.dart';
import '../../../categories/presentation/providers/units_provider.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../../../../core/localization/app_localizations.dart';
import 'package:sawa/core/errors/error_formatter.dart';
import '../../../categories/data/models/category_model.dart';
import '../../../categories/data/models/unit_model.dart';
import 'package:sawa/core/utils/arabic_number_parser.dart';

class EditItemScreen extends ConsumerStatefulWidget {
  final String listId;
  final String itemId;
  final String homeId;

  const EditItemScreen({
    super.key,
    required this.listId,
    required this.itemId,
    required this.homeId,
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

  final _nameFocus = FocusNode();
  final _quantityFocus = FocusNode();
  final _priceFocus = FocusNode();
  final _notesFocus = FocusNode();

  String? _selectedUnitId;
  String? _selectedCategoryId;
  bool _isLoading = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _loadItem(widget.homeId);
  }

  Future<void> _loadItem(String homeId) async {
    try {
      final repository = ref.read(
        shoppingItemRepositoryForHomeProvider(homeId),
      );
      final item = await repository.getShoppingItemById(itemId: widget.itemId);

      if (item != null && mounted) {
        setState(() {
          _nameController.text = item.name;
          _quantityController.text =
              item.quantity == item.quantity.roundToDouble()
              ? item.quantity.toInt().toString()
              : item.quantity.toStringAsFixed(1);
          _priceController.text = item.price?.toString() ?? '';
          _notesController.text = item.notes ?? '';
          _selectedUnitId = item.unitId;
          _selectedCategoryId = item.categoryId;
          _isInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        SawaSnackBar.error(
          context,
          '${context.translate('error')}: ${ErrorFormatter.format(e, context)}',
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    _nameFocus.dispose();
    _quantityFocus.dispose();
    _priceFocus.dispose();
    _notesFocus.dispose();
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
    final listAsync = ref.watch(
      shoppingListByIdForHomeProvider((
        listId: widget.listId,
        homeId: widget.homeId,
      )),
    );

    return listAsync.when(
      data: (list) {
        if (list == null) {
          return Scaffold(
            appBar: AppBar(title: Text(context.translate('edit_item'))),
            body: Center(child: Text(context.translate('list_not_found'))),
          );
        }

        final unitsAsync = ref.watch(unitsProvider(null));
        final categoriesAsync = ref.watch(categoriesProvider(widget.homeId));

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
          body: SawaEmptyState(
            title: context.translate('error_title'),
            message: error.toString(),
            icon: Icons.error_outline_rounded,
            isError: true,
            actionText: context.translate('retry'),
            onAction: () => ref.invalidate(
              shoppingListByIdForHomeProvider((
                listId: widget.listId,
                homeId: widget.homeId,
              )),
            ),
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
        title: Text(
          context.translate('edit_item'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            SawaCard(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SawaTextField(
                    controller: _nameController,
                    focusNode: _nameFocus,
                    textInputAction: TextInputAction.next,
                    onSubmitted: (_) => _quantityFocus.requestFocus(),
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
                        child: SawaTextField(
                          controller: _quantityController,
                          focusNode: _quantityFocus,
                          textInputAction: TextInputAction.next,
                          onSubmitted: (_) => _priceFocus.requestFocus(),
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
                              fillColor: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest
                                  .withValues(alpha: 0.3),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusMd,
                                ),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            items: [
                              DropdownMenuItem(
                                value: null,
                                child: Text(context.translate('no_unit')),
                              ),
                              ...units.map(
                                (unit) => DropdownMenuItem(
                                  value: unit.id,
                                  child: Text('${unit.name} (${unit.symbol})'),
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedUnitId = value;
                              });
                            },
                          ),
                          loading: () => const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          error: (e, s) =>
                              Text(context.translate('load_units_failed')),
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.gapLG,
                  SawaTextField(
                    controller: _priceController,
                    focusNode: _priceFocus,
                    textInputAction: TextInputAction.next,
                    onSubmitted: (_) => _notesFocus.requestFocus(),
                    labelText: context.translate('price_optional'),
                    hintText: '0.00',
                    prefixIcon: Icons.attach_money,
                    suffixIcon: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                      child: Text(
                        context.translate('currency_symbol'),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
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
            SawaCard(
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
                        fillColor: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest
                            .withValues(alpha: 0.3),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusMd,
                          ),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: null,
                          child: Text(context.translate('no_category')),
                        ),
                        ...categories.map(
                          (category) => DropdownMenuItem(
                            value: category.id,
                            child: Text(
                              category.name == 'Other'
                                  ? context.translate('other')
                                  : category.name,
                            ),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedCategoryId = value;
                        });
                      },
                    ),
                    loading: () => const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    error: (e, s) =>
                        Text(context.translate('load_categories_failed')),
                  ),
                  AppSpacing.gapLG,
                  SawaTextField(
                    controller: _notesController,
                    focusNode: _notesFocus,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => ActionDebouncer.execute(_saveItem),
                    labelText: context.translate('notes_optional'),
                    prefixIcon: Icons.notes_outlined,
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            AppSpacing.gapXXL,
            SawaButton(
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
      final repository = ref.read(
        shoppingItemRepositoryForHomeProvider(widget.homeId),
      );
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
        SawaSnackBar.success(
          context,
          context.translate('item_updated_success'),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        SawaSnackBar.error(
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
