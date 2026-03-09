// lib/services/api_service.dart

import 'package:dio/dio.dart';

class ApiService {
  late final Dio dio;
  static const String baseUrl = 'https://tascesalary.com.ng/auth_api';

  // Singleton pattern
  static final ApiService _instance = ApiService._internal();

  factory ApiService() {
    return _instance;
  }

  ApiService._internal() {
    dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 3),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      validateStatus: (status) {
        return status! < 500;
      },
    ));

    dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      error: true,
      requestHeader: true,
      responseHeader: true,
    ));
  }

  // Add auth token to dio instance
  void setAuthToken(String token) {
    dio.options.headers['Authorization'] = 'Bearer $token';
  }

  // Remove auth token
  void clearAuthToken() {
    dio.options.headers.remove('Authorization');
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await dio.post(
        '/api/auth/login.php',
        data: {
          'email': email,
          'password': password,
        },
      );

      return response.data;
    } on DioException catch (e) {
      if (e.response != null) {
        return e.response!.data;
      }
      throw 'Connection error. Please try again.';
    } catch (e) {
      throw 'An unexpected error occurred';
    }
  }

  // Forgot password functionality
  Future<Map<String, dynamic>> requestPasswordReset(String email) async {
    try {
      print('Sending password reset request for email: $email');
      final response = await dio.post(
        '/api/auth/forgot_password.php',
        data: {
          'email': email,
        },
      );
      print('Response status: ${response.statusCode}');
      print('Response headers: ${response.headers}');
      print('Response data type: ${response.data.runtimeType}');
      print('Response data: ${response.data}');

      if (response.data == null) {
        print('Warning: Response data is null!');
        return {'success': false, 'message': 'No response from server'};
      }

      return response.data;
    } on DioException catch (e) {
      print('DioException caught: ${e.message}');
      print('DioException response: ${e.response?.data}');
      if (e.response != null) {
        return e.response!.data;
      }
      throw 'Connection error. Please try again.';
    } catch (e) {
      print('Unexpected error: $e');
      throw 'An unexpected error occurred';
    }
  }

  Future<Map<String, dynamic>> verifyResetOTP(String email, String otp) async {
    try {
      final response = await dio.post(
        '/api/auth/verify_otp.php',
        data: {
          'email': email,
          'otp': otp,
        },
      );

      return response.data;
    } on DioException catch (e) {
      if (e.response != null) {
        return e.response!.data;
      }
      throw 'Connection error. Please try again.';
    } catch (e) {
      throw 'An unexpected error occurred';
    }
  }

  Future<Map<String, dynamic>> resetPassword(
      String email, String newPassword, String resetToken) async {
    try {
      final response = await dio.post(
        '/api/auth/reset_password.php',
        data: {
          'email': email,
          'new_password': newPassword,
          'reset_token': resetToken,
        },
      );

      return response.data;
    } on DioException catch (e) {
      if (e.response != null) {
        return e.response!.data;
      }
      throw 'Connection error. Please try again.';
    } catch (e) {
      throw 'An unexpected error occurred';
    }
  }

  // Test API endpoint
  Future<Map<String, dynamic>> testApi() async {
    try {
      print('Testing API endpoint...');
      final response = await dio.post(
        '/test_api.php',
        data: {
          'test': 'data',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      print('Test API response: ${response.data}');
      return response.data;
    } on DioException catch (e) {
      print('Test API DioException: ${e.message}');
      if (e.response != null) {
        return e.response!.data;
      }
      throw 'Connection error. Please try again.';
    } catch (e) {
      print('Test API unexpected error: $e');
      throw 'An unexpected error occurred';
    }
  }
}
