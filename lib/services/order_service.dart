import 'package:azmode/Core/api/api_client.dart';
import 'package:azmode/Core/api/api_endpoints.dart';

import '../models/order.dart';

class OrderService {
  OrderService({required this.apiClient});

  final ApiClient apiClient;

  Future<Order> submitOrder() async {
    final response = await apiClient.post(
      ApiEndpoints.orderSubmit,
      requiresAuth: true,
    );

    if (response is! Map<String, dynamic>) {
      throw ApiException('پاسخ ثبت سفارش نامعتبر است.');
    }

    return Order.fromJson(response);
  }

  Future<List<Order>> getMyOrders() async {
    final response = await apiClient.get(
      ApiEndpoints.myOrders,
      requiresAuth: true,
    );

    if (response is! Map<String, dynamic>) {
      throw ApiException('پاسخ سفارش‌ها نامعتبر است.');
    }

    final results = response['results'];

    if (results is! List) {
      throw ApiException('لیست سفارش‌ها نامعتبر است.');
    }

    return results
        .map((item) => Order.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }
}
