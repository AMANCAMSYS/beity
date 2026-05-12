import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/invitations_provider.dart';

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
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceAll('Exception: ', ''),
              textDirection: TextDirection.rtl,
            ),
            backgroundColor: Colors.red,
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
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'دعوة عضو جديد',
          textDirection: TextDirection.rtl,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'إضافة عضو إلى ${widget.homeName}',
                style: Theme.of(context).textTheme.titleLarge,
                textDirection: TextDirection.rtl,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textDirection: TextDirection.ltr,
                decoration: const InputDecoration(
                  labelText: 'البريد الإلكتروني',
                  hintText: 'example@email.com',
                  prefixIcon: Icon(Icons.email),
                ),
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
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: const InputDecoration(
                  labelText: 'الدور',
                  prefixIcon: Icon(Icons.person),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'admin',
                    child: Text('مدير'),
                  ),
                  DropdownMenuItem(
                    value: 'member',
                    child: Text('عضو'),
                  ),
                  DropdownMenuItem(
                    value: 'viewer',
                    child: Text('مشاهد'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedRole = value);
                  }
                },
              ),
              const SizedBox(height: 8),
              Text(
                'المدير: يمكنه إدارة القوائم والأعضاء\nالعضو: يمكنه تعديل القوائم\nالمشاهد: يمكنه المشاهدة فقط',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                textDirection: TextDirection.rtl,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _sendInvitation,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'إرسال الدعوة',
                        textDirection: TextDirection.rtl,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
