import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  final _descriptionController = TextEditingController();
  String _selectedIcon = 'shopping_cart';
  bool _isLoading = false;

  static const _iconOptions = [
    {'icon': 'shopping_cart', 'label': 'مشتريات', 'data': Icons.shopping_cart},
    {'icon': 'shopping_bag', 'label': 'تسوق', 'data': Icons.shopping_bag},
    {'icon': 'local_grocery_store', 'label': 'بقالة', 'data': Icons.local_grocery_store},
    {'icon': 'local_pharmacy', 'label': 'صيدلية', 'data': Icons.local_pharmacy},
    {'icon': 'local_hospital', 'label': 'صحة', 'data': Icons.local_hospital},
    {'icon': 'restaurant', 'label': 'مطعم', 'data': Icons.restaurant},
    {'icon': 'local_cafe', 'label': 'مقهى', 'data': Icons.local_cafe},
    {'icon': 'home', 'label': 'منزل', 'data': Icons.home},
    {'icon': 'hardware', 'label': 'أدوات', 'data': Icons.hardware},
    {'icon': 'build', 'label': 'صيانة', 'data': Icons.build},
    {'icon': 'child_care', 'label': 'أطفال', 'data': Icons.child_care},
    {'icon': 'pets', 'label': 'حيوانات', 'data': Icons.pets},
    {'icon': 'card_giftcard', 'label': 'هدايا', 'data': Icons.card_giftcard},
    {'icon': 'celebration', 'label': 'احتفال', 'data': Icons.celebration},
    {'icon': 'school', 'label': 'مدرسة', 'data': Icons.school},
    {'icon': 'fitness_center', 'label': 'رياضة', 'data': Icons.fitness_center},
    {'icon': 'cleaning_services', 'label': 'تنظيف', 'data': Icons.cleaning_services},
    {'icon': 'local_florist', 'label': 'زهور', 'data': Icons.local_florist},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل إنشاء القائمة: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إنشاء قائمة تسوق'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Selected icon preview
              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getIconData(_selectedIcon),
                    size: 48,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Icon picker
              Text(
                'اختر أيقونة القائمة',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(12),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _iconOptions.map((option) {
                    final isSelected = _selectedIcon == option['icon'];
                    return GestureDetector(
                      onTap: () => setState(() => _selectedIcon = option['icon'] as String),
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Theme.of(context).primaryColor.withValues(alpha: 0.15)
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: isSelected
                              ? Border.all(color: Theme.of(context).primaryColor, width: 2)
                              : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              option['data'] as IconData,
                              color: isSelected
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey[600],
                              size: 22,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              option['label'] as String,
                              style: TextStyle(
                                fontSize: 8,
                                color: isSelected
                                    ? Theme.of(context).primaryColor
                                    : Colors.grey[600],
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),

              // Name field
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'اسم القائمة',
                  hintText: 'مثال: مشتريات الأسبوع',
                  prefixIcon: const Icon(Icons.list_alt),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                autofocus: true,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'اسم القائمة مطلوب';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description field
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'الوصف (اختياري)',
                  hintText: 'مثال: خضروات وفواكه ولحوم',
                  prefixIcon: const Icon(Icons.description_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.done,
                maxLines: 2,
                onFieldSubmitted: (_) => _createList(),
              ),
              const SizedBox(height: 32),

              // Create button
              ElevatedButton(
                onPressed: _isLoading ? null : _createList,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'إنشاء القائمة',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
