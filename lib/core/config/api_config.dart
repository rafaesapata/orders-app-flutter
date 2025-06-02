class ApiConfig {
  // Configurações baseadas no projeto React
  static const String baseUrl = 'https://api.develop.verocard.udstec.io/employer-register/api/v1';
  
  // Configurações do AWS Cognito
  static const String cognitoDomain = 'https://verocard-auth-dev.auth.us-east-1.amazoncognito.com/';
  static const String userPoolWebClientId = '72nk00dlm4in06ka7uf1cgd13l';
  static const String userPoolId = 'us-east-1_X71K7DiLe';
  static const String region = 'us-east-1';
  
  // Headers padrão
  static Map<String, String> get defaultHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
  
  // Headers com autenticação
  static Map<String, String> getAuthHeaders(String token) => {
    ...defaultHeaders,
    'Authorization': 'Bearer $token',
  };
  
  // Endpoints
  static const String loginEndpoint = '/auth/login';
  static const String refreshTokenEndpoint = '/auth/refresh';
  static const String userProfileEndpoint = '/auth/user';
  static const String employeesEndpoint = '/employees';
  static const String ordersEndpoint = '/orders';
  static const String productsEndpoint = '/products';
  
  // Configurações de timeout
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}

