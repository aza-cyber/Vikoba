// ignore_for_file: use_build_context_synchronously

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/l10n/locale_provider.dart';
import '../../core/models/models.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../shell/main_shell.dart';
import '../shell/user_shell.dart';

/// Second step of SMS sign-in: the member has requested a code (sent to
/// [phone]) and now enters it here to complete login. Handles verifying the
/// code and resending a new one after a short cooldown.
///
/// [devCode] is only ever non-null when the backend has no live SMS gateway
/// (development), in which case it is shown on screen so the flow is testable
/// without receiving a real text.
class OtpVerifyScreen extends StatefulWidget {
  final String phone;
  final String? devCode;
  const OtpVerifyScreen({super.key, required this.phone, this.devCode});

  @override
  State<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends State<OtpVerifyScreen> {
  final _code = TextEditingController();
  bool _verifying = false;
  bool _resending = false;
  String? _devCode;

  /// Seconds left before a resend is allowed. Matches the server's 60s resend
  /// window so the button doesn't offer an action the backend would reject.
  int _resendIn = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _devCode = widget.devCode;
    _startCooldown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _code.dispose();
    super.dispose();
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _resendIn = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _resendIn--);
      if (_resendIn <= 0) t.cancel();
    });
  }

  Future<void> _verify() async {
    FocusScope.of(context).unfocus();
    final locale = context.read<LocaleProvider>();
    final code = _code.text.trim();
    if (code.length < 4) {
      _snack(locale.t('otp_wrong_code'), error: true);
      return;
    }
    setState(() => _verifying = true);
    final appState = context.read<AppState>();
    final role = await appState.verifyLoginOtp(phone: widget.phone, code: code);
    if (!mounted) return;
    setState(() => _verifying = false);
    if (role == null) {
      _snack(locale.t(appState.loginErrorKey ?? 'otp_wrong_code'), error: true);
      return;
    }
    _openShell(role, appState);
  }

  Future<void> _resend() async {
    final locale = context.read<LocaleProvider>();
    setState(() => _resending = true);
    final result =
        await context.read<AppState>().requestLoginOtp(phone: widget.phone);
    if (!mounted) return;
    setState(() => _resending = false);
    if (!result.ok) {
      _snack(locale.t(result.errorKey ?? 'otp_send_failed'), error: true);
      return;
    }
    setState(() => _devCode = result.devCode);
    _startCooldown();
    _snack(locale.t('sms_code_sent').replaceFirst('%s', Fmt.phone(widget.phone)));
  }

  void _openShell(MemberRole role, AppState state) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider<AppState>.value(
          value: state,
          child:
              role == MemberRole.admin ? const MainShell() : const UserShell(),
        ),
      ),
    );
  }

  void _snack(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: error ? const Color(0xFFC0392B) : AppColors.primary,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    final canResend = _resendIn <= 0 && !_resending;
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: const BackButton(color: AppColors.textPrimary),
        title: Text(locale.t('sms_login_title')),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              const Icon(Icons.sms_outlined,
                  size: 56, color: AppColors.primary),
              const SizedBox(height: 20),
              Text(
                locale.t('sms_code_sent').replaceFirst(
                    '%s', Fmt.phone(widget.phone)),
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                locale.t('enter_sms_code'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              if (_devCode != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF6E5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFF3D08A)),
                  ),
                  child: Text(
                    locale.t('otp_dev_code').replaceFirst('%s', _devCode!),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Color(0xFF8A6D1B),
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ],
              const SizedBox(height: 28),
              TextField(
                controller: _code,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                autofocus: true,
                maxLength: 6,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                style: const TextStyle(
                    fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: 8),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: '••••••',
                  labelText: locale.t('verification_code'),
                ),
                onSubmitted: (_) => _verify(),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _verifying ? null : _verify,
                child: _verifying
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text(locale.t('verify')),
              ),
              const SizedBox(height: 14),
              Center(
                child: TextButton(
                  onPressed: canResend ? _resend : null,
                  child: _resending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          _resendIn > 0
                              ? locale
                                  .t('resend_in')
                                  .replaceFirst('%s', '$_resendIn')
                              : locale.t('resend_code'),
                          style: TextStyle(
                            color: canResend
                                ? AppColors.primary
                                : AppColors.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
