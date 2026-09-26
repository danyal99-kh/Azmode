import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../Core/api/api_client.dart';
import '../model.dart';
import 'category_repository.dart';
import 'paged_result.dart';

class ApiCategoryRepository implements CategoryRepository {
  ApiCategoryRepository({
    required this.baseUrl,
    http.Client? client,
    this.accessToken,
    ApiClient? apiClient,
  }) : _client = client ?? http.Client(),
       _apiClient = apiClient;

  final String baseUrl;
  final String? accessToken;
  final http.Client _client;

  /// ApiClient برای عملیات CRUD (handles auth, refresh, errors).
  final ApiClient? _apiClient;

  static const String _categoriesPath = '/api/categories/';

  @override
  Future<List<ProductCategory>> fetchCategories() async {
    final apiClient = _apiClient;
    if (apiClient != null) {
      return _fetchCategoriesViaApiClient(apiClient);
    }
    return _fetchCategoriesViaHttpClient();
  }

  Future<List<ProductCategory>> _fetchCategoriesViaApiClient(
    ApiClient apiClient,
  ) async {
    try {
      final decoded = await apiClient.get(
        _categoriesPath,
        requiresAuth: false,
      );
      return _parseCategoriesResponse(decoded);
    } on ApiException catch (e) {
      throw DataException(_mapErrorKind(e), e.message);
    }
  }

  Future<List<ProductCategory>> _fetchCategoriesViaHttpClient() async {
    try {
      final uri = Uri.parse(baseUrl).resolve(_categoriesPath);

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

      return _parseCategoriesResponse(decoded);
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
  Future<ProductCategory> createCategory(String name) async {
    final apiClient = _apiClient;
    if (apiClient == null) {
      throw StateError('ApiClient is not configured for CategoryRepository');
    }

    try {
      final decoded = await apiClient.post(
        _categoriesPath,
        body: {'name': name},
        requiresAuth: true,
      );

      if (decoded is! Map<String, dynamic>) {
        throw const DataException(
          DataErrorKind.unknown,
          'Invalid category response.',
        );
      }

      return _categoryFromJson(decoded);
    } on ApiException catch (e) {
      throw DataException(_mapErrorKind(e), e.message);
    }
  }

  @override
  Future<ProductCategory> updateCategory(String id, String newName) async {
    final apiClient = _apiClient;
    if (apiClient == null) {
      throw StateError('ApiClient is not configured for CategoryRepository');
    }

    try {
      final decoded = await apiClient.patch(
        '$_categoriesPath$id/',
        body: {'name': newName},
        requiresAuth: true,
      );

      if (decoded is! Map<String, dynamic>) {
        throw const DataException(
          DataErrorKind.unknown,
          'Invalid category response.',
        );
      }

      return _categoryFromJson(decoded);
    } on ApiException catch (e) {
      throw DataException(_mapErrorKind(e), e.message);
    }
  }

  @override
  Future<void> deleteCategory(String id) async {
    final apiClient = _apiClient;
    if (apiClient == null) {
      throw StateError('ApiClient is not configured for CategoryRepository');
    }

    try {
      await apiClient.delete(
        '$_categoriesPath$id/',
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

  List<ProductCategory> _parseCategoriesResponse(dynamic decoded) {
    if (decoded is List) {
      return decoded
          .whereType<Map>()
          .map((item) => _categoryFromJson(Map<String, dynamic>.from(item)))
          .toList();
    }

    if (decoded is Map<String, dynamic>) {
      final results = decoded['results'];

      if (results is List) {
        return results
            .whereType<Map>()
            .map((item) => _categoryFromJson(Map<String, dynamic>.from(item)))
            .toList();
      }
    }

    throw const DataException(
      DataErrorKind.unknown,
      'Unsupported categories response format.',
    );
  }

  ProductCategory _categoryFromJson(Map<String, dynamic> json) {
    return ProductCategory(
      id: _toString(json['id']),
      name: _toString(json['name']),
      imageUrl: _toNullableString(json['image']),
    );
  }

  String _toString(dynamic value) {
    return value?.toString() ?? '';
  }

  String? _toNullableString(dynamic value) {
    final valueString = value?.toString().trim();

    if (valueString == null || valueString.isEmpty) {
      return null;
    }

    return valueString;
  }
}
