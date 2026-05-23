import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/foundation.dart';

class EnvLoader {
  static final Map<String, String> _env = {};

  /// Loads the environment variables from the .env asset.
  static Future<void> load() async {
    try {
      final String content = await rootBundle.loadString('.env');
      final List<String> lines = content.split('\n');
      for (var line in lines) {
        line = line.trim();
        // Skip empty lines and comments
        if (line.isEmpty || line.startsWith('#')) continue;
        
        final int eqIndex = line.indexOf('=');
        if (eqIndex != -1) {
          final String key = line.substring(0, eqIndex).trim();
          String value = line.substring(eqIndex + 1).trim();
          
          // Remove wrapping quotes if present
          if ((value.startsWith("'") && value.endsWith("'")) ||
              (value.startsWith('"') && value.endsWith('"'))) {
            value = value.substring(1, value.length - 1);
          }
          
          _env[key] = value;
        }
      }
    } catch (e) {
      debugPrint("Warning: Failed to load .env asset: $e");
    }
  }

  /// Retrieves the value of an environment variable.
  static String get(String key, {String fallback = ''}) {
    return _env[key] ?? fallback;
  }
}
