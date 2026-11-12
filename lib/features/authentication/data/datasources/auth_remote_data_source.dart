import '../../../../core/network/api_client.dart';

class AuthUser {
  final String id;
  final String email;
  final String fullName;
  final String defaultCurrency;
  final String language;

  AuthUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.defaultCurrency,
    required this.language,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: (json['fullName'] ?? json['full_name'] ?? '') as String,
      defaultCurrency: (json['defaultCurrency'] ?? json['default_currency'] ?? 'ETB') as String,
      language: (json['language'] ?? 'en') as String,
    );
  }
}

class AuthRemoteDataSource {
  final ApiClient apiClient;

  AuthRemoteDataSource({required this.apiClient});

  Future<AuthUser> register({
    required String email,
    required String password,
    required String fullName,
    String defaultCurrency = 'ETB',
    String language = 'en',
  }) async {
    final res = await apiClient.post('/auth/register', body: {
      'email': email,
      'password': password,
      'fullName': fullName,
      'defaultCurrency': defaultCurrency,
      'language': language,
    });

    final tokens = res['tokens'];
    if (tokens != null) {
      await apiClient.saveTokens(
        accessToken: tokens['accessToken'],
        refreshToken: tokens['refreshToken'],
      );
    }

    return AuthUser.fromJson(res['user']);
  }

  Future<AuthUser> login({
    required String email,
    required String password,
  }) async {
    final res = await apiClient.post('/auth/login', body: {
      'email': email,
      'password': password,
    });

    final tokens = res['tokens'];
    if (tokens != null) {
      await apiClient.saveTokens(
        accessToken: tokens['accessToken'],
        refreshToken: tokens['refreshToken'],
      );
    }

    return AuthUser.fromJson(res['user']);
  }

  Future<void> logout() async {
    try {
      await apiClient.post('/auth/logout');
    } finally {
      await apiClient.clearTokens();
    }
  }

  Future<AuthUser?> getMe() async {
    final token = await apiClient.getAccessToken();
    if (token == null || token.isEmpty) return null;

    try {
      final res = await apiClient.get('/auth/me');
      return AuthUser.fromJson(res['user']);
    } catch (_) {
      await apiClient.clearTokens();
      return null;
    }
  }
}
