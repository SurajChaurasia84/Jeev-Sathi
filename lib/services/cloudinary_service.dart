import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../config/cloudinary_config.dart';

class CloudinaryService {
  /// Uploads a file to Cloudinary via Unsigned Upload Preset.
  /// Returns the secure URL string on success, or throws an exception on failure.
  static Future<String> uploadImage(File file) async {
    final cloudName = CloudinaryConfig.cloudName.trim();
    final uploadPreset = CloudinaryConfig.uploadPreset.trim();

    if (cloudName == 'YOUR_CLOUD_NAME' || uploadPreset == 'YOUR_UPLOAD_PRESET' || cloudName.isEmpty || uploadPreset.isEmpty) {
      throw Exception(
        'Cloudinary setup is incomplete. Please configure your cloudName and uploadPreset in lib/config/cloudinary_config.dart.'
      );
    }

    final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');

    try {
      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', file.path));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final String? secureUrl = responseData['secure_url'];
        if (secureUrl != null && secureUrl.isNotEmpty) {
          return secureUrl;
        } else {
          throw Exception('secure_url missing from response');
        }
      } else {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final String errorMessage = responseData['error']?['message'] ?? 'Unknown Cloudinary error';
        throw Exception('Cloudinary Upload Failed (${response.statusCode}): $errorMessage');
      }
    } catch (e) {
      debugPrint('Cloudinary Upload Error: $e');
      rethrow;
    }
  }
}
