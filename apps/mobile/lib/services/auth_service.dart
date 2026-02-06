import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_service.dart';

class User {
  final String userId;
  final String email;
  final String role;

  User({
    required this.userId,
    required this.email,
    required this.role,
  });

  factory User.fromToken(String token) {
    final parts = token.split('.');
    if (parts.length != 3) throw Exception('Invalid token');
    
    final payload = jsonDecode(
      utf8.decode(base64Url.decode(base64Url.normalize(parts[1])))
    );
    
    return User(
      userId: payload['sub'],
      email: payload['email'],
      role: payload['role'],
    );
  }
}

class AuthService {
  final ApiService _api;
  final _storage = const FlutterSecureStorage();
  
  static const _tokenKey = 'auth_token';
  static const _tenantKey = 'tenant_id';

  AuthService(this._api);

  Future<User> login({
    required String email,
    required String password,
    required String tenantId,
  }) async {
    try {
      // Set tenant header
      _api.dio.options.headers['x-tenant-id'] = tenantId;
      
      final response = await _api.dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      final token = response.data['access_token'];
      if (token == null) throw Exception('No token received');

      // Save credentials
      await _storage.write(key: _tokenKey, value: token);
      await _storage.write(key: _tenantKey, value: tenantId);

      // Set token for API
      _api.setToken(token);

      return User.fromToken(token);
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _tenantKey);
    _api.dio.options.headers.remove('Authorization');
  }

  Future<User?> getCurrentUser() async {
    final token = await _storage.read(key: _tokenKey);
    final tenantId = await _storage.read(key: _tenantKey);
    
    if (token == null || tenantId == null) return null;

    try {
      // Check if token is expired
      final user = User.fromToken(token);
      
      // Restore API headers
      _api.setToken(token);
      _api.dio.options.headers['x-tenant-id'] = tenantId;
      
      return user;
    } catch (e) {
      await logout();
      return null;
    }
  }

  Future<bool> isAuthenticated() async {
    final user = await getCurrentUser();
    return user != null;
  }
}
