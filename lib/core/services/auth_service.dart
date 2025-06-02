import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/auth.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'auth_user';
  static const String _refreshTokenKey = 'refresh_token';

  // Simulação de usuários para demonstração
  static final Map<String, Map<String, dynamic>> _users = {
    'admin@example.com': {
      'id': '1',
      'email': 'admin@example.com',
      'name': 'Administrador',
      'password': _hashPassword('admin123'),
      'avatar': null,
    },
    'user@example.com': {
      'id': '2',
      'email': 'user@example.com',
      'name': 'Usuário Teste',
      'password': _hashPassword('user123'),
      'avatar': null,
    },
  };

  static String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<LoginResponse> login(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1)); // Simula delay de rede

    final hashedPassword = _hashPassword(password);
    final userData = _users[email.toLowerCase()];

    if (userData == null || userData['password'] != hashedPassword) {
      throw Exception('Email ou senha inválidos');
    }

    final user = User(
      id: userData['id'],
      email: userData['email'],
      name: userData['name'],
      avatar: userData['avatar'],
      lastLogin: DateTime.now(),
    );

    final token = _generateToken(user.id);
    final refreshToken = _generateRefreshToken(user.id);
    final expiresAt = DateTime.now().add(const Duration(hours: 24));

    final response = LoginResponse(
      token: token,
      refreshToken: refreshToken,
      user: user,
      expiresAt: expiresAt,
    );

    await _saveAuthData(response);
    return response;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    await prefs.remove(_refreshTokenKey);
  }

  Future<User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    
    if (userJson == null) return null;
    
    try {
      final userData = jsonDecode(userJson) as Map<String, dynamic>;
      return User.fromJson(userData);
    } catch (e) {
      return null;
    }
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<bool> isAuthenticated() async {
    final token = await getToken();
    final user = await getCurrentUser();
    return token != null && user != null;
  }

  Future<void> _saveAuthData(LoginResponse response) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, response.token);
    await prefs.setString(_refreshTokenKey, response.refreshToken);
    await prefs.setString(_userKey, jsonEncode(response.user.toJson()));
  }

  String _generateToken(String userId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final data = '$userId:$timestamp';
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return 'token_${digest.toString().substring(0, 32)}';
  }

  String _generateRefreshToken(String userId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final data = 'refresh_$userId:$timestamp';
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return 'refresh_${digest.toString().substring(0, 32)}';
  }

  Future<bool> validateToken(String token) async {
    // Simulação de validação de token
    await Future.delayed(const Duration(milliseconds: 500));
    return token.startsWith('token_') && token.length > 10;
  }

  Future<LoginResponse?> refreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString(_refreshTokenKey);
    final user = await getCurrentUser();

    if (refreshToken == null || user == null) {
      return null;
    }

    // Simula refresh do token
    await Future.delayed(const Duration(milliseconds: 500));

    final newToken = _generateToken(user.id);
    final newRefreshToken = _generateRefreshToken(user.id);
    final expiresAt = DateTime.now().add(const Duration(hours: 24));

    final response = LoginResponse(
      token: newToken,
      refreshToken: newRefreshToken,
      user: user,
      expiresAt: expiresAt,
    );

    await _saveAuthData(response);
    return response;
  }
}

