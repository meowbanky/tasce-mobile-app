import 'dart:io';
import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';

class UpdateInfo {
  final String version;
  final int buildNumber;
  final String changelog;
  final bool forceUpdate;
  final String downloadUrl;

  UpdateInfo({
    required this.version,
    required this.buildNumber,
    required this.changelog,
    required this.forceUpdate,
    required this.downloadUrl,
  });

  factory UpdateInfo.fromJson(Map<String, dynamic> json) {
    // Handle build_number as either string or int
    int buildNumber;
    if (json['build_number'] is String) {
      buildNumber = int.tryParse(json['build_number']) ?? 0;
    } else if (json['build_number'] is int) {
      buildNumber = json['build_number'];
    } else {
      buildNumber = 0;
    }

    return UpdateInfo(
      version: json['version'] ?? '',
      buildNumber: buildNumber,
      changelog: json['changelog'] ?? '',
      forceUpdate: json['force_update'] ?? false,
      downloadUrl: json['download_url'] ?? '',
    );
  }
}

class UpdateService {
  static const String _versionUrl =
      'https://tascesalary.com.ng/download/version.json';
  static const String _downloadBaseUrl = 'https://tascesalary.com.ng/download/';

  final Dio _dio = Dio();

  // Singleton pattern
  static final UpdateService _instance = UpdateService._internal();
  factory UpdateService() => _instance;
  UpdateService._internal();

  /// Check for app updates
  Future<UpdateInfo?> checkForUpdates() async {
    try {
      // Get current app info
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      final String currentVersion = packageInfo.version;
      final String currentBuildNumber = packageInfo.buildNumber;

      print('Current version: $currentVersion+$currentBuildNumber');

      // Fetch version info from server
      final Response response = await _dio.get(
        _versionUrl,
        options: Options(
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        print('Server response data: ${response.data}');
        final UpdateInfo updateInfo = UpdateInfo.fromJson(response.data);
        print(
            'Server version: ${updateInfo.version}+${updateInfo.buildNumber}');

        // Compare versions
        if (_isNewVersionAvailable(
            currentVersion, currentBuildNumber, updateInfo)) {
          print(
              'New version available: ${updateInfo.version}+${updateInfo.buildNumber}');
          return updateInfo;
        } else {
          print('App is up to date');
          return null;
        }
      }

      return null;
    } catch (e) {
      print('Error checking for updates: $e');
      print('Error stack trace: ${StackTrace.current}');
      return null;
    }
  }

  /// Compare versions to determine if update is needed
  bool _isNewVersionAvailable(
      String currentVersion, String currentBuildNumber, UpdateInfo updateInfo) {
    try {
      print('Comparing versions:');
      print('Current: $currentVersion+$currentBuildNumber');
      print('Server: ${updateInfo.version}+${updateInfo.buildNumber}');

      // Parse current version
      final List<int> currentParts =
          currentVersion.split('.').map((e) => int.parse(e)).toList();
      final int currentBuild = int.parse(currentBuildNumber);

      // Parse server version
      final List<int> serverParts =
          updateInfo.version.split('.').map((e) => int.parse(e)).toList();
      final int serverBuild = updateInfo.buildNumber;

      print(
          'Parsed current: ${currentParts[0]}.${currentParts[1]}.${currentParts[2]}+$currentBuild');
      print(
          'Parsed server: ${serverParts[0]}.${serverParts[1]}.${serverParts[2]}+$serverBuild');

      // Compare major version
      if (serverParts[0] > currentParts[0]) return true;
      if (serverParts[0] < currentParts[0]) return false;

      // Compare minor version
      if (serverParts[1] > currentParts[1]) return true;
      if (serverParts[1] < currentParts[1]) return false;

      // Compare patch version
      if (serverParts[2] > currentParts[2]) return true;
      if (serverParts[2] < currentParts[2]) return false;

      // Compare build number
      return serverBuild > currentBuild;
    } catch (e) {
      print('Error comparing versions: $e');
      print('Error stack trace: ${StackTrace.current}');
      return false;
    }
  }

  /// Download APK file
  Future<bool> downloadUpdate(
      UpdateInfo updateInfo, Function(double) onProgress) async {
    try {
      // Request storage permission
      if (Platform.isAndroid) {
        print('Requesting storage permissions...');

        // For Android 13+ (API 33+), use READ_MEDIA_IMAGES permission
        // For older versions, use storage permission
        Permission permission;
        if (await _isAndroid13OrHigher()) {
          print('Using READ_MEDIA_IMAGES permission for Android 13+');
          permission = Permission.photos; // This maps to READ_MEDIA_IMAGES
        } else {
          print('Using storage permission for older Android');
          permission = Permission.storage;
        }

        final status = await permission.request();
        print('Permission status: $status');

        if (!status.isGranted) {
          print('Storage permission denied. Status: $status');
          // Try to open app settings to let user grant permission manually
          await openAppSettings();
          return false;
        }

        print('Storage permission granted successfully');
      }

      // Get download directory
      final Directory? downloadDir = await getExternalStorageDirectory();
      if (downloadDir == null) {
        print('Could not access download directory');
        return false;
      }

      // Create downloads folder
      final Directory downloadsDir = Directory('${downloadDir.path}/Downloads');
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }

      // Determine architecture and filename
      final String architecture = await getArchitecture();
      final String fileName = 'tasce_${architecture}_${updateInfo.version}.apk';
      final String filePath = '${downloadsDir.path}/$fileName';

      print('Downloading to: $filePath');

      // Download file
      await _dio.download(
        '$_downloadBaseUrl$fileName',
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = received / total;
            onProgress(progress);
          }
        },
        options: Options(
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 300), // 5 minutes
        ),
      );

      print('Download completed: $filePath');
      return true;
    } catch (e) {
      print('Error downloading update: $e');
      print('Attempting to open download page in browser as fallback...');

      // Fallback: Open download page in browser
      try {
        final success = await openDownloadPage();
        if (success) {
          print('Successfully opened download page in browser');
          return true;
        } else {
          print('Failed to open download page in browser');
          return false;
        }
      } catch (browserError) {
        print('Error opening download page: $browserError');
        return false;
      }
    }
  }

  /// Get device architecture
  Future<String> getArchitecture() async {
    if (Platform.isAndroid) {
      try {
        // Use device_info_plus to get the actual architecture
        final deviceInfo = DeviceInfoPlugin();
        final androidInfo = await deviceInfo.androidInfo;

        // Get supported ABIs and use the first one (primary architecture)
        final List<String> supportedAbis = androidInfo.supportedAbis;
        print('Supported ABIs: $supportedAbis');

        if (supportedAbis.isNotEmpty) {
          final String primaryAbi = supportedAbis.first;

          // Map ABI to our naming convention
          switch (primaryAbi) {
            case 'arm64-v8a':
              return 'arm64-v8a';
            case 'armeabi-v7a':
              return 'armeabi-v7a';
            case 'x86_64':
              return 'x86_64';
            case 'x86':
              return 'x86_64'; // Use x86_64 for x86 devices
            default:
              print('Unknown ABI: $primaryAbi, defaulting to arm64-v8a');
              return 'arm64-v8a'; // Default to most common
          }
        }

        // Fallback to arm64-v8a if we can't detect
        print('Could not detect ABI, defaulting to arm64-v8a');
        return 'arm64-v8a';
      } catch (e) {
        print('Error detecting architecture: $e');
        return 'arm64-v8a'; // Default fallback
      }
    } else if (Platform.isIOS) {
      return 'ios';
    }
    return 'unknown';
  }

  /// Check if device is running Android 13 or higher
  Future<bool> _isAndroid13OrHigher() async {
    if (!Platform.isAndroid) return false;

    try {
      // Use device_info_plus to get Android version
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      return androidInfo.version.sdkInt >= 33; // API level 33 is Android 13
    } catch (e) {
      print('Error checking Android version: $e');
      return false;
    }
  }

  /// Install downloaded APK (Android only)
  Future<bool> installUpdate(String filePath) async {
    try {
      if (!Platform.isAndroid) {
        print('Installation only supported on Android');
        return false;
      }

      // Check if file exists
      final File apkFile = File(filePath);
      if (!await apkFile.exists()) {
        print('APK file not found: $filePath');
        return false;
      }

      // Use FileProvider to create a content URI
      const platform = MethodChannel('com.tasce_mobile/installer');
      final Map<String, dynamic> args = {
        'filePath': filePath,
      };

      final bool result = await platform.invokeMethod('installApk', args);
      print('Installation result from platform: $result');
      return result;
    } catch (e) {
      print('Error installing update: $e');
      return false;
    }
  }

  /// Open download page in browser
  Future<bool> openDownloadPage() async {
    try {
      final Uri url = Uri.parse('https://tascesalary.com.ng/download.html');
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
        return true;
      }
      return false;
    } catch (e) {
      print('Error opening download page: $e');
      return false;
    }
  }

  /// Get current app version info
  Future<Map<String, String>> getCurrentVersionInfo() async {
    try {
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      return {
        'version': packageInfo.version,
        'buildNumber': packageInfo.buildNumber,
        'appName': packageInfo.appName,
        'packageName': packageInfo.packageName,
      };
    } catch (e) {
      print('Error getting version info: $e');
      return {};
    }
  }
}
