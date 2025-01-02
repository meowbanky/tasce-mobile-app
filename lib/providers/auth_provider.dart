// lib/providers/auth_provider.dart

import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../models/user.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();

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
}
