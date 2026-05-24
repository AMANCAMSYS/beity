import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:beity/app/theme/app_spacing.dart';
import 'package:beity/app/theme/app_colors.dart';
import 'package:beity/shared/widgets/design_system/beity_card.dart';
import 'package:beity/shared/widgets/design_system/beity_button.dart';
import 'package:beity/shared/widgets/design_system/beity_text_field.dart';
import '../providers/invitations_provider.dart';
import 'package:beity/core/utils/action_debouncer.dart';

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
  String _selectedRole = 'member';
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendInvitation() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await ref.read(invitationNotifierProvider.notifier).sendInvitation(
            homeId: widget.homeId,
            email: _emailController.text.trim(),
            role: _selectedRole,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'تم إرسال الدعوة بنجاح',
              textDirection: TextDirection.rtl,
            ),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceAll('Exception: ', ''),
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('دعوة عضو جديد'),
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
                'إضافة عضو إلى ${widget.homeName}',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              AppSpacing.gapSM,
              Text(
                'سيتم إرسال رابط دعوة إلى البريد الإلكتروني للمستخدم.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
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
                      controller: _emailController,
                      labelText: 'البريد الإلكتروني',
                      hintText: 'example@email.com',
                      prefixIcon: Icons.email_rounded,
                      keyboardType: TextInputType.emailAddress,
                      textDirection: TextDirection.ltr,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'يرجى إدخال البريد الإلكتروني';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                            .hasMatch(value)) {
                          return 'البريد الإلكتروني غير صالح';
                        }
                        return null;
                      },
                    ),
                    AppSpacing.gapXL,
                    Text(
                      'صلاحيات العضو',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    AppSpacing.gapMD,
                    DropdownButtonFormField<String>(
                      value: _selectedRole,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: const Icon(Icons.security_rounded),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'admin', child: Text('مدير')),
                        DropdownMenuItem(value: 'member', child: Text('عضو')),
                        DropdownMenuItem(value: 'viewer', child: Text('مشاهد')),
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
                      'مدير',
                      'يمكنه إدارة القوائم، إضافة وحذف الأعضاء وتعديل الأدوار.',
                      Icons.admin_panel_settings_rounded,
                    ),
                    AppSpacing.gapSM,
                    _buildRoleInfo(
                      context,
                      'عضو',
                      'يمكنه إضافة وتعديل القوائم والمنتجات والمهام بشكل كامل.',
                      Icons.person_rounded,
                    ),
                    AppSpacing.gapSM,
                    _buildRoleInfo(
                      context,
                      'مشاهد',
                      'يمكنه مشاهدة القوائم والمهام فقط دون القدرة على التعديل.',
                      Icons.visibility_rounded,
                    ),
                  ],
                ),
              ),
              AppSpacing.gapXXL,
              BeityButton(
                onPressed: () => ActionDebouncer.execute(_sendInvitation),
                text: 'إرسال الدعوة',
                isLoading: _isLoading,
                type: BeityButtonType.primary,
                icon: Icons.send_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleInfo(BuildContext context, String title, String desc, IconData icon) {
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
