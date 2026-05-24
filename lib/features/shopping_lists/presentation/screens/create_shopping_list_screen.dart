import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:beity/app/theme/app_colors.dart';
import 'package:beity/app/theme/app_spacing.dart';
import 'package:beity/shared/widgets/design_system/beity_button.dart';
import 'package:beity/shared/widgets/design_system/beity_text_field.dart';
import 'package:beity/shared/widgets/design_system/beity_card.dart';
import '../../../../core/utils/action_debouncer.dart';
import 'package:go_router/go_router.dart';

import '../../domain/usecases/create_shopping_list_usecase.dart';
import '../providers/shopping_lists_provider.dart';

class CreateShoppingListScreen extends ConsumerStatefulWidget {
  final String homeId;

  const CreateShoppingListScreen({super.key, required this.homeId});

  @override
  ConsumerState<CreateShoppingListScreen> createState() => _CreateShoppingListScreenState();
}

class _CreateShoppingListScreenState extends ConsumerState<CreateShoppingListScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String _selectedIcon = 'shopping_cart';
  bool _isLoading = false;

  static const _iconOptions = [
    {'icon': 'shopping_cart', 'ar': 'مشتريات', 'en': 'Groceries', 'data': Icons.shopping_cart},
    {'icon': 'shopping_bag', 'ar': 'تسوق', 'en': 'Shopping', 'data': Icons.shopping_bag},
    {'icon': 'local_grocery_store', 'ar': 'بقالة', 'en': 'Store', 'data': Icons.local_grocery_store},
    {'icon': 'local_pharmacy', 'ar': 'صيدلية', 'en': 'Pharmacy', 'data': Icons.local_pharmacy},
    {'icon': 'local_hospital', 'ar': 'صحة', 'en': 'Health', 'data': Icons.local_hospital},
    {'icon': 'restaurant', 'ar': 'مطعم', 'en': 'Restaurant', 'data': Icons.restaurant},
    {'icon': 'local_cafe', 'ar': 'مقهى', 'en': 'Cafe', 'data': Icons.local_cafe},
    {'icon': 'home', 'ar': 'منزل', 'en': 'Home', 'data': Icons.home},
    {'icon': 'hardware', 'ar': 'أدوات', 'en': 'Tools', 'data': Icons.hardware},
    {'icon': 'build', 'ar': 'صيانة', 'en': 'Build', 'data': Icons.build},
    {'icon': 'child_care', 'ar': 'أطفال', 'en': 'Baby', 'data': Icons.child_care},
    {'icon': 'pets', 'ar': 'حيوانات', 'en': 'Pets', 'data': Icons.pets},
    {'icon': 'card_giftcard', 'ar': 'هدايا', 'en': 'Gifts', 'data': Icons.card_giftcard},
    {'icon': 'celebration', 'ar': 'احتفال', 'en': 'Celebration', 'data': Icons.celebration},
    {'icon': 'school', 'ar': 'مدرسة', 'en': 'School', 'data': Icons.school},
    {'icon': 'fitness_center', 'ar': 'رياضة', 'en': 'Fitness', 'data': Icons.fitness_center},
    {'icon': 'cleaning_services', 'ar': 'تنظيف', 'en': 'Cleaning', 'data': Icons.cleaning_services},
    {'icon': 'local_florist', 'ar': 'زهور', 'en': 'Flowers', 'data': Icons.local_florist},
  ];

  @override
  void dispose() {
    _nameController.dispose();
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

    setState(() => _isLoading = true);

    try {
      final repository = ref.read(shoppingListRepositoryProvider);
      final useCase = CreateShoppingListUseCase(repository);
      final list = await useCase(
        homeId: widget.homeId,
        name: _nameController.text,
        icon: _selectedIcon,
      );

      if (mounted) {
        context.pop();
        context.push('/shopping-list/${list.id}');
      }
    } catch (e) {
      if (mounted) {
        final isArabic = Localizations.localeOf(context).languageCode == 'ar';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${isArabic ? 'فشل إنشاء القائمة' : 'Failed to create list'}: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(isArabic ? 'إنشاء قائمة تسوق' : 'Create Shopping List', style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
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
              BeityCard(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isArabic ? 'اختر أيقونة القائمة' : 'Choose List Icon',
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
                        return GestureDetector(
                          onTap: () => setState(() => _selectedIcon = option['icon'] as String),
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? theme.primaryColor.withValues(alpha: 0.15)
                                  : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                              border: isSelected
                                  ? Border.all(color: theme.primaryColor, width: 2)
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
                                  (isArabic ? option['ar'] : option['en']) as String,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isSelected
                                        ? theme.primaryColor
                                        : theme.colorScheme.onSurfaceVariant,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
              BeityCard(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: BeityTextField(
                  controller: _nameController,
                  labelText: isArabic ? 'اسم القائمة' : 'List Name',
                  hintText: isArabic ? 'مثال: مشتريات الأسبوع' : 'e.g. Weekly Groceries',
                  prefixIcon: Icons.list_alt_rounded,
                  autofocus: true,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return isArabic ? 'اسم القائمة مطلوب' : 'List name is required';
                    }
                    return null;
                  },
                ),
              ),
              AppSpacing.gapXXL,

              // Create button
              BeityButton(
                text: _isLoading 
                    ? (isArabic ? 'جاري الإنشاء...' : 'Creating...') 
                    : (isArabic ? 'إنشاء القائمة' : 'Create List'),
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
