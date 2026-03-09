import 'package:flutter/material.dart';
import '../services/update_service.dart';

class UpdateProvider extends ChangeNotifier {
  final UpdateService _updateService = UpdateService();
  
  bool _isChecking = false;
  bool _hasUpdate = false;
  UpdateInfo? _updateInfo;
  String _error = '';

  bool get isChecking => _isChecking;
  bool get hasUpdate => _hasUpdate;
  UpdateInfo? get updateInfo => _updateInfo;
  String get error => _error;

  /// Check for updates
  Future<void> checkForUpdates() async {
    if (_isChecking) return;

    setState(() {
      _isChecking = true;
      _error = '';
    });

    try {
      final updateInfo = await _updateService.checkForUpdates();
      
      setState(() {
        _hasUpdate = updateInfo != null;
        _updateInfo = updateInfo;
        _isChecking = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isChecking = false;
      });
    }
  }

  /// Clear update info
  void clearUpdateInfo() {
    setState(() {
      _hasUpdate = false;
      _updateInfo = null;
      _error = '';
    });
  }

  /// Get current version info
  Future<Map<String, String>> getCurrentVersionInfo() async {
    return await _updateService.getCurrentVersionInfo();
  }

  /// Open download page
  Future<bool> openDownloadPage() async {
    return await _updateService.openDownloadPage();
  }

  void setState(VoidCallback fn) {
    fn();
    notifyListeners();
  }
} 