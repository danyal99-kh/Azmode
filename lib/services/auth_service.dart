import 'package:azmode/Core/api/api_client.dart';
import 'package:azmode/Core/api/api_endpoints.dart';
import 'package:azmode/Core/storage/token_storage.dart';


import '../models/user.dart';

class AuthService {
  AuthService({
    required this.apiClient,
    TokenStorage? tokenStorage,
  }) : tokenStorage = tokenStorage ?? TokenStorage.instance;

  final ApiClient apiClient;
  final TokenStorage tokenStorage;

  Future<User> login({
    required String username,
    required String password,
  }) async {
    final response = await apiClient.post(
      ApiEndpoints.login,
      body: {
        'username': username,
        'password': password,
      },
    );

    if (response is! Map<String, dynamic>) {
      throw ApiException(
        'پاسخ نامعتبر از سرور دریافت شد.',
      );
    }

    final accessToken = response['access']?.toString();
    final refreshToken = response['refresh']?.toString();

    if (accessToken == null || accessToken.isEmpty) {
      throw ApiException(
        'توکن ورود از سرور دریافت نشد.',
      );
    }

    await tokenStorage.saveTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );

    return getCurrentUser();
  }

  Future<User> getCurrentUser() async {
    final response = await apiClient.get(
      ApiEndpoints.me,
      requiresAuth: true,
    );

    if (response is! Map<String, dynamic>) {
      throw ApiException(
        'اطلاعات کاربر نامعتبر است.',
      );
    }

    return User.fromJson(response);
  }

  Future<void> logout() async {
    await tokenStorage.clearTokens();
  }

  Future<bool> isLoggedIn() async {
    return tokenStorage.hasAccessToken();
  }
}