import 'package:azmode/Core/api/api_client.dart';
import 'package:azmode/Core/api/api_endpoints.dart';

import '../models/proforma.dart';

class ProformaService {
  ProformaService({required this.apiClient});

  final ApiClient apiClient;

  /// ثبت سفارش از روی سبد خرید فعلی کاربر (سمت بک‌اند از جدول CartItem
  /// خوانده می‌شود، نیازی به ارسال آیتم‌ها در بدنه نیست).
  Future<ProformaOrder> submit() async {
    final response = await apiClient.post(
      ApiEndpoints.orderSubmit,
      requiresAuth: true,
    );
    return _parseSingle(response);
  }

  Future<List<ProformaOrder>> fetchMine() async {
    final response = await apiClient.get(
      ApiEndpoints.myOrders,
      requiresAuth: true,
    );
    return _parseList(response);
  }

  /// فقط ادمین — لیست همه‌ی سفارش‌ها.
  Future<List<ProformaOrder>> fetchAll() async {
    final response = await apiClient.get(
      ApiEndpoints.orders,
      requiresAuth: true,
    );
    return _parseList(response);
  }

  /// فقط ادمین — تایید/رد سفارش.
  Future<void> updateStatus(int orderId, ProformaStatus status) async {
    await apiClient.patch(
      '${ApiEndpoints.orders}$orderId/status/',
      requiresAuth: true,
      body: {'status': proformaStatusToKey(status)},
    );
  }

  ProformaOrder _parseSingle(dynamic response) {
    if (response is! Map<String, dynamic>) {
      throw ApiException('پاسخ سفارش از سرور نامعتبر است.');
    }
    return ProformaOrder.fromJson(response);
  }

  List<ProformaOrder> _parseList(dynamic decoded) {
    if (decoded is List) {
      return decoded
          .whereType<Map>()
          .map((e) => ProformaOrder.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    if (decoded is Map<String, dynamic>) {
      final results = decoded['results'];
      if (results is List) {
        return results
            .whereType<Map>()
            .map((e) => ProformaOrder.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    }
    throw ApiException('پاسخ لیست سفارش‌ها از سرور نامعتبر است.');
  }
}
