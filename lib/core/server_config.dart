import 'package:shared_preferences/shared_preferences.dart';
import 'config.dart';

/// Persists the backend address the app talks to, so it can be changed right on
/// the device (e.g. after switching Wi-Fi, when the PC gets a new IP) without
/// editing [Config] and rebuilding the APK.
///
/// Falls back to the compiled-in [Config.apiBaseUrl] when nothing is saved.
class ServerConfig {
  ServerConfig._();

  static const _key = 'server_base_url';

  /// The saved URL, or the compiled-in default if none was saved yet.
  static Future<String> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    return (saved != null && saved.trim().isNotEmpty)
        ? saved.trim()
        : Config.apiBaseUrl;
  }

  /// Persists [url] in canonical form. Returns the value actually stored.
  static Future<String> save(String url) async {
    final normalized = normalize(url);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, normalized);
    return normalized;
  }

  /// Turns lenient input into a canonical `http://host:port` string. Accepts
  /// `192.168.1.5`, `192.168.1.5:8090`, or a full `http://...` URL. Appends the
  /// default port ([Config.apiPort]) when none is given.
  static String normalize(String input) {
    var s = input.trim();
    if (s.isEmpty) return Config.apiBaseUrl;
    if (!s.startsWith('http://') && !s.startsWith('https://')) {
      s = 'http://$s';
    }
    while (s.endsWith('/')) {
      s = s.substring(0, s.length - 1);
    }
    final uri = Uri.tryParse(s);
    if (uri != null && !uri.hasPort) {
      s = '$s:${Config.apiPort}';
    }
    return s;
  }
}
