import 'package:flutter/material.dart';

enum MessageType {
  info,
  success,
  warning,
  error,
}

class MessageWidget extends StatelessWidget {
  const MessageWidget({
    super.key,
    required this.message,
    this.title,
    this.type = MessageType.info,
    this.icon,
    this.actionLabel,
    this.onActionPressed,
  });

  final String message;
  final String? title;
  final MessageType type;
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onActionPressed;

  Color _backgroundColor(ColorScheme colorScheme) {
    switch (type) {
      case MessageType.success:
        return colorScheme.secondaryContainer;

      case MessageType.warning:
        return colorScheme.tertiaryContainer;

      case MessageType.error:
        return colorScheme.errorContainer;

      case MessageType.info:
        return colorScheme.primaryContainer;
    }
  }

  Color _foregroundColor(ColorScheme colorScheme) {
    switch (type) {
      case MessageType.success:
        return colorScheme.onSecondaryContainer;

      case MessageType.warning:
        return colorScheme.onTertiaryContainer;

      case MessageType.error:
        return colorScheme.onErrorContainer;

      case MessageType.info:
        return colorScheme.onPrimaryContainer;
    }
  }

  IconData _defaultIcon() {
    switch (type) {
      case MessageType.success:
        return Icons.check_circle_outline_rounded;

      case MessageType.warning:
        return Icons.warning_amber_rounded;

      case MessageType.error:
        return Icons.error_outline_rounded;

      case MessageType.info:
        return Icons.info_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final foregroundColor = _foregroundColor(colorScheme);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _backgroundColor(colorScheme),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon ?? _defaultIcon(),
            color: foregroundColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null)
                  Text(
                    title!,
                    style: TextStyle(
                      color: foregroundColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                if (title != null) const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(
                    color: foregroundColor,
                  ),
                ),
                if (actionLabel != null) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: onActionPressed,
                    child: Text(actionLabel!),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}