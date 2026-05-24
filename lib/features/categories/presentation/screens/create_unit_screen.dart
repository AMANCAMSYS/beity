import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/action_debouncer.dart';
import 'package:go_router/go_router.dart';

import '../providers/units_provider.dart';

class CreateUnitScreen extends ConsumerStatefulWidget {
  const CreateUnitScreen({super.key});

  @override
  ConsumerState<CreateUnitScreen> createState() => _CreateUnitScreenState();
}

class _CreateUnitScreenState extends ConsumerState<CreateUnitScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _symbolController = TextEditingController();
  String _selectedType = 'count';
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _symbolController.dispose();
    super.dispose();
  }

  Future<void> _createUnit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await ref.read(unitNotifierProvider.notifier).createUnit(
            name: _nameController.text.trim(),
            symbol: _symbolController.text.trim(),
            type: _selectedType,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'تم إنشاء الوحدة بنجاح',
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
          'إنشاء وحدة جديدة',
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
                  labelText: 'اسم الوحدة',
                  prefixIcon: Icon(Icons.straighten),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'يرجى إدخال اسم الوحدة';
                  }
                  if (value.length > 50) {
                    return 'اسم الوحدة طويل جداً';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _symbolController,
                textDirection: TextDirection.ltr,
                decoration: const InputDecoration(
                  labelText: 'رمز الوحدة',
                  hintText: 'مثال: kg',
                  prefixIcon: Icon(Icons.text_fields),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'يرجى إدخال رمز الوحدة';
                  }
                  if (value.length > 10) {
                    return 'رمز الوحدة طويل جداً';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'نوع الوحدة',
                  prefixIcon: Icon(Icons.category),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'weight',
                    child: Text('وزن'),
                  ),
                  DropdownMenuItem(
                    value: 'volume',
                    child: Text('حجم'),
                  ),
                  DropdownMenuItem(
                    value: 'count',
                    child: Text('عدد'),
                  ),
                  DropdownMenuItem(
                    value: 'length',
                    child: Text('طول'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedType = value);
                  }
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : () => ActionDebouncer.execute(_createUnit),
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
                        'إنشاء الوحدة',
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
