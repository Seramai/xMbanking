import 'package:flutter/material.dart';

class StatusMessages {
  static void success(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 3),
    SnackBarBehavior behavior = SnackBarBehavior.floating,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    _show(context,
        message: message,
        backgroundColor: Colors.green,
        icon: Icons.check_circle,
        duration: duration,
        behavior: behavior,
        actionLabel: actionLabel,
        onAction: onAction);
  }

  static void error(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 4),
    SnackBarBehavior behavior = SnackBarBehavior.floating,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    _show(context,
        message: message,
        backgroundColor: Colors.red,
        icon: Icons.error_outline,
        duration: duration,
        behavior: behavior,
        actionLabel: actionLabel,
        onAction: onAction);
  }

  static void info(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 3),
    SnackBarBehavior behavior = SnackBarBehavior.floating,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    _show(context,
        message: message,
        backgroundColor: Colors.blue,
        icon: Icons.info_outline,
        duration: duration,
        behavior: behavior,
        actionLabel: actionLabel,
        onAction: onAction);
  }

  static void _show(
    BuildContext context, {
    required String message,
    required Color backgroundColor,
    required IconData icon,
    required Duration duration,
    required SnackBarBehavior behavior,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final snackBar = SnackBar(
      content: Row(
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(child: Text(message)),
        ],
      ),
      backgroundColor: backgroundColor,
      duration: duration,
      behavior: behavior,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      action: (actionLabel != null && onAction != null)
          ? SnackBarAction(
              label: actionLabel,
              onPressed: onAction,
              textColor: Colors.white,
            )
          : null,
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}


