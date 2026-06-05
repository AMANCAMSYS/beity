import 'package:sawa/core/errors/error_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:sawa/core/utils/auth_error_messages.dart';
import 'package:sawa/core/utils/action_guard.dart';
import 'package:sawa/app/theme/app_spacing.dart';
import 'package:sawa/app/theme/app_colors.dart';
import 'package:sawa/shared/widgets/design_system/sawa_button.dart';
import 'package:sawa/shared/widgets/design_system/sawa_text_field.dart';
import '../../data/repositories/auth_repository.dart';
import '../providers/auth_provider.dart';
import '../../../../core/localization/app_localizations.dart';

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
  final _nameFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  final _guard = ActionGuard();

  @override
  void dispose() {
    _guard.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    FocusManager.instance.primaryFocus?.unfocus();

    setState(() => _isLoading = true);

    try {
      await ref
          .read(authNotifierProvider.notifier)
          .signUp(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            fullName: _nameController.text.trim(),
            language: Localizations.localeOf(context).languageCode,
          );

      if (mounted) {
        final redirect = GoRouterState.of(
          context,
        ).uri.queryParameters['redirect'];
        if (redirect != null && redirect.isNotEmpty) {
          context.go(redirect);
        } else {
          context.go('/');
        }
      }
    } on EmailConfirmationRequiredException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.translate('verification_email_sent')),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorFormatter.format(e, context)),
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
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.home_rounded, size: 80, color: theme.primaryColor),
                  AppSpacing.gapMD,
                  Text(
                    context.translate('sawa'),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  AppSpacing.gapSM,
                  Text(
                    context.translate('create_new_account'),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                  AppSpacing.gapXXL,

                  // Name Field
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
                    onSubmitted: (_) => _emailFocusNode.requestFocus(),
                  ),
                  AppSpacing.gapMD,

                  // Email Field
                  SawaTextField(
                    controller: _emailController,
                    focusNode: _emailFocusNode,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    textDirection: TextDirection.ltr,
                    labelText: context.translate('email'),
                    hintText: 'example@email.com',
                    prefixIcon: Icons.email_rounded,
                    validator: (value) {
                      final error = AuthErrorMessages.validateEmail(
                        context,
                        value,
                      );
                      return error.isEmpty ? null : error;
                    },
                    onSubmitted: (_) => _passwordFocusNode.requestFocus(),
                  ),
                  AppSpacing.gapMD,

                  // Password Field
                  SawaTextField(
                    controller: _passwordController,
                    focusNode: _passwordFocusNode,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.next,
                    textDirection: TextDirection.ltr,
                    labelText: context.translate('password'),
                    prefixIcon: Icons.lock_rounded,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                        color: isDark
                            ? AppColors.textHintDark
                            : AppColors.textHintLight,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    validator: (value) {
                      final error = AuthErrorMessages.validatePassword(
                        context,
                        value,
                      );
                      return error.isEmpty ? null : error;
                    },
                    onSubmitted: (_) =>
                        _confirmPasswordFocusNode.requestFocus(),
                  ),
                  AppSpacing.gapMD,

                  // Confirm Password Field
                  SawaTextField(
                    controller: _confirmPasswordController,
                    focusNode: _confirmPasswordFocusNode,
                    obscureText: _obscureConfirmPassword,
                    textInputAction: TextInputAction.done,
                    textDirection: TextDirection.ltr,
                    labelText: context.translate('confirm_password'),
                    prefixIcon: Icons.lock_outline_rounded,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                        color: isDark
                            ? AppColors.textHintDark
                            : AppColors.textHintLight,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return context.translate('confirm_password_required');
                      }
                      if (value != _passwordController.text) {
                        return context.translate('passwords_do_not_match');
                      }
                      return null;
                    },
                    onSubmitted: (_) => _guard.run(_register),
                  ),
                  AppSpacing.gapLG,

                  // Register Button
                  SawaButton(
                    text: context.translate('create_account'),
                    isLoading: _isLoading,
                    onPressed: () => _guard.run(_register),
                  ),
                  AppSpacing.gapMD,

                  // Login Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        context.translate('already_have_account'),
                        style: theme.textTheme.bodyMedium,
                      ),
                      TextButton(
                        onPressed: () => context.go('/login'),
                        child: Text(
                          context.translate('login'),
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
