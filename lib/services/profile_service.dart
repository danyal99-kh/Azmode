import 'package:azmode/Core/api/api_client.dart';
import 'package:azmode/Core/api/api_endpoints.dart';

import '../models/user.dart';

class ProfileService {
  ProfileService({required this.apiClient});

  final ApiClient apiClient;

  Future<User> updateProfile({
    required String fullName,
    required String phone,
  }) async {
    final response = await apiClient.patch(
      ApiEndpoints.updateProfile,
      requiresAuth: true,
      body: {'full_name': fullName, 'phone': phone},
    );

    if (response is! Map<String, dynamic>) {
      throw ApiException('پاسخ نامعتبر از سرور دریافت شد.');
    }

    return User.fromJson(response);
  }

  Future<void> createUser({
    required String username,
    required String password,
    required String fullName,
    required String phone,
    bool isAdmin = false,
  }) async {
    await apiClient.post(
      ApiEndpoints.adminCreateUser,
      requiresAuth: true,
      body: {
        'username': username,
        'password': password,
        'full_name': fullName,
        'phone': phone,
        'is_admin': isAdmin,
      },
    );
  }
}
