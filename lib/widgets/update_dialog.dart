import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:path_provider/path_provider.dart';
import '../services/update_service.dart';

class UpdateDialog extends StatefulWidget {
  final UpdateInfo updateInfo;
  final VoidCallback? onDismiss;

  const UpdateDialog({
    super.key,
    required this.updateInfo,
    this.onDismiss,
  });

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  String _downloadStatus = '';

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !widget.updateInfo.forceUpdate && !_isDownloading,
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.system_update,
                      color: Colors.blue,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Update Available',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Version ${widget.updateInfo.version}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Changelog
              if (widget.updateInfo.changelog.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'What\'s New:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.updateInfo.changelog,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Download Progress
              if (_isDownloading) ...[
                Column(
                  children: [
                    Text(
                      _downloadStatus,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: _downloadProgress,
                      backgroundColor: Colors.grey[200],
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${(_downloadProgress * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],

              // Action Buttons
              Row(
                children: [
                  if (!widget.updateInfo.forceUpdate && !_isDownloading) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          widget.onDismiss?.call();
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Later'),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isDownloading ? null : _handleUpdate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isDownloading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: SpinKitThreeBounce(
                                color: Colors.white,
                                size: 12,
                              ),
                            )
                          : Text(
                              widget.updateInfo.forceUpdate
                                  ? 'Update Now'
                                  : 'Update',
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleUpdate() async {
    setState(() {
      _isDownloading = true;
      _downloadStatus = 'Preparing download...';
    });

    try {
      final updateService = UpdateService();

      final success = await updateService.downloadUpdate(
        widget.updateInfo,
        (progress) {
          setState(() {
            _downloadProgress = progress;
            _downloadStatus = 'Downloading...';
          });
        },
      );

      if (success) {
        setState(() {
          _downloadStatus = 'Download completed! Installing...';
        });

        // Get the downloaded file path
        final String architecture = await updateService.getArchitecture();
        final String fileName =
            'tasce_${architecture}_${widget.updateInfo.version}.apk';

        print('Architecture detected: $architecture');
        print('File name: $fileName');

        // Get download directory
        final Directory? downloadDir = await getExternalStorageDirectory();
        if (downloadDir != null) {
          final Directory downloadsDir =
              Directory('${downloadDir.path}/Downloads');
          final String filePath = '${downloadsDir.path}/$fileName';

          print('Download directory: ${downloadDir.path}');
          print('Downloads directory: ${downloadsDir.path}');
          print('Full file path: $filePath');

          // Check if file exists
          final File apkFile = File(filePath);
          final bool fileExists = await apkFile.exists();
          print('APK file exists: $fileExists');

          if (fileExists) {
            // Try to install the APK
            print('Attempting to install APK...');
            final bool installSuccess =
                await updateService.installUpdate(filePath);
            print('Installation result: $installSuccess');

            if (installSuccess) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Opening installer...'),
                    backgroundColor: Colors.green,
                  ),
                );
                Navigator.of(context).pop();
              }
            } else {
              // Installation failed, show manual install dialog
              if (mounted) {
                _showManualInstallDialog(filePath, updateService);
              }
            }
          } else {
            // File doesn't exist
            print('APK file not found at: $filePath');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      'Download completed but file not found. Please check your Downloads folder.'),
                  backgroundColor: Colors.orange,
                ),
              );
              Navigator.of(context).pop();
            }
          }
        } else {
          // Couldn't get download directory
          print('Could not access download directory');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Download completed! Please check your Downloads folder.'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.of(context).pop();
          }
        }
      } else {
        setState(() {
          _isDownloading = false;
          _downloadStatus = 'Download failed';
        });

        if (mounted) {
          _showDownloadFailedDialog(updateService);
        }
      }
    } catch (e) {
      setState(() {
        _isDownloading = false;
        _downloadStatus = 'Error: $e';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showManualInstallDialog(String filePath, UpdateService updateService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Installation'),
        content: Text(
          'The APK has been downloaded to:\n$filePath\n\n'
          'Please install it manually from your file manager.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
          ElevatedButton(
            onPressed: () async {
              final currentContext = context;
              Navigator.of(currentContext).pop();
              await updateService.openDownloadPage();
            },
            child: const Text('Open Download Page'),
          ),
        ],
      ),
    );
  }

  void _showDownloadFailedDialog(UpdateService updateService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Download Failed'),
        content: const Text(
          'Unable to download the update directly. This might be due to storage permissions. '
          'Would you like to open the download page in your browser instead?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final currentContext = context;
              Navigator.of(currentContext).pop();
              final success = await updateService.openDownloadPage();
              if (success) {
                ScaffoldMessenger.of(currentContext).showSnackBar(
                  const SnackBar(
                    content: Text('Opening download page in browser...'),
                    backgroundColor: Colors.blue,
                  ),
                );
              }
            },
            child: const Text('Open in Browser'),
          ),
        ],
      ),
    );
  }
}
