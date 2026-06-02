import 'package:flutter/foundation.dart';

/// App configuration. The API base URL is resolved per platform so the app
/// "just works" in the common dev setups without flags:
///
///   * Web (Chrome) / desktop (Windows, macOS, Linux) / iOS simulator
///       → http://localhost:8080/api/v1   (the browser/app runs on the host)
///   * Android emulator
///       → http://10.0.2.2:8080/api/v1    (10.0.2.2 is the emulator's alias
///         for the host machine's loopback)
///
/// Always overridable at run time — this wins over the platform default:
///   flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8080/api/v1
///
/// A physical phone must use the host PC's LAN IP (and the backend listens on
/// all interfaces, so that's reachable) — pass it via --dart-define.
class AppConfig {
  AppConfig._();

  static const String _override =
      String.fromEnvironment('API_BASE_URL', defaultValue: '');

  static String get apiBaseUrl {
    if (_override.isNotEmpty) return _override;
    if (kIsWeb) return 'http://localhost:8080/api/v1';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8080/api/v1';
    }
    return 'http://localhost:8080/api/v1';
  }

  static const Duration apiTimeout = Duration(seconds: 15);
}
