import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../shared/widgets/design_system/sawa_button.dart';
import '../../../../shared/widgets/design_system/sawa_text_field.dart';
import '../../../../shared/widgets/design_system/sawa_snack_bar.dart';
import '../../../../shared/widgets/design_system/sawa_dialog.dart';
import '../../../../core/utils/action_debouncer.dart';
import '../../../../core/localization/app_localizations.dart';
import 'package:sawa/core/errors/error_formatter.dart';
import '../providers/shopping_items_provider.dart';

import '../../domain/usecases/add_item_usecase.dart';
import '../../../categories/presentation/providers/units_provider.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../../../settings/presentation/providers/app_settings_provider.dart';
import 'package:sawa/core/utils/arabic_number_parser.dart';

class QuickAddItemBottomSheet extends ConsumerStatefulWidget {
  final String listId;
  final String homeId;

  const QuickAddItemBottomSheet({
    super.key,
    required this.listId,
    required this.homeId,
  });

  @override
  ConsumerState<QuickAddItemBottomSheet> createState() =>
      _QuickAddItemBottomSheetState();
}

class _QuickAddItemBottomSheetState
    extends ConsumerState<QuickAddItemBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');

  final _nameFocusNode = FocusNode();

  String? _selectedUnitId;
  String? _selectedCategoryId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _nameFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  void _incrementQuantity() {
    final currentVal = double.tryParse(_quantityController.text) ?? 1.0;
    setState(() {
      _quantityController.text = (currentVal + 1.0).toInt().toString();
    });
    final hapticEnabled = ref.read(appSettingsProvider).hapticFeedback;
    if (hapticEnabled) {
      HapticFeedback.lightImpact();
    }
  }

  void _decrementQuantity() {
    final currentVal = double.tryParse(_quantityController.text) ?? 1.0;
    if (currentVal > 1.0) {
      setState(() {
        _quantityController.text = (currentVal - 1.0).toInt().toString();
      });
      final hapticEnabled = ref.read(appSettingsProvider).hapticFeedback;
      if (hapticEnabled) {
        HapticFeedback.lightImpact();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unitsAsync = ref.watch(unitsProvider(null));
    final categoriesAsync = ref.watch(categoriesProvider(widget.homeId));

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusXl),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 48,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.2,
                  ),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.xl,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        context.translate('add_item'),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      AppSpacing.gapLG,
                      // Item Name Input
                      SawaTextField(
                        controller: _nameController,
                        focusNode: _nameFocusNode,
                        labelText: context.translate(
                          'item_name_required_label',
                        ),
                        hintText: context.translate('item_name_hint'),
                        prefixIcon: Icons.shopping_basket_outlined,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return context.translate('item_name_required_msg');
                          }
                          return null;
                        },
                      ),
                      AppSpacing.gapLG,
                      // Quantity Row with Tactile Buttons & Unit
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  context.translate('quantity'),
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    IconButton.filledTonal(
                                      onPressed: _decrementQuantity,
                                      icon: const Icon(Icons.remove_rounded),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    Expanded(
                                      child: TextField(
                                        controller: _quantityController,
                                        keyboardType:
                                            const TextInputType.numberWithOptions(
                                              decimal: true,
                                            ),
                                        textAlign: TextAlign.center,
                                        decoration: InputDecoration(
                                          isDense: true,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                vertical: 10,
                                              ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              AppSpacing.radiusMd,
                                            ),
                                            borderSide: BorderSide(
                                              color: theme.colorScheme.outline
                                                  .withValues(alpha: 0.3),
                                            ),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              AppSpacing.radiusMd,
                                            ),
                                            borderSide: BorderSide(
                                              color: theme.colorScheme.outline
                                                  .withValues(alpha: 0.2),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    IconButton.filledTonal(
                                      onPressed: _incrementQuantity,
                                      icon: const Icon(Icons.add_rounded),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          AppSpacing.gapMD,
                          Expanded(
                            flex: 2,
                            child: unitsAsync.when(
                              data: (units) => DropdownButtonFormField<String>(
                                initialValue: _selectedUnitId,
                                decoration: InputDecoration(
                                  labelText: context.translate('unit'),
                                  prefixIcon: const Icon(
                                    Icons.straighten,
                                    size: 20,
                                  ),
                                  filled: true,
                                  fillColor: theme
                                      .colorScheme
                                      .surfaceContainerHighest
                                      .withValues(alpha: 0.3),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppSpacing.radiusMd,
                                    ),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                ),
                                style: theme.textTheme.bodyMedium,
                                items: [
                                  DropdownMenuItem(
                                    value: null,
                                    child: Text(
                                      context.translate('no_unit'),
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                  ),
                                  ...units.map(
                                    (unit) => DropdownMenuItem(
                                      value: unit.id,
                                      child: Text(
                                        '${unit.name} (${unit.symbol})',
                                        style: theme.textTheme.bodyMedium,
                                        overflow: TextOverflow.ellipsis,
                                      ),
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
                                child: Padding(
                                  padding: EdgeInsets.only(top: 24),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                              error: (e, s) =>
                                  Text(context.translate('load_units_failed')),
                            ),
                          ),
                        ],
                      ),
                      AppSpacing.gapLG,
                      // Category selection
                      categoriesAsync.when(
                        data: (categories) => DropdownButtonFormField<String>(
                          initialValue: _selectedCategoryId,
                          decoration: InputDecoration(
                            labelText: context.translate('category'),
                            prefixIcon: const Icon(
                              Icons.category_outlined,
                              size: 20,
                            ),
                            filled: true,
                            fillColor: theme.colorScheme.surfaceContainerHighest
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
                      AppSpacing.gapXL,
                      // Add Button
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveItem({required bool skipDuplicateCheck}) async {
    if (!_formKey.currentState!.validate()) return;

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
        price: null,
        notes: null,
        skipDuplicateCheck: skipDuplicateCheck,
      );
      final hapticEnabled = ref.read(appSettingsProvider).hapticFeedback;
      if (hapticEnabled) {
        HapticFeedback.mediumImpact();
      }
      // The offline aware repository and realtime stream handle immediate local and remote updates,
      // so we do not need to explicitly invalidate the provider.
      if (mounted) {
        Navigator.pop(context);
        SawaSnackBar.success(
          context,
          context.translate(
            'added_item_success',
            arguments: {'name': _nameController.text},
          ),
        );
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
