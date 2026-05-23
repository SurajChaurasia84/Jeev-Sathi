import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../config/cloudinary_config.dart';
import 'package:crypto/crypto.dart';

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

  /// Deletes a file from Cloudinary using the API Key and API Secret.
  /// Extracts the public ID from the secure URL and sends a signed POST request.
  static Future<void> deleteImage(String imageUrl) async {
    final cloudName = CloudinaryConfig.cloudName.trim();
    final apiKey = CloudinaryConfig.apiKey.trim();
    final apiSecret = CloudinaryConfig.apiSecret.trim();

    if (cloudName.isEmpty || cloudName == 'YOUR_CLOUD_NAME') {
      return; // Cannot delete without cloud name
    }

    if (apiKey.isEmpty || apiKey == 'YOUR_API_KEY' || apiSecret.isEmpty || apiSecret == 'YOUR_API_SECRET') {
      debugPrint('Cloudinary credentials (apiKey or apiSecret) are not set. Skipping Cloudinary image deletion.');
      return; // Skip if credentials are not configured
    }

    final String? publicId = _extractPublicId(imageUrl);
    if (publicId == null || publicId.isEmpty) {
      debugPrint('Could not extract public ID from Cloudinary URL: $imageUrl');
      return;
    }

    final int timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    
    // Create the signature: sha1("public_id=<public_id>&timestamp=<timestamp><api_secret>")
    final String signatureString = 'public_id=$publicId&timestamp=$timestamp$apiSecret';
    final String signature = sha1.convert(utf8.encode(signatureString)).toString();

    final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/destroy');

    try {
      final response = await http.post(
        url,
        body: {
          'public_id': publicId,
          'api_key': apiKey,
          'timestamp': timestamp.toString(),
          'signature': signature,
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData['result'] == 'ok') {
          debugPrint('Successfully deleted image from Cloudinary: $publicId');
        } else {
          debugPrint('Cloudinary returned unexpected destroy result: ${responseData['result']}');
        }
      } else {
        debugPrint('Cloudinary Destroy Request Failed with status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Cloudinary Destroy Request Error: $e');
    }
  }

  /// Extracts the public ID from a standard Cloudinary secure URL.
  static String? _extractPublicId(String url) {
    try {
      final Uri uri = Uri.parse(url);
      final List<String> segments = uri.pathSegments;

      final int uploadIndex = segments.indexOf('upload');
      if (uploadIndex == -1 || uploadIndex >= segments.length - 1) {
        return null;
      }

      int startIndex = uploadIndex + 1;
      // Skip the version segment if it starts with 'v' followed by digits
      if (segments[startIndex].startsWith('v') && RegExp(r'^v\d+$').hasMatch(segments[startIndex])) {
        startIndex++;
      }

      final List<String> idSegments = segments.sublist(startIndex);
      if (idSegments.isEmpty) return null;

      final String lastSegment = idSegments.last;
      final int dotIndex = lastSegment.lastIndexOf('.');
      if (dotIndex != -1) {
        idSegments[idSegments.length - 1] = lastSegment.substring(0, dotIndex);
      }

      return idSegments.join('/');
    } catch (e) {
      debugPrint('Failed to extract public ID: $e');
      return null;
    }
  }
}
