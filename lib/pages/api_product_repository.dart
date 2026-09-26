// ignore_for_file: unused_element

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../Core/api/api_client.dart';
import '../model.dart';
import 'paged_result.dart';
import 'product_image.dart';
import 'product_query.dart';
import 'product_repository.dart';

class ApiProductRepository implements ProductRepository {
  ApiProductRepository({
    required this.baseUrl,
    http.Client? client,
    this.accessToken,
    ApiClient? apiClient,
  }) : _client = client ?? http.Client(),
       _apiClient = apiClient;

  /// مثال:
  /// http://192.168.1.100:8000
  ///
  /// نباید /api/products/ داشته باشد.
  final String baseUrl;

  final String? accessToken;

  final http.Client _client;

  /// ApiClient اختیاری برای عملیات multipart.
  /// اگر null باشد، از http.Client مستقیم استفاده می‌شود (fallback).
  final ApiClient? _apiClient;

  static const String _productsPath = '/api/products/';

  @override
  Future<PagedResult<Product>> fetchProducts(
    ProductQuery query,
    PageRequest request,
  ) async {
    try {
      final params = <String, String>{
        'page': request.page.toString(),
        'page_size': request.pageSize.toString(),
      };

      // توجه:
      // Backend فعلی DRF شما SearchFilter دارد و پارامتر درست search است،
      // نه q.
      if (query.search.trim().isNotEmpty) {
        params['search'] = query.search.trim();
      }

      if (query.categoryId != null && query.categoryId!.trim().isNotEmpty) {
        params['category'] = query.categoryId!;
      }

      final uri = Uri.parse(
        baseUrl,
      ).resolve(_productsPath).replace(queryParameters: params);

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

      return _parsePagedResponse(decoded);
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
  Future<Product?> fetchProduct(String id) async {
    try {
      final uri = Uri.parse(baseUrl).resolve('$_productsPath$id/');

      final response = await _client
          .get(uri, headers: _headers())
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 404) {
        return null;
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw DataException(
          DataErrorKind.server,
          'GET $uri -> ${response.statusCode}: ${response.body}',
        );
      }

      final decoded = jsonDecode(response.body);

      if (decoded is! Map<String, dynamic>) {
        throw const DataException(
          DataErrorKind.unknown,
          'Invalid product response.',
        );
      }

      return _productFromJson(decoded);
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
  Future<Product> createProduct(Product product) async {
    final fields = _productToFields(product);
    final files = _buildImageFiles(product);

    final decoded = await _executeMultipart(
      'POST',
      _productsPath,
      fields: fields,
      files: files,
    );

    if (decoded is! Map<String, dynamic>) {
      throw const DataException(
        DataErrorKind.unknown,
        'Invalid product response.',
      );
    }

    return _productFromJson(decoded);
  }

  /// ساخت لیست فایل‌های multipart از تصویر محصول.
  ///
  /// - اگر تصویر base64 معتبر باشد → فایل ساخته می‌شود.
  /// - اگر data URI (`data:image/...;base64,...`) باشد → prefix حذف و decode می‌شود.
  /// - اگر تصویر URL یا asset باشد → فایلی ساخته نمی‌شود (سرور فیلد image را
  ///   خالی می‌گذارد و تصویر قبلی حفظ می‌شود).
  List<http.MultipartFile> _buildImageFiles(Product product) {
    final files = <http.MultipartFile>[];

    if (product.imageSource != ProductImageSource.base64) {
      return files;
    }

    final raw = product.imageUrl.trim();
    if (raw.isEmpty) return files;

    // Handle data URI: data:image/png;base64,iVBORw0KGgo...
    String base64Data = raw;
    if (raw.startsWith('data:')) {
      final commaIndex = raw.indexOf(',');
      if (commaIndex == -1) return files;
      final header = raw.substring(0, commaIndex);
      if (!header.contains('base64')) return files;
      base64Data = raw.substring(commaIndex + 1);
    }

    try {
      final bytes = base64Decode(base64Data);
      if (bytes.isEmpty) return files;

      // Detect extension from data URI or default to .jpg
      String ext = 'jpg';
      if (raw.startsWith('data:image/')) {
        final mimeMatch = RegExp(r'data:image/(\w+);').firstMatch(raw);
        if (mimeMatch != null) {
          ext = mimeMatch.group(1) ?? 'jpg';
          if (ext == 'jpeg') ext = 'jpg';
        }
      }

      files.add(http.MultipartFile.fromBytes(
        'image',
        bytes,
        filename: 'product_${product.id}.$ext',
      ));
    } catch (_) {}

    return files;
  }

  /// اجرای درخواست multipart از طریق ApiClient یا fallback به http.Client.
  Future<dynamic> _executeMultipart(
    String method,
    String path, {
    required Map<String, String> fields,
    required List<http.MultipartFile> files,
  }) async {
    final apiClient = _apiClient;
    if (apiClient != null) {
      // Use ApiClient (handles auth, refresh, errors consistently)
      if (method == 'POST') {
        return apiClient.postMultipart(
          path,
          fields: fields,
          files: files,
          requiresAuth: true,
        );
      } else {
        return apiClient.patchMultipart(
          path,
          fields: fields,
          files: files,
          requiresAuth: true,
        );
      }
    }

    // Fallback: use http.Client directly (for backward compatibility)
    final uri = Uri.parse(baseUrl).resolve(path);

    try {
      final request = http.MultipartRequest(method, uri);
      request.headers.addAll(_headers());
      request.fields.addAll(fields);
      request.files.addAll(files);

      final streamedResponse = await request.send().timeout(
            const Duration(seconds: 30),
          );
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw DataException(
          DataErrorKind.server,
          '$method $uri -> ${response.statusCode}: ${response.body}',
        );
      }

      return jsonDecode(response.body);
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
  Future<Product> updateProduct(String id, Product product) async {
    final fields = _productToFields(product);
    final files = _buildImageFiles(product);

    final decoded = await _executeMultipart(
      'PATCH',
      '$_productsPath$id/',
      fields: fields,
      files: files,
    );

    if (decoded is! Map<String, dynamic>) {
      throw const DataException(
        DataErrorKind.unknown,
        'Invalid product response.',
      );
    }

    return _productFromJson(decoded);
  }

  @override
  Future<void> deleteProduct(String id) async {
    try {
      final uri = Uri.parse(baseUrl).resolve('$_productsPath$id/');

      final response = await _client
          .delete(uri, headers: _headers())
          .timeout(const Duration(seconds: 15));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw DataException(
          DataErrorKind.server,
          'DELETE $uri -> ${response.statusCode}: ${response.body}',
        );
      }
    } on SocketException catch (e) {
      throw DataException(DataErrorKind.network, e.message);
    } on HttpException catch (e) {
      throw DataException(DataErrorKind.network, e.message);
    } on DataException {
      rethrow;
    } catch (e) {
      throw DataException(DataErrorKind.unknown, e.toString());
    }
  }

  @override
  void invalidate() {
    // Repository خودش Cache ندارد.
    // CachedProductRepository بیرونی این کار را انجام می‌دهد.
  }

  Map<String, String> _productToFields(Product product) {
    final fields = <String, String>{
      'name': product.name,
      'price': product.price.toString(),
      'description': product.description,
      'category': product.categoryId,
      'image_aspect_ratio': product.imageAspectRatio.name,
    };

    // color در Backend یک JSONField با لیست رنگ‌ها است.
    // اگر colors خالی نباشد، به‌صورت JSON Array ارسال می‌شود.
    if (product.colors.isNotEmpty) {
      fields['color'] = jsonEncode(product.colors);
    }
    if (product.size != null && product.size!.isNotEmpty) {
      fields['size'] = product.size!;
    }
    if (product.brand != null && product.brand!.isNotEmpty) {
      fields['brand'] = product.brand!;
    }
    if (product.sku != null && product.sku!.isNotEmpty) {
      fields['sku'] = product.sku!;
    }
    if (product.specifications != null &&
        product.specifications!.isNotEmpty) {
      fields['specifications'] = product.specifications!;
    }
    if (product.packagingType != null &&
        product.packagingType!.id.isNotEmpty) {
      fields['packaging_type'] = product.packagingType!.id;
    }

    return fields;
  }

  Map<String, String> _headers() {
    final headers = <String, String>{'Accept': 'application/json'};

    if (accessToken != null && accessToken!.trim().isNotEmpty) {
      headers['Authorization'] = 'Bearer ${accessToken!.trim()}';
    }

    return headers;
  }

  PagedResult<Product> _parsePagedResponse(dynamic decoded) {
    // اگر Backend بدون Pagination لیست ساده برگرداند:
    //
    // [
    //   {...},
    //   {...}
    // ]
    if (decoded is List) {
      final products = decoded
          .whereType<Map>()
          .map((item) => _productFromJson(Map<String, dynamic>.from(item)))
          .toList();

      return PagedResult<Product>(
        items: products,
        hasMore: false,
        total: products.length,
      );
    }

    // Django REST Framework PageNumberPagination:
    //
    // {
    //   "count": 100,
    //   "next": "...",
    //   "previous": null,
    //   "results": [...]
    // }
    if (decoded is Map<String, dynamic>) {
      final results = decoded['results'];

      if (results is List) {
        final products = results
            .whereType<Map>()
            .map((item) => _productFromJson(Map<String, dynamic>.from(item)))
            .toList();

        return PagedResult<Product>(
          items: products,
          hasMore: decoded['next'] != null,
          total: _toInt(decoded['count']),
        );
      }
    }

    throw const DataException(
      DataErrorKind.unknown,
      'Unsupported products response format.',
    );
  }

  Product _productFromJson(Map<String, dynamic> json) {
    final id = _toString(json['id']);

    final categoryId = _toString(json['category']);

    final image = _absoluteUrl(_toNullableString(json['image']));

    final rawColors = json['color'];

    final colors = <String>[];

    if (rawColors is List) {
      for (final value in rawColors) {
        final stringValue = value?.toString().trim();

        if (stringValue != null && stringValue.isNotEmpty) {
          colors.add(stringValue);
        }
      }
    } else if (rawColors is String && rawColors.trim().isNotEmpty) {
      colors.add(rawColors.trim());
    }

    final primaryColor = colors.isNotEmpty ? colors.first : null;

    return Product(
      id: id,
      name: _toString(json['name']),
      categoryId: categoryId,
      price: _toDouble(json['price']),
      description: _toString(json['description']),
      imageUrl: image,
      colors: colors,
      color: primaryColor,
      size: _toNullableString(json['size']),
      brand: _toNullableString(json['brand']),
      sku: _toNullableString(json['sku']),
      specifications: _toNullableString(json['specifications']),
      packagingType: _packagingTypeFromJson(json),
      stock: _toInt(json['stock']),
      isAvailable: true,
      imageAspectRatio: imageAspectRatioFromKey(
        _toNullableString(json['image_aspect_ratio']),
      ),
      imageSource: detectImageSource(image),
      createdAt: _parseDateTime(json['created_at']),
    );
  }

  String _packagingTypeName(Map<String, dynamic> json) {
    // اگر بعداً Backend به‌جای ID نام را برگرداند،
    // همین Mapper هر دو حالت را پشتیبانی می‌کند.

    final name = json['packaging_type_name'];

    if (name != null) {
      final value = name.toString().trim();

      if (value.isNotEmpty) {
        return value;
      }
    }

    final id = json['packaging_type'];

    if (id == null) {
      return '';
    }

    return id.toString();
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

  int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  double _toDouble(dynamic value) {
    if (value is double) {
      return value;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  DateTime _parseDateTime(dynamic value) {
    if (value == null) {
      return DateTime.now();
    }

    final parsed = DateTime.tryParse(value.toString());

    return parsed ?? DateTime.now();
  }

  PackagingType? _packagingTypeFromJson(Map<String, dynamic> json) {
    final id = json['packaging_type'];

    if (id == null) {
      return null;
    }

    final name = json['packaging_type_name'];

    return PackagingType(id: id.toString(), name: name?.toString() ?? '');
  }
}
