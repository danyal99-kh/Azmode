import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../Core/api/api_client.dart';
import '../model.dart';
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

  static const String _stockAdjustPath = '/api/warehouse/stock/adjust/';
  static const String _stockHistoryPath = '/api/warehouse/stock/history/';

  /// ثبت تغییر موجودی در Backend.
  ///
  /// [productId] شناسه محصول، [change] مقدار تغییر (مثبت یا منفی)،
  /// [reason] دلیل تغییر. در صورت موفقیت، تاریخچه به‌روزرسانی‌شده برمی‌گردد.
  Future<List<StockMovement>> adjustStock({
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
        _stockAdjustPath,
        body: {
          'product_id': productId,
          'quantity_change': change,
          'reason': reason,
        },
        requiresAuth: true,
      );

      // Backend می‌تواند یکی از دو قالب را برگرداند:
      // ۱) لیست تاریخچه کامل
      // ۲) فقط رکورد جدید
      if (decoded is List) {
        return decoded
            .whereType<Map>()
            .map((item) => _stockMovementFromJson(Map<String, dynamic>.from(item)))
            .toList();
      }

      if (decoded is Map<String, dynamic>) {
        final results = decoded['results'];
        if (results is List) {
          return results
              .whereType<Map>()
              .map((item) => _stockMovementFromJson(Map<String, dynamic>.from(item)))
              .toList();
        }
        // رکورد تکی جدید
        return [_stockMovementFromJson(decoded)];
      }

      throw const DataException(
        DataErrorKind.unknown,
        'Invalid stock adjust response.',
      );
    } on ApiException catch (e) {
      throw DataException(_mapErrorKind(e), e.message);
    }
  }

  /// دریافت تاریخچه تغییرات موجودی از Backend.
  Future<List<StockMovement>> fetchStockHistory({String? productId}) async {
    final apiClient = _apiClient;
    if (apiClient != null) {
      return _fetchStockHistoryViaApiClient(apiClient, productId);
    }
    return _fetchStockHistoryViaHttpClient(productId);
  }

  Future<List<StockMovement>> _fetchStockHistoryViaApiClient(
    ApiClient apiClient,
    String? productId,
  ) async {
    try {
      final endpoint = productId != null && productId.isNotEmpty
          ? '$_stockHistoryPath?product_id=$productId'
          : _stockHistoryPath;

      final decoded = await apiClient.get(
        endpoint,
        requiresAuth: true,
      );

      return _parseStockHistoryResponse(decoded);
    } on ApiException catch (e) {
      throw DataException(_mapErrorKind(e), e.message);
    }
  }

  Future<List<StockMovement>> _fetchStockHistoryViaHttpClient(
    String? productId,
  ) async {
    try {
      final uri = productId != null && productId.isNotEmpty
          ? Uri.parse(baseUrl).resolve(_stockHistoryPath).replace(
              queryParameters: {'product_id': productId},
            )
          : Uri.parse(baseUrl).resolve(_stockHistoryPath);

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

      return _parseStockHistoryResponse(decoded);
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

  List<StockMovement> _parseStockHistoryResponse(dynamic decoded) {
    if (decoded is List) {
      return decoded
          .whereType<Map>()
          .map((item) => _stockMovementFromJson(Map<String, dynamic>.from(item)))
          .toList();
    }

    if (decoded is Map<String, dynamic>) {
      final results = decoded['results'];

      if (results is List) {
        return results
            .whereType<Map>()
            .map((item) => _stockMovementFromJson(Map<String, dynamic>.from(item)))
            .toList();
      }
    }

    throw const DataException(
      DataErrorKind.unknown,
      'Unsupported stock history response format.',
    );
  }

  StockMovement _stockMovementFromJson(Map<String, dynamic> json) {
    return StockMovement(
      id: json['id']?.toString() ?? '',
      productId: json['product_id']?.toString() ?? '',
      quantityChange: _toInt(json['quantity_change']),
      date: _parseDateTime(json['date']),
      reason: json['reason']?.toString() ?? '',
    );
  }

  int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  DateTime _parseDateTime(dynamic value) {
    if (value == null) {
      return DateTime.now();
    }

    final parsed = DateTime.tryParse(value.toString());

    return parsed ?? DateTime.now();
  }
}
