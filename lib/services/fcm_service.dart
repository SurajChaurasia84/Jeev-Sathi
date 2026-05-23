import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart';
import 'env_loader.dart';

class FCMService {
  static const String _scopes = 'https://www.googleapis.com/auth/firebase.messaging';

  /// Obtains the Google OAuth2 access token using the credentials stored in the .env file.
  static Future<String?> _getAccessToken() async {
    try {
      final String projectId = EnvLoader.get('FIREBASE_PROJECT_ID');
      final String clientEmail = EnvLoader.get('FIREBASE_CLIENT_EMAIL');
      final String privateKeyId = EnvLoader.get('FIREBASE_PRIVATE_KEY_ID');
      
      // Parse the private key from .env (replaces literal '\n' and '\\n' back to actual newlines)
      String privateKey = EnvLoader.get('FIREBASE_PRIVATE_KEY');
      privateKey = privateKey.replaceAll(r'\n', '\n').replaceAll(r'\\n', '\n');

      // If privateKey has wrapping quotes, remove them
      if (privateKey.startsWith('"') && privateKey.endsWith('"')) {
        privateKey = privateKey.substring(1, privateKey.length - 1);
      }

      if (projectId.isEmpty || clientEmail.isEmpty || privateKey.isEmpty) {
        debugPrint('FCMService Error: Missing Firebase credentials in .env file.');
        return null;
      }

      final Map<String, dynamic> credentialsJson = {
        "type": "service_account",
        "project_id": projectId,
        "private_key_id": privateKeyId,
        "private_key": privateKey,
        "client_email": clientEmail,
      };

      final ServiceAccountCredentials credentials = ServiceAccountCredentials.fromJson(credentialsJson);
      final client = await clientViaServiceAccount(credentials, [_scopes]);
      return client.credentials.accessToken.data;
    } catch (e) {
      debugPrint('FCMService: Error fetching access token: $e');
      return null;
    }
  }

  /// Sends a push notification to all users subscribed to the 'sos_alerts' topic.
  static Future<void> sendSOSNotification({
    required String animal,
    required String description,
    required String reportId,
  }) async {
    try {
      final String projectId = EnvLoader.get('FIREBASE_PROJECT_ID');
      if (projectId.isEmpty) {
        debugPrint('FCMService Error: FIREBASE_PROJECT_ID is empty in .env');
        return;
      }

      final String? token = await _getAccessToken();
      if (token == null) {
        debugPrint('FCMService Error: Failed to obtain OAuth2 token.');
        return;
      }

      // New FCM HTTP v1 Endpoint
      final Uri url = Uri.parse('https://fcm.googleapis.com/v1/projects/$projectId/messages:send');

      final response = await http.post(
        url,
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'message': {
            'topic': 'sos_alerts',
            'notification': {
              'title': '🚨 आपातकालीन अलर्ट: $animal रेस्क्यू',
              'body': description.isNotEmpty ? description : 'मदद की आवश्यकता है।',
            },
            'android': {
              'notification': {
                'icon': 'ic_stat_pets',
                'color': '#10B981',
              }
            },
            'data': {
              'click_action': 'FLUTTER_NOTIFICATION_CLICK',
              'id': reportId,
            },
          }
        }),
      );

      debugPrint('FCM v1 Response: ${response.statusCode} - ${response.body}');
    } catch (e) {
      debugPrint('FCMService: Error sending notification: $e');
    }
  }
}
