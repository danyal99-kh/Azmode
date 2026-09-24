import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(
    this.message, {
    this.statusCode,
  });

  @override
  String toString() {
    return message;
  }
}

class ApiClient {
  ApiClient({
    required this.baseUrl,
  });

  final String baseUrl;

  Future<dynamic> get(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    return _request(
      method: 'GET',
      endpoint: endpoint,
      headers: headers,
    );
  }

  Future<dynamic> post(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    return _request(
      method: 'POST',
      endpoint: endpoint,
      body: body,
      headers: headers,
    );
  }

  Future<dynamic> put(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    return _request(
      method: 'PUT',
      endpoint: endpoint,
      body: body,
      headers: headers,
    );
  }

  Future<dynamic> patch(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    return _request(
      method: 'PATCH',
      endpoint: endpoint,
      body: body,
      headers: headers,
    );
  }

  Future<dynamic> delete(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    return _request(
      method: 'DELETE',
      endpoint: endpoint,
      headers: headers,
    );
  }

  Future<dynamic> _request({
    required String method,
    required String endpoint,
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');

    final requestHeaders = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      ...?headers,
    };

    try {
      late http.Response response;

      switch (method) {
        case 'GET':
          response = await http.get(
            uri,
            headers: requestHeaders,
          );
          break;

        case 'POST':
          response = await http.post(
            uri,
            headers: requestHeaders,
            body: body == null ? null : jsonEncode(body),
          );
          break;

        case 'PUT':
          response = await http.put(
            uri,
            headers: requestHeaders,
            body: body == null ? null : jsonEncode(body),
          );
          break;

        case 'PATCH':
          response = await http.patch(
            uri,
            headers: requestHeaders,
            body: body == null ? null : jsonEncode(body),
          );
          break;

        case 'DELETE':
          response = await http.delete(
            uri,
            headers: requestHeaders,
          );
          break;

        default:
          throw ApiException(
            'HTTP method is not supported: $method',
          );
      }

      return _handleResponse(response);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        'خطا در برقراری ارتباط با سرور',
      );
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
      _extractErrorMessage(data, statusCode),
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