import '../../core/services/fumo_store.dart';
import 'auth_model.dart';

class AuthSessionStore {
  AuthSessionStore({required this._store});

  static const accessTokenKey = 'access_token';
  static const refreshTokenKey = 'refresh_token';
  static const expiresAtKey = 'expires_at';

  final FumoStore _store;

  Future<AuthSession?> read() async {
    return AuthSession(
      accessToken: await _store.read(key: accessTokenKey) ?? '',
      refreshToken: await _store.read(key: refreshTokenKey) ?? '',
      expiresAt: int.tryParse(await _store.read(key: expiresAtKey) ?? '0') ?? 0,
    );
  }

  Future<void> save(AuthSession session) async {
    await _store.write(key: accessTokenKey, value: session.accessToken);
    await _store.write(key: refreshTokenKey, value: session.refreshToken);
    await _store.write(
      key: expiresAtKey,
      value: session.expiresAt.toString(),
    );
  }

  Future<void> clear() async {
    await _store.delete(key: accessTokenKey);
    await _store.delete(key: refreshTokenKey);
    await _store.delete(key: expiresAtKey);
  }
}
