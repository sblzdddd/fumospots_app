import 'package:dio/dio.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/config/fumospots_config.dart';
import '../../core/services/fumo_client.dart';
import '../../core/services/fumo_client_error.dart';
import 'auth_exception.dart';
import 'auth_flow.dart';
import 'auth_model.dart';
import 'auth_session_store.dart';

class AuthRepository {
  AuthRepository({
    required this._client,
    required this._sessions,
    required this._config,
  });

  final FumoClient _client;
  final AuthSessionStore _sessions;
  final FumospotsConfig _config;

  Future<AuthSession?> readSession() => _sessions.read();

  Future<void> clearStoredSession() => _sessions.clear();

  Future<void> saveSession(AuthSession session) => _sessions.save(session);

  String get loginRedirect =>
      AuthLinks.fromConfig(_config).loginRedirect.toString();

  Future<AuthSession> signInWithPassword({
    required String email,
    required String password,
  }) async {
    final response = await _client.post(
      '/auth/v1/token',
      isAuth: true,
      queryParameters: const {'grant_type': 'password'},
      data: {'email': email, 'password': password},
      fallback: 'Password login failed.',
    );
    return _requireSession(response.data, 'Password login failed.');
  }

  Future<AuthSession?> signUpWithPassword({
    required String email,
    required String password,
  }) async {
    final response = await _client.post(
      '/auth/v1/signup',
      isAuth: true,
      queryParameters: {'redirect_to': loginRedirect},
      data: {'email': email, 'password': password},
      fallback: 'Registration failed.',
    );
    final session = _optionalSession(response.data);
    if (session != null) {
      await _sessions.save(session);
    }
    return session;
  }

  Future<void> sendMagicLink({required String email}) async {
    await _client.post(
      '/auth/v1/otp',
      isAuth: true,
      queryParameters: {'redirect_to': loginRedirect},
      data: {'email': email, 'create_user': false},
      fallback: 'Failed to send the login link.',
    );
  }

  Future<AuthSession> verifyEmailCode({
    required String email,
    required String token,
    required String type,
  }) async {
    final response = await _client.post(
      '/auth/v1/verify',
      isAuth: true,
      data: {'email': email, 'token': token, 'type': type},
      fallback: 'Email verification failed.',
    );
    return _requireSession(response.data, 'Email verification failed.');
  }

  Future<AuthSession> exchangeAuthorizationCode({
    required String code,
    required String codeVerifier,
  }) async {
    final response = await _client.post(
      '/auth/v1/token',
      isAuth: true,
      queryParameters: const {'grant_type': 'pkce'},
      data: {'auth_code': code, 'code_verifier': codeVerifier},
      fallback: 'Could not finish signing in.',
    );
    return _requireSession(response.data, 'Could not finish signing in.');
  }

  Future<AuthSession> refreshSession(String refreshToken) async {
    final response = await _client.post(
      '/auth/v1/token',
      isAuth: true,
      queryParameters: const {'grant_type': 'refresh_token'},
      data: {'refresh_token': refreshToken},
      fallback: 'Could not refresh the login session.',
    );
    return _requireSession(response.data, 'Could not refresh the login session.');
  }

  Future<CurrentUser> fetchCurrentUser() async {
    final response = await _client.get(
      '/api/profile/me',
      fallback: 'Could not load your profile.',
    );
    final json = _asMap(response.data);
    if (json == null) {
      throw const FumoClientError('Could not load your profile.');
    }
    return CurrentUser.fromJson(json);
  }

  Future<void> saveUsername(String username) async {
    await _client.post(
      '/api/profile/setup',
      data: {'username': username},
      fallback: 'Failed to save the author ID.',
    );
  }

  Future<void> signOut(String accessToken) async {
    try {
      await _client.post<void>(
        '/auth/v1/logout',
        isAuth: true,
        queryParameters: const {'scope': 'global'},
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );
    } on FumoClientError {
      debugPrint('Could not sign out using logout endpoint.');
    } finally {
      await _sessions.clear();
    }
  }

  Future<AuthSession> _requireSession(Object? data, String fallback) async {
    final session = _optionalSession(data);
    if (session == null) {
      throw AuthException(fallback);
    }
    await _sessions.save(session);
    return session;
  }

  AuthSession? _optionalSession(Object? data) {
    final root = _asMap(data);
    if (root == null) {
      return null;
    }
    final nested = root['session'];
    final source = nested is Map ? _asMap(nested) : root;
    if (source == null) {
      return null;
    }
    final access = source['access_token'];
    final refresh = source['refresh_token'];
    if (access is! String ||
        access.isEmpty ||
        refresh is! String ||
        refresh.isEmpty) {
      return null;
    }
    if (source['expires_at'] == null && source['expires_in'] is num) {
      source['expires_at'] =
          DateTime.now().millisecondsSinceEpoch ~/ 1000 +
          (source['expires_in'] as num).toInt();
    }
    source['expires_at'] ??=
        DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600;
    try {
      return AuthSession.fromJson(source);
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic>? _asMap(Object? data) {
    if (data is Map<String, dynamic>) {
      return Map<String, dynamic>.of(data);
    }
    if (data is Map) {
      return data.map((key, value) => MapEntry('$key', value));
    }
    return null;
  }
}
