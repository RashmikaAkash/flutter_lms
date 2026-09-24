import '../../errors/api_exception.dart';
import '../../network/api_client.dart';
import 'app_notification.dart';
import 'notification_page.dart';

class NotificationService {
  NotificationService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<NotificationPage> getMyNotifications({
    int page = 1,
    int limit = 20,
    bool unreadOnly = false,
  }) async {
    final response = await _apiClient.get(
      '/api/v1/notifications/me',
      queryParameters: {
        'page': page,
        'limit': limit,
        'unreadOnly': unreadOnly,
      },
      requiresAuth: true,
    );
    final data = _responseData(response.data, 'notifications');
    return NotificationPage.fromJson(Map<String, dynamic>.from(data));
  }

  Future<int> getUnreadCount() async {
    final response = await _apiClient.get(
      '/api/v1/notifications/me/unread-count',
      requiresAuth: true,
    );
    final data = _responseData(response.data, 'unread count');
    final count = data['unreadCount'];
    if (count is num) {
      return count.toInt();
    }
    throw const ApiException(message: 'Unread notification count is invalid');
  }

  Future<AppNotification> markRead(String notificationId) async {
    final response = await _apiClient.patch(
      '/api/v1/notifications/$notificationId/read',
      requiresAuth: true,
    );
    final data = _responseData(response.data, 'notification');
    final notification = data['notification'];
    if (notification is! Map) {
      throw const ApiException(message: 'Updated notification is unavailable');
    }
    return AppNotification.fromJson(Map<String, dynamic>.from(notification));
  }

  Future<int> markAllRead() async {
    final response = await _apiClient.patch(
      '/api/v1/notifications/me/read-all',
      requiresAuth: true,
    );
    final data = _responseData(response.data, 'updated notifications');
    final count = data['updatedCount'];
    return count is num ? count.toInt() : 0;
  }

  Future<void> deleteNotification(String notificationId) async {
    await _apiClient.delete(
      '/api/v1/notifications/$notificationId',
      requiresAuth: true,
    );
  }

  Map<String, dynamic> _responseData(dynamic response, String label) {
    if (response is! Map<String, dynamic>) {
      throw ApiException(message: 'Invalid $label response');
    }
    final data = response['data'];
    if (data is! Map<String, dynamic>) {
      throw ApiException(message: '$label data is unavailable');
    }
    return data;
  }
}
