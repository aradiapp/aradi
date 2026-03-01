import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:aradi/app/theme/app_theme.dart';
import 'package:aradi/app/providers/data_providers.dart';
import 'package:aradi/core/models/user.dart';
import 'package:aradi/core/services/contact_request_service.dart';

class ContactAdminPage extends ConsumerStatefulWidget {
  final UserRole userRole;

  const ContactAdminPage({super.key, required this.userRole});

  @override
  ConsumerState<ContactAdminPage> createState() => _ContactAdminPageState();
}

class _ContactAdminPageState extends ConsumerState<ContactAdminPage> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  final _contactRequestService = ContactRequestService();
  bool _isSubmitting = false;
  String get _basePath => widget.userRole == UserRole.seller ? '/seller' : '/dev';

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSubmitting = true);
    try {
      final user = await ref.read(authServiceProvider).getCurrentUser();
      if (user == null || !mounted) return;
      await _contactRequestService.submitContactRequest(
        userId: user.id,
        userEmail: user.email,
        userName: user.name,
        role: widget.userRole == UserRole.seller ? 'seller' : 'developer',
        subject: _subjectController.text.trim(),
        message: _messageController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Message sent. Admin will reply to your email.'),
          backgroundColor: AppTheme.successColor,
        ),
      );
      _subjectController.clear();
      _messageController.clear();
      context.go(_basePath);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contact admin'),
        backgroundColor: AppTheme.accentColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Send a message to administration. You will receive a reply at your registered email.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _subjectController,
                decoration: const InputDecoration(
                  labelText: 'Subject',
                  border: OutlineInputBorder(),
                  hintText: 'e.g. Listing verification question',
                ),
                textCapitalization: TextCapitalization.sentences,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a subject' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _messageController,
                decoration: const InputDecoration(
                  labelText: 'Message',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                  hintText: 'Type your message...',
                ),
                maxLines: 6,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a message' : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Send message'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
