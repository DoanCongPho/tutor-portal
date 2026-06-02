/// Compile-time configuration.
///
/// Override at run time with `--dart-define`:
///   flutter run --dart-define=API_BASE_URL=http://localhost:8080/api/v1
///
/// Defaults assume the backend runs on the host machine and is reached from
/// the Android emulator (10.0.2.2). For iOS simulator or web, override to
/// http://localhost:8080/api/v1.
class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8080/api/v1',
  );

  static const Duration apiTimeout = Duration(seconds: 15);
}
