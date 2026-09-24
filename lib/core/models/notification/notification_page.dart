import '../pagination.dart';
import 'app_notification.dart';

class NotificationPage {
  const NotificationPage({
    required this.notifications,
    required this.pagination,
  });

  final List<AppNotification> notifications;
  final Pagination pagination;

  factory NotificationPage.fromJson(Map<String, dynamic> json) {
    final rawNotifications = json['notifications'];
    final notifications = rawNotifications is List
        ? rawNotifications
            .whereType<Map>()
            .map(
              (item) => AppNotification.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList()
        : const <AppNotification>[];
    final rawPagination = json['pagination'];

    return NotificationPage(
      notifications: notifications,
      pagination: rawPagination is Map
          ? Pagination.fromJson(Map<String, dynamic>.from(rawPagination))
          : const Pagination(
              page: 1,
              limit: 20,
              totalItems: 0,
              totalPages: 0,
              hasNextPage: false,
              hasPreviousPage: false,
            ),
    );
  }
}
