// ignore_for_file: unused_element

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

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
  }) : _client = client ?? http.Client();

  /// مثال:
  /// http://192.168.1.100:8000
  ///
  /// نباید /api/products/ داشته باشد.
  final String baseUrl;

  final String? accessToken;

  final http.Client _client;

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
  void invalidate() {
    // Repository خودش Cache ندارد.
    // CachedProductRepository بیرونی این کار را انجام می‌دهد.
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
