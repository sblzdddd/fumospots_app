import 'package:get_it/get_it.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/config/fumospots_config.dart';
import '../../../core/services/fumo_client_error.dart';
import '../auth_controller.dart';
import '../auth_flow.dart';
import 'auth_browser_page.dart';
import 'auth_login_fields.dart';
import 'auth_login_methods.dart';
import 'auth_login_mode.dart';
import 'auth_username_form.dart';

class AuthLoginView extends StatefulWidget {
  const AuthLoginView({super.key});

  @override
  State<AuthLoginView> createState() => _AuthLoginViewState();
}

class _AuthLoginViewState extends State<AuthLoginView> {
  final AuthController _auth = GetIt.instance<AuthController>();
  final AuthLinks _links = AuthLinks.fromConfig(
    GetIt.instance<FumospotsConfig>(),
  );
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirm = TextEditingController();
  final TextEditingController _callback = TextEditingController();
  final TextEditingController _username = TextEditingController();
  final GlobalKey _formKey = GlobalKey();

  AuthLoginSection _section = AuthLoginSection.login;
  int? _methodIndex;
  String? _formError;
  String? _notice;
  String _otpType = 'email';
  bool _awaitingEmail = false;
  bool _setupUsername = false;
  bool _closing = false;

  AuthEmailMode? get _mode => authEmailMode(_section, _methodIndex);

  bool get _registering => _section == AuthLoginSection.register;

  @override
  void initState() {
    super.initState();
    _auth.addListener(_onAuthChanged);
    _setupUsername =
        _auth.isSignedIn && _auth.user != null && !_auth.hasUsername;
    if (_auth.isSignedIn && _auth.hasUsername) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _leaveIfSignedIn());
    }
  }

  @override
  void dispose() {
    _auth.removeListener(_onAuthChanged);
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    _callback.dispose();
    _username.dispose();
    super.dispose();
  }

  void _onAuthChanged() {
    _leaveIfSignedIn();
  }

  void _leaveIfSignedIn() {
    if (!mounted || !_auth.isSignedIn || _auth.user == null || _closing) {
      return;
    }
    final route = ModalRoute.of(context);
    if (route != null && !route.isCurrent) {
      return;
    }
    if (!_auth.hasUsername) {
      if (!_setupUsername) {
        setState(() => _setupUsername = true);
      }
      return;
    }
    _closing = true;
    Navigator.of(context).pop();
  }


  String get _submitLabel {
    if (_auth.busy) {
      return 'Processing...';
    }
    return switch (_mode) {
      AuthEmailMode.password => 'Log in',
      AuthEmailMode.link => 'Send login link',
      AuthEmailMode.register => 'Register',
      null => 'Log in / Register',
    };
  }

  bool get _canSubmit =>
      _mode != null && !_auth.busy && _email.text.trim().isNotEmpty;

  void _setSection(AuthLoginSection section) {
    if (_section == section || _auth.busy) {
      return;
    }
    setState(() {
      _section = section;
      _callback.clear();
      _formError = null;
      _notice = null;
      _awaitingEmail = false;
      if (section == AuthLoginSection.register && _methodIndex == 0) {
        _methodIndex = 1;
      }
    });
  }

  void _setMethod(int? index) {
    if (_auth.busy || index == _methodIndex) {
      return;
    }
    setState(() {
      _methodIndex = index;
      if (index == 0) {
        _section = AuthLoginSection.login;
      }
      _formError = null;
      _notice = null;
      _awaitingEmail = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = _formKey.currentContext;
      if (target != null) {
        Scrollable.ensureVisible(
          target,
          alignment: 0.2,
          duration: const Duration(milliseconds: 250),
        );
      }
    });
  }

  bool _validate() {
    final mode = _mode;
    if (mode == null) {
      _formError = 'Choose an email method first.';
      return false;
    }
    if (_email.text.trim().isEmpty) {
      _formError = 'Please enter an email address.';
      return false;
    }
    final needsPassword = mode != AuthEmailMode.link;
    if (needsPassword && _password.text.length < authMinPasswordLength) {
      _formError =
          'Password must be at least $authMinPasswordLength characters.';
      return false;
    }
    if (mode == AuthEmailMode.register && _password.text != _confirm.text) {
      _formError = 'The passwords do not match.';
      return false;
    }
    return true;
  }

  Future<void> _submit() async {
    if (!_validate()) {
      setState(() {});
      return;
    }
    setState(() {
      _formError = null;
      _notice = null;
    });
    try {
      switch (_mode) {
        case AuthEmailMode.password:
          await _auth.signInWithPassword(
            email: _email.text,
            password: _password.text,
          );
          _leaveIfSignedIn();
        case AuthEmailMode.register:
          final established = await _auth.signUpWithPassword(
            email: _email.text,
            password: _password.text,
          );
          if (!mounted) {
            return;
          }
          if (!established) {
            setState(() {
              _notice = 'Registration submitted. Please open the confirmation link in your email before logging in. If you cannot find it, please check spam.';
              _awaitingEmail = true;
              _otpType = 'signup';
            });
            return;
          }
          _leaveIfSignedIn();
        case AuthEmailMode.link:
          await _auth.sendMagicLink(email: _email.text);
          if (!mounted) {
            return;
          }
          setState(() {
            _notice = 'The login link has been sent to your email. Open the link in the email to come back and continue. If you cannot find it, please check spam.';
            _awaitingEmail = true;
            _otpType = 'email';
          });
        case null:
          break;
      }
    } on FumoClientError catch (error) {
      if (mounted) {
        setState(() => _formError = error.message);
      }
    }
  }

  Future<void> _submitOAuth(AuthOAuthOption option) async {
    if (_auth.busy) {
      return;
    }
    setState(() {
      _formError = null;
      _notice = null;
    });
    try {
      final pkce = AuthPkce.generate();
      final url = _links.authorize(
        provider: option.provider,
        codeChallenge: pkce.challenge,
        scopes: option.scopes,
      );
      final result = await Navigator.of(context).push<AuthBrowserResult>(
        MaterialPageRoute(
          builder: (_) => AuthBrowserPage(
            initialUrl: url,
            callbackUri: _links.loginRedirect,
            codeVerifier: pkce.verifier,
            title: _registering ? option.registerLabel : option.loginLabel,
          ),
        ),
      );
      if (!mounted || result == null) {
        return;
      }
      if (result.succeeded) {
        _leaveIfSignedIn();
        return;
      }
      setState(() => _formError = result.message ?? option.failureMessage);
    } on FumoClientError catch (error) {
      if (mounted) {
        setState(() => _formError = error.message);
      }
    }
  }

  Future<void> _continueEmail() async {
    final value = _callback.text.trim();
    if (value.isEmpty) {
      setState(() => _formError = 'Paste the email link or enter the code.');
      return;
    }
    setState(() => _formError = null);
    final uri = _uriFromInput(value);
    if (uri != null) {
      final result = await Navigator.of(context).push<AuthBrowserResult>(
        MaterialPageRoute(
          builder: (_) => AuthBrowserPage(
            initialUrl: uri,
            callbackUri: _links.loginRedirect,
            title: 'Email link',
          ),
        ),
      );
      if (!mounted || result == null) {
        return;
      }
      if (result.succeeded) {
        _leaveIfSignedIn();
        return;
      }
      setState(
        () => _formError = result.message ?? 'Email verification failed.',
      );
      return;
    }
    try {
      await _auth.verifyEmailCode(
        email: _email.text,
        token: value.replaceAll(RegExp(r'\s+'), ''),
        type: _otpType,
      );
      _leaveIfSignedIn();
    } on FumoClientError catch (error) {
      if (mounted) {
        setState(() => _formError = error.message);
      }
    }
  }

  Uri? _uriFromInput(String value) {
    final match = RegExp(
      r'https?://\S+',
      caseSensitive: false,
    ).firstMatch(value);
    if (match == null) {
      return null;
    }
    var raw = match.group(0)!;
    while (raw.endsWith('.') || raw.endsWith(',') || raw.endsWith(')')) {
      raw = raw.substring(0, raw.length - 1);
    }
    final uri = Uri.tryParse(raw);
    if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
      return null;
    }
    return uri;
  }

  Future<void> _saveUsername() async {
    final value = _username.text.trim().toLowerCase();
    if (!authUsernamePattern.hasMatch(value)) {
      setState(() {
        _formError =
            'Author ID must be 3-24 letters, numbers, underscores, or hyphens.';
      });
      return;
    }
    setState(() => _formError = null);
    try {
      await _auth.saveUsername(value);
      if (mounted) {
        _leaveIfSignedIn();
      }
    } on FumoClientError catch (error) {
      if (mounted) {
        setState(() => _formError = error.message);
      }
    }
  }

  Future<void> _signOut() async {
    try {
      await _auth.signOut();
    } on FumoClientError catch (error) {
      if (mounted) {
        setState(() => _formError = error.message);
      }
      return;
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _setupUsername = false;
      _formError = null;
      _section = AuthLoginSection.login;
      _methodIndex = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_setupUsername ? 'Author ID' : 'Log in / Register'),
      ),
      body: ListenableBuilder(
        listenable: _auth,
        builder: (context, _) {
          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                children: [
                  if (_setupUsername)
                    AuthUsernameForm(
                      email: _auth.user?.email,
                      username: _username,
                      busy: _auth.busy,
                      error: _formError,
                      onSave: _saveUsername,
                      onSignOut: _signOut,
                      onChanged: () => setState(() {}),
                    )
                  else ...[
                    AuthLoginMethods(
                      section: _section,
                      methodIndex: _methodIndex,
                      busy: _auth.busy,
                      onSectionChanged: _setSection,
                      onMethodChanged: _setMethod,
                      onOAuth: _submitOAuth,
                    ),
                    AuthLoginFields(
                      mode: _mode,
                      busy: _auth.busy,
                      email: _email,
                      password: _password,
                      confirmPassword: _confirm,
                      callback: _callback,
                      formKey: _formKey,
                      notice: _notice,
                      error: _formError,
                      awaitingEmail: _awaitingEmail,
                      canSubmit: _canSubmit,
                      submitLabel: _submitLabel,
                      onSubmit: _submit,
                      onContinue: _continueEmail,
                      onChanged: () => setState(() {}),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
