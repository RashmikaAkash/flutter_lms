import 'package:flutter/material.dart';

import '../core/errors/api_exception.dart';
import '../core/models/notification/app_notification.dart';
import '../core/models/notification/notification_service.dart';
import '../widgets/message_widget.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _notificationService = NotificationService();
  final List<AppNotification> _notifications = [];
  final Set<String> _busyNotificationIds = {};

  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasNextPage = false;
  bool _isMarkingAllRead = false;
  int _page = 1;
  int _unreadCount = 0;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications({bool loadMore = false}) async {
    if (loadMore) {
      if (_isLoadingMore || !_hasNextPage) return;
      setState(() => _isLoadingMore = true);
    } else {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      _page = 1;
    }

    try {
      final nextPage = loadMore ? _page + 1 : 1;
      final result = await _notificationService.getMyNotifications(
        page: nextPage,
        limit: 20,
      );
      final unreadCount = await _notificationService.getUnreadCount();
      if (!mounted) return;
      setState(() {
        if (loadMore) {
          _notifications.addAll(result.notifications);
        } else {
          _notifications
            ..clear()
            ..addAll(result.notifications);
        }
        _page = nextPage;
        _hasNextPage = result.pagination.hasNextPage;
        _unreadCount = unreadCount;
        _isLoading = false;
        _isLoadingMore = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      if (error.isUnauthorized) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/login',
          (route) => false,
        );
        return;
      }
      setState(() {
        _errorMessage = error.message;
        _isLoading = false;
        _isLoadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Unable to load notifications. Please try again.';
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _markRead(AppNotification notification) async {
    if (notification.isRead || _busyNotificationIds.contains(notification.id)) {
      return;
    }
    setState(() => _busyNotificationIds.add(notification.id));
    try {
      await _notificationService.markRead(notification.id);
      if (mounted) await _loadNotifications();
    } on ApiException catch (error) {
      if (mounted) _showError(error.message);
    } catch (_) {
      if (mounted) _showError('Unable to mark notification as read.');
    } finally {
      if (mounted) setState(() => _busyNotificationIds.remove(notification.id));
    }
  }

  Future<void> _markAllRead() async {
    if (_unreadCount == 0 || _isMarkingAllRead) return;
    setState(() => _isMarkingAllRead = true);
    try {
      await _notificationService.markAllRead();
      if (mounted) await _loadNotifications();
    } on ApiException catch (error) {
      if (mounted) _showError(error.message);
    } catch (_) {
      if (mounted) _showError('Unable to mark notifications as read.');
    } finally {
      if (mounted) setState(() => _isMarkingAllRead = false);
    }
  }

  Future<void> _deleteNotification(AppNotification notification) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete notification?'),
        content: const Text('This notification will be permanently removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busyNotificationIds.add(notification.id));
    try {
      await _notificationService.deleteNotification(notification.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification deleted.')),
        );
        await _loadNotifications();
      }
    } on ApiException catch (error) {
      if (mounted) _showError(error.message);
    } catch (_) {
      if (mounted) _showError('Unable to delete notification.');
    } finally {
      if (mounted) setState(() => _busyNotificationIds.remove(notification.id));
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final localDate = date.toLocal();
    return '${localDate.day.toString().padLeft(2, '0')}/'
        '${localDate.month.toString().padLeft(2, '0')}/'
        '${localDate.year}  '
        '${localDate.hour.toString().padLeft(2, '0')}:'
        '${localDate.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildNotification(AppNotification notification) {
    final isBusy = _busyNotificationIds.contains(notification.id);
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: notification.isRead
              ? Theme.of(context).colorScheme.surfaceContainerHighest
              : Theme.of(context).colorScheme.primaryContainer,
          child: Icon(
            notification.isRead
                ? Icons.notifications_none
                : Icons.notifications_active_outlined,
          ),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight:
                notification.isRead ? FontWeight.normal : FontWeight.w600,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(notification.message),
              if (notification.createdAt != null) ...[
                const SizedBox(height: 6),
                Text(
                  _formatDate(notification.createdAt),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
        trailing: isBusy
            ? const SizedBox.square(
                dimension: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : PopupMenuButton<String>(
                onSelected: (action) {
                  if (action == 'read') _markRead(notification);
                  if (action == 'delete') _deleteNotification(notification);
                },
                itemBuilder: (context) => [
                  if (!notification.isRead)
                    const PopupMenuItem(
                      value: 'read',
                      child: Text('Mark as read'),
                    ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete'),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: MessageWidget(
            title: 'Unable to load notifications',
            message: _errorMessage!,
            type: MessageType.error,
            actionLabel: 'Retry',
            onActionPressed: _loadNotifications,
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadNotifications,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          if (_notifications.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 70),
              child: MessageWidget(
                title: 'You’re all caught up',
                message: 'New course and learning updates will appear here.',
                type: MessageType.info,
              ),
            )
          else
            ..._notifications.map(_buildNotification),
          if (_hasNextPage)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: OutlinedButton.icon(
                  onPressed: _isLoadingMore
                      ? null
                      : () => _loadNotifications(loadMore: true),
                  icon: _isLoadingMore
                      ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.expand_more),
                  label: const Text('Load more'),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Chip(label: Text('Unread: $_unreadCount')),
            ),
          ),
          IconButton(
            onPressed:
                _unreadCount == 0 || _isMarkingAllRead ? null : _markAllRead,
            tooltip: 'Mark all as read',
            icon: _isMarkingAllRead
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.done_all),
          ),
        ],
      ),
      body: SafeArea(child: _buildContent()),
    );
  }
}

class NotificationsAction extends StatefulWidget {
  const NotificationsAction({super.key});

  @override
  State<NotificationsAction> createState() => _NotificationsActionState();
}

class _NotificationsActionState extends State<NotificationsAction> {
  final NotificationService _notificationService = NotificationService();
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUnreadCount();
  }

  Future<void> _loadUnreadCount() async {
    try {
      final count = await _notificationService.getUnreadCount();
      if (mounted) setState(() => _unreadCount = count);
    } catch (_) {}
  }

  Future<void> _openNotifications() async {
    await Navigator.pushNamed(context, '/notifications');
    if (mounted) _loadUnreadCount();
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: _openNotifications,
      tooltip: _unreadCount > 0
          ? 'Notifications ($_unreadCount unread)'
          : 'Notifications',
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.notifications_outlined),
          if (_unreadCount > 0)
            Positioned(
              right: -6,
              top: -5,
              child: Container(
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.error,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  _unreadCount > 99 ? '99+' : '$_unreadCount',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onError,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
