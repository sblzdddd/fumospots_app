import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';

import '../../core/i18n/keys.dart';
import '../../core/services/fumo_client_error.dart';
import 'auth_exception.dart';
import 'auth_flow.dart';
import 'auth_model.dart';
import 'auth_repository.dart';

class AuthController extends ChangeNotifier {
  final AuthRepository _repository = GetIt.instance<AuthRepository>();

  AuthSession? session;
  CurrentUser? user;
  bool ready = false;
  bool busy = false;
  String? errorMessage;

  bool get isSignedIn => session != null;

  bool get hasUsername => user?.profile.username?.isNotEmpty ?? false;

  bool get isAdmin => user?.profile.role == 'admin';

  Map<String, String> get authHeaders {
    final accessToken = session?.accessToken;
    if (accessToken == null || accessToken.isEmpty) {
      return const {};
    }
    return {'Authorization': 'Bearer $accessToken'};
  }

  Future<void> init() {
    return _initFuture ??= _restore();
  }

  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) {
    final normalizedEmail = _normalizeEmail(email);
    return _run(() async {
      final nextSession = await _repository.signInWithPassword(
        email: normalizedEmail,
        password: password,
      );
      await _commitSession(nextSession);
    });
  }

  Future<bool> signUpWithPassword({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = _normalizeEmail(email);
    var established = false;
    await _run(() async {
      final nextSession = await _repository.signUpWithPassword(
        email: normalizedEmail,
        password: password,
      );
      if (nextSession == null) {
        return;
      }
      await _commitSession(nextSession);
      established = true;
    });
    return established;
  }

  Future<void> sendMagicLink({required String email}) {
    final normalizedEmail = _normalizeEmail(email);
    return _run(() => _repository.sendMagicLink(email: normalizedEmail));
  }

  Future<void> verifyEmailCode({
    required String email,
    required String token,
    required String type,
  }) {
    final normalizedEmail = _normalizeEmail(email);
    final normalizedToken = token.trim();
    if (normalizedToken.isEmpty) {
      throw const AuthException(S.emailCodeRequired);
    }
    return _run(() async {
      final nextSession = await _repository.verifyEmailCode(
        email: normalizedEmail,
        token: normalizedToken,
        type: type,
      );
      await _commitSession(nextSession);
    });
  }

  Future<void> completeAuthorizationCode({
    required String code,
    required String codeVerifier,
  }) {
    return _run(() async {
      final nextSession = await _repository.exchangeAuthorizationCode(
        code: code,
        codeVerifier: codeVerifier,
      );
      await _commitSession(nextSession);
    });
  }

  Future<void> completeImplicitSession({
    required String accessToken,
    required String refreshToken,
    int? expiresAt,
    int? expiresIn,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final nextSession = AuthSession(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresAt: expiresAt ?? now + (expiresIn ?? 3600),
    );
    return _run(() async {
      await _repository.saveSession(nextSession);
      await _commitSession(nextSession);
    });
  }

  Future<void> saveUsername(String username) {
    final normalized = username.trim().toLowerCase();
    if (!authUsernamePattern.hasMatch(normalized)) {
      throw const AuthException(S.authorIdInvalid);
    }
    return _run(() async {
      await _repository.saveUsername(normalized);
      user = await _repository.fetchCurrentUser();
      errorMessage = null;
    });
  }

  String _normalizeEmail(String email) {
    final normalizedEmail = email.trim();
    if (normalizedEmail.isEmpty) {
      throw const AuthException(S.enterEmail);
    }
    return normalizedEmail;
  }

  void adoptSession(AuthSession next) {
    session = next;
    _notify();
  }

  void clearLocalSession() {
    session = null;
    user = null;
    _notify();
  }

  Future<void> signOut() async {
    final accessToken = session?.accessToken;
    await _run(() async {
      if (accessToken != null && accessToken.isNotEmpty) {
        await _repository.signOut(accessToken);
      } else {
        await _repository.clearStoredSession();
      }
      session = null;
      user = null;
      errorMessage = null;
    });
  }

  Future<void>? _initFuture;
  int _revision = 0;
  bool _disposed = false;

  Future<void> _restore() async {
    try {
      final stored = await _repository.readSession();
      if (stored == null) {
        ready = true;
        _notify();
        return;
      }
      await _applySession(stored);
      ready = true;
      _notify();
    } on FumoClientError catch (error) {
      errorMessage = error.message;
      if (error.isUnauthorized) {
        session = null;
        user = null;
        await _repository.clearStoredSession();
      }
      ready = true;
      _notify();
    }
  }

  Future<void> _commitSession(AuthSession next) async {
    final applied = await _applySession(next);
    if (applied || user != null) {
      return;
    }
    throw AuthException(errorMessage ?? S.profileLoadFailed);
  }

  Future<bool> _applySession(AuthSession nextSession) async {
    final revision = ++_revision;
    var current = nextSession;
    if (current.expiresAt - DateTime.now().millisecondsSinceEpoch ~/ 1000 <=
        30) {
      current = await _repository.refreshSession(current.refreshToken);
    }
    if (revision != _revision) {
      return false;
    }
    session = current;

    try {
      final nextUser = await _repository.fetchCurrentUser();
      if (revision != _revision) {
        return false;
      }
      user = nextUser;
      errorMessage = null;
      return true;
    } on FumoClientError catch (error) {
      if (revision != _revision) {
        return false;
      }
      user = null;
      if (error.isUnauthorized) {
        session = null;
        await _repository.clearStoredSession();
      }
      errorMessage = error.message;
      return false;
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    busy = true;
    errorMessage = null;
    _notify();
    try {
      await action();
    } on FumoClientError catch (error) {
      errorMessage = error.message;
      rethrow;
    } finally {
      busy = false;
      ready = true;
      _notify();
    }
  }

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
