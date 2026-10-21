import 'package:dio/dio.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/services/fumo_client.dart';
import '../../core/services/fumo_client_error.dart';
import '../../utils/json_converter.dart';
import 'auth_model.dart';
import 'auth_session_store.dart';

class AuthRepository {
  AuthRepository({required this._client, required this._sessions});

  final FumoClient _client;
  final AuthSessionStore _sessions;

  Future<AuthSession?> readSession() => _sessions.read();

  Future<void> sendEmailLogin({required String email}) async {
    await _client.post(
      '/auth/v1/otp',
      isAuth: true,
      data: {'email': email, 'create_user': false},
      options: Options(responseType: ResponseType.plain),
      fallback: 'Could not send the login email.',
    );
  }

  Future<AuthSession> verifyEmailLogin({
    required String email,
    required String token,
  }) async {
    final response = await _client.post(
      '/auth/v1/verify',
      isAuth: true,
      data: {'email': email, 'token': token, 'type': 'password'},
      fallback: 'Password verification failed.',
    );
    final session = _sessionFromResponse(response.data);
    await _sessions.save(session);
    return session;
  }

  Future<AuthSession> refreshSession(String refreshToken) async {
    final response = await _client.post(
      '/auth/v1/token',
      isAuth: true,
      queryParameters: const {'grant_type': 'refresh_token'},
      data: {'refresh_token': refreshToken},
      fallback: 'Could not refresh the login session.',
    );
    final session = _sessionFromResponse(response.data);
    await _sessions.save(session);
    return session;
  }

  Future<CurrentUser> fetchCurrentUser() async {
    final response = await _client.get(
      '/api/profile/me',
      fallback: 'Could not load your profile.',
    );
    return CurrentUser.fromJson(toJsonMap(response.data));
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

  AuthSession _sessionFromResponse(Object? data) {
    final json = Map<String, dynamic>.of(toJsonMap(data));
    if (json['expires_at'] == null && json['expires_in'] is num) {
      final expiresIn = (json['expires_in'] as num).toInt();
      json['expires_at'] =
          DateTime.now().millisecondsSinceEpoch ~/ 1000 + expiresIn;
    }
    return AuthSession.fromJson(json);
  }
}
