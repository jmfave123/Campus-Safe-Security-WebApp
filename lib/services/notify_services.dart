// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:http/http.dart' as http;

class NotifServices {
  static const String _appId = "ce9ff261-c17d-4aeb-9b89-464e05179046";
  static const String _authKey =
      "Basic os_v2_app_z2p7eyobpvfoxg4jizhakf4qi2s2lwti4tcen2e3gfltqenbxmvaoeayxp5kaqpxhb2ao234mun35u2ja6unubpoqannkmevo372mzq";
  static const String _onesignalUrl =
      "https://onesignal.com/api/v1/notifications";

  static Future<void> sendGroupNotification({
    required String userType,
    required String heading,
    required String content,
    String? bigPicture,
  }) async {
    final Map<String, dynamic> notificationData = {
      "app_id": _appId,
      "filters": [
        {
          "field": "tag",
          "key": "userType",
          "relation": "=",
          "value": userType,
        }
      ],
      "headings": {"en": heading},
      "contents": {"en": content},
    };

    if (bigPicture != null) {
      notificationData["big_picture"] = bigPicture;
    }

    try {
      final response = await http.post(
        Uri.parse(_onesignalUrl),
        headers: {
          "Content-Type": "application/json; charset=utf-8",
          "Authorization": _authKey,
        },
        body: jsonEncode(notificationData),
      );

      if (response.statusCode == 200) {
        print("Group notification sent successfully: ${response.body}");
      } else {
        print("Failed to send group notification: ${response.body}");
      }
    } catch (e) {
      print("Exception sending group notification: $e");
    }
  }

  static Future<void> sendIndividualNotification({
    required String playerId,
    required String heading,
    required String content,
    String? bigPicture,
  }) async {
    final Map<String, dynamic> notificationData = {
      "app_id": _appId,
      "include_player_ids": [playerId],
      "headings": {"en": heading},
      "contents": {"en": content},
    };

    if (bigPicture != null) {
      notificationData["big_picture"] = bigPicture;
    }

    try {
      final response = await http.post(
        Uri.parse(_onesignalUrl),
        headers: {
          "Content-Type": "application/json; charset=utf-8",
          "Authorization": _authKey,
        },
        body: jsonEncode(notificationData),
      );

      if (response.statusCode == 200) {
        print("Individual notification sent successfully: ${response.body}");
      } else {
        print("Failed to send individual notification: ${response.body}");
      }
    } catch (e) {
      print("Exception sending individual notification: $e");
    }
  }

  static Future<void> sendNotificationToSpecificUser({
    required String userId,
    required String heading,
    required String content,
    String? bigPicture,
  }) async {
    try {
      // Create the notification content with filters targeting the specific userId
      var notification = {
        "app_id": _appId,
        "headings": {"en": heading},
        "contents": {"en": content},
        "filters": [
          {"field": "tag", "key": "userId", "relation": "=", "value": userId}
        ],
      };

      // Add big picture if provided
      if (bigPicture != null && bigPicture.isNotEmpty) {
        notification["big_picture"] = bigPicture;
      }
      // Send the notification through HTTP request
      final response = await http.post(
        Uri.parse(_onesignalUrl),
        headers: {
          "Content-Type": "application/json; charset=utf-8",
          "Authorization": _authKey,
        },
        body: jsonEncode(notification),
      );

      if (response.statusCode == 200) {
        print('OneSignal notification sent to user with ID: $userId');
      } else {
        print('Failed to send OneSignal notification: ${response.body}');
      }
    } catch (e) {
      print('Error sending OneSignal notification to specific user: $e');
      rethrow;
    }
  }
}
