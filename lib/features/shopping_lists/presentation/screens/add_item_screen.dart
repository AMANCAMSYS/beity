import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sawa/app/theme/app_spacing.dart';
import 'package:sawa/shared/widgets/design_system/sawa_button.dart';
import 'package:sawa/shared/widgets/design_system/sawa_text_field.dart';
import 'package:sawa/shared/widgets/design_system/sawa_card.dart';
import 'package:sawa/shared/widgets/design_system/sawa_empty_state.dart';
import 'package:sawa/shared/widgets/design_system/sawa_snack_bar.dart';
import 'package:sawa/shared/widgets/design_system/sawa_dialog.dart';
import '../../../../core/utils/action_debouncer.dart';
import '../../domain/entities/autocomplete_suggestion.dart';
import '../providers/shopping_items_provider.dart';
import '../providers/shopping_lists_provider.dart';
import '../widgets/item_suggestions_widget.dart';
import '../../domain/usecases/add_item_usecase.dart';
import '../../../categories/presentation/providers/units_provider.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../../../../core/localization/app_localizations.dart';
import 'package:sawa/core/errors/error_formatter.dart';
import '../../../categories/data/models/category_model.dart';
import '../../../categories/data/models/unit_model.dart';
import 'package:sawa/core/utils/arabic_number_parser.dart';

class AddItemScreen extends ConsumerStatefulWidget {
  final String listId;
  final String homeId;

  const AddItemScreen({super.key, required this.listId, required this.homeId});

  @override
  ConsumerState<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends ConsumerState<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _priceController = TextEditingController();
  final _notesController = TextEditingController();
  final _nameFocusNode = FocusNode();
  final _quantityFocusNode = FocusNode();
  final _priceFocusNode = FocusNode();
  final _notesFocusNode = FocusNode();

  String? _selectedUnitId;
  String? _selectedCategoryId;
  bool _isLoading = false;
  String _nameQuery = '';
  List<AutocompleteSuggestion> _suggestions = [];
  Timer? _debounceTimer;

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
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 300), () {
        _fetchSuggestions(query);
      });
    }
  }

  Future<void> _fetchSuggestions(String query) async {
    if (query.trim().length < 2) {
      setState(() => _suggestions = []);
      return;
    }

    try {
      final repository = ref.read(
        shoppingItemRepositoryForHomeProvider(widget.homeId),
      );
      final results = await repository.getAutocompleteSuggestions(
        homeId: widget.homeId,
        query: query,
      );

      if (mounted) {
        setState(() => _suggestions = results);
      }
    } catch (_) {
      // Silently fail — suggestions are non-critical
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _nameController.removeListener(_onNameChanged);
    _nameController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    _nameFocusNode.dispose();
    _quantityFocusNode.dispose();
    _priceFocusNode.dispose();
    _notesFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            appBar: AppBar(title: Text(context.translate('add_item'))),
            body: Center(child: Text(context.translate('list_not_found'))),
          );
        }

        final unitsAsync = ref.watch(unitsProvider(null));
        final categoriesAsync = ref.watch(categoriesProvider(widget.homeId));

        return _buildScreen(context, unitsAsync, categoriesAsync);
      },
      loading: () {
        return Scaffold(
          appBar: AppBar(title: Text(context.translate('add_item'))),
          body: const Center(child: CircularProgressIndicator()),
        );
      },
      error: (error, _) {
        return Scaffold(
          appBar: AppBar(title: Text(context.translate('add_item'))),
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
          context.translate('add_item'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            SawaCard(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SawaTextField(
                    controller: _nameController,
                    focusNode: _nameFocusNode,
                    labelText: context.translate('item_name_required_label'),
                    hintText: context.translate('item_name_hint'),
                    prefixIcon: Icons.shopping_basket_outlined,
                    autofocus: true,
                    textInputAction: TextInputAction.next,
                    onSubmitted: (_) => _quantityFocusNode.requestFocus(),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return context.translate('item_name_required_msg');
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
                          suggestion.quantity ==
                              suggestion.quantity.roundToDouble()
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
                        child: SawaTextField(
                          controller: _quantityController,
                          focusNode: _quantityFocusNode,
                          labelText: context.translate('quantity'),
                          prefixIcon: Icons.numbers,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.next,
                          onSubmitted: (_) => _priceFocusNode.requestFocus(),
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
                            isExpanded: true,
                            isDense: true,
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
                    focusNode: _priceFocusNode,
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
                    textInputAction: TextInputAction.next,
                    onSubmitted: (_) => _notesFocusNode.requestFocus(),
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
                      isExpanded: true,
                      isDense: true,
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
                    focusNode: _notesFocusNode,
                    labelText: context.translate('notes_optional'),
                    hintText: context.translate('notes_hint'),
                    prefixIcon: Icons.notes_outlined,
                    maxLines: 2,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => ActionDebouncer.execute(
                      () => _saveItem(skipDuplicateCheck: false),
                    ),
                  ),
                ],
              ),
            ),
            AppSpacing.gapXXL,
            SawaButton(
              text: _isLoading
                  ? context.translate('adding')
                  : context.translate('add'),
              icon: Icons.add_rounded,
              isLoading: _isLoading,
              onPressed: () => ActionDebouncer.execute(
                () => _saveItem(skipDuplicateCheck: false),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveItem({required bool skipDuplicateCheck}) async {
    if (!_formKey.currentState!.validate()) return;
    FocusManager.instance.primaryFocus?.unfocus();

    setState(() => _isLoading = true);

    try {
      final repository = ref.read(
        shoppingItemRepositoryForHomeProvider(widget.homeId),
      );
      final useCase = AddItemUseCase(repository);

      await useCase(
        listId: widget.listId,
        homeId: widget.homeId,
        name: _nameController.text,
        quantity: _quantityController.text.parseDouble(),
        unitId: _selectedUnitId,
        categoryId: _selectedCategoryId,
        price: _priceController.text.isNotEmpty
            ? _priceController.text.parseDouble()
            : null,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        skipDuplicateCheck: skipDuplicateCheck,
      );

      if (mounted) {
        SawaSnackBar.success(
          context,
          context.translate(
            'item_added_success',
            arguments: {'name': _nameController.text.trim()},
          ),
        );
        context.pop();
      }
    } on DuplicateItemException catch (e) {
      if (mounted) {
        final shouldAdd = await _showDuplicateWarning(e.itemName);
        if (shouldAdd == true && mounted) {
          await _saveItem(skipDuplicateCheck: true);
        }
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
        setState(() => _isLoading = false);
      }
    }
  }

  Future<bool?> _showDuplicateWarning(String itemName) {
    return SawaDialog.show(
      context,
      title: context.translate('duplicate_item'),
      message: context.translate(
        'duplicate_item_msg',
        arguments: {'name': itemName},
      ),
      confirmText: context.translate('add'),
      cancelText: context.translate('cancel'),
      icon: Icons.warning_amber_rounded,
    );
  }
}
