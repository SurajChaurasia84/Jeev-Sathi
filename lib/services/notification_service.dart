import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'env_loader.dart';

/// Notification service that calls the Vercel backend to send FCM pushes.
///
/// This replaces the old [FCMService] approach of calling FCM directly from
/// the Flutter app with an embedded service-account key.
class NotificationService {
  /// Base URL of the deployed Vercel backend.
  /// Set VERCEL_URL in your .env file after deployment, e.g.:
  ///   VERCEL_URL=https://jeev-sathi-api.vercel.app
  static String get _baseUrl => EnvLoader.get('VERCEL_URL');
  static String get _apiSecret => EnvLoader.get('API_SECRET');

  // ──────────────────────────────────────────────────────────────────────────
  // Public API
  // ──────────────────────────────────────────────────────────────────────────

  /// Broadcasts a New SOS notification to ALL installed users within a 5 km radius
  /// except the person who posted the SOS ([reporterId]).
  static Future<void> notifyNewSOS({
    required String reporterId,
    required String animal,
    required String description,
    required String reportId,
    required double latitude,
    required double longitude,
  }) async {
    await _post('/api/notify-all', {
      'reporterId': reporterId,
      'title': '🚨 आपातकालीन अलर्ट: $animal रेस्क्यू',
      'body': description.isNotEmpty ? description : 'मदद की आवश्यकता है। तुरंत मदद करें!',
      'latitude': latitude,
      'longitude': longitude,
      'data': {
        'type': 'new_sos',
        'id': reportId,
      },
    });
  }

  /// Sends a "SOS Accepted" notification to the SOS reporter ([reporterUid]).
  static Future<void> notifySOSAccepted({
    required String reporterUid,
    required String animal,
    required String reportId,
    required String sevakName,
    String? targetToken,
  }) async {
    await _post('/api/notify-user', {
      'targetUid': reporterUid,
      if (targetToken != null && targetToken.isNotEmpty) 'targetToken': targetToken,
      'title': '✅ आपकी SOS स्वीकार की गई!',
      'body': '$sevakName आपके $animal की सहायता के लिए आ रहे हैं।',
      'data': {
        'type': 'sos_accepted',
        'id': reportId,
      },
    });
  }

  /// Sends a "SOS Resolved" notification to the SOS reporter ([reporterUid]).
  static Future<void> notifySOSResolved({
    required String reporterUid,
    required String animal,
    required String reportId,
    String? targetToken,
  }) async {
    await _post('/api/notify-user', {
      'targetUid': reporterUid,
      if (targetToken != null && targetToken.isNotEmpty) 'targetToken': targetToken,
      'title': '🎉 SOS रेस्क्यू पूर्ण!',
      'body': 'आपके $animal का रेस्क्यू सफलतापूर्वक पूर्ण हो गया। धन्यवाद!',
      'data': {
        'type': 'sos_resolved',
        'id': reportId,
      },
    });
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Private helpers
  // ──────────────────────────────────────────────────────────────────────────

  static Future<void> _post(String path, Map<String, dynamic> body) async {
    final url = _baseUrl;
    if (url.isEmpty) {
      debugPrint('NotificationService: VERCEL_URL not set in .env — skipping notification.');
      return;
    }

    try {
      final response = await http
          .post(
            Uri.parse('$url$path'),
            headers: {
              'Content-Type': 'application/json',
              'x-api-secret': _apiSecret,
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        debugPrint('NotificationService [$path] error ${response.statusCode}: ${response.body}');
      } else {
        debugPrint('NotificationService [$path] sent: ${response.body}');
      }
    } catch (e) {
      // Never let notification errors crash the app
      debugPrint('NotificationService [$path] exception: $e');
    }
  }
}
