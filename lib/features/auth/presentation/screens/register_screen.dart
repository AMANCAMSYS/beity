import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:beity/core/utils/auth_error_messages.dart';
import 'package:beity/core/utils/action_debouncer.dart';
import 'package:beity/app/theme/app_spacing.dart';
import 'package:beity/app/theme/app_colors.dart';
import 'package:beity/shared/widgets/design_system/beity_button.dart';
import 'package:beity/shared/widgets/design_system/beity_text_field.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await ref.read(authNotifierProvider.notifier).signUp(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            fullName: _nameController.text.trim(),
          );

      if (mounted) {
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        String message = 'حدث خطأ، يرجى المحاولة مرة أخرى';
        final errorStr = e.toString().toLowerCase();
        if (errorStr.contains('already') ||
            errorStr.contains('registered') ||
            errorStr.contains('exists')) {
          message = AuthErrorMessages.mapError('user_already_registered');
        } else if (errorStr.contains('weak') ||
            errorStr.contains('password') ||
            errorStr.contains('short')) {
          message = AuthErrorMessages.mapError('weak_password');
        } else if (errorStr.contains('invalid') ||
            errorStr.contains('email') ||
            errorStr.contains('valid')) {
          message = AuthErrorMessages.mapError('invalid_email');
        } else if (errorStr.contains('confirm')) {
          message = 'تم إرسال بريد تأكيد، يرجى לבדוק بريدك الإلكتروني';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message, textDirection: TextDirection.rtl),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.home_rounded,
                    size: 80,
                    color: theme.primaryColor,
                  ),
                  AppSpacing.gapMD,
                  Text(
                    'بيتي',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  AppSpacing.gapSM,
                  Text(
                    'إنشاء حساب جديد',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                  ),
                  AppSpacing.gapXXL,

                  // Name Field
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
                  AppSpacing.gapMD,

                  // Email Field
                  BeityTextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textDirection: TextDirection.ltr,
                    labelText: 'البريد الإلكتروني',
                    hintText: 'example@email.com',
                    prefixIcon: Icons.email_rounded,
                    validator: (value) {
                      final error = AuthErrorMessages.validateEmail(value);
                      return error.isEmpty ? null : error;
                    },
                  ),
                  AppSpacing.gapMD,

                  // Password Field
                  BeityTextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textDirection: TextDirection.ltr,
                    labelText: 'كلمة المرور',
                    prefixIcon: Icons.lock_rounded,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                        color: isDark ? AppColors.textHintDark : AppColors.textHintLight,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    validator: (value) {
                      final error = AuthErrorMessages.validatePassword(value);
                      return error.isEmpty ? null : error;
                    },
                  ),
                  AppSpacing.gapMD,

                  // Confirm Password Field
                  BeityTextField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    textDirection: TextDirection.ltr,
                    labelText: 'تأكيد كلمة المرور',
                    prefixIcon: Icons.lock_outline_rounded,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                        color: isDark ? AppColors.textHintDark : AppColors.textHintLight,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'يرجى تأكيد كلمة المرور';
                      }
                      if (value != _passwordController.text) {
                        return 'كلمات المرور غير متطابقة';
                      }
                      return null;
                    },
                  ),
                  AppSpacing.gapLG,

                  // Register Button
                  BeityButton(
                    text: 'إنشاء حساب',
                    isLoading: _isLoading,
                    onPressed: () => ActionDebouncer.execute(_register),
                  ),
                  AppSpacing.gapMD,

                  // Login Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'لديك حساب بالفعل؟',
                        textDirection: TextDirection.rtl,
                        style: theme.textTheme.bodyMedium,
                      ),
                      TextButton(
                        onPressed: () => context.go('/login'),
                        child: Text(
                          'تسجيل الدخول',
                          textDirection: TextDirection.rtl,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
