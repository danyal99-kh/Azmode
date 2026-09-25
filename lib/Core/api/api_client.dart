import 'dart:async';
import 'dart:convert';

import 'package:azmode/Core/storage/token_storage.dart';
import 'package:http/http.dart' as http;

import 'api_endpoints.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(
    this.message, {
    this.statusCode,
  });

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({
    required this.baseUrl,
    TokenStorage? tokenStorage,
  }) : _tokenStorage = tokenStorage ?? TokenStorage.instance;

  final String baseUrl;
  final TokenStorage _tokenStorage;

  bool _isRefreshing = false;

  Future<dynamic> get(
    String endpoint, {
    bool requiresAuth = false,
    Map<String, String>? headers,
  }) {
    return _request(
      method: 'GET',
      endpoint: endpoint,
      requiresAuth: requiresAuth,
      headers: headers,
    );
  }

  Future<dynamic> post(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = false,
    Map<String, String>? headers,
  }) {
    return _request(
      method: 'POST',
      endpoint: endpoint,
      body: body,
      requiresAuth: requiresAuth,
      headers: headers,
    );
  }

  Future<dynamic> put(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = false,
    Map<String, String>? headers,
  }) {
    return _request(
      method: 'PUT',
      endpoint: endpoint,
      body: body,
      requiresAuth: requiresAuth,
      headers: headers,
    );
  }

  Future<dynamic> patch(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = false,
    Map<String, String>? headers,
  }) {
    return _request(
      method: 'PATCH',
      endpoint: endpoint,
      body: body,
      requiresAuth: requiresAuth,
      headers: headers,
    );
  }

  Future<dynamic> delete(
    String endpoint, {
    bool requiresAuth = false,
    Map<String, String>? headers,
  }) {
    return _request(
      method: 'DELETE',
      endpoint: endpoint,
      requiresAuth: requiresAuth,
      headers: headers,
    );
  }

  Future<dynamic> _request({
    required String method,
    required String endpoint,
    Map<String, dynamic>? body,
    bool requiresAuth = false,
    Map<String, String>? headers,
    bool allowRefresh = true,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');

    final requestHeaders = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      ...?headers,
    };

    if (requiresAuth) {
      final accessToken = await _tokenStorage.getAccessToken();

      if (accessToken == null || accessToken.isEmpty) {
        throw ApiException(
          'برای انجام این درخواست باید وارد حساب شوید.',
          statusCode: 401,
        );
      }

      requestHeaders['Authorization'] =
          'Bearer $accessToken';
    }

    try {
      final response = await _sendRequest(
        method: method,
        uri: uri,
        headers: requestHeaders,
        body: body,
      );

      // Access Token منقضی شده
      if (response.statusCode == 401 &&
          requiresAuth &&
          allowRefresh) {
        final refreshed = await _refreshAccessToken();

        if (refreshed) {
          return _request(
            method: method,
            endpoint: endpoint,
            body: body,
            requiresAuth: requiresAuth,
            headers: headers,
            allowRefresh: false,
          );
        }

        await _tokenStorage.clearTokens();

        throw ApiException(
          'نشست شما منقضی شده است. لطفاً دوباره وارد شوید.',
          statusCode: 401,
        );
      }

      return _handleResponse(response);
    } on TimeoutException {
      throw ApiException(
        'زمان اتصال به سرور به پایان رسید.',
      );
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException(
        'خطا در برقراری ارتباط با سرور.',
      );
    }
  }

  Future<http.Response> _sendRequest({
    required String method,
    required Uri uri,
    required Map<String, String> headers,
    Map<String, dynamic>? body,
  }) async {
    final encodedBody =
        body == null ? null : jsonEncode(body);

    switch (method) {
      case 'GET':
        return http
            .get(
              uri,
              headers: headers,
            )
            .timeout(
              const Duration(seconds: 20),
            );

      case 'POST':
        return http
            .post(
              uri,
              headers: headers,
              body: encodedBody,
            )
            .timeout(
              const Duration(seconds: 20),
            );

      case 'PUT':
        return http
            .put(
              uri,
              headers: headers,
              body: encodedBody,
            )
            .timeout(
              const Duration(seconds: 20),
            );

      case 'PATCH':
        return http
            .patch(
              uri,
              headers: headers,
              body: encodedBody,
            )
            .timeout(
              const Duration(seconds: 20),
            );

      case 'DELETE':
        return http
            .delete(
              uri,
              headers: headers,
            )
            .timeout(
              const Duration(seconds: 20),
            );

      default:
        throw ApiException(
          'HTTP method is not supported: $method',
        );
    }
  }

  Future<bool> _refreshAccessToken() async {
    if (_isRefreshing) {
      return false;
    }

    _isRefreshing = true;

    try {
      final refreshToken =
          await _tokenStorage.getRefreshToken();

      if (refreshToken == null ||
          refreshToken.isEmpty) {
        return false;
      }

      final uri = Uri.parse(
        '$baseUrl${ApiEndpoints.refresh}',
      );

      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'refresh': refreshToken,
            }),
          )
          .timeout(
            const Duration(seconds: 20),
          );

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        return false;
      }

      final data = jsonDecode(response.body);

      if (data is! Map<String, dynamic>) {
        return false;
      }

      final newAccessToken =
          data['access']?.toString();

      if (newAccessToken == null ||
          newAccessToken.isEmpty) {
        return false;
      }

      await _tokenStorage.saveTokens(
        accessToken: newAccessToken,
        refreshToken: refreshToken,
      );

      return true;
    } catch (_) {
      return false;
    } finally {
      _isRefreshing = false;
    }
  }

  dynamic _handleResponse(http.Response response) {
    final statusCode = response.statusCode;

    dynamic data;

    if (response.body.isNotEmpty) {
      try {
        data = jsonDecode(response.body);
      } catch (_) {
        data = response.body;
      }
    }

    if (statusCode >= 200 && statusCode < 300) {
      return data;
    }

    throw ApiException(
      _extractErrorMessage(
        data,
        statusCode,
      ),
      statusCode: statusCode,
    );
  }

  String _extractErrorMessage(
    dynamic data,
    int statusCode,
  ) {
    if (data is Map<String, dynamic>) {
      if (data['detail'] != null) {
        return data['detail'].toString();
      }

      if (data['message'] != null) {
        return data['message'].toString();
      }

      if (data['error'] != null) {
        return data['error'].toString();
      }

      if (data.isNotEmpty) {
        return data.values
            .map((value) => value.toString())
            .join('\n');
      }
    }

    switch (statusCode) {
      case 400:
        return 'اطلاعات ارسال‌شده صحیح نیست.';

      case 401:
        return 'احراز هویت انجام نشده است.';

      case 403:
        return 'شما اجازه انجام این کار را ندارید.';

      case 404:
        return 'درخواست موردنظر پیدا نشد.';

      case 409:
        return 'این درخواست با وضعیت فعلی سازگار نیست.';

      case 422:
        return 'اطلاعات ارسال‌شده قابل پردازش نیست.';

      case 500:
        return 'خطای داخلی سرور رخ داده است.';

      default:
        return 'خطای سرور: $statusCode';
    }
  }
}