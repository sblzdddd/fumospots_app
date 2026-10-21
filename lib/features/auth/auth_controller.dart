import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';

import '../../core/services/fumo_client_error.dart';
import 'auth_exception.dart';
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

  Future<void> sendEmailLogin({required String email}) async {
    final normalizedEmail = _normalizeEmail(email);
    await _run(() => _repository.sendEmailLogin(email: normalizedEmail));
  }

  Future<void> verifyEmailLogin({
    required String email,
    required String token,
  }) async {
    final normalizedEmail = _normalizeEmail(email);
    final normalizedToken = token.trim();
    if (normalizedToken.isEmpty) {
      throw const AuthException('Email verification code is required.');
    }

    await _run(() async {
      final nextSession = await _repository.verifyEmailLogin(
        email: normalizedEmail,
        token: normalizedToken,
      );
      await _applySession(nextSession);
      if (user == null) {
        throw AuthException(errorMessage ?? 'Could not load your profile.');
      }
    });
  }

  String _normalizeEmail(String email) {
    final normalizedEmail = email.trim();
    if (normalizedEmail.isEmpty) {
      throw const AuthException('Email is required.');
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
      ready = true;
      _notify();
    }
  }

  Future<void> _applySession(AuthSession nextSession) async {
    final revision = ++_revision;
    var current = nextSession;
    if (current.expiresAt - DateTime.now().millisecondsSinceEpoch ~/ 1000 <= 30) {
      current = await _repository.refreshSession(current.refreshToken);
    }
    if (revision != _revision) {
      return;
    }
    session = current;

    try {
      final nextUser = await _repository.fetchCurrentUser();
      if (revision != _revision) {
        return;
      }
      user = nextUser;
      errorMessage = null;
    } on FumoClientError catch (error) {
      if (revision != _revision) {
        return;
      }
      user = null;
      if (error.isUnauthorized) {
        session = null;
      }
      errorMessage = error.message;
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
