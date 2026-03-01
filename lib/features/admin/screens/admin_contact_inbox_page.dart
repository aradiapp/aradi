import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:aradi/app/theme/app_theme.dart';
import 'package:aradi/core/models/contact_request.dart';
import 'package:aradi/core/services/contact_request_service.dart';

class AdminContactInboxPage extends ConsumerStatefulWidget {
  const AdminContactInboxPage({super.key});

  @override
  ConsumerState<AdminContactInboxPage> createState() => _AdminContactInboxPageState();
}

class _AdminContactInboxPageState extends ConsumerState<AdminContactInboxPage> {
  final ContactRequestService _service = ContactRequestService();

  Future<void> _openReplyEmail(ContactRequest request) async {
    final uri = Uri(
      scheme: 'mailto',
      path: request.userEmail,
      queryParameters: {
        'subject': 'Re: ${request.subject}',
        'body': 'Hi ${request.userName},\n\n',
      },
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      await _service.markAsReplied(request.id, '[Replied via email]');
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cannot open email. Reply to: ${request.userEmail}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<List<ContactRequest>>(
        stream: _service.streamAllContactRequests(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: AppTheme.errorColor),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}', textAlign: TextAlign.center),
                ],
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final requests = snapshot.data!;
          if (requests.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, size: 64, color: AppTheme.textSecondary),
                  const SizedBox(height: 16),
                  Text(
                    'No contact messages yet',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final r = requests[index];
              final isUnread = r.status == 'unread';
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isUnread ? AppTheme.primaryColor : Colors.grey,
                    child: Icon(
                      isUnread ? Icons.mail : Icons.mail_outline,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  title: Text(
                    r.subject,
                    style: TextStyle(
                      fontWeight: isUnread ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(
                    '${r.userName} (${r.role}) · ${_formatDate(r.createdAt)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () => _showDetail(context, r),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatDate(DateTime d) {
    final now = DateTime.now();
    if (d.year == now.year && d.month == now.month && d.day == now.day) {
      return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    }
    return '${d.day}/${d.month}/${d.year}';
  }

  void _showDetail(BuildContext context, ContactRequest r) {
    _service.markAsRead(r.id);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.95,
        expand: false,
        builder: (ctx, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                r.subject,
                style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Chip(label: Text(r.role)),
                  const SizedBox(width: 8),
                  Text(
                    r.userName,
                    style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              SelectableText(
                r.userEmail,
                style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                      color: AppTheme.primaryColor,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                _formatDate(r.createdAt),
                style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
              ),
              const Divider(height: 24),
              Text(
                r.message,
                style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(height: 1.5),
              ),
              if (r.adminReplyText != null) ...[
                const Divider(height: 24),
                Text(
                  'Your reply',
                  style: Theme.of(ctx).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  r.adminReplyText!,
                  style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(height: 1.5),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _openReplyEmail(r);
                  },
                  icon: const Icon(Icons.email),
                  label: const Text('Reply via email'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
