import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sawa/app/theme/app_spacing.dart';
import 'package:sawa/app/theme/app_colors.dart';
import 'package:sawa/shared/widgets/design_system/sawa_text_field.dart';
import 'package:sawa/shared/widgets/design_system/sawa_button.dart';
import 'package:sawa/core/utils/action_debouncer.dart';
import '../providers/inventory_provider.dart';
import '../../domain/usecases/add_inventory_item_usecase.dart';
import 'package:sawa/core/errors/error_formatter.dart';
import 'package:sawa/core/localization/app_localizations.dart';

class InventoryQuickAddSheet extends ConsumerStatefulWidget {
  final String homeId;
  final VoidCallback onItemAdded;

  const InventoryQuickAddSheet({
    super.key,
    required this.homeId,
    required this.onItemAdded,
  });

  @override
  ConsumerState<InventoryQuickAddSheet> createState() =>
      _InventoryQuickAddSheetState();
}

class _InventoryQuickAddSheetState extends ConsumerState<InventoryQuickAddSheet> {
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    ActionDebouncer.execute(() async {
        setState(() {
          _isSubmitting = true;
          _error = null;
        });

        try {
          final useCase = AddInventoryItemUseCase(
            ref.read(inventoryRepositoryProvider),
          );

          final name = _nameController.text.trim();
          final quantity = double.tryParse(_quantityController.text) ?? 1;

          await useCase(
            homeId: widget.homeId,
            name: name,
            quantity: quantity,
          );

          ref.invalidate(inventoryItemsProvider(widget.homeId));

          if (mounted) {
            widget.onItemAdded();
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                behavior: SnackBarBehavior.floating,
                content: Text(
                  context.translate(
                    'added_to_inventory_success_msg',
                    arguments: {'name': name},
                    fallback: 'Added "$name" to inventory',
                  ),
                ),
                backgroundColor: AppColors.success,
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            setState(() => _error = ErrorFormatter.format(e, context));
          }
        } finally {
          if (mounted) setState(() => _isSubmitting = false);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
        left: AppSpacing.xl,
        right: AppSpacing.xl,
        top: AppSpacing.md,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 48,
                height: 5,
                margin: const EdgeInsets.only(bottom: AppSpacing.xl),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
              ),
            ),
            
            // Title
            Text(
              context.translate('quick_add_to_inventory', fallback: 'Quick Add to Inventory'),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            AppSpacing.gapXL,

            // Error message
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: theme.colorScheme.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  border: Border.all(color: theme.colorScheme.error.withValues(alpha: 0.15)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline_rounded, color: theme.colorScheme.error, size: 20),
                    AppSpacing.gapMD,
                    Expanded(
                      child: Text(
                        _error!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              AppSpacing.gapLG,
            ],

            // Name field
            SawaTextField(
              controller: _nameController,
              labelText: context.translate('product_name', fallback: 'Product Name'),
              hintText: context.translate('what_to_add_hint', fallback: 'What do you want to add?'),
              prefixIcon: Icons.inventory_2_rounded,
              autofocus: true,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return context.translate(
                    'please_enter_product_name',
                    fallback: 'Please enter product name',
                  );
                }
                return null;
              },
            ),
            AppSpacing.gapLG,

            // Quantity section
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.translate('initial_quantity', fallback: 'Initial Quantity'),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                AppSpacing.gapSM,
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: SawaTextField(
                        controller: _quantityController,
                        hintText: '1',
                        prefixIcon: Icons.numbers_rounded,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return context.translate('field_required', fallback: 'This field is required');
                          }
                          final q = double.tryParse(value);
                          if (q == null || q <= 0) {
                            return context.translate('invalid_value', fallback: 'Invalid value');
                          }
                          return null;
                        },
                      ),
                    ),
                    AppSpacing.gapMD,
                    // Quick quantity buttons
                    Row(
                      children: [
                        _buildQuantityButton('1', theme),
                        AppSpacing.gapXS,
                        _buildQuantityButton('2', theme),
                        AppSpacing.gapXS,
                        _buildQuantityButton('5', theme),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            AppSpacing.gapXXL,

            // Submit button
            SawaButton(
              onPressed: _submit,
              isLoading: _isSubmitting,
              text: context.translate('add_to_inventory', fallback: 'Add to Inventory'),
              icon: Icons.check_circle_rounded,
              width: double.infinity,
            ),
            AppSpacing.gapSM,
          ],
        ),
      ),
    );
  }

  Widget _buildQuantityButton(String qty, ThemeData theme) {
    final isSelected = _quantityController.text == qty;
    return SizedBox(
      width: 48,
      height: 48,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _quantityController.text = qty);
        },
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSelected ? theme.colorScheme.primary : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
              color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected ? [
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              )
            ] : null,
          ),
          alignment: Alignment.center,
          child: Text(
            qty,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : theme.colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
