import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aradi/app/theme/app_theme.dart';
import 'package:aradi/core/models/notification_event.dart';
import 'package:aradi/core/services/notification_service.dart';
import 'package:aradi/core/services/auth_service.dart';
import 'package:aradi/app/providers/data_providers.dart';
import 'package:aradi/core/models/user.dart';

class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  List<NotificationEvent> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authService = ref.read(authServiceProvider);
      final currentUser = await authService.getCurrentUser();
      
      if (currentUser != null) {
        final notificationService = NotificationService();
        _notifications = await notificationService.getNotifications(currentUser.id);
        print('Loaded ${_notifications.length} notifications for user ${currentUser.id}');
      } else {
        _notifications = [];
        print('No current user found');
      }
    } catch (e) {
      print('Error loading notifications: $e');
      _notifications = [];
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final notification = _notifications[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _NotificationCard(
                          notification: notification,
                          onTap: () => _handleNotificationTap(notification),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(
              Icons.notifications_none,
              size: 64,
              color: AppTheme.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No Notifications',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You\'ll receive notifications about offers, listings, and updates here',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _markAllAsRead() async {
    try {
      final authService = ref.read(authServiceProvider);
      final currentUser = await authService.getCurrentUser();
      
      if (currentUser != null) {
        final notificationService = NotificationService();
        // Mark all notifications as read
        for (var notification in _notifications) {
          await notificationService.markAsRead(currentUser.id, notification.id);
        }
        
        setState(() {
          for (var notification in _notifications) {
            // Update local state
          }
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All notifications marked as read'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error marking notifications as read: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  void _handleNotificationTap(NotificationEvent notification) async {
    // Mark notification as read
    try {
      final authService = ref.read(authServiceProvider);
      final currentUser = await authService.getCurrentUser();
      
      if (currentUser != null && !notification.isRead) {
        final notificationService = NotificationService();
        await notificationService.markAsRead(currentUser.id, notification.id);
        
        // Update local state
        setState(() {
          // Update the notification in the list
          final index = _notifications.indexWhere((n) => n.id == notification.id);
          if (index != -1) {
            _notifications[index] = notification.copyWith(isRead: true);
          }
        });
      }
    } catch (e) {
      print('Error marking notification as read: $e');
    }
    
    // Show notification details popup
    _showNotificationDetails(notification);
  }

  void _showNotificationDetails(NotificationEvent notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              _getNotificationIcon(notification.type),
              color: _getNotificationColor(notification.type),
              size: 24,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                notification.title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification.body,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  _formatNotificationTime(notification.createdAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
            if (notification.data != null && notification.data!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Additional Details:',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._getFilteredNotificationData(notification).entries.map((entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${entry.key}: ',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              entry.value.toString(),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    )).toList(),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          // Handle preferred developer notification with View Listing button
          if (notification.type == NotificationType.preferredDeveloper && 
              notification.data != null && 
              notification.data!['listingId'] != null)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.go('/dev/listing/${notification.data!['listingId']}');
              },
              child: const Text('View Listing'),
            )
          // Handle other notifications with deep links
          else if (notification.deepLink != null)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.go(notification.deepLink!);
              },
              child: const Text('View Details'),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.offerReceived:
        return Icons.attach_money;
      case NotificationType.offerAccepted:
        return Icons.check_circle;
      case NotificationType.offerRejected:
        return Icons.cancel;
      case NotificationType.newMessage:
        return Icons.message;
      case NotificationType.kycRejected:
        return Icons.warning;
      case NotificationType.listingRejected:
        return Icons.warning;
      case NotificationType.listingApproved:
        return Icons.check_circle;
      case NotificationType.preferredDeveloper:
        return Icons.workspace_premium;
      case NotificationType.systemAlert:
        return Icons.info;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.offerReceived:
        return AppTheme.successColor;
      case NotificationType.offerAccepted:
        return AppTheme.successColor;
      case NotificationType.offerRejected:
        return AppTheme.errorColor;
      case NotificationType.newMessage:
        return AppTheme.primaryColor;
      case NotificationType.kycRejected:
        return AppTheme.errorColor;
      case NotificationType.listingRejected:
        return AppTheme.errorColor;
      case NotificationType.listingApproved:
        return AppTheme.successColor;
      case NotificationType.preferredDeveloper:
        return Colors.amber[700]!;
      case NotificationType.systemAlert:
        return AppTheme.warningColor;
      default:
        return AppTheme.primaryColor;
    }
  }

  String _formatNotificationTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  Map<String, dynamic> _getFilteredNotificationData(NotificationEvent notification) {
    if (notification.data == null || notification.data!.isEmpty) {
      return {};
    }

    // For preferred developer notifications, only show specific fields
    if (notification.type == NotificationType.preferredDeveloper) {
      final filteredData = <String, dynamic>{};
      
      // Only include listingTitle, listingPrice, and area
      if (notification.data!.containsKey('listingTitle')) {
        filteredData['Listing Title'] = notification.data!['listingTitle'];
      }
      if (notification.data!.containsKey('listingPrice')) {
        filteredData['Listing Price'] = notification.data!['listingPrice'];
      }
      if (notification.data!.containsKey('area')) {
        filteredData['Area'] = notification.data!['area'];
      }
      
      return filteredData;
    }

    // For all other notifications, show all data
    return notification.data!;
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationEvent notification;
  final VoidCallback onTap;

  const _NotificationCard({
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: _getNotificationColor().withOpacity(0.1),
                child: Icon(
                  _getNotificationIcon(),
                  size: 20,
                  color: _getNotificationColor(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatDate(notification.createdAt),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              if (!notification.isRead)
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getNotificationIcon() {
    switch (notification.type) {
      case NotificationType.offerReceived:
        return Icons.mail;
      case NotificationType.listingVerified:
        return Icons.verified;
      case NotificationType.offerAccepted:
        return Icons.check_circle;
      case NotificationType.offerRejected:
        return Icons.cancel;
      case NotificationType.newMessage:
        return Icons.message;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor() {
    switch (notification.type) {
      case NotificationType.offerReceived:
        return AppTheme.warningColor;
      case NotificationType.listingVerified:
        return AppTheme.successColor;
      case NotificationType.offerAccepted:
        return AppTheme.successColor;
      case NotificationType.offerRejected:
        return AppTheme.errorColor;
      case NotificationType.newMessage:
        return AppTheme.primaryColor;
      default:
        return AppTheme.textSecondary;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
