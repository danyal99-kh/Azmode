import 'package:flutter/foundation.dart';

import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  AuthProvider({
    required AuthService authService,
    required ProfileService profileService,
  }) : _authService = authService,
       _profileService = profileService;

  final AuthService _authService;
  final ProfileService _profileService;

  AuthStatus _status = AuthStatus.initial;
  User? _user;
  String? _errorMessage;

  AuthStatus get status => _status;
  User? get user => _user;
  String? get errorMessage => _errorMessage;

  bool get isLoading => _status == AuthStatus.loading;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isUnauthenticated => _status == AuthStatus.unauthenticated;
  bool get isAdmin => _user?.isAdmin == true;

  Future<void> checkAuthStatus() async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final loggedIn = await _authService.isLoggedIn();
      if (!loggedIn) {
        _user = null;
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return;
      }
      _user = await _authService.getCurrentUser();
      _status = AuthStatus.authenticated;
      notifyListeners();
    } catch (e) {
      _user = null;
      _status = AuthStatus.unauthenticated;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<bool> login({
    required String username,
    required String password,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      _user = await _authService.login(username: username, password: password);
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _user = null;
      _status = AuthStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _status = AuthStatus.loading;
    notifyListeners();
    try {
      await _authService.logout();
    } finally {
      _user = null;
      _errorMessage = null;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    if (_status == AuthStatus.error) {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  /// ویرایش پروفایل کاربر لاگین‌شده — منتقل‌شده از StoreProvider.
  Future<String?> updateProfile({
    required String fullName,
    required String phone,
  }) async {
    if (_user == null) return 'کاربری وارد نشده است.';
    try {
      _user = await _profileService.updateProfile(
        fullName: fullName,
        phone: phone,
      );
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  /// ایجاد کاربر جدید توسط ادمین — منتقل‌شده از StoreProvider.addUser.
  Future<String?> createUser({
    required String username,
    required String password,
    required String fullName,
    required String phone,
    bool isAdmin = false,
  }) async {
    try {
      await _profileService.createUser(
        username: username,
        password: password,
        fullName: fullName,
        phone: phone,
        isAdmin: isAdmin,
      );
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}
