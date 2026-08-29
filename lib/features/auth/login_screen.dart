// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/config.dart';
import '../../core/l10n/locale_provider.dart';
import '../../core/server_config.dart';
import '../../core/state/app_state.dart';
import '../../core/state/groups_store.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../widgets/common.dart';
import '../shell/main_shell.dart';
import '../shell/user_shell.dart';
import '../superadmin/groups_admin_screen.dart';
import 'group_login.dart';
import 'otp_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _server = TextEditingController();
  final _requestName = TextEditingController();
  final _requestPhone = TextEditingController(text: '+255 ');
  final _requestShares = TextEditingController(text: '1');
  bool _obscure = true;
  bool _showAdvancedServer = false;
  bool _savingServer = false;
  bool _loggingIn = false;

  @override
  void initState() {
    super.initState();
    // Prefill with the address currently in use (saved or compiled-in default).
    ServerConfig.load().then((url) {
      if (mounted) setState(() => _server.text = url);
    });
  }

  @override
  void dispose() {
    _phone.dispose();
    _password.dispose();
    _server.dispose();
    _requestName.dispose();
    _requestPhone.dispose();
    _requestShares.dispose();
    super.dispose();
  }

  /// The member's full phone: the fixed +255 country code plus the national
  /// number typed into the field (which no longer carries the prefix itself).
  String get _fullPhone => '+255 ${_phone.text.trim()}';

  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    final locale = context.read<LocaleProvider>();
    if (_password.text.trim().isEmpty) {
      _showError(locale.t('pin_required'));
      return;
    }

    // Super-admin path: a platform account that manages the group registry,
    // authenticated against the database (online) or the built-in default
    // (offline). A super admin signs in with a username, not a 9-digit phone —
    // so we only attempt this path when the identifier isn't a phone number,
    // keeping normal member logins from making an extra round-trip.
    final phoneDigits = _phone.text.replaceAll(RegExp(r'\D'), '');
    if (phoneDigits.length < 9) {
      setState(() => _loggingIn = true);
      final isSuper = await context
          .read<GroupsStore>()
          .authenticateSuperAdmin(_phone.text, _password.text);
      if (!mounted) return;
      setState(() => _loggingIn = false);
      if (isSuper) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const GroupsAdminScreen()),
        );
        return;
      }
      // Not a super admin and not a valid phone number.
      _showError(locale.t('phone_required'));
      return;
    }

    setState(() => _loggingIn = true);
    final appState = context.read<AppState>();

    if (Config.useApi) {
      // Online: the backend authenticates and scopes the member to their group.
      final role = await appState.login(
        phone: _fullPhone,
        password: _password.text.trim(),
      );
      if (!mounted) return;
      setState(() => _loggingIn = false);
      if (role == null) {
        // The AppState set a precise reason: unreachable server, suspended
        // account, or wrong phone/PIN.
        _showError(locale.t(appState.loginErrorKey ?? 'login_failed'));
        return;
      }
      _openShell(role, appState);
      return;
    }

    // Offline: members live in per-group databases, so find which group's data
    // recognises this phone + PIN and open the app scoped to that group.
    final groups = context.read<GroupsStore>().groups;
    final session = await resolveGroupLogin(
      defaultState: appState,
      groups: groups,
      phone: _fullPhone,
      password: _password.text.trim(),
    );
    if (!mounted) return;
    setState(() => _loggingIn = false);
    if (session == null) {
      _showError(locale.t(appState.loginErrorKey ?? 'login_failed'));
      return;
    }
    _openShell(session.role, session.state);
  }

  /// Starts SMS sign-in: requests a one-time code for the entered phone and, on
  /// success, opens the code-entry screen. Only offered online (API mode), where
  /// the backend can text the code.
  Future<void> _loginWithSms() async {
    FocusScope.of(context).unfocus();
    final locale = context.read<LocaleProvider>();
    final phoneDigits = _phone.text.replaceAll(RegExp(r'\D'), '');
    if (phoneDigits.length < 9) {
      _showError(locale.t('phone_required'));
      return;
    }
    setState(() => _loggingIn = true);
    final result =
        await context.read<AppState>().requestLoginOtp(phone: _fullPhone);
    if (!mounted) return;
    setState(() => _loggingIn = false);
    if (!result.ok) {
      _showError(locale.t(result.errorKey ?? 'otp_send_failed'));
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider<AppState>.value(
          value: context.read<AppState>(),
          child: OtpVerifyScreen(
            phone: _fullPhone,
            devCode: result.devCode,
          ),
        ),
      ),
    );
  }

  /// Opens the admin or member panel scoped to [state] — the group the member
  /// logged into. Providing that [AppState] to the shell makes every screen
  /// below read that group's own members, savings, loans and settings.
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

  /// Dedicated super-admin sign-in. The main identifier field is a phone input
  /// (digits only), so a text username like "superadmin" can't be typed there;
  /// this dialog takes a plain username + PIN and, on success, opens the group
  /// registry. Authenticates against the DB online, or the built-in default
  /// (superadmin / 0000) offline.
  Future<void> _showSuperAdminLogin() async {
    final locale = context.read<LocaleProvider>();
    final userCtrl = TextEditingController();
    final pinCtrl = TextEditingController();
    bool obscure = true;
    bool submitting = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(builder: (context, setDialogState) {
          Future<void> submit() async {
            final user = userCtrl.text.trim();
            final pin = pinCtrl.text.trim();
            if (user.isEmpty || pin.isEmpty) return;
            setDialogState(() => submitting = true);
            final ok = await context
                .read<GroupsStore>()
                .authenticateSuperAdmin(user, pin);
            if (!dialogContext.mounted) return;
            setDialogState(() => submitting = false);
            if (!ok) {
              ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(
                backgroundColor: const Color(0xFFC0392B),
                content: Text(locale.t('login_failed')),
              ));
              return;
            }
            Navigator.pop(dialogContext);
            if (!mounted) return;
            Navigator.of(this.context).pushReplacement(
              MaterialPageRoute(builder: (_) => const GroupsAdminScreen()),
            );
          }

          return AlertDialog(
            backgroundColor: AppColors.surface,
            title: Text(locale.t('super_admin_login')),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: userCtrl,
                    autocorrect: false,
                    enableSuggestions: false,
                    textInputAction: TextInputAction.next,
                    decoration:
                        InputDecoration(labelText: locale.t('username')),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: pinCtrl,
                    obscureText: obscure,
                    keyboardType: TextInputType.number,
                    onSubmitted: (_) => submit(),
                    decoration: InputDecoration(
                      labelText: locale.t('password'),
                      suffixIcon: IconButton(
                        icon: Icon(
                            obscure ? Icons.visibility_off : Icons.visibility,
                            color: AppColors.textMuted),
                        onPressed: () =>
                            setDialogState(() => obscure = !obscure),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed:
                    submitting ? null : () => Navigator.pop(dialogContext),
                child: Text(locale.t('cancel')),
              ),
              ElevatedButton(
                style:
                    ElevatedButton.styleFrom(minimumSize: const Size(90, 44)),
                onPressed: submitting ? null : submit,
                child: submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text(locale.t('login')),
              ),
            ],
          );
        });
      },
    );
    userCtrl.dispose();
    pinCtrl.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: const Color(0xFFC0392B),
    ));
  }

  Future<void> _saveServer() async {
    FocusScope.of(context).unfocus();
    setState(() => _savingServer = true);
    final ok = await context.read<AppState>().setServerUrl(_server.text);
    if (!mounted) return;
    final locale = context.read<LocaleProvider>();
    setState(() {
      _savingServer = false;
      _server.text = ServerConfig.normalize(_server.text);
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok ? locale.t('connected') : locale.t('connection_error')),
      backgroundColor: ok ? AppColors.primary : const Color(0xFFC0392B),
    ));
  }

  Future<void> _showMembershipRequest() async {
    _requestName.clear();
    _requestPhone.text = '+255 ';
    _requestShares.text = '1';
    bool submitting = false;
    final locale = context.read<LocaleProvider>();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(builder: (context, setDialogState) {
          Future<void> submit() async {
            final name = _requestName.text.trim();
            final phone = Fmt.phone(_requestPhone.text);
            final shares = int.tryParse(_requestShares.text.trim()) ?? 1;
            if (name.isEmpty) return;
            setDialogState(() => submitting = true);
            final error = await context.read<AppState>().requestMembership(
                  name: name,
                  phone: phone,
                  shares: shares,
                );
            if (!context.mounted) return;
            setDialogState(() => submitting = false);
            final messenger = ScaffoldMessenger.of(this.context);
            if (error != null) {
              messenger.showSnackBar(SnackBar(
                backgroundColor: const Color(0xFFC0392B),
                content: Text(error),
              ));
              return;
            }
            Navigator.pop(dialogContext);
            messenger.showSnackBar(SnackBar(
              backgroundColor: AppColors.primary,
              content: Text(locale.t('membership_request_sent')),
            ));
          }

          return AlertDialog(
            backgroundColor: AppColors.surface,
            title: Text(locale.t('request_membership')),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _requestName,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(labelText: locale.t('member')),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _requestPhone,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [TzPhoneInputFormatter()],
                    decoration:
                        InputDecoration(labelText: locale.t('phone_number')),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _requestShares,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: locale.t('shares')),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed:
                    submitting ? null : () => Navigator.pop(dialogContext),
                child: Text(locale.t('cancel')),
              ),
              ElevatedButton(
                onPressed: submitting ? null : submit,
                child: submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text(locale.t('submit_request')),
              ),
            ],
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    final appState = context.watch<AppState>();
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SingleChildScrollView(
        // Keep the form a comfortable reading width and centre it, so the
        // screen stays tidy on tablets and the web build.
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _hero(locale),
                // The form sheet lifts up over the hero's base, so its rounded
                // top corners reveal the green behind them — a modern overlap.
                Transform.translate(
                  offset: const Offset(0, -26),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: AppColors.surface,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(28)),
                    ),
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (appState.connectionError) ...[
                          const _ConnectionBanner(),
                          const SizedBox(height: 8),
                        ],
                        _credentialsForm(locale),
                        const SizedBox(height: 22),
                        _primaryActions(locale),
                        const SizedBox(height: 18),
                        _helpLinks(locale),
                        // Server address — only relevant in online (API) mode.
                        if (Config.useApi) _advancedServer(locale),
                        const SizedBox(height: 12),
                        _footer(locale),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// The branded header: a green gradient banner with a curved base, holding the
  /// language pill, the logo in a floating white badge, and the app wordmark +
  /// tagline. Gives the screen an immediate, attractive brand identity.
  Widget _hero(LocaleProvider locale) {
    final topInset = MediaQuery.of(context).padding.top;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(24, topInset + 14, 24, 46),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
      ),
      child: Column(
        children: [
          Align(alignment: Alignment.centerRight, child: _langPill(locale)),
          const SizedBox(height: 4),
          // Logo in a floating white circle. A long-press here is the discreet,
          // unadvertised entry to the super-admin sign-in — there is no visible
          // button for it, keeping that privileged path off the screen.
          GestureDetector(
            onLongPress: _loggingIn ? null : _showSuperAdminLogin,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const AppLogo(
                size: 96,
                backgroundColor: Colors.transparent,
                borderWidth: 0,
                padding: EdgeInsets.zero,
              ),
            ),
          ),
          const SizedBox(height: 22),
          Text(
            locale.t('app_tagline'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            locale.t('app_descriptor'),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.88),
              fontWeight: FontWeight.w500,
              fontSize: 13.5,
            ),
          ),
        ],
      ),
    );
  }

  /// Translucent language switch pill, sat in the top-right of the hero.
  Widget _langPill(LocaleProvider locale) => Material(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(30),
        child: InkWell(
          onTap: () => locale.toggle(),
          borderRadius: BorderRadius.circular(30),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.language, size: 16, color: Colors.white),
                const SizedBox(width: 6),
                Text(locale.isSwahili ? 'English' : 'Kiswahili',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      );

  /// Phone number and PIN inputs.
  Widget _credentialsForm(LocaleProvider locale) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _label(locale.t('phone_number')),
          const SizedBox(height: 8),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            // The national number is entered here; the fixed +255 country code
            // is shown as a prefix and prepended at sign-in.
            inputFormatters: [TzPhoneInputFormatter()],
            decoration: InputDecoration(
              hintText: locale.t('enter_phone'),
              prefixIcon: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 10, 0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text('+255',
                        style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                            fontSize: 16)),
                  ],
                ),
              ),
              prefixIconConstraints:
                  const BoxConstraints(minWidth: 0, minHeight: 0),
              suffixIcon: const Icon(Icons.keyboard_arrow_down,
                  color: AppColors.textMuted),
            ),
          ),
          const SizedBox(height: 18),
          _label(locale.t('password')),
          const SizedBox(height: 8),
          TextField(
            controller: _password,
            obscureText: _obscure,
            decoration: InputDecoration(
              hintText: locale.t('pin_hint'),
              suffixIcon: IconButton(
                icon: Icon(
                    _obscure ? Icons.visibility_off : Icons.visibility,
                    color: AppColors.textMuted),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
        ],
      );

  /// Primary sign-in button, plus the SMS option in online mode.
  Widget _primaryActions(LocaleProvider locale) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton(
            onPressed: _loggingIn ? null : _login,
            child: _loggingIn ? _buttonSpinner() : Text(locale.t('login')),
          ),
          // SMS sign-in needs the backend to text a code, so it's only
          // offered in online (API) mode.
          if (Config.useApi) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _loggingIn ? null : _loginWithSms,
              icon: const Icon(Icons.sms_outlined, size: 18),
              label: Text(locale.t('login_with_sms')),
            ),
          ],
        ],
      );

  /// Forgot-PIN prompt and the membership-request link, framed by divider lines.
  Widget _helpLinks(LocaleProvider locale) => Column(
        children: [
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 6),
          TextButton(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(locale.t('reset_pin_hint'))),
            ),
            child: Text(locale.t('forgot_pin'),
                style: const TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: _showMembershipRequest,
            child: Text(locale.t('ask_admin_register'),
                style: const TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 6),
          const Divider(height: 1, color: AppColors.border),
        ],
      );

  /// Collapsible server-address panel. Lets you repoint the app at the PC's
  /// current IP after a Wi-Fi change without rebuilding the APK.
  Widget _advancedServer(LocaleProvider locale) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 28),
          const Divider(height: 1),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () =>
                setState(() => _showAdvancedServer = !_showAdvancedServer),
            icon: Icon(
                _showAdvancedServer ? Icons.expand_less : Icons.expand_more),
            label: Text(locale.t('advanced_settings')),
            style:
                TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
          ),
          if (_showAdvancedServer) ...[
            const SizedBox(height: 8),
            _label(locale.t('server_address')),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: TextField(
                    controller: _server,
                    keyboardType: TextInputType.url,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: InputDecoration(
                        hintText: '192.168.1.20:${Config.apiPort}'),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    // The app-wide button theme uses Size.fromHeight
                    // (full width); override with a finite min width.
                    style: ElevatedButton.styleFrom(
                        minimumSize: const Size(80, 48)),
                    onPressed: _savingServer ? null : _saveServer,
                    child: _savingServer
                        ? _buttonSpinner(18)
                        : Text(locale.t('save')),
                  ),
                ),
              ],
            ),
          ],
        ],
      );

  /// App version string. The super-admin sign-in has no visible control here;
  /// it is reached only by long-pressing the logo (see [_hero]).
  Widget _footer(LocaleProvider locale) => Column(
        children: [
          Center(
            child: Text(
              '${locale.t('version_label')} ${Config.appVersion}',
              style: const TextStyle(
                  color: AppColors.textMuted, fontSize: 11.5),
            ),
          ),
          const SizedBox(height: 8),
        ],
      );

  Widget _label(String text) => Align(
        alignment: Alignment.centerLeft,
        child: Text(text,
            style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
                fontSize: 13)),
      );

  /// White spinner sized to sit inside a filled button while it's busy.
  Widget _buttonSpinner([double size = 20]) => SizedBox(
        width: size,
        height: size,
        child: const CircularProgressIndicator(
            strokeWidth: 2, color: Colors.white),
      );
}

/// Shown on the login screen when the app launched but couldn't reach the
/// backend. Lets the user retry once the server/Wi-Fi is sorted, without
/// having to restart the app.
class _ConnectionBanner extends StatefulWidget {
  const _ConnectionBanner();

  @override
  State<_ConnectionBanner> createState() => _ConnectionBannerState();
}

class _ConnectionBannerState extends State<_ConnectionBanner> {
  bool _retrying = false;

  Future<void> _retry() async {
    setState(() => _retrying = true);
    await context.read<AppState>().refresh();
    if (mounted) setState(() => _retrying = false);
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.read<LocaleProvider>();
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFDECEC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF5C2C2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_off, color: Color(0xFFC0392B), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              locale.t('connection_error'),
              style: const TextStyle(
                  color: Color(0xFFC0392B), fontSize: 12.5, height: 1.3),
            ),
          ),
          const SizedBox(width: 8),
          _retrying
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : TextButton(
                  onPressed: _retry,
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFC0392B),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(0, 0),
                  ),
                  child: Text(locale.t('retry')),
                ),
        ],
      ),
    );
  }
}

