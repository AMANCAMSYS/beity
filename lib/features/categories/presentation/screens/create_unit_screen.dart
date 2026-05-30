import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/utils/action_debouncer.dart';
import 'package:go_router/go_router.dart';

import 'package:beity/shared/widgets/design_system/beity_snack_bar.dart';
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
        BeitySnackBar.success(context, context.translate('unit_created_success'));
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
        title: Text(context.translate('create_new_unit')),
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
                  labelText: context.translate('unit_name'),
                  prefixIcon: const Icon(Icons.straighten),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return context.translate('please_enter_unit_name');
                  }
                  if (value.length > 50) {
                    return context.translate('unit_name_too_long');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _symbolController,
                textDirection: TextDirection.ltr,
                decoration: InputDecoration(
                  labelText: context.translate('unit_symbol'),
                  hintText: 'e.g. kg',
                  prefixIcon: const Icon(Icons.text_fields),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return context.translate('please_enter_unit_symbol');
                  }
                  if (value.length > 10) {
                    return context.translate('unit_symbol_too_long');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedType,
                decoration: InputDecoration(
                  labelText: context.translate('unit_type'),
                  prefixIcon: const Icon(Icons.category),
                ),
                items: [
                  DropdownMenuItem(
                    value: 'weight',
                    child: Text(context.translate('weight')),
                  ),
                  DropdownMenuItem(
                    value: 'volume',
                    child: Text(context.translate('volume')),
                  ),
                  DropdownMenuItem(
                    value: 'count',
                    child: Text(context.translate('count')),
                  ),
                  DropdownMenuItem(
                    value: 'length',
                    child: Text(context.translate('length')),
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
                    : Text(
                        context.translate('create_unit'),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
