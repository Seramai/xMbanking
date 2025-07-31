import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  // notification data
  final List<NotificationItem> _notifications = [
    NotificationItem(
      id: '1',
      title: 'Transaction Alert',
      message: 'You received KES 2,500.00 from MPESA',
      timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      type: NotificationType.transaction,
      isRead: false,
    ),
    NotificationItem(
      id: '2',
      title: 'Security Alert',
      message: 'New login detected from Chrome browser',
      timestamp: DateTime.now().subtract(const Duration(hours: 3)),
      type: NotificationType.security,
      isRead: false,
    ),
    NotificationItem(
      id: '3',
      title: 'Account Update',
      message: 'Your profile information has been updated successfully',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      type: NotificationType.account,
      isRead: true,
    ),
    NotificationItem(
      id: '4',
      title: 'Withdrawal Completed',
      message: 'ATM withdrawal of KES 1,000.00 was successful',
      timestamp: DateTime.now().subtract(const Duration(days: 2)),
      type: NotificationType.transaction,
      isRead: true,
    ),
    NotificationItem(
      id: '5',
      title: 'System Maintenance',
      message: 'Scheduled maintenance will occur on Sunday 2AM-4AM',
      timestamp: DateTime.now().subtract(const Duration(days: 3)),
      type: NotificationType.system,
      isRead: true,
    ),
    NotificationItem(
      id: '6',
      title: 'Payment Reminder',
      message: 'Your utility bill payment is due in 3 days',
      timestamp: DateTime.now().subtract(const Duration(days: 4)),
      type: NotificationType.reminder,
      isRead: false,
    ),
  ];

  int get _unreadCount => _notifications.where((n) => !n.isRead).length;

  void _markAsRead(String notificationId) {
    setState(() {
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index].isRead = true;
      }
    });
  }

  void _markAllAsRead() {
    setState(() {
      for (var notification in _notifications) {
        notification.isRead = true;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All notifications marked as read'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _deleteNotification(String notificationId) {
    setState(() {
      _notifications.removeWhere((n) => n.id == notificationId);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notification deleted'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.transaction:
        return Colors.green;
      case NotificationType.security:
        return Colors.red;
      case NotificationType.account:
        return Colors.blue;
      case NotificationType.system:
        return Colors.orange;
      case NotificationType.reminder:
        return Colors.purple;
    }
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.transaction:
        return Icons.account_balance_wallet;
      case NotificationType.security:
        return Icons.security;
      case NotificationType.account:
        return Icons.person;
      case NotificationType.system:
        return Icons.settings;
      case NotificationType.reminder:
        return Icons.notifications_active;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Notifications'),
            if (_unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$_unreadCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text(
                'Mark All Read',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A237E).withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: _notifications.isEmpty
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.notifications_off,
                      size: 80,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No notifications',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'You\'re all caught up!',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _notifications.length,
                itemBuilder: (context, index) {
                  final notification = _notifications[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: notification.isRead ? 2 : 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: notification.isRead
                            ? null
                            : Border.all(
                                color: Color(0xFF1A237E).withOpacity(0.1),
                                width: 1,
                              ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _getNotificationColor(notification.type).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _getNotificationIcon(notification.type),
                            color: _getNotificationColor(notification.type),
                            size: 24,
                          ),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                notification.title,
                                style: TextStyle(
                                  fontWeight: notification.isRead 
                                      ? FontWeight.normal 
                                      : FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            if (!notification.isRead)
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              notification.message,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              DateFormat('MMM dd, yyyy • hh:mm a').format(notification.timestamp),
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'mark_read' && !notification.isRead) {
                              _markAsRead(notification.id);
                            } else if (value == 'delete') {
                              _deleteNotification(notification.id);
                            }
                          },
                          itemBuilder: (context) => [
                            if (!notification.isRead)
                              const PopupMenuItem(
                                value: 'mark_read',
                                child: Row(
                                  children: [
                                    Icon(Icons.mark_email_read, size: 18),
                                    SizedBox(width: 8),
                                    Text('Mark as Read'),
                                  ],
                                ),
                              ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, size: 18, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Delete', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        onTap: () {
                          if (!notification.isRead) {
                            _markAsRead(notification.id);
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Tapped: ${notification.title}'),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
enum NotificationType {
  transaction,
  security,
  account,
  system,
  reminder,
}

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final NotificationType type;
  bool isRead;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.type,
    this.isRead = false,
  });
}