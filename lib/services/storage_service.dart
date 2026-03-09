// lib/services/storage_service.dart

import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';

class StorageService {
  final FlutterSecureStorage _storage;

  StorageService()
      : _storage = const FlutterSecureStorage(
          webOptions: WebOptions(
            dbName: 'tasce_mobile',
            publicKey: 'tasce_mobile_key',
          ),
        );

  Future<void> saveUser(User user) async {
    await _storage.write(key: 'user', value: jsonEncode(user.toJson()));
  }

  Future<User?> getUser() async {
    final userStr = await _storage.read(key: 'user');
    if (userStr != null) {
      final userMap = jsonDecode(userStr);
      return User.fromJson(userMap, userMap['token']);
    }
    return null;
  }

  Future<void> clearUser() async {
    await _storage.delete(key: 'user');
  }

  Future<bool> isLoggedIn() async {
    return await _storage.containsKey(key: 'user');
  }

  // Remember login functionality
  Future<void> saveRememberLogin(bool remember, String email, String password) async {
    if (remember) {
      await _storage.write(key: 'remember_login', value: 'true');
      await _storage.write(key: 'saved_email', value: email);
      await _storage.write(key: 'saved_password', value: password);
    } else {
      await _storage.delete(key: 'remember_login');
      await _storage.delete(key: 'saved_email');
      await _storage.delete(key: 'saved_password');
    }
  }

  Future<Map<String, String?>> getRememberedCredentials() async {
    final remember = await _storage.read(key: 'remember_login');
    if (remember == 'true') {
      final email = await _storage.read(key: 'saved_email');
      final password = await _storage.read(key: 'saved_password');
      return {'email': email, 'password': password};
    }
    return {'email': null, 'password': null};
  }

  // Biometric authentication
  Future<void> saveBiometricCredentials(String email, String password) async {
    await _storage.write(key: 'biometric_enabled', value: 'true');
    await _storage.write(key: 'biometric_email', value: email);
    await _storage.write(key: 'biometric_password', value: password);
  }

  Future<Map<String, String?>> getBiometricCredentials() async {
    final enabled = await _storage.read(key: 'biometric_enabled');
    if (enabled == 'true') {
      final email = await _storage.read(key: 'biometric_email');
      final password = await _storage.read(key: 'biometric_password');
      return {'email': email, 'password': password};
    }
    return {'email': null, 'password': null};
  }

  Future<bool> isBiometricEnabled() async {
    final enabled = await _storage.read(key: 'biometric_enabled');
    return enabled == 'true';
  }

  Future<void> clearBiometricCredentials() async {
    await _storage.delete(key: 'biometric_enabled');
    await _storage.delete(key: 'biometric_email');
    await _storage.delete(key: 'biometric_password');
  }
}
