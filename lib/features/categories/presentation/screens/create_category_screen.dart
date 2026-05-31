import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/action_debouncer.dart';
import 'package:go_router/go_router.dart';

import 'package:beity/shared/widgets/design_system/beity_snack_bar.dart';
import '../providers/categories_provider.dart';
import 'package:beity/core/localization/app_localizations.dart';
import '../../../settings/presentation/providers/app_settings_provider.dart';

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

      final hapticEnabled = ref.read(appSettingsProvider).hapticFeedback;
      if (hapticEnabled) {
        HapticFeedback.mediumImpact();
      }

      if (mounted) {
        BeitySnackBar.success(context, context.translate('category_created_success'));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        BeitySnackBar.error(
          context,
          e.toString().replaceAll('Exception: ', ''),
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
        title: Text(context.translate('create_new_category')),
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
                decoration: InputDecoration(
                  labelText: context.translate('category_name'),
                  prefixIcon: const Icon(Icons.category),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return context.translate('please_enter_category_name');
                  }
                  if (value.length > 100) {
                    return context.translate('category_name_too_long');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedType,
                decoration: InputDecoration(
                  labelText: context.translate('category_type'),
                  prefixIcon: const Icon(Icons.type_specimen),
                ),
                items: [
                  DropdownMenuItem(
                    value: 'shopping',
                    child: Text(context.translate('shopping')),
                  ),
                  DropdownMenuItem(
                    value: 'inventory',
                    child: Text(context.translate('inventory_filter')),
                  ),
                  DropdownMenuItem(
                    value: 'expense',
                    child: Text(context.translate('expense')),
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
                decoration: InputDecoration(
                  labelText: context.translate('icon_optional'),
                  hintText: '🛒',
                  prefixIcon: const Icon(Icons.emoji_emotions),
                ),
                onChanged: (value) {
                  setState(() => _selectedIcon = value.isEmpty ? null : value);
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(
                  labelText: context.translate('color_optional'),
                  hintText: '#FF5733',
                  prefixIcon: const Icon(Icons.color_lens),
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
                    : Text(
                        context.translate('create_category'),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
