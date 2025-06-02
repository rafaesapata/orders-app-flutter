import 'package:flutter/foundation.dart';

import '../../core/services/auth_service.dart';
import '../../data/models/auth.dart';
import '../../data/models/user.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  AuthState _state = const AuthState();

  AuthState get state => _state;
  User? get user => _state.user;
  bool get isAuthenticated => _state.isAuthenticated;
  bool get isLoading => _state.isLoading;
  String? get error => _state.error;

  AuthProvider() {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    _updateState(_state.copyWith(isLoading: true));

    try {
      final isAuth = await _authService.isAuthenticated();
      if (isAuth) {
        final user = await _authService.getCurrentUser();
        final token = await _authService.getToken();

        if (user != null && token != null) {
          _updateState(AuthState(
            user: user,
            token: token,
            isAuthenticated: true,
            isLoading: false,
          ));
          return;
        }
      }

      _updateState(const AuthState(isLoading: false));
    } catch (e) {
      _updateState(AuthState(
        isLoading: false,
        error: 'Erro ao verificar autenticação: ${e.toString()}',
      ));
    }
  }

  Future<bool> login(String email, String password) async {
    _updateState(_state.copyWith(isLoading: true, error: null));

    try {
      // Validação básica
      if (email.isEmpty || password.isEmpty) {
        throw Exception('Email e senha são obrigatórios');
      }

      if (!_isValidEmail(email)) {
        throw Exception('Email inválido');
      }

      final response = await _authService.login(email, password);

      _updateState(AuthState(
        user: response.user,
        token: response.token,
        isAuthenticated: true,
        isLoading: false,
      ));

      return true;
    } catch (e) {
      _updateState(AuthState(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      ));
      return false;
    }
  }

  Future<void> logout() async {
    _updateState(_state.copyWith(isLoading: true));

    try {
      await _authService.logout();
      _updateState(const AuthState(isLoading: false));
    } catch (e) {
      _updateState(AuthState(
        isLoading: false,
        error: 'Erro ao fazer logout: ${e.toString()}',
      ));
    }
  }

  Future<bool> refreshToken() async {
    try {
      final response = await _authService.refreshToken();
      if (response != null) {
        _updateState(AuthState(
          user: response.user,
          token: response.token,
          isAuthenticated: true,
          isLoading: false,
        ));
        return true;
      }
      return false;
    } catch (e) {
      await logout();
      return false;
    }
  }

  void clearError() {
    if (_state.error != null) {
      _updateState(_state.copyWith(error: null));
    }
  }

  void _updateState(AuthState newState) {
    _state = newState;
    notifyListeners();
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
}
