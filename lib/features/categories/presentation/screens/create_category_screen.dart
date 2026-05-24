import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/action_debouncer.dart';
import 'package:go_router/go_router.dart';

import '../providers/categories_provider.dart';

class CreateCategoryScreen extends ConsumerStatefulWidget {
  final String homeId;

  const CreateCategoryScreen({
    super.key,
    required this.homeId,
  });

  @override
  ConsumerState<CreateCategoryScreen> createState() =>
      _CreateCategoryScreenState();
}

class _CreateCategoryScreenState extends ConsumerState<CreateCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String _selectedType = 'shopping';
  String? _selectedIcon;
  String? _selectedColor;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _createCategory() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await ref.read(categoryNotifierProvider.notifier).createCategory(
            homeId: widget.homeId,
            name: _nameController.text.trim(),
            type: _selectedType,
            icon: _selectedIcon,
            color: _selectedColor,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'تم إنشاء التصنيف بنجاح',
              textDirection: TextDirection.rtl,
            ),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceAll('Exception: ', ''),
              textDirection: TextDirection.rtl,
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'إنشاء تصنيف جديد',
          textDirection: TextDirection.rtl,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                textDirection: TextDirection.rtl,
                decoration: const InputDecoration(
                  labelText: 'اسم التصنيف',
                  prefixIcon: Icon(Icons.category),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'يرجى إدخال اسم التصنيف';
                  }
                  if (value.length > 100) {
                    return 'اسم التصنيف طويل جداً';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'نوع التصنيف',
                  prefixIcon: Icon(Icons.type_specimen),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'shopping',
                    child: Text('تسوق'),
                  ),
                  DropdownMenuItem(
                    value: 'inventory',
                    child: Text('مخزون'),
                  ),
                  DropdownMenuItem(
                    value: 'expense',
                    child: Text('مصروفات'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedType = value);
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                textDirection: TextDirection.ltr,
                decoration: const InputDecoration(
                  labelText: 'الأيقونة (اختياري)',
                  hintText: 'مثال: 🛒',
                  prefixIcon: Icon(Icons.emoji_emotions),
                ),
                onChanged: (value) {
                  setState(() => _selectedIcon = value.isEmpty ? null : value);
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                textDirection: TextDirection.ltr,
                decoration: const InputDecoration(
                  labelText: 'اللون (اختياري)',
                  hintText: 'مثال: #FF5733',
                  prefixIcon: Icon(Icons.color_lens),
                ),
                onChanged: (value) {
                  setState(
                      () => _selectedColor = value.isEmpty ? null : value);
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : () => ActionDebouncer.execute(_createCategory),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'إنشاء التصنيف',
                        textDirection: TextDirection.rtl,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
