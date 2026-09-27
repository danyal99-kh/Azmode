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
  Future<ProductCategory> createCategory(String name, {String? imageBase64}) async {
    final apiClient = _apiClient;
    if (apiClient == null) {
      throw StateError('ApiClient is not configured for CategoryRepository');
    }

    try {
      final fields = <String, String>{'name': name};
      final files = _buildImageFiles(imageBase64);

      final decoded = await apiClient.postMultipart(
        _categoriesPath,
        fields: fields,
        files: files,
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
  Future<ProductCategory> updateCategory(
    String id,
    String newName, {
    String? imageBase64,
    bool clearImage = false,
  }) async {
    final apiClient = _apiClient;
    if (apiClient == null) {
      throw StateError('ApiClient is not configured for CategoryRepository');
    }

    try {
      final fields = <String, String>{'name': newName};
      if (clearImage) {
        fields['image'] = '';
      }
      final files = _buildImageFiles(imageBase64);

      final decoded = await apiClient.patchMultipart(
        '$_categoriesPath$id/',
        fields: fields,
        files: files,
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

  List<http.MultipartFile> _buildImageFiles(String? imageBase64) {
    final files = <http.MultipartFile>[];

    if (imageBase64 == null || imageBase64.trim().isEmpty) {
      return files;
    }

    String base64Data = imageBase64.trim();
    if (base64Data.startsWith('data:')) {
      final commaIndex = base64Data.indexOf(',');
      if (commaIndex == -1) return files;
      final header = base64Data.substring(0, commaIndex);
      if (!header.contains('base64')) return files;
      base64Data = base64Data.substring(commaIndex + 1);
    }

    try {
      final bytes = base64Decode(base64Data);
      if (bytes.isEmpty) return files;

      String ext = 'jpg';
      if (imageBase64.startsWith('data:image/')) {
        final mimeMatch = RegExp(r'data:image/(\w+);').firstMatch(imageBase64);
        if (mimeMatch != null) {
          ext = mimeMatch.group(1) ?? 'jpg';
          if (ext == 'jpeg') ext = 'jpg';
        }
      }

      files.add(http.MultipartFile.fromBytes(
        'image',
        bytes,
        filename: 'category_image.$ext',
      ));
    } catch (_) {}

    return files;
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
      imageUrl: _absoluteUrl(_toNullableString(json['image'])),
    );
  }

  String _absoluteUrl(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '';
    }

    final trimmed = value.trim();

    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }

    final base = Uri.parse(baseUrl);

    if (trimmed.startsWith('/')) {
      return '${base.scheme}://${base.authority}$trimmed';
    }

    return '${base.scheme}://${base.authority}/$trimmed';
  }

  String _toString(dynamic value) {
    return value?.toString() ?? '';
  }

  String? _toNullableString(dynamic value) {
    if (value == null) {
      return null;
    }

    final stringValue = value.toString().trim();

    return stringValue.isEmpty ? null : stringValue;
  }
}
