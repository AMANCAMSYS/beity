import 'package:sawa/core/errors/error_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:sawa/core/utils/auth_error_messages.dart';
import 'package:sawa/core/utils/action_guard.dart';
import 'package:sawa/app/theme/app_spacing.dart';
import 'package:sawa/app/theme/app_colors.dart';
import 'package:sawa/core/widgets/sawa_cached_image.dart';
import 'package:sawa/shared/widgets/design_system/sawa_button.dart';
import 'package:sawa/shared/widgets/design_system/sawa_text_field.dart';
import 'package:sawa/shared/widgets/design_system/sawa_card.dart';
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
  final _nameFocusNode = FocusNode();
  final _phoneFocusNode = FocusNode();
  bool _isEditing = false;
  bool _isLoading = false;
  bool _isAvatarLoading = false;
  final _guard = ActionGuard();
  final _imagePicker = ImagePicker();

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
    FocusManager.instance.primaryFocus?.unfocus();

    setState(() => _isLoading = true);

    try {
      await ref
          .read(authNotifierProvider.notifier)
          .updateProfile(
            fullName: _nameController.text.trim(),
            phone: _phoneController.text.trim().isEmpty
                ? null
                : _phoneController.text.trim(),
          );

      setState(() => _isEditing = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.translate('profile_updated_success')),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.translate(
                'profile_update_failed',
                arguments: {'error': ErrorFormatter.format(e, context)},
              ),
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

  Future<void> _pickAndUploadAvatar() async {
    setState(() => _isAvatarLoading = true);

    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 78,
      );
      if (image == null) return;

      final bytes = await image.readAsBytes();
      final extension = image.name.split('.').last;
      final contentType = switch (extension.toLowerCase()) {
        'png' => 'image/png',
        'webp' => 'image/webp',
        _ => 'image/jpeg',
      };

      await ref
          .read(authNotifierProvider.notifier)
          .updateAvatar(
            bytes: bytes,
            extension: extension,
            contentType: contentType,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.translate('profile_updated_success')),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.translate(
                'profile_update_failed',
                arguments: {'error': ErrorFormatter.format(e, context)},
              ),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAvatarLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _guard.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _nameFocusNode.dispose();
    _phoneFocusNode.dispose();
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
              Icon(
                Icons.person_off_rounded,
                size: 64,
                color: theme.colorScheme.outline,
              ),
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
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: _isEditing ? _buildEditForm(user) : _buildProfileView(user),
      ),
    );
  }

  Widget _buildAvatar(UserModel user, {bool editable = false}) {
    final theme = Theme.of(context);
    final hasAvatar = user.avatarUrl != null && user.avatarUrl!.isNotEmpty;

    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.xs),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.2),
              width: 2,
            ),
          ),
          child: hasAvatar
              ? SawaCachedImage(
                  imageUrl: user.avatarUrl!,
                  width: 112,
                  height: 112,
                  isAvatar: true,
                )
              : CircleAvatar(
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
        if (editable)
          IconButton.filled(
            onPressed: _isAvatarLoading
                ? null
                : () => _guard.run(_pickAndUploadAvatar),
            icon: _isAvatarLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.camera_alt_rounded),
            tooltip: context.translate('change_profile_photo'),
          ),
      ],
    );
  }

  Widget _buildProfileView(UserModel user) {
    final theme = Theme.of(context);

    return Column(
      children: [
        AppSpacing.gapLG,
        _buildAvatar(user),
        AppSpacing.gapXL,
        Text(
          user.fullName,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        AppSpacing.gapXS,
        Text(
          user.email,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        AppSpacing.gapXL,
        SawaCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              _buildInfoRow(
                Icons.person_outline_rounded,
                context.translate('name'),
                user.fullName,
              ),
              Divider(
                height: AppSpacing.xl,
                color: theme.colorScheme.outlineVariant,
              ),
              _buildInfoRow(
                Icons.email_outlined,
                context.translate('email'),
                user.email,
              ),
              Divider(
                height: AppSpacing.xl,
                color: theme.colorScheme.outlineVariant,
              ),
              _buildInfoRow(
                Icons.phone_outlined,
                context.translate('phone'),
                user.phone ?? context.translate('not_specified'),
              ),
            ],
          ),
        ),
        AppSpacing.gapXL,
        SawaButton(
          onPressed: () => _guard.run(
            () async => ref.read(authNotifierProvider.notifier).signOut(),
          ),
          text: context.translate('sign_out'),
          type: SawaButtonType.secondary,
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

  Widget _buildEditForm(UserModel user) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSpacing.gapLG,
          Center(child: _buildAvatar(user, editable: true)),
          AppSpacing.gapXL,
          SawaCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                SawaTextField(
                  controller: _nameController,
                  focusNode: _nameFocusNode,
                  textDirection: TextDirection.rtl,
                  textInputAction: TextInputAction.next,
                  labelText: context.translate('full_name'),
                  prefixIcon: Icons.person_rounded,
                  validator: (value) {
                    final error = AuthErrorMessages.validateName(
                      context,
                      value,
                    );
                    return error.isEmpty ? null : error;
                  },
                  onSubmitted: (_) => _phoneFocusNode.requestFocus(),
                ),
                AppSpacing.gapLG,
                SawaTextField(
                  controller: _phoneController,
                  focusNode: _phoneFocusNode,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  textDirection: TextDirection.ltr,
                  labelText: context.translate('phone_optional'),
                  prefixIcon: Icons.phone_rounded,
                  hintText: '+90 xxx xxx xxxx',
                  onSubmitted: (_) => _guard.run(_updateProfile),
                ),
              ],
            ),
          ),
          AppSpacing.gapXL,
          Row(
            children: [
              Expanded(
                child: SawaButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          setState(() => _isEditing = false);
                          _loadUserData();
                        },
                  text: context.translate('cancel'),
                  type: SawaButtonType.secondary,
                ),
              ),
              AppSpacing.gapMD,
              Expanded(
                child: SawaButton(
                  onPressed: () => _guard.run(_updateProfile),
                  text: context.translate('save'),
                  isLoading: _isLoading,
                  type: SawaButtonType.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
