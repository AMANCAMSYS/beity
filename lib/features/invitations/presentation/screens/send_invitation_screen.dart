import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sawa/app/theme/app_spacing.dart';
import 'package:sawa/app/theme/app_colors.dart';
import 'package:sawa/shared/widgets/design_system/sawa_card.dart';
import 'package:sawa/shared/widgets/design_system/sawa_button.dart';
import 'package:sawa/shared/widgets/design_system/sawa_text_field.dart';
import '../providers/invitations_provider.dart';
import 'package:sawa/core/utils/action_debouncer.dart';
import '../../../../core/localization/app_localizations.dart';

class SendInvitationScreen extends ConsumerStatefulWidget {
  final String homeId;
  final String homeName;

  const SendInvitationScreen({
    super.key,
    required this.homeId,
    required this.homeName,
  });

  @override
  ConsumerState<SendInvitationScreen> createState() =>
      _SendInvitationScreenState();
}

class _SendInvitationScreenState extends ConsumerState<SendInvitationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _emailFocusNode = FocusNode();
  String _selectedRole = 'member';
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _emailFocusNode.dispose();
    super.dispose();
  }

  Future<void> _sendInvitation() async {
    if (!_formKey.currentState!.validate()) return;
    FocusManager.instance.primaryFocus?.unfocus();

    setState(() => _isLoading = true);

    try {
      await ref
          .read(invitationNotifierProvider.notifier)
          .sendInvitation(
            homeId: widget.homeId,
            email: _emailController.text.trim(),
            role: _selectedRole,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.translate('invitation_sent_success')),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
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

    return Scaffold(
      appBar: AppBar(
        title: Text(context.translate('invite_new_member')),
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
                    color: theme.colorScheme.tertiary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.mail_rounded,
                    size: 64,
                    color: theme.colorScheme.tertiary,
                  ),
                ),
              ),
              AppSpacing.gapXL,
              Text(
                context.translate(
                  'add_member_to_home',
                  arguments: {'homeName': widget.homeName},
                ),
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              AppSpacing.gapSM,
              Text(
                context.translate('invitation_email_instruction'),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
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
                      controller: _emailController,
                      focusNode: _emailFocusNode,
                      labelText: context.translate('email'),
                      hintText: 'example@email.com',
                      prefixIcon: Icons.email_rounded,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      textDirection: TextDirection.ltr,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return context.translate('email_required');
                        }
                        if (!RegExp(
                          r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                        ).hasMatch(value)) {
                          return context.translate('email_invalid');
                        }
                        return null;
                      },
                      onSubmitted: (_) =>
                          ActionDebouncer.execute(_sendInvitation),
                    ),
                    AppSpacing.gapXL,
                    Text(
                      context.translate('member_permissions'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    AppSpacing.gapMD,
                    DropdownButtonFormField<String>(
                      initialValue: _selectedRole,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.3),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusMd,
                          ),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: const Icon(Icons.security_rounded),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 'admin',
                          child: Text(context.translate('admin')),
                        ),
                        DropdownMenuItem(
                          value: 'member',
                          child: Text(context.translate('member')),
                        ),
                        DropdownMenuItem(
                          value: 'viewer',
                          child: Text(context.translate('viewer')),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedRole = value);
                        }
                      },
                    ),
                    AppSpacing.gapLG,
                    _buildRoleInfo(
                      context,
                      context.translate('admin'),
                      context.translate('role_desc_admin'),
                      Icons.admin_panel_settings_rounded,
                    ),
                    AppSpacing.gapSM,
                    _buildRoleInfo(
                      context,
                      context.translate('member'),
                      context.translate('role_desc_member'),
                      Icons.person_rounded,
                    ),
                    AppSpacing.gapSM,
                    _buildRoleInfo(
                      context,
                      context.translate('viewer'),
                      context.translate('role_desc_viewer'),
                      Icons.visibility_rounded,
                    ),
                  ],
                ),
              ),
              AppSpacing.gapXXL,
              SawaButton(
                onPressed: () => ActionDebouncer.execute(_sendInvitation),
                text: context.translate('send_invitation'),
                isLoading: _isLoading,
                type: SawaButtonType.primary,
                icon: Icons.send_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleInfo(
    BuildContext context,
    String title,
    String desc,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              Text(
                desc,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
