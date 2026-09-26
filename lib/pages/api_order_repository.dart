import 'package:azmode/Core/api/api_client.dart';
import 'package:azmode/Core/api/api_endpoints.dart';

class ApiOrderRepository {
  ApiOrderRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<Map<String, dynamic>> submitOrder() async {
    final response = await _apiClient.post(
      ApiEndpoints.orderSubmit,
      requiresAuth: true,
    );

    if (response is! Map<String, dynamic>) {
      throw ApiException('پاسخ ثبت سفارش از سرور نامعتبر است.');
    }

    return response;
  }

  Future<List<Map<String, dynamic>>> fetchMyOrders() async {
    final response = await _apiClient.get(
      ApiEndpoints.myOrders,
      requiresAuth: true,
    );

    if (response is! List) {
      throw ApiException('پاسخ سفارش‌ها از سرور نامعتبر است.');
    }

    return response.whereType<Map<String, dynamic>>().toList();
  }

  Future<List<Map<String, dynamic>>> fetchAllOrders() async {
    final response = await _apiClient.get(
      ApiEndpoints.orders,
      requiresAuth: true,
    );

    if (response is! List) {
      throw ApiException('پاسخ سفارش‌ها از سرور نامعتبر است.');
    }

    return response.whereType<Map<String, dynamic>>().toList();
  }

  Future<Map<String, dynamic>> updateOrderStatus({
    required String orderId,
    required String status,
  }) async {
    final response = await _apiClient.patch(
      '${ApiEndpoints.orders}$orderId/status/',
      requiresAuth: true,
      body: {'status': status},
    );

    if (response is! Map<String, dynamic>) {
      throw ApiException('پاسخ تغییر وضعیت سفارش از سرور نامعتبر است.');
    }

    return response;
  }
}
