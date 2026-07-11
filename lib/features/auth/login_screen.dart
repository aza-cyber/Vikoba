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

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phone = TextEditingController(text: '+255 ');
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
        phone: _phone.text,
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
      phone: _phone.text,
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (appState.connectionError) const _ConnectionBanner(),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => locale.toggle(),
                  icon: const Icon(Icons.language, size: 18),
                  label: Text(locale.isSwahili ? 'English' : 'Kiswahili'),
                  style: TextButton.styleFrom(
                      foregroundColor: AppColors.textSecondary),
                ),
              ),
              const SizedBox(height: 20),
              const _Logo(),
              const SizedBox(height: 36),
              Text(
                locale.t('welcome_back'),
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                locale.t('login_subtitle'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              Text(
                locale.t('login_role_hint'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 12.5, height: 1.35),
              ),
              const SizedBox(height: 32),
              _label(locale.t('phone_number')),
              const SizedBox(height: 8),
              TextField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                // Same rule as the member form: allow a +255/0 prefix but cap
                // the national number at 9 digits.
                inputFormatters: [TzPhoneInputFormatter()],
                decoration: const InputDecoration(hintText: '+255 7XX XXX XXX'),
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
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loggingIn ? null : _login,
                child: _loggingIn
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text(locale.t('login')),
              ),
              const SizedBox(height: 18),
              Center(
                child: TextButton(
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(locale.t('reset_pin_hint'))),
                  ),
                  child: Text(locale.t('forgot_pin'),
                      style: const TextStyle(color: AppColors.textSecondary)),
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(locale.t('no_account'),
                        style: const TextStyle(color: AppColors.textSecondary)),
                    const SizedBox(width: 4),
                    TextButton(
                      onPressed: _showMembershipRequest,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        minimumSize: const Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(locale.t('ask_admin_register'),
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
              // Server address — only relevant in online (API) mode. Lets you
              // repoint the app at the PC's current IP after a Wi-Fi change
              // without rebuilding the APK.
              if (Config.useApi) ...[
                const SizedBox(height: 28),
                const Divider(height: 1),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () => setState(
                      () => _showAdvancedServer = !_showAdvancedServer),
                  icon: Icon(_showAdvancedServer
                      ? Icons.expand_less
                      : Icons.expand_more),
                  label: Text(locale.t('advanced_settings')),
                  style: TextButton.styleFrom(
                      foregroundColor: AppColors.textSecondary),
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
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : Text(locale.t('save')),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
              const SizedBox(height: 16),
              Center(
                child: TextButton.icon(
                  onPressed: _loggingIn ? null : _showSuperAdminLogin,
                  icon: const Icon(Icons.shield_outlined, size: 18),
                  label: Text(locale.t('super_admin_login')),
                  style: TextButton.styleFrom(
                      foregroundColor: AppColors.textSecondary),
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  '${locale.t('version_label')} ${Config.appVersion}',
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 11.5),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Align(
        alignment: Alignment.centerLeft,
        child: Text(text,
            style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
                fontSize: 13)),
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

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    final locale = context.read<LocaleProvider>();
    return Column(
      children: [
        const AppLogo(
          width: 184,
          height: 112,
          backgroundColor: Colors.transparent,
          borderWidth: 0,
          padding: EdgeInsets.zero,
        ),
        const SizedBox(height: 14),
        Text(
          locale.t('app_name'),
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: AppColors.primary,
            letterSpacing: 1.5,
          ),
        ),
        Text(
          locale.t('app_tagline'),
          style: const TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
              fontSize: 13),
        ),
        const SizedBox(height: 2),
        Text(
          locale.t('app_descriptor'),
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
        ),
      ],
    );
  }
}
