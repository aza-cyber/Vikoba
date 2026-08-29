/// SMS delivery for the VICOBA API — currently the Africa's Talking gateway,
/// used to send login one-time passcodes (OTP).
///
/// Kept behind the small [SmsSender] interface so the server depends on the
/// capability, not the vendor: swapping in Twilio (or a fake for tests) is a
/// one-line change at the call site. When no provider is configured the server
/// uses [NoopSmsSender], which logs instead of sending — so the OTP flow works
/// end-to-end in development without an SMS account.
library;

import 'dart:convert';

import 'package:http/http.dart' as http;

/// The outcome of a send attempt. [ok] is false when the gateway rejected the
/// message or the request failed; [detail] carries a human-readable reason for
/// the server log (never shown to the app).
class SmsResult {
  final bool ok;
  final String detail;
  const SmsResult(this.ok, this.detail);
}

abstract class SmsSender {
  /// Sends [message] to [toPhone] (E.164, e.g. "+255712345678"). Never throws —
  /// transport/gateway failures are reported via [SmsResult.ok] == false.
  Future<SmsResult> send({required String toPhone, required String message});

  /// Whether a real gateway is wired up. When false the caller may surface the
  /// code another way (e.g. return it in the dev response) so the flow is
  /// testable without an SMS account.
  bool get isLive;
}

/// Resolves the configured sender from environment variables:
///   AT_USERNAME   Africa's Talking username ('sandbox' for the test account)
///   AT_API_KEY    Africa's Talking API key
///   AT_SENDER_ID  optional alphanumeric sender id / short code
/// If username or key is missing, returns a [NoopSmsSender] (dev mode).
SmsSender smsSenderFromEnv(Map<String, String> env, {http.Client? client}) {
  final username = (env['AT_USERNAME'] ?? '').trim();
  final apiKey = (env['AT_API_KEY'] ?? '').trim();
  if (username.isEmpty || apiKey.isEmpty) return const NoopSmsSender();
  return AfricasTalkingSms(
    username: username,
    apiKey: apiKey,
    senderId: (env['AT_SENDER_ID'] ?? '').trim(),
    client: client,
  );
}

/// No real gateway configured: logs the message and reports success so the
/// server can carry on. Pair with a dev-only response that echoes the code.
class NoopSmsSender implements SmsSender {
  const NoopSmsSender();

  @override
  bool get isLive => false;

  @override
  Future<SmsResult> send({
    required String toPhone,
    required String message,
  }) async {
    // Intentionally not printing the message body (it contains the OTP) to
    // stdout here — the caller logs a redacted line. Return ok so the flow
    // proceeds; the code is surfaced via the dev response instead.
    return const SmsResult(true, 'noop (no SMS provider configured)');
  }
}

/// Africa's Talking bulk-SMS gateway. Popular across East Africa (Tanzania,
/// Kenya) where VICOBA groups operate. Uses the version1 messaging endpoint:
/// an application/x-www-form-urlencoded POST authenticated by the `apiKey`
/// header. See https://developers.africastalking.com/docs/sms/sending/bulk.
class AfricasTalkingSms implements SmsSender {
  AfricasTalkingSms({
    required this.username,
    required this.apiKey,
    this.senderId = '',
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String username;
  final String apiKey;

  /// Optional registered sender id / short code. When empty, Africa's Talking
  /// sends from a shared pool number.
  final String senderId;

  final http.Client _client;

  /// The 'sandbox' username uses the sandbox host; live accounts use the
  /// production host.
  Uri get _endpoint => Uri.parse(username == 'sandbox'
      ? 'https://api.sandbox.africastalking.com/version1/messaging'
      : 'https://api.africastalking.com/version1/messaging');

  @override
  bool get isLive => true;

  @override
  Future<SmsResult> send({
    required String toPhone,
    required String message,
  }) async {
    try {
      final res = await _client
          .post(
            _endpoint,
            headers: {
              'apiKey': apiKey,
              'Content-Type': 'application/x-www-form-urlencoded',
              'Accept': 'application/json',
            },
            body: {
              'username': username,
              'to': toPhone,
              'message': message,
              if (senderId.isNotEmpty) 'from': senderId,
            },
          )
          .timeout(const Duration(seconds: 10));

      if (res.statusCode < 200 || res.statusCode >= 300) {
        return SmsResult(false, 'HTTP ${res.statusCode}: ${res.body}');
      }
      // A successful call returns SMSMessageData.Recipients[].status == 'Success'
      // per number. Treat "no recipient accepted" as a failure so the caller
      // knows the number was rejected (e.g. unroutable).
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final recipients = (body['SMSMessageData']
              as Map<String, dynamic>?)?['Recipients'] as List<dynamic>? ??
          const [];
      final accepted = recipients.any((r) =>
          (r as Map<String, dynamic>)['status'].toString().toLowerCase() ==
          'success');
      return accepted
          ? const SmsResult(true, 'sent')
          : SmsResult(false, 'no recipient accepted: ${res.body}');
    } catch (e) {
      return SmsResult(false, 'send failed: $e');
    }
  }
}
