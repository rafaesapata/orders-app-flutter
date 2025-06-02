import 'package:flutter/foundation.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/api_client.dart';
import '../../data/models/user.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final ApiClient _apiClient = ApiClient();

  User? _user;
  bool _isLoading = false;
  String? _error;
  bool _isAuthenticated = false;

  // Getters
  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _isAuthenticated;

  AuthProvider() {
    _initialize();
  }

  /// Inicializa o provider verificando se há usuário logado
  Future<void> _initialize() async {
    _apiClient.initialize();
    await _checkAuthStatus();
  }

  /// Verifica o status de autenticação
  Future<void> _checkAuthStatus() async {
    try {
      _isAuthenticated = await _authService.isAuthenticated();
      if (_isAuthenticated) {
        _user = await _authService.getCurrentUser();
      }
    } catch (e) {
      _isAuthenticated = false;
      _user = null;
    }
    notifyListeners();
  }

  /// Realiza login
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _authService.login(email, password);
      
      if (response.success && response.user != null) {
        _user = response.user;
        _isAuthenticated = true;
        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        _setError(response.error ?? 'Erro de autenticação');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Erro de conexão: $e');
      _setLoading(false);
      return false;
    }
  }

  /// Realiza logout
  Future<void> logout() async {
    _setLoading(true);

    try {
      await _authService.logout();
    } catch (e) {
      // Ignora erros de logout
    } finally {
      _user = null;
      _isAuthenticated = false;
      _setLoading(false);
      notifyListeners();
    }
  }

  /// Atualiza o token de acesso
  Future<bool> refreshToken() async {
    try {
      final success = await _authService.refreshToken();
      if (!success) {
        await logout();
      }
      return success;
    } catch (e) {
      await logout();
      return false;
    }
  }

  /// Atualiza informações do usuário
  Future<void> updateUserProfile({
    String? name,
    String? email,
  }) async {
    if (_user == null) return;

    _setLoading(true);

    try {
      // Aqui você pode implementar a chamada para atualizar o perfil na API
      // Por enquanto, apenas atualiza localmente
      _user = _user!.copyWith(
        name: name ?? _user!.name,
        email: email ?? _user!.email,
      );
      
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError('Erro ao atualizar perfil: $e');
      _setLoading(false);
    }
  }

  /// Verifica se o email está verificado
  Future<bool> checkEmailVerification() async {
    try {
      // Implementar verificação de email se necessário
      return _user?.isEmailVerified ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Solicita redefinição de senha
  Future<bool> requestPasswordReset(String email) async {
    _setLoading(true);
    _clearError();

    try {
      // Implementar solicitação de redefinição de senha
      // Por enquanto, simula sucesso
      await Future.delayed(const Duration(seconds: 2));
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Erro ao solicitar redefinição de senha: $e');
      _setLoading(false);
      return false;
    }
  }

  /// Altera a senha
  Future<bool> changePassword(String currentPassword, String newPassword) async {
    _setLoading(true);
    _clearError();

    try {
      // Implementar alteração de senha
      // Por enquanto, simula sucesso
      await Future.delayed(const Duration(seconds: 2));
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Erro ao alterar senha: $e');
      _setLoading(false);
      return false;
    }
  }

  /// Valida se o token ainda é válido
  Future<bool> validateToken() async {
    try {
      return await _authService.isAuthenticated();
    } catch (e) {
      return false;
    }
  }

  /// Define estado de carregamento
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Define erro
  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  /// Limpa erro
  void clearError() {
    _clearError();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  /// Limpa todos os dados
  void clear() {
    _user = null;
    _isAuthenticated = false;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _apiClient.dispose();
    super.dispose();
  }
}

