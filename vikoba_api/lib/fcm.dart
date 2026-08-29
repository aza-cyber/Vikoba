/// Push notifications for the VICOBA API via Firebase Cloud Messaging (FCM)
/// HTTP v1.
///
/// Behind the [PushSender] interface so the server depends on the capability,
/// not on Firebase specifically. When no service account is configured the
/// server uses [NoopPushSender], which logs instead of sending — so the rest of
/// the app (device registration, event hooks) works end-to-end without a
/// Firebase project. Drop in a service account to go live; no code changes.
///
/// To activate:
///   1. Create a Firebase project and enable Cloud Messaging.
///   2. Project settings → Service accounts → "Generate new private key" — this
///      downloads a service-account JSON.
///   3. Point the server at it: set FCM_SERVICE_ACCOUNT=/path/to/that.json
///      (its `project_id` field is read automatically).
library;

import 'dart:convert';
import 'dart:io';

import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

/// The result of a fan-out send: how many device tokens FCM accepted, and any
/// tokens it reported as permanently invalid (unregistered/uninstalled) so the
/// caller can prune them from the database.
class PushResult {
  final int sent;
  final List<String> invalidTokens;
  const PushResult(this.sent, this.invalidTokens);
}

abstract class PushSender {
  /// Sends a notification with [title]/[body] (and optional [data]) to each of
  /// [tokens]. Never throws — per-token failures are absorbed and reflected in
  /// the returned [PushResult].
  Future<PushResult> sendToTokens(
    List<String> tokens, {
    required String title,
    required String body,
    Map<String, String>? data,
  });

  /// Whether a real FCM project is wired up. When false, [sendToTokens] logs
  /// and returns an empty result.
  bool get isLive;
}

/// Builds the configured sender. Reads a Firebase service-account JSON from the
/// path in FCM_SERVICE_ACCOUNT (or GOOGLE_APPLICATION_CREDENTIALS). If neither
/// is set or the file can't be read, returns a [NoopPushSender].
PushSender pushSenderFromEnv(Map<String, String> env, {http.Client? client}) {
  final path = (env['FCM_SERVICE_ACCOUNT'] ??
          env['GOOGLE_APPLICATION_CREDENTIALS'] ??
          '')
      .trim();
  if (path.isEmpty) return const NoopPushSender();
  try {
    final json = jsonDecode(File(path).readAsStringSync())
        as Map<String, dynamic>;
    final projectId = (json['project_id'] ?? '').toString();
    if (projectId.isEmpty) {
      stdout.writeln('FCM: service account has no project_id; push disabled.');
      return const NoopPushSender();
    }
    return FcmV1Sender(
      credentials: ServiceAccountCredentials.fromJson(json),
      projectId: projectId,
      client: client,
    );
  } catch (e) {
    stdout.writeln('FCM: could not load service account ($path): $e — '
        'push disabled.');
    return const NoopPushSender();
  }
}

/// No Firebase configured: logs a redacted line and reports nothing sent.
class NoopPushSender implements PushSender {
  const NoopPushSender();

  @override
  bool get isLive => false;

  @override
  Future<PushResult> sendToTokens(
    List<String> tokens, {
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    if (tokens.isNotEmpty) {
      stdout.writeln('FCM (noop): would notify ${tokens.length} device(s): '
          '"$title".');
    }
    return const PushResult(0, []);
  }
}

/// Firebase Cloud Messaging HTTP v1 sender. Authenticates each send with a
/// short-lived OAuth2 access token derived from the service account (refreshed
/// automatically), then POSTs one message per device token to
/// `/v1/projects/{projectId}/messages:send`.
class FcmV1Sender implements PushSender {
  FcmV1Sender({
    required this.credentials,
    required this.projectId,
    http.Client? client,
  }) : _baseClient = client;

  final ServiceAccountCredentials credentials;
  final String projectId;
  final http.Client? _baseClient;

  static const _scopes = ['https://www.googleapis.com/auth/firebase.messaging'];

  AutoRefreshingAuthClient? _authClient;

  @override
  bool get isLive => true;

  Future<AutoRefreshingAuthClient> _client() async {
    return _authClient ??= _baseClient == null
        ? await clientViaServiceAccount(credentials, _scopes)
        : await clientViaServiceAccount(credentials, _scopes,
            baseClient: _baseClient);
  }

  Uri get _endpoint =>
      Uri.parse('https://fcm.googleapis.com/v1/projects/$projectId/messages:send');

  @override
  Future<PushResult> sendToTokens(
    List<String> tokens, {
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    if (tokens.isEmpty) return const PushResult(0, []);
    final client = await _client();
    var sent = 0;
    final invalid = <String>[];

    for (final token in tokens) {
      try {
        final payload = {
          'message': {
            'token': token,
            'notification': {'title': title, 'body': body},
            if (data != null && data.isNotEmpty) 'data': data,
            'android': {'priority': 'high'},
          }
        };
        final res = await client
            .post(_endpoint,
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode(payload))
            .timeout(const Duration(seconds: 10));
        if (res.statusCode >= 200 && res.statusCode < 300) {
          sent++;
        } else if (res.statusCode == 404 || res.statusCode == 400) {
          // 404 UNREGISTERED / 400 invalid-argument → the token is dead; tell
          // the caller so it can be removed.
          invalid.add(token);
          stdout.writeln('FCM: dropping invalid token '
              '(...${token.length > 6 ? token.substring(token.length - 6) : token}): '
              '${res.statusCode}');
        } else {
          stdout.writeln('FCM: send failed ${res.statusCode}: ${res.body}');
        }
      } catch (e) {
        stdout.writeln('FCM: send error: $e');
      }
    }
    return PushResult(sent, invalid);
  }
}
