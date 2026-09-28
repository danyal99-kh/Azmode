import 'dart:convert';

import 'package:http/http.dart' as http;

import '../Core/api/api_client.dart';
import '../Core/api/api_endpoints.dart';
import 'paged_result.dart';

class ApiWarehouseRepository {
  ApiWarehouseRepository({
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

  /// ثبت تغییر موجودی در Backend.
  ///
  /// [productId] شناسه محصول، [change] مقدار تغییر (مثبت یا منفی)،
  /// [reason] دلیل تغییر. در صورت موفقیت، مقدار new_stock برمی‌گردد.
  Future<int> adjustStock({
    required String productId,
    required int change,
    required String reason,
  }) async {
    final apiClient = _apiClient;
    if (apiClient == null) {
      throw StateError('ApiClient is not configured for WarehouseRepository');
    }

    try {
      final decoded = await apiClient.post(
        ApiEndpoints.stockAdjust(productId),
        body: {
          'quantity_change': change,
          'reason': reason,
        },
        requiresAuth: true,
      );

      if (decoded is Map<String, dynamic>) {
        final newStock = decoded['new_stock'];
        if (newStock is int) {
          return newStock;
        }
        if (newStock is num) {
          return newStock.toInt();
        }
      }

      throw const FormatException('Invalid stock adjust response.');
    } on ApiException {
      rethrow;
    } catch (e) {
      if (e is FormatException) rethrow;
      throw DataException(DataErrorKind.unknown, e.toString());
    }
  }
}
