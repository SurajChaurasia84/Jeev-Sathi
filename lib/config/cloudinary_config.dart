import '../services/env_loader.dart';

class CloudinaryConfig {
  static String get cloudName => EnvLoader.get('CLOUDINARY_CLOUD_NAME', fallback: 'dk8tnszro');
  static String get uploadPreset => EnvLoader.get('CLOUDINARY_UPLOAD_PRESET', fallback: 'jeevsathi');
  static String get apiKey => EnvLoader.get('CLOUDINARY_API_KEY', fallback: '695158693225734');
  static String get apiSecret => EnvLoader.get('CLOUDINARY_API_SECRET', fallback: 'Kx67kaAJ1mInY89qMudv0px4IbY');
}

