import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  ApiException(this.message, {this.statusCode, this.data});

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  late http.Client _client;
  String? _accessToken;

  void initialize() {
    _client = http.Client();
  }

  void setAccessToken(String? token) {
    _accessToken = token;
  }

  String? get accessToken => _accessToken;

  Map<String, String> get _headers {
    final headers = Map<String, String>.from(ApiConfig.defaultHeaders);
    if (_accessToken != null) {
      headers['Authorization'] = 'Bearer $_accessToken';
    }
    return headers;
  }

  Future<Map<String, dynamic>> get(String endpoint) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      final response = await _client.get(url, headers: _headers)
          .timeout(ApiConfig.receiveTimeout);

      return _handleResponse(response);
    } on SocketException {
      throw ApiException('Sem conexão com a internet');
    } on HttpException {
      throw ApiException('Erro de conexão HTTP');
    } catch (e) {
      throw ApiException('Erro inesperado: $e');
    }
  }

  Future<Map<String, dynamic>> post(String endpoint, {Map<String, dynamic>? data}) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      final response = await _client.post(
        url,
        headers: _headers,
        body: data != null ? jsonEncode(data) : null,
      ).timeout(ApiConfig.receiveTimeout);

      return _handleResponse(response);
    } on SocketException {
      throw ApiException('Sem conexão com a internet');
    } on HttpException {
      throw ApiException('Erro de conexão HTTP');
    } catch (e) {
      throw ApiException('Erro inesperado: $e');
    }
  }

  Future<Map<String, dynamic>> put(String endpoint, {Map<String, dynamic>? data}) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      final response = await _client.put(
        url,
        headers: _headers,
        body: data != null ? jsonEncode(data) : null,
      ).timeout(ApiConfig.receiveTimeout);

      return _handleResponse(response);
    } on SocketException {
      throw ApiException('Sem conexão com a internet');
    } on HttpException {
      throw ApiException('Erro de conexão HTTP');
    } catch (e) {
      throw ApiException('Erro inesperado: $e');
    }
  }

  Future<Map<String, dynamic>> delete(String endpoint) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      final response = await _client.delete(url, headers: _headers)
          .timeout(ApiConfig.receiveTimeout);

      return _handleResponse(response);
    } on SocketException {
      throw ApiException('Sem conexão com a internet');
    } on HttpException {
      throw ApiException('Erro de conexão HTTP');
    } catch (e) {
      throw ApiException('Erro inesperado: $e');
    }
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    final statusCode = response.statusCode;
    
    try {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      
      if (statusCode >= 200 && statusCode < 300) {
        return data;
      } else {
        final message = data['message'] ?? data['error'] ?? 'Erro desconhecido';
        throw ApiException(message, statusCode: statusCode, data: data);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      
      // Se não conseguir fazer parse do JSON, usa a mensagem padrão baseada no status
      String message;
      switch (statusCode) {
        case 400:
          message = 'Dados inválidos';
          break;
        case 401:
          message = 'Não autorizado - faça login novamente';
          break;
        case 403:
          message = 'Acesso negado';
          break;
        case 404:
          message = 'Recurso não encontrado';
          break;
        case 422:
          message = 'Dados de entrada inválidos';
          break;
        case 500:
          message = 'Erro interno do servidor';
          break;
        default:
          message = 'Erro de conexão (Status: $statusCode)';
      }
      
      throw ApiException(message, statusCode: statusCode);
    }
  }

  void dispose() {
    _client.close();
  }
}

