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
}
