// ignore_for_file: avoid_print, avoid_web_libraries_in_flutter

import 'dart:js' as js;
import 'package:flutter/foundation.dart';

class WebNotificationService {
  static bool _isInitialized = false;

  /// Check if OneSignal is available and initialized
  static bool get isAvailable {
    if (!kIsWeb) return false;
    
    try {
      return js.context.hasProperty('OneSignal') && _isInitialized;
    } catch (e) {
      return false;
    }
  }

  /// Initialize the service (OneSignal is already initialized in HTML)
  static Future<void> initialize() async {
    if (!kIsWeb) return;

    try {
      // Wait for OneSignal to be available
      await _waitForOneSignal();
      _isInitialized = true;
      print('Web notification service initialized');
    } catch (e) {
      print('Error initializing web notification service: $e');
    }
  }

  /// Wait for OneSignal to be loaded
  static Future<void> _waitForOneSignal() async {
    int attempts = 0;
    const maxAttempts = 50; // 5 seconds max wait
    
    while (attempts < maxAttempts) {
      try {
        if (js.context.hasProperty('OneSignal')) {
          return;
        }
      } catch (e) {
        // Continue waiting
      }
      await Future.delayed(const Duration(milliseconds: 100));
      attempts++;
    }
    
    throw Exception('OneSignal SDK not found');
  }

  /// Request notification permission
  static Future<bool> requestPermission() async {
    if (!kIsWeb || !isAvailable) return false;

    try {
      // Use OneSignal's built-in permission request
      js.context.callMethod('eval', [
        '''
        OneSignal.Notifications.requestPermission().then(function(accepted) {
          console.log("Permission granted: " + accepted);
        });
        '''
      ]);

      // Wait a bit and check permission status
      await Future.delayed(const Duration(milliseconds: 1000));
      return await getPermissionStatus() == 'granted';
    } catch (e) {
      print('Error requesting permission: $e');
      return false;
    }
  }

  /// Get current permission status
  static Future<String> getPermissionStatus() async {
    if (!kIsWeb) return 'unsupported';

    try {
      final permission = js.context['Notification']['permission'];
      return permission.toString();
    } catch (e) {
      print('Error getting permission status: $e');
      return 'denied';
    }
  }

  /// Check if notifications are enabled
  static Future<bool> areNotificationsEnabled() async {
    final status = await getPermissionStatus();
    return status == 'granted';
  }

  /// Show a simple local notification (fallback)
  static void showLocalNotification({
    required String title,
    required String message,
    String? icon,
  }) {
    if (!kIsWeb) return;

    try {
      final permission = js.context['Notification']['permission'];
      if (permission == 'granted') {
        js.context.callMethod('eval', [
          '''
          new Notification("$title", {
            body: "$message",
            icon: "${icon ?? '/App_Logo.png'}",
            tag: "campus-safe-notification"
          });
          '''
        ]);
      }
    } catch (e) {
      print('Error showing local notification: $e');
    }
  }
}
