import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sawa/app/theme/app_spacing.dart';
import 'package:sawa/shared/widgets/design_system/sawa_button.dart';
import 'package:sawa/shared/widgets/design_system/sawa_text_field.dart';
import 'package:sawa/shared/widgets/design_system/sawa_card.dart';
import 'package:sawa/app/router/shopping_route_paths.dart';
import '../../../../core/utils/action_debouncer.dart';
import 'package:go_router/go_router.dart';
import 'package:sawa/core/errors/error_formatter.dart';

import 'package:sawa/shared/widgets/design_system/sawa_snack_bar.dart';
import '../../domain/usecases/create_shopping_list_usecase.dart';
import '../providers/shopping_lists_provider.dart';
import '../../../../core/localization/app_localizations.dart';

class CreateShoppingListScreen extends ConsumerStatefulWidget {
  final String homeId;

  const CreateShoppingListScreen({super.key, required this.homeId});

  @override
  ConsumerState<CreateShoppingListScreen> createState() =>
      _CreateShoppingListScreenState();
}

class _CreateShoppingListScreenState
    extends ConsumerState<CreateShoppingListScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _nameFocusNode = FocusNode();
  String _selectedIcon = 'shopping_cart';
  bool _isLoading = false;

  static const _iconOptions = [
    {
      'icon': 'shopping_cart',
      'key': 'cat_groceries',
      'data': Icons.shopping_cart,
    },
    {'icon': 'shopping_bag', 'key': 'cat_shopping', 'data': Icons.shopping_bag},
    {
      'icon': 'local_grocery_store',
      'key': 'cat_store',
      'data': Icons.local_grocery_store,
    },
    {
      'icon': 'local_pharmacy',
      'key': 'cat_pharmacy',
      'data': Icons.local_pharmacy,
    },
    {
      'icon': 'local_hospital',
      'key': 'cat_health',
      'data': Icons.local_hospital,
    },
    {'icon': 'restaurant', 'key': 'cat_restaurant', 'data': Icons.restaurant},
    {'icon': 'local_cafe', 'key': 'cat_cafe', 'data': Icons.local_cafe},
    {'icon': 'home', 'key': 'cat_home', 'data': Icons.home},
    {'icon': 'hardware', 'key': 'cat_tools', 'data': Icons.hardware},
    {'icon': 'build', 'key': 'cat_build', 'data': Icons.build},
    {'icon': 'child_care', 'key': 'cat_baby', 'data': Icons.child_care},
    {'icon': 'pets', 'key': 'cat_pets', 'data': Icons.pets},
    {'icon': 'card_giftcard', 'key': 'cat_gifts', 'data': Icons.card_giftcard},
    {
      'icon': 'celebration',
      'key': 'cat_celebration',
      'data': Icons.celebration,
    },
    {'icon': 'school', 'key': 'cat_school', 'data': Icons.school},
    {
      'icon': 'fitness_center',
      'key': 'cat_fitness',
      'data': Icons.fitness_center,
    },
    {
      'icon': 'cleaning_services',
      'key': 'cat_cleaning',
      'data': Icons.cleaning_services,
    },
    {
      'icon': 'local_florist',
      'key': 'cat_flowers',
      'data': Icons.local_florist,
    },
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  IconData _getIconData(String iconName) {
    for (final option in _iconOptions) {
      if (option['icon'] == iconName) return option['data'] as IconData;
    }
    return Icons.shopping_cart;
  }

  Future<void> _createList() async {
    if (!_formKey.currentState!.validate()) return;
    FocusManager.instance.primaryFocus?.unfocus();

    setState(() => _isLoading = true);

    try {
      final repository = ref.read(
        shoppingListRepositoryForHomeProvider(widget.homeId),
      );
      final useCase = CreateShoppingListUseCase(repository);
      final list = await useCase(
        homeId: widget.homeId,
        name: _nameController.text,
        icon: _selectedIcon,
      );

      if (mounted) {
        SawaSnackBar.success(
          context,
          context.translate('list_created_success'),
        );
        context.pop();
        context.push(ShoppingRoutePaths.detail(list.id));
      }
    } catch (e) {
      if (mounted) {
        SawaSnackBar.error(
          context,
          '${context.translate('create_list_failed')}: ${ErrorFormatter.format(e, context)}',
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.translate('create_shopping_list'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Selected icon preview
              Center(
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getIconData(_selectedIcon),
                    size: 48,
                    color: theme.primaryColor,
                  ),
                ),
              ),
              AppSpacing.gapXL,

              // Icon picker
              SawaCard(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.translate('choose_list_icon'),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    AppSpacing.gapMD,
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: _iconOptions.map((option) {
                        final isSelected = _selectedIcon == option['icon'];
                        return InkWell(
                          onTap: () => setState(
                            () => _selectedIcon = option['icon'] as String,
                          ),
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusMd,
                          ),
                          child: Ink(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? theme.primaryColor.withValues(alpha: 0.15)
                                  : theme.colorScheme.surfaceContainerHighest
                                        .withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusMd,
                              ),
                              border: isSelected
                                  ? Border.all(
                                      color: theme.primaryColor,
                                      width: 2,
                                    )
                                  : null,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  option['data'] as IconData,
                                  color: isSelected
                                      ? theme.primaryColor
                                      : theme.colorScheme.onSurfaceVariant,
                                  size: 24,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  context.translate(option['key'] as String),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isSelected
                                        ? theme.primaryColor
                                        : theme.colorScheme.onSurfaceVariant,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              AppSpacing.gapLG,

              // Name field
              SawaCard(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: SawaTextField(
                  controller: _nameController,
                  focusNode: _nameFocusNode,
                  labelText: context.translate('list_name'),
                  hintText: context.translate('list_name_hint'),
                  prefixIcon: Icons.list_alt_rounded,
                  autofocus: true,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => ActionDebouncer.execute(_createList),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return context.translate('list_name_required');
                    }
                    return null;
                  },
                ),
              ),
              AppSpacing.gapXXL,

              // Create button
              SawaButton(
                text: _isLoading
                    ? context.translate('creating')
                    : context.translate('create_list'),
                icon: Icons.add_task_rounded,
                isLoading: _isLoading,
                onPressed: () => ActionDebouncer.execute(_createList),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
