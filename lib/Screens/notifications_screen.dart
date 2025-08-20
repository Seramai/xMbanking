import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../Utils/status_messages.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
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
  final Color darkBlue = const Color(0xFF1A237E);

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
    StatusMessages.success(context, message: 'All notifications marked as read');
  }

  void _deleteNotification(String notificationId) {
    setState(() {
      _notifications.removeWhere((n) => n.id == notificationId);
    });
    StatusMessages.info(context, message: 'Notification deleted');
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.transaction:
        return Colors.green;
      case NotificationType.security:
        return Colors.red;
      case NotificationType.account:
        return darkBlue;
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
            const Flexible(
              child: Text(
                'NOTIFICATIONS',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            if (_unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$_unreadCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        backgroundColor: darkBlue,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_unreadCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton(
                onPressed: _markAllAsRead,
                child: const Text(
                  'MARK ALL READ',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Container(
        color: Colors.white,
        child: _notifications.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.notifications_off,
                      size: 80,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'NO NOTIFICATIONS',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w900, 
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You\'re all caught up!',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                itemCount: _notifications.length,
                itemBuilder: (context, index) {
                  final notification = _notifications[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    elevation: notification.isRead ? 1 : 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: notification.isRead
                            ? null
                            : Border.all(
                                color: darkBlue.withOpacity(0.15),
                                width: 1,
                              ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _getNotificationColor(notification.type).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _getNotificationIcon(notification.type),
                            color: _getNotificationColor(notification.type),
                            size: 20,
                          ),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                notification.title,
                                style: TextStyle(
                                  fontWeight: notification.isRead 
                                      ? FontWeight.w600 
                                      : FontWeight.w800, 
                                  fontSize: 14,
                                  color: Colors.black87,
                                  letterSpacing: 0.1,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (!notification.isRead)
                              Container(
                                width: 6,
                                height: 6,
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
                                color: Colors.grey[700],
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              DateFormat('MMM dd, yyyy • hh:mm a').format(notification.timestamp),
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        trailing: SizedBox(
                          width: 24,
                          child: PopupMenuButton<String>(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: Icon(
                              Icons.more_vert,
                              size: 18,
                              color: Colors.grey[600],
                            ),
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
                                  height: 40,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.mark_email_read, size: 16),
                                      SizedBox(width: 8),
                                      Text(
                                        'Mark as Read',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              const PopupMenuItem(
                                value: 'delete',
                                height: 40,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.delete, size: 16, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text(
                                      'Delete',
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        onTap: () {
                          if (!notification.isRead) {
                            _markAsRead(notification.id);
                          }
                          StatusMessages.info(context, message: 'Tapped: ${notification.title}', duration: const Duration(seconds: 1));
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