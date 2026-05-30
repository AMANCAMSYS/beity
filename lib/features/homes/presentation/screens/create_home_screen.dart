import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:beity/app/theme/app_spacing.dart';
import 'package:beity/core/localization/app_localizations.dart';
import 'package:beity/shared/widgets/design_system/beity_card.dart';
import 'package:beity/shared/widgets/design_system/beity_button.dart';
import 'package:beity/shared/widgets/design_system/beity_snack_bar.dart';
import 'package:beity/shared/widgets/design_system/beity_text_field.dart';
import 'package:beity/core/utils/action_debouncer.dart';
import '../../domain/entities/home_type.dart';
import '../providers/homes_provider.dart';

class CreateHomeScreen extends ConsumerStatefulWidget {
  const CreateHomeScreen({super.key});

  @override
  ConsumerState<CreateHomeScreen> createState() => _CreateHomeScreenState();
}

class _CreateHomeScreenState extends ConsumerState<CreateHomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  HomeType _selectedType = HomeType.family;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _createHome() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await ref.read(homesNotifierProvider.notifier).createHome(
            name: _nameController.text.trim(),
            type: _selectedType.value,
          );

      if (mounted) {
        BeitySnackBar.success(context, context.translate('home_created_success'));
        ref.invalidate(hasHomesProvider);
        ref.invalidate(userHomesProvider);
        ref.invalidate(activeHomeIdProvider);
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        BeitySnackBar.error(
          context,
          context.translate('create_home_failed', arguments: {'error': e.toString()}),
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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.translate('create_new_home')),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppSpacing.gapLG,
              Center(
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.home_work_rounded,
                    size: 80,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              AppSpacing.gapXL,
              Text(
                context.translate('start_new_chapter'),
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              AppSpacing.gapSM,
              Text(
                context.translate('create_home_desc'),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              AppSpacing.gapXXL,
              BeityCard(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BeityTextField(
                      controller: _nameController,
                      textDirection: Directionality.of(context),
                      labelText: context.translate('home_name'),
                      prefixIcon: Icons.home_rounded,
                      hintText: context.translate('home_name_hint'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return context.translate('home_name_required');
                        }
                        if (value.length > 100) {
                          return context.translate('home_name_too_long');
                        }
                        return null;
                      },
                    ),
                    AppSpacing.gapXL,
                    Text(
                      context.translate('home_type'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    AppSpacing.gapMD,
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: HomeType.allValues.map((type) {
                        final isSelected = _selectedType == type;
                        return ChoiceChip(
                          label: Text(context.translate(type.value)),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _selectedType = type);
                            }
                          },
                          showCheckmark: false,
                          backgroundColor: theme.colorScheme.surfaceContainerHighest,
                          selectedColor: theme.colorScheme.primary.withValues(alpha: 0.2),
                          labelStyle: TextStyle(
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurfaceVariant,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                            side: BorderSide(
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : Colors.transparent,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              AppSpacing.gapXXL,
              BeityButton(
                onPressed: () => ActionDebouncer.execute(_createHome),
                text: context.translate('create_home_button'),
                isLoading: _isLoading,
                type: BeityButtonType.primary,
                icon: Icons.add_home_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
