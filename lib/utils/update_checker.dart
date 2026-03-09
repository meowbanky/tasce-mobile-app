import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/update_provider.dart';
import '../widgets/update_dialog.dart';

class UpdateChecker {
  /// Check for updates and show dialog if available
  static Future<void> checkForUpdates(BuildContext context) async {
    final updateProvider = Provider.of<UpdateProvider>(context, listen: false);
    
    try {
      await updateProvider.checkForUpdates();
      
      if (updateProvider.hasUpdate && updateProvider.updateInfo != null) {
        if (context.mounted) {
          showDialog(
            context: context,
            barrierDismissible: !(updateProvider.updateInfo!.forceUpdate),
            builder: (context) => UpdateDialog(
              updateInfo: updateProvider.updateInfo!,
              onDismiss: () => updateProvider.clearUpdateInfo(),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to check for updates: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Check for updates silently (no dialog)
  static Future<bool> checkForUpdatesSilently(BuildContext context) async {
    final updateProvider = Provider.of<UpdateProvider>(context, listen: false);
    
    try {
      await updateProvider.checkForUpdates();
      return updateProvider.hasUpdate;
    } catch (e) {
      return false;
    }
  }

  /// Show update dialog if update is available
  static void showUpdateDialog(BuildContext context) {
    final updateProvider = Provider.of<UpdateProvider>(context, listen: false);
    
    if (updateProvider.hasUpdate && updateProvider.updateInfo != null) {
      showDialog(
        context: context,
        barrierDismissible: !(updateProvider.updateInfo!.forceUpdate),
        builder: (context) => UpdateDialog(
          updateInfo: updateProvider.updateInfo!,
          onDismiss: () => updateProvider.clearUpdateInfo(),
        ),
      );
    }
  }
} 