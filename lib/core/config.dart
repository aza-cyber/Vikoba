/// App-wide configuration.
///
/// Nothing here needs editing to change environment: every value is overridable
/// at build time with `--dart-define`, and the server address is *also*
/// changeable on-device (login screen → Server address, persisted by
/// [ServerConfig]). So switching Wi-Fi/IP — or building an offline APK — never
/// requires touching this file or rebuilding just to change a constant.
///
/// Examples:
///   flutter run --dart-define=API_BASE_URL=http://192.168.1.20:8090
///   flutter build apk --dart-define=USE_API=false
///   flutter build apk --dart-define=API_PORT=8080
class Config {
  Config._();

  /// Human-facing app version, shown on the login screen for support. Keep in
  /// sync with pubspec.yaml's `version:` (before the build `+N`).
  static const String appVersion = '1.0.0';

  /// Storage backend. true = online API (PostgreSQL via the HTTP backend),
  /// false = offline SQLite (Drift). Override: `--dart-define=USE_API=false`.
  static const bool useApi = bool.fromEnvironment('USE_API', defaultValue: true);

  /// Port used when a typed server address omits one, and in [apiBaseUrl]'s
  /// default below. Override: `--dart-define=API_PORT=8090`.
  static const int apiPort = int.fromEnvironment('API_PORT', defaultValue: 8090);

  /// Compiled-in default backend URL — used only until an address is saved
  /// on-device. It deliberately does NOT hard-code a specific LAN IP: pass yours
  /// at build time (`--dart-define=API_BASE_URL=http://<your-PC-IP>:8090`) or
  /// just type it into the app once (it persists). The default 10.0.2.2 is the
  /// Android emulator's alias for the host PC.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8090',
  );
}
