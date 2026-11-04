import 'package:flutter/foundation.dart' show kIsWeb;

class Config {
  /// Override with: flutter run --dart-define=API_URL=http://192.168.1.10:3000
  static const _apiUrl = String.fromEnvironment('API_URL');

  static String get baseUrl {
    if (_apiUrl.isNotEmpty) return _apiUrl;
    if (kIsWeb) return Uri.base.origin; // nginx proxies /api and /socket.io
    return 'http://10.0.2.2:3000'; // Android emulator -> host machine
  }
}
