import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../Core/api/api_client.dart';
import '../model.dart';
import 'notification_repository.dart';
import 'paged_result.dart';

class ApiNotificationRepository implements NotificationRepository {
  ApiNotificationRepository({
    required this.baseUrl,
    http.Client? client,
    this.accessToken,
    ApiClient? apiClient,
  }) : _client = client ?? http.Client(),
       _apiClient = apiClient;

  final String baseUrl;
  final String? accessToken;
  final http.Client _client;
  final ApiClient? _apiClient;

  static const String _notificationsPath = '/api/notifications/';

  @override
  Future<List<AppNotification>> fetchNotifications() async {
    final apiClient = _apiClient;
    if (apiClient != null) {
      return _fetchNotificationsViaApiClient(apiClient);
    }
    return _fetchNotificationsViaHttpClient();
  }

  Future<List<AppNotification>> _fetchNotificationsViaApiClient(
    ApiClient apiClient,
  ) async {
    try {
      final decoded = await apiClient.get(
        _notificationsPath,
        requiresAuth: true,
      );
      return _parseNotificationsResponse(decoded);
    } on ApiException catch (e) {
      throw DataException(_mapErrorKind(e), e.message);
    }
  }

  Future<List<AppNotification>> _fetchNotificationsViaHttpClient() async {
    try {
      final uri = Uri.parse(baseUrl).resolve(_notificationsPath);

      final response = await _client
          .get(uri, headers: _headers())
          .timeout(const Duration(seconds: 15));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw DataException(
          DataErrorKind.server,
          'GET $uri -> ${response.statusCode}: ${response.body}',
        );
      }

      final decoded = jsonDecode(response.body);

      return _parseNotificationsResponse(decoded);
    } on SocketException catch (e) {
      throw DataException(DataErrorKind.network, e.message);
    } on HttpException catch (e) {
      throw DataException(DataErrorKind.network, e.message);
    } on FormatException catch (e) {
      throw DataException(
        DataErrorKind.unknown,
        'Invalid JSON response: ${e.message}',
      );
    } on DataException {
      rethrow;
    } catch (e) {
      throw DataException(DataErrorKind.unknown, e.toString());
    }
  }

  @override
  Future<void> markAllAsRead() async {
    final apiClient = _apiClient;
    if (apiClient == null) {
      throw StateError('ApiClient is not configured for NotificationRepository');
    }

    try {
      await apiClient.post(
        '$_notificationsPath mark-all-read/',
        requiresAuth: true,
      );
    } on ApiException catch (e) {
      throw DataException(_mapErrorKind(e), e.message);
    }
  }

  @override
  Future<void> markAsRead(String id) async {
    final apiClient = _apiClient;
    if (apiClient == null) {
      throw StateError('ApiClient is not configured for NotificationRepository');
    }

    try {
      await apiClient.patch(
        '$_notificationsPath$id/read/',
        requiresAuth: true,
      );
    } on ApiException catch (e) {
      throw DataException(_mapErrorKind(e), e.message);
    }
  }

  @override
  Future<void> deleteNotification(String id) async {
    final apiClient = _apiClient;
    if (apiClient == null) {
      throw StateError('ApiClient is not configured for NotificationRepository');
    }

    try {
      await apiClient.delete(
        '$_notificationsPath$id/',
        requiresAuth: true,
      );
    } on ApiException catch (e) {
      throw DataException(_mapErrorKind(e), e.message);
    }
  }

  DataErrorKind _mapErrorKind(ApiException e) {
    final code = e.statusCode;
    if (code != null) {
      if (code >= 500) return DataErrorKind.server;
      if (code == 408 || code == 429) return DataErrorKind.timeout;
      if (code == 401 || code == 403) return DataErrorKind.unknown;
      if (code >= 400 && code < 500) return DataErrorKind.server;
    }
    return DataErrorKind.unknown;
  }

  Map<String, String> _headers() {
    final headers = <String, String>{'Accept': 'application/json'};

    if (accessToken != null && accessToken!.trim().isNotEmpty) {
      headers['Authorization'] = 'Bearer ${accessToken!.trim()}';
    }

    return headers;
  }

  List<AppNotification> _parseNotificationsResponse(dynamic decoded) {
    if (decoded is List) {
      return decoded
          .whereType<Map>()
          .map((item) => _notificationFromJson(Map<String, dynamic>.from(item)))
          .toList();
    }

    if (decoded is Map<String, dynamic>) {
      final results = decoded['results'];

      if (results is List) {
        return results
            .whereType<Map>()
            .map((item) => _notificationFromJson(Map<String, dynamic>.from(item)))
            .toList();
      }
    }

    throw const DataException(
      DataErrorKind.unknown,
      'Unsupported notifications response format.',
    );
  }

  AppNotification _notificationFromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id']?.toString() ?? '',
      type: _parseNotificationType(json['type']),
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      date: _parseDateTime(json['date']),
      isRead: json['is_read'] == true,
      targetUserId: json['target_user_id']?.toString(),
      relatedId: json['related_id']?.toString(),
    );
  }

  NotificationType _parseNotificationType(dynamic value) {
    final str = value?.toString() ?? '';
    switch (str) {
      case 'new_product':
        return NotificationType.newProduct;
      case 'order_approved':
        return NotificationType.orderApproved;
      case 'order_rejected':
        return NotificationType.orderRejected;
      default:
        return NotificationType.general;
    }
  }

  DateTime _parseDateTime(dynamic value) {
    if (value == null) {
      return DateTime.now();
    }

    final parsed = DateTime.tryParse(value.toString());

    return parsed ?? DateTime.now();
  }
}
