import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../model.dart';
import 'packaging_type_repository.dart';
import 'paged_result.dart';

class ApiPackagingTypeRepository implements PackagingTypeRepository {
  ApiPackagingTypeRepository({
    required this.baseUrl,
    http.Client? client,
    this.accessToken,
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final String? accessToken;
  final http.Client _client;

  static const String _packagingTypesPath = '/api/packaging-types/';

  @override
  Future<List<PackagingType>> fetchPackagingTypes() async {
    try {
      final uri = Uri.parse(baseUrl).resolve(_packagingTypesPath);

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

      return _parsePackagingTypesResponse(decoded);
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

  Map<String, String> _headers() {
    final headers = <String, String>{'Accept': 'application/json'};

    if (accessToken != null && accessToken!.trim().isNotEmpty) {
      headers['Authorization'] = 'Bearer ${accessToken!.trim()}';
    }

    return headers;
  }

  List<PackagingType> _parsePackagingTypesResponse(dynamic decoded) {
    if (decoded is List) {
      return decoded
          .whereType<Map>()
          .map(
            (item) => _packagingTypeFromJson(Map<String, dynamic>.from(item)),
          )
          .toList();
    }

    if (decoded is Map<String, dynamic>) {
      final results = decoded['results'];

      if (results is List) {
        return results
            .whereType<Map>()
            .map(
              (item) => _packagingTypeFromJson(Map<String, dynamic>.from(item)),
            )
            .toList();
      }
    }

    throw const DataException(
      DataErrorKind.unknown,
      'Unsupported packaging types response format.',
    );
  }

  PackagingType _packagingTypeFromJson(Map<String, dynamic> json) {
    return PackagingType(
      id: _toString(json['id']),
      name: _toString(json['name']),
    );
  }

  String _toString(dynamic value) {
    return value?.toString() ?? '';
  }
}
