import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../Core/api/api_client.dart';
import '../Core/api/api_endpoints.dart';
import '../model.dart';
import 'paged_result.dart';
import 'product_image.dart';

class ApiBannerRepository {
  ApiBannerRepository({
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

  static const String _bannersPath = '/api/banners/';

  Future<List<PromoBanner>> fetchBanners() async {
    final apiClient = _apiClient;
    if (apiClient != null) {
      return _fetchBannersViaApiClient(apiClient);
    }
    return _fetchBannersViaHttpClient();
  }

  Future<List<PromoBanner>> _fetchBannersViaApiClient(
    ApiClient apiClient,
  ) async {
    try {
      final decoded = await apiClient.get(
        _bannersPath,
        requiresAuth: true,
      );
      return _parseBannersResponse(decoded);
    } on ApiException catch (e) {
      throw DataException(_mapErrorKind(e), e.message);
    }
  }

  Future<List<PromoBanner>> _fetchBannersViaHttpClient() async {
    try {
      final uri = Uri.parse(baseUrl).resolve(_bannersPath);

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

      return _parseBannersResponse(decoded);
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

  Future<PromoBanner> createBanner(PromoBanner banner) async {
    final apiClient = _apiClient;
    if (apiClient == null) {
      throw StateError('ApiClient is not configured for BannerRepository');
    }

    try {
      final fields = _bannerToFields(banner);
      final files = _buildImageFiles(banner);

      final decoded = await apiClient.postMultipart(
        _bannersPath,
        fields: fields,
        files: files,
        requiresAuth: true,
      );

      if (decoded is! Map<String, dynamic>) {
        throw const DataException(
          DataErrorKind.unknown,
          'Invalid banner response.',
        );
      }

      return _bannerFromJson(decoded);
    } on ApiException catch (e) {
      throw DataException(_mapErrorKind(e), e.message);
    }
  }

  Future<PromoBanner> updateBanner(String id, PromoBanner banner) async {
    final apiClient = _apiClient;
    if (apiClient == null) {
      throw StateError('ApiClient is not configured for BannerRepository');
    }

    try {
      final fields = _bannerToFields(banner);
      final files = _buildImageFiles(banner);

      final decoded = await apiClient.patchMultipart(
        '$_bannersPath$id/',
        fields: fields,
        files: files,
        requiresAuth: true,
      );

      if (decoded is! Map<String, dynamic>) {
        throw const DataException(
          DataErrorKind.unknown,
          'Invalid banner response.',
        );
      }

      return _bannerFromJson(decoded);
    } on ApiException catch (e) {
      throw DataException(_mapErrorKind(e), e.message);
    }
  }

  Future<void> deleteBanner(String id) async {
    final apiClient = _apiClient;
    if (apiClient == null) {
      throw StateError('ApiClient is not configured for BannerRepository');
    }

    try {
      await apiClient.delete(
        '$_bannersPath$id/',
        requiresAuth: true,
      );
    } on ApiException catch (e) {
      throw DataException(_mapErrorKind(e), e.message);
    }
  }

  Future<void> reorderBanner(String id, int newSortOrder) async {
    final apiClient = _apiClient;
    if (apiClient == null) {
      throw StateError('ApiClient is not configured for BannerRepository');
    }

    try {
      await apiClient.patch(
        '$_bannersPath$id/',
        body: {'sort_order': newSortOrder},
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

  List<PromoBanner> _parseBannersResponse(dynamic decoded) {
    if (decoded is List) {
      return decoded
          .whereType<Map>()
          .map((item) => _bannerFromJson(Map<String, dynamic>.from(item)))
          .toList();
    }

    if (decoded is Map<String, dynamic>) {
      final results = decoded['results'];

      if (results is List) {
        return results
            .whereType<Map>()
            .map((item) => _bannerFromJson(Map<String, dynamic>.from(item)))
            .toList();
      }
    }

    throw const DataException(
      DataErrorKind.unknown,
      'Unsupported banners response format.',
    );
  }

  PromoBanner _bannerFromJson(Map<String, dynamic> json) {
    return PromoBanner(
      id: _toString(json['id']),
      title: _toString(json['title']),
      subtitle: _toString(json['subtitle']),
      imageUrl: _absoluteUrl(_toNullableString(json['image'])),
      imageSource: detectImageSource(_absoluteUrl(_toNullableString(json['image']))),
      isActive: json['is_active'] == true,
      sortOrder: _toInt(json['sort_order']),
      startDate: _parseDateTime(json['start_date']),
      endDate: _parseDateTime(json['end_date']),
      targetType: bannerTargetTypeFromKey(_toNullableString(json['target_type'])),
      targetId: _toNullableString(json['target_id']),
      style: PromoBannerStyle.teal,
      description: '',
    );
  }

  Map<String, String> _bannerToFields(PromoBanner banner) {
    final fields = <String, String>{
      'title': banner.title,
      'subtitle': banner.subtitle,
      'is_active': banner.isActive.toString(),
      'sort_order': banner.sortOrder.toString(),
      'target_type': banner.targetType.name,
    };

    if (banner.targetId != null && banner.targetId!.isNotEmpty) {
      fields['target_id'] = banner.targetId!;
    }
    if (banner.startDate != null) {
      fields['start_date'] = banner.startDate!.toIso8601String();
    }
    if (banner.endDate != null) {
      fields['end_date'] = banner.endDate!.toIso8601String();
    }

    return fields;
  }

  List<http.MultipartFile> _buildImageFiles(PromoBanner banner) {
    final files = <http.MultipartFile>[];

    if (banner.imageSource != ProductImageSource.base64) {
      return files;
    }

    final raw = banner.imageUrl.trim();
    if (raw.isEmpty) return files;

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
        filename: 'banner_${banner.id}.$ext',
      ));
    } catch (_) {}

    return files;
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

  DateTime? _parseDateTime(dynamic value) {
    if (value == null) {
      return null;
    }

    final parsed = DateTime.tryParse(value.toString());

    return parsed;
  }
}
