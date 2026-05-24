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
    final currentUser = ref.read(currentUserProvider);
    currentUser.whenData((user) {
      if (user != null) {
        _nameController.text = user.fullName;
        _phoneController.text = user.phone ?? '';
      }
    });
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
          const SnackBar(
            content: Text(
              'تم تحديث الملف الشخصي بنجاح',
              textDirection: TextDirection.rtl,
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'فشل تحديث الملف الشخصي: ${e.toString()}',
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
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('الملف الشخصي'),
        centerTitle: true,
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit_rounded),
              onPressed: () => setState(() => _isEditing = true),
              tooltip: 'تعديل الملف الشخصي',
            ),
        ],
      ),
      body: currentUser.when(
        data: (user) {
          if (user == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_off_rounded, size: 64, color: theme.colorScheme.outline),
                  AppSpacing.gapMD,
                  const Text('لا يوجد بيانات مستخدم', textDirection: TextDirection.rtl),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: _isEditing
                ? _buildEditForm()
                : _buildProfileView(user),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded, size: 64, color: theme.colorScheme.error),
              AppSpacing.gapMD,
              Text('خطأ: ${error.toString()}', textDirection: TextDirection.rtl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileView(dynamic user) {
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
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Icon(
              Icons.person_rounded,
              size: 64,
              color: theme.colorScheme.onPrimaryContainer,
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
              _buildInfoRow(Icons.person_outline_rounded, 'الاسم', user.fullName),
              Divider(height: AppSpacing.xl, color: theme.colorScheme.outlineVariant),
              _buildInfoRow(Icons.email_outlined, 'البريد الإلكتروني', user.email),
              Divider(height: AppSpacing.xl, color: theme.colorScheme.outlineVariant),
              _buildInfoRow(Icons.phone_outlined, 'رقم الهاتف', user.phone ?? 'غير محدد'),
            ],
          ),
        ),
        AppSpacing.gapXL,
        BeityButton(
          onPressed: () => ActionDebouncer.execute(() => ref.read(authNotifierProvider.notifier).signOut()),
          text: 'تسجيل الخروج',
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
                  labelText: 'الاسم الكامل',
                  prefixIcon: Icons.person_rounded,
                  validator: (value) {
                    final error = AuthErrorMessages.validateName(value);
                    return error.isEmpty ? null : error;
                  },
                ),
                AppSpacing.gapLG,
                BeityTextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  textDirection: TextDirection.ltr,
                  labelText: 'رقم الهاتف (اختياري)',
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
                  text: 'إلغاء',
                  type: BeityButtonType.secondary,
                ),
              ),
              AppSpacing.gapMD,
              Expanded(
                child: BeityButton(
                  onPressed: () => ActionDebouncer.execute(_updateProfile),
                  text: 'حفظ',
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
