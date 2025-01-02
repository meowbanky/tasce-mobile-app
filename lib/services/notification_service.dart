// lib/services/notification_service.dart

import 'package:flutter/material.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

class NotificationService {
  static const String oneSignalAppId = 'fd579f2c-888c-4c12-beb0-d64af223581f';
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Initialize OneSignal
      OneSignal.initialize(oneSignalAppId);

      // Request permission
      OneSignal.Notifications.requestPermission(true);

      // Handle notification opened handler
      OneSignal.Notifications.addClickListener(
          (OSNotificationClickEvent event) {
        debugPrint('Notification clicked:');
        debugPrint('Title: ${event.notification.title}');
        debugPrint('Body: ${event.notification.body}');
        debugPrint('Additional Data: ${event.notification.additionalData}');
        _handleNotificationOpen(event);
      });

      // Handle notification will show in foreground handler
      OneSignal.Notifications.addForegroundWillDisplayListener(
          (OSNotificationWillDisplayEvent event) {
        debugPrint('Notification received in foreground');
        // Allow the notification to be displayed
        debugPrint('Title: ${event.notification.title}');
        debugPrint('Body: ${event.notification.body}');
      });

      // Handle in-app message click
      OneSignal.InAppMessages.addClickListener(
          (OSInAppMessageClickEvent event) {
        debugPrint("In App Message Clicked: ${event.toString()}");
      });

      _initialized = true;
      debugPrint('OneSignal initialized successfully');
    } catch (e, stackTrace) {
      debugPrint('Error initializing OneSignal: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  static Future<void> setExternalUserId(String userId) async {
    try {
      await OneSignal.login(userId);
      debugPrint('External user ID set: $userId');
    } catch (e) {
      debugPrint('Error setting external user ID: $e');
    }
  }

  static void _handleNotificationOpen(OSNotificationClickEvent event) {
    try {
      final data = event.notification.additionalData;
      final notification = event.notification;

      if (data != null) {
        // Handle different notification types
        switch (data['type']) {
          case 'payslip':
            _navigateToPayslip(data['payslip_id']?.toString());
            break;
          case 'announcement':
            _navigateToAnnouncement(data['announcement_id']?.toString());
            break;
        }
      }
    } catch (e) {
      debugPrint('Error handling notification open: $e');
    }
  }

  static void _navigateToPayslip(String? payslipId) {
    debugPrint('Navigate to payslip: $payslipId');
    // Implement navigation using your preferred navigation method
  }

  static void _navigateToAnnouncement(String? announcementId) {
    debugPrint('Navigate to announcement: $announcementId');
    // Implement navigation using your preferred navigation method
  }

  static Future<void> subscribeToTopic(String topic) async {
    try {
      await OneSignal.User.addTagWithKey(topic, 'true');
      debugPrint('Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('Error subscribing to topic: $e');
    }
  }

  static Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await OneSignal.User.removeTag(topic);
      debugPrint('Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('Error unsubscribing from topic: $e');
    }
  }

  // Add method to handle notification permission changes
  static void listenForPermissionChanges() {
    OneSignal.Notifications.addPermissionObserver((bool permission) {
      debugPrint("Notification permission state changed: $permission");
    });
  }

  // Add method to check if notifications are enabled
  static Future<bool> areNotificationsEnabled() async {
    return OneSignal.Notifications.permission;
  }
}
