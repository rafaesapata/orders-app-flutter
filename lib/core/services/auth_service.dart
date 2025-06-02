import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'api_client.dart';
import '../../data/models/user.dart';
import '../../data/models/auth.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final ApiClient _apiClient = ApiClient();
  static const String _tokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userKey = 'user_data';

  /// Realiza login usando AWS Cognito
  Future<LoginResponse> login(String email, String password) async {
    try {
      // Preparar dados para autenticação Cognito
      final authData = {
        'AuthFlow': 'USER_PASSWORD_AUTH',
        'ClientId': ApiConfig.userPoolWebClientId,
        'AuthParameters': {
          'USERNAME': email,
          'PASSWORD': password,
        },
      };

      // Fazer requisição para AWS Cognito
      final cognitoUrl = Uri.parse('https://cognito-idp.${ApiConfig.region}.amazonaws.com/');
      final response = await http.post(
        cognitoUrl,
        headers: {
          'Content-Type': 'application/x-amz-json-1.1',
          'X-Amz-Target': 'AWSCognitoIdentityProviderService.InitiateAuth',
        },
        body: jsonEncode(authData),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final authResult = data['AuthenticationResult'];
        
        if (authResult != null) {
          final accessToken = authResult['AccessToken'];
          final refreshToken = authResult['RefreshToken'];
          final idToken = authResult['IdToken'];
          
          // Decodificar o ID token para obter informações do usuário
          final user = _parseUserFromIdToken(idToken);
          
          // Salvar tokens
          await _saveTokens(accessToken, refreshToken);
          await _saveUser(user);
          
          // Configurar cliente API
          _apiClient.setAccessToken(accessToken);
          
          return LoginResponse(
            success: true,
            user: user,
            accessToken: accessToken,
            refreshToken: refreshToken,
          );
        }
      }
      
      // Tratar erros específicos do Cognito
      final errorData = jsonDecode(response.body);
      final errorType = errorData['__type'] ?? '';
      String errorMessage = 'Erro de autenticação';
      
      switch (errorType) {
        case 'NotAuthorizedException':
          errorMessage = 'Email ou senha incorretos';
          break;
        case 'UserNotConfirmedException':
          errorMessage = 'Usuário não confirmado. Verifique seu email';
          break;
        case 'UserNotFoundException':
          errorMessage = 'Usuário não encontrado';
          break;
        case 'TooManyRequestsException':
          errorMessage = 'Muitas tentativas. Tente novamente mais tarde';
          break;
        default:
          errorMessage = errorData['message'] ?? 'Erro de autenticação';
      }
      
      return LoginResponse(
        success: false,
        error: errorMessage,
      );
      
    } catch (e) {
      return LoginResponse(
        success: false,
        error: 'Erro de conexão: $e',
      );
    }
  }

  /// Atualiza o token usando refresh token
  Future<bool> refreshToken() async {
    try {
      final refreshToken = await _getRefreshToken();
      if (refreshToken == null) return false;

      final authData = {
        'AuthFlow': 'REFRESH_TOKEN_AUTH',
        'ClientId': ApiConfig.userPoolWebClientId,
        'AuthParameters': {
          'REFRESH_TOKEN': refreshToken,
        },
      };

      final cognitoUrl = Uri.parse('https://cognito-idp.${ApiConfig.region}.amazonaws.com/');
      final response = await http.post(
        cognitoUrl,
        headers: {
          'Content-Type': 'application/x-amz-json-1.1',
          'X-Amz-Target': 'AWSCognitoIdentityProviderService.InitiateAuth',
        },
        body: jsonEncode(authData),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final authResult = data['AuthenticationResult'];
        
        if (authResult != null) {
          final newAccessToken = authResult['AccessToken'];
          await _saveAccessToken(newAccessToken);
          _apiClient.setAccessToken(newAccessToken);
          return true;
        }
      }
      
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Obtém informações do usuário atual
  Future<User?> getCurrentUser() async {
    try {
      final userData = await _getSavedUser();
      if (userData != null) {
        return userData;
      }

      // Se não tem dados salvos, tenta buscar da API
      final token = await _getAccessToken();
      if (token != null) {
        _apiClient.setAccessToken(token);
        final response = await _apiClient.get(ApiConfig.userProfileEndpoint);
        final user = User.fromJson(response);
        await _saveUser(user);
        return user;
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Verifica se o usuário está autenticado
  Future<bool> isAuthenticated() async {
    final token = await _getAccessToken();
    if (token == null) return false;

    // Verifica se o token ainda é válido
    if (_isTokenExpired(token)) {
      // Tenta renovar o token
      final refreshed = await refreshToken();
      return refreshed;
    }

    _apiClient.setAccessToken(token);
    return true;
  }

  /// Realiza logout
  Future<void> logout() async {
    try {
      // Invalidar token no servidor se possível
      final token = await _getAccessToken();
      if (token != null) {
        try {
          await _apiClient.post('/auth/logout');
        } catch (e) {
          // Ignora erro de logout no servidor
        }
      }
    } finally {
      // Limpar dados locais
      await _clearTokens();
      await _clearUser();
      _apiClient.setAccessToken(null);
    }
  }

  /// Parse do usuário a partir do ID token do Cognito
  User _parseUserFromIdToken(String idToken) {
    try {
      // Decodificar JWT (parte do payload)
      final parts = idToken.split('.');
      if (parts.length != 3) throw Exception('Token inválido');
      
      final payload = parts[1];
      // Adicionar padding se necessário
      final normalizedPayload = payload.padRight((payload.length + 3) ~/ 4 * 4, '=');
      final decoded = utf8.decode(base64Url.decode(normalizedPayload));
      final data = jsonDecode(decoded);
      
      return User(
        id: data['sub'] ?? '',
        email: data['email'] ?? '',
        name: data['name'] ?? data['given_name'] ?? data['email'] ?? '',
        isEmailVerified: data['email_verified'] ?? false,
        lastLogin: DateTime.now(),
      );
    } catch (e) {
      // Fallback para dados básicos
      return User(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        email: 'user@example.com',
        name: 'Usuário',
        isEmailVerified: true,
        lastLogin: DateTime.now(),
      );
    }
  }

  /// Verifica se o token está expirado
  bool _isTokenExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;
      
      final payload = parts[1];
      final normalizedPayload = payload.padRight((payload.length + 3) ~/ 4 * 4, '=');
      final decoded = utf8.decode(base64Url.decode(normalizedPayload));
      final data = jsonDecode(decoded);
      
      final exp = data['exp'];
      if (exp == null) return true;
      
      final expirationDate = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      return DateTime.now().isAfter(expirationDate);
    } catch (e) {
      return true;
    }
  }

  // Métodos de persistência
  Future<void> _saveTokens(String accessToken, String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, accessToken);
    await prefs.setString(_refreshTokenKey, refreshToken);
  }

  Future<void> _saveAccessToken(String accessToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, accessToken);
  }

  Future<String?> _getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<String?> _getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  Future<void> _clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_refreshTokenKey);
  }

  Future<void> _saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  Future<User?> _getSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString(_userKey);
    if (userData != null) {
      return User.fromJson(jsonDecode(userData));
    }
    return null;
  }

  Future<void> _clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
  }
}

