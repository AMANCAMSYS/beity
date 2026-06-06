import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:sawa/app/theme/app_spacing.dart';
import 'package:sawa/core/localization/app_localizations.dart';
import 'package:sawa/shared/widgets/design_system/sawa_card.dart';
import 'package:sawa/shared/widgets/design_system/sawa_button.dart';
import 'package:sawa/shared/widgets/design_system/sawa_snack_bar.dart';
import 'package:sawa/shared/widgets/design_system/sawa_text_field.dart';
import 'package:sawa/core/utils/action_debouncer.dart';
import 'package:sawa/core/errors/error_formatter.dart';
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
  final _nameFocusNode = FocusNode();
  HomeType _selectedType = HomeType.family;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  Future<void> _createHome() async {
    if (!_formKey.currentState!.validate()) return;
    FocusManager.instance.primaryFocus?.unfocus();

    setState(() => _isLoading = true);

    try {
      await ref
          .read(homesNotifierProvider.notifier)
          .createHome(
            name: _nameController.text.trim(),
            type: _selectedType.value,
          );

      if (mounted) {
        SawaSnackBar.success(
          context,
          context.translate('home_created_success'),
        );
        ref.invalidate(hasHomesProvider);
        ref.invalidate(userHomesProvider);
        ref.invalidate(activeHomeIdProvider);
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        SawaSnackBar.error(
          context,
          context.translate(
            'create_home_failed',
            arguments: {'error': ErrorFormatter.format(e, context)},
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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.translate('create_new_home')),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
              SawaCard(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SawaTextField(
                      controller: _nameController,
                      focusNode: _nameFocusNode,
                      textDirection: Directionality.of(context),
                      textInputAction: TextInputAction.done,
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
                      onSubmitted: (_) => ActionDebouncer.execute(_createHome),
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
                          backgroundColor:
                              theme.colorScheme.surfaceContainerHighest,
                          selectedColor: theme.colorScheme.primary.withValues(
                            alpha: 0.2,
                          ),
                          labelStyle: TextStyle(
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurfaceVariant,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusMd,
                            ),
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
              SawaButton(
                onPressed: () => ActionDebouncer.execute(_createHome),
                text: context.translate('create_home_button'),
                isLoading: _isLoading,
                type: SawaButtonType.primary,
                icon: Icons.add_home_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
