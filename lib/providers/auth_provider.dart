import 'package:flutter/foundation.dart';

import '../models/user.dart';
import '../services/auth_service.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

class AuthProvider extends ChangeNotifier {
  AuthProvider({
    required AuthService authService,
  }) : _authService = authService;

  final AuthService _authService;

  AuthStatus _status = AuthStatus.initial;
  User? _user;
  String? _errorMessage;

  AuthStatus get status => _status;

  User? get user => _user;

  String? get errorMessage => _errorMessage;

  bool get isLoading => _status == AuthStatus.loading;

  bool get isAuthenticated =>
      _status == AuthStatus.authenticated;

  bool get isUnauthenticated =>
      _status == AuthStatus.unauthenticated;

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
      _user = await _authService.login(
        username: username,
        password: password,
      );

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
}