import 'package:beity/core/errors/error_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:beity/core/utils/auth_error_messages.dart';
import 'package:beity/core/utils/action_debouncer.dart';
import 'package:beity/app/theme/app_spacing.dart';
import 'package:beity/app/theme/app_colors.dart';
import 'package:beity/shared/widgets/design_system/beity_button.dart';
import 'package:beity/shared/widgets/design_system/beity_text_field.dart';
import 'package:beity/shared/widgets/design_system/beity_card.dart';
import '../providers/auth_provider.dart';
import '../../data/models/user_model.dart';
import '../../../../core/localization/app_localizations.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final user = ref.read(cachedCurrentUserProvider);
    if (user != null) {
      _nameController.text = user.fullName;
      _phoneController.text = user.phone ?? '';
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await ref.read(authNotifierProvider.notifier).updateProfile(
            fullName: _nameController.text.trim(),
            phone: _phoneController.text.trim().isEmpty
                ? null
                : _phoneController.text.trim(),
          );

      setState(() => _isEditing = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.translate('profile_updated_success'),
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.translate('profile_update_failed', arguments: {'error': ErrorFormatter.format(e, context)}),
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
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(cachedCurrentUserProvider);
    final theme = Theme.of(context);

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(context.translate('profile')),
          centerTitle: true,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_off_rounded, size: 64, color: theme.colorScheme.outline),
              AppSpacing.gapMD,
              Text(context.translate('no_user_data')),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(context.translate('profile')),
        centerTitle: true,
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit_rounded),
              onPressed: () => setState(() => _isEditing = true),
              tooltip: context.translate('edit_profile'),
            ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: _isEditing ? _buildEditForm() : _buildProfileView(user),
      ),
    );
  }

  Widget _buildProfileView(UserModel user) {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        AppSpacing.gapLG,
        Container(
          padding: const EdgeInsets.all(AppSpacing.xs),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2), width: 2),
          ),
          child: CircleAvatar(
            radius: 56,
            backgroundColor: theme.colorScheme.primary,
            child: Text(
              user.fullName.characters.isNotEmpty
                  ? user.fullName.characters.take(1).toString()
                  : '?',
              style: theme.textTheme.headlineLarge?.copyWith(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 48,
              ),
            ),
          ),
        ),
        AppSpacing.gapXL,
        Text(
          user.fullName,
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        AppSpacing.gapXS,
        Text(
          user.email,
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
        AppSpacing.gapXL,
        BeityCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              _buildInfoRow(Icons.person_outline_rounded, context.translate('name'), user.fullName),
              Divider(height: AppSpacing.xl, color: theme.colorScheme.outlineVariant),
              _buildInfoRow(Icons.email_outlined, context.translate('email'), user.email),
              Divider(height: AppSpacing.xl, color: theme.colorScheme.outlineVariant),
              _buildInfoRow(Icons.phone_outlined, context.translate('phone'), user.phone ?? context.translate('not_specified')),
            ],
          ),
        ),
        AppSpacing.gapXL,
        BeityButton(
          onPressed: () => ActionDebouncer.execute(() => ref.read(authNotifierProvider.notifier).signOut()),
          text: context.translate('sign_out'),
          type: BeityButtonType.secondary,
          icon: Icons.logout_rounded,
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        AppSpacing.gapMD,
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEditForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSpacing.gapLG,
          BeityCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                BeityTextField(
                  controller: _nameController,
                  textDirection: TextDirection.rtl,
                  labelText: context.translate('full_name'),
                  prefixIcon: Icons.person_rounded,
                  validator: (value) {
                    final error = AuthErrorMessages.validateName(context, value);
                    return error.isEmpty ? null : error;
                  },
                ),
                AppSpacing.gapLG,
                BeityTextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  textDirection: TextDirection.ltr,
                  labelText: context.translate('phone_optional'),
                  prefixIcon: Icons.phone_rounded,
                  hintText: '+90 xxx xxx xxxx',
                ),
              ],
            ),
          ),
          AppSpacing.gapXL,
          Row(
            children: [
                Expanded(
                child: BeityButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          setState(() => _isEditing = false);
                          _loadUserData();
                        },
                  text: context.translate('cancel'),
                  type: BeityButtonType.secondary,
                ),
              ),
              AppSpacing.gapMD,
              Expanded(
                child: BeityButton(
                  onPressed: () => ActionDebouncer.execute(_updateProfile),
                  text: context.translate('save'),
                  isLoading: _isLoading,
                  type: BeityButtonType.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
