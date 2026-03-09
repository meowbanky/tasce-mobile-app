import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/update_provider.dart';
import 'update_dialog.dart';

class VersionInfoWidget extends StatefulWidget {
  final bool showUpdateButton;
  final VoidCallback? onUpdatePressed;

  const VersionInfoWidget({
    Key? key,
    this.showUpdateButton = true,
    this.onUpdatePressed,
  }) : super(key: key);

  @override
  State<VersionInfoWidget> createState() => _VersionInfoWidgetState();
}

class _VersionInfoWidgetState extends State<VersionInfoWidget> {
  Map<String, String> _versionInfo = {};

  @override
  void initState() {
    super.initState();
    _loadVersionInfo();
  }

  Future<void> _loadVersionInfo() async {
    final updateProvider = Provider.of<UpdateProvider>(context, listen: false);
    final versionInfo = await updateProvider.getCurrentVersionInfo();
    
    if (mounted) {
      setState(() {
        _versionInfo = versionInfo;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UpdateProvider>(
      builder: (context, updateProvider, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 20,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'App Information',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Version info
              if (_versionInfo.isNotEmpty) ...[
                _buildInfoRow('App Name', _versionInfo['appName'] ?? 'Unknown'),
                _buildInfoRow('Version', _versionInfo['version'] ?? 'Unknown'),
                _buildInfoRow('Build Number', _versionInfo['buildNumber'] ?? 'Unknown'),
                _buildInfoRow('Package', _versionInfo['packageName'] ?? 'Unknown'),
              ] else ...[
                const Center(
                  child: SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ],
              
              const SizedBox(height: 16),
              
              // Update status
              if (updateProvider.hasUpdate) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.system_update,
                        size: 18,
                        color: Colors.orange[700],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Update available: ${updateProvider.updateInfo?.version}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.orange[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              
              // Action buttons
              if (widget.showUpdateButton) ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: updateProvider.isChecking
                            ? null
                            : () => updateProvider.checkForUpdates(),
                        icon: updateProvider.isChecking
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.refresh, size: 18),
                        label: Text(
                          updateProvider.isChecking ? 'Checking...' : 'Check for Updates',
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    if (updateProvider.hasUpdate) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: widget.onUpdatePressed ?? () {
                            // Show update dialog
                            showDialog(
                              context: context,
                              barrierDismissible: !(updateProvider.updateInfo?.forceUpdate ?? false),
                              builder: (context) => UpdateDialog(
                                updateInfo: updateProvider.updateInfo!,
                                onDismiss: () => updateProvider.clearUpdateInfo(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.download, size: 18),
                          label: const Text('Update'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
              
              // Error message
              if (updateProvider.error.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 16,
                        color: Colors.red[700],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          updateProvider.error,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }
} 