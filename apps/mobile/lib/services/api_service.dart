import 'package:dio/dio.dart';
import 'dart:io';

class ApiService {
  late Dio dio;

  ApiService() {
    // For Android Emulator use 10.0.2.2, for iOS/Web use localhost
    final baseUrl = Platform.isAndroid ? 'http://10.0.2.2:3000' : 'http://localhost:3000';
    
    dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 3),
      headers: {
        'Content-Type': 'application/json',
        'x-tenant-id': 'demo_tenant', // Hardcoded for now, should be dynamic
      },
    ));
    
    dio.interceptors.add(LogInterceptor(responseBody: true, requestBody: true));
    
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // We need to read token. 
        // Circular dependency issue if we inject AuthService here directly?
        // Better to pass token getter or use a singleton for storage.
        // For simplicity, let's read from storage directly here or assume it's passed.
        // But to avoid adding dependency, let's use a callback or global.
        
        // Actually, let's use flutter_secure_storage directly here for the token injection
        // to keep ApiService simple or allow setting the token.
        // Ideally AuthService sets the default header on Dio upon login.
        return handler.next(options);
      },
      onError: (DioException e, handler) {
        if (e.response?.statusCode == 401) {
           // Handle unauthorized (logout)
        }
        return handler.next(e);
      }
    ));
  }

  // Helper to set token from AuthService
  void setToken(String token) {
     dio.options.headers['Authorization'] = 'Bearer $token';
  }

  Future<Response> get(String path) => dio.get(path);
  
  Future<Response> post(String path, dynamic data) => dio.post(path, data: data);
}
