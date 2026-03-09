// lib/providers/auth_provider.dart

import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../services/biometric_service.dart';
import '../models/user.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();
  final BiometricService _biometricService = BiometricService();

  bool _isLoading = false;
  User? _user;

  bool get isLoading => _isLoading;
  bool get isLoggedIn => _user != null;
  User? get user => _user;

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // lib/providers/auth_provider.dart

  // In auth_provider.dart, update the login method

  // lib/providers/auth_provider.dart

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      setLoading(true);

      final response = await _apiService.login(email, password);

      if (response['success'] == true) {
        final token = response['token'];
        _apiService.setAuthToken(token); // Set token for future requests

        final user = User.fromJson(
          response['user'],
          token,
        );

        await _storageService.saveUser(user);
        _user = user;
      }

      return response;
    } finally {
      setLoading(false);
    }
  }

  Future<void> logout() async {
    _apiService.clearAuthToken(); // Clear token
    await _storageService.clearUser();
    _user = null;
    notifyListeners();
  }

  // Remember login functionality
  Future<void> saveRememberLogin(
      bool remember, String email, String password) async {
    await _storageService.saveRememberLogin(remember, email, password);
  }

  Future<Map<String, String?>> getRememberedCredentials() async {
    return await _storageService.getRememberedCredentials();
  }

  // Biometric authentication
  Future<bool> isBiometricAvailable() async {
    return await _biometricService.isBiometricAvailable();
  }

  Future<List<dynamic>> getAvailableBiometrics() async {
    return await _biometricService.getAvailableBiometrics();
  }

  Future<bool> authenticateWithBiometric() async {
    return await _biometricService.authenticate();
  }

  Future<void> saveBiometricCredentials(String email, String password) async {
    await _storageService.saveBiometricCredentials(email, password);
  }

  Future<Map<String, String?>> getBiometricCredentials() async {
    return await _storageService.getBiometricCredentials();
  }

  Future<bool> isBiometricEnabled() async {
    return await _storageService.isBiometricEnabled();
  }

  Future<void> clearBiometricCredentials() async {
    await _storageService.clearBiometricCredentials();
  }

  Future<Map<String, dynamic>> loginWithBiometric() async {
    try {
      setLoading(true);

      // First authenticate with biometric
      final isAuthenticated = await authenticateWithBiometric();
      if (!isAuthenticated) {
        return {'success': false, 'message': 'Biometric authentication failed'};
      }

      // Get saved credentials
      final credentials = await getBiometricCredentials();
      if (credentials['email'] == null || credentials['password'] == null) {
        return {
          'success': false,
          'message': 'No saved biometric credentials found'
        };
      }

      // Login with saved credentials
      return await login(credentials['email']!, credentials['password']!);
    } finally {
      setLoading(false);
    }
  }

  // Forgot password functionality
  Future<Map<String, dynamic>> requestPasswordReset(String email) async {
    try {
      setLoading(true);
      final response = await _apiService.requestPasswordReset(email);
      return response;
    } finally {
      setLoading(false);
    }
  }

  Future<Map<String, dynamic>> verifyResetOTP(String email, String otp) async {
    try {
      setLoading(true);
      final response = await _apiService.verifyResetOTP(email, otp);
      return response;
    } finally {
      setLoading(false);
    }
  }

  Future<Map<String, dynamic>> resetPassword(String email, String newPassword, String resetToken) async {
    try {
      setLoading(true);
      final response = await _apiService.resetPassword(email, newPassword, resetToken);
      return response;
    } finally {
      setLoading(false);
    }
  }
}
