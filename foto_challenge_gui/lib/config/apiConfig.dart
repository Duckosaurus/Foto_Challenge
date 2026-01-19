import 'package:flutter/foundation.dart';

class ApiConfig {
  // Dev-URLs
  static const String _androidEmulatorBase = "http://10.0.2.2:3000";
  static const String _webBase = "http://localhost:3000";

  // Optional: wenn du später echte Geräte nutzt:
  // static const String _deviceBase = "http://192.168.0.123:3000";

  static String get baseUrl => kIsWeb ? _webBase : _androidEmulatorBase;
}
