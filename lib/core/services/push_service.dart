import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../data/repository_base.dart';

/// Background isolate handler for messages that arrive while the app is
/// terminated or backgrounded. Must be a top-level function. The OS renders the
/// notification tray entry itself; nothing more is needed here.
@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  // Intentionally empty: the system tray shows the notification. Hook custom
  // background work here later if needed.
}

/// Wraps Firebase Cloud Messaging so the rest of the app never touches Firebase
/// directly — and, crucially, so a missing/incomplete Firebase configuration
/// can never crash the app.
///
/// Everything is guarded: if `Firebase.initializeApp()` throws (no
/// google-services.json / firebase_options yet), push simply stays disabled and
/// [isAvailable] is false. Wire up Firebase (see docs/PUSH_SETUP.md) to turn it
/// on with no further code changes.
class PushService {
  PushService._();
  static final PushService instance = PushService._();

  bool _initialized = false;
  bool _available = false;
  String? _token;

  /// The current device token, or null if push isn't available/permitted.
  String? get token => _token;

  /// Whether Firebase initialised and messaging is usable on this platform.
  bool get isAvailable => _available;

  /// The platform label stored alongside the token server-side.
  String get _platform {
    if (kIsWeb) return 'web';
    return defaultTargetPlatform.name; // android | iOS | ...
  }

  /// Initialises Firebase + messaging once. Safe to call repeatedly and safe to
  /// call when Firebase isn't configured — it just leaves push disabled.
  /// [onMessage] is invoked for notifications that arrive while the app is in
  /// the foreground (the OS does not show those automatically).
  Future<void> init({
    void Function(String title, String body)? onForegroundMessage,
  }) async {
    if (_initialized) return;
    _initialized = true;
    try {
      await Firebase.initializeApp();
      final messaging = FirebaseMessaging.instance;

      // iOS/web require an explicit permission prompt; Android <13 grants by
      // default. Not-determined/denied still leaves the app fully functional.
      final settings = await messaging.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        _available = false;
        return;
      }

      FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);
      FirebaseMessaging.onMessage.listen((m) {
        final n = m.notification;
        if (n != null && onForegroundMessage != null) {
          onForegroundMessage(n.title ?? '', n.body ?? '');
        }
      });

      // getToken() can block indefinitely when FCM has no valid config to
      // register against, so cap it — a null token just leaves push disabled.
      _token = await messaging
          .getToken()
          .timeout(const Duration(seconds: 15), onTimeout: () => null);
      _available = _token != null;
    } catch (e) {
      // No Firebase config, unsupported platform, or a transient error — push
      // stays off and the app carries on normally.
      _available = false;
      if (kDebugMode) {
        debugPrint('PushService: notifications disabled ($e).');
      }
    }
  }

  /// Ensures the device token is registered with [repo] for the current member.
  /// Also keeps the backend in sync when FCM rotates the token. No-op when push
  /// is unavailable.
  Future<void> registerWith(Repository repo) async {
    if (!_available) return;
    final token = _token;
    if (token != null) {
      await repo.registerDevice(token: token, platform: _platform);
    }
    // Re-register whenever FCM issues a new token for this device.
    try {
      FirebaseMessaging.instance.onTokenRefresh.listen((t) {
        _token = t;
        repo.registerDevice(token: t, platform: _platform);
      });
    } catch (_) {
      // Ignore: listening is best-effort.
    }
  }

  /// Removes this device's token from [repo] (called at sign-out) so the phone
  /// stops receiving the signed-out member's notifications.
  Future<void> unregisterFrom(Repository repo) async {
    final token = _token;
    if (token != null) {
      await repo.unregisterDevice(token);
    }
  }
}
