import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

import '../../../features/auth/auth_controller.dart';
import '../../../features/auth/auth_model.dart';
import '../../../features/auth/auth_repository.dart';
import '../../../features/auth/auth_session_store.dart';
import '../fumo_client.dart';
import '../fumo_client_error.dart';

class FumoAuthInterceptor extends Interceptor {
  static const retriedExtraKey = 'authRetried';

  FumoClient get _client => GetIt.instance<FumoClient>();
  AuthSessionStore get _sessions => GetIt.instance<AuthSessionStore>();
  AuthRepository get _repository => GetIt.instance<AuthRepository>();
  AuthController get _controller => GetIt.instance<AuthController>();
  Future<AuthSession>? _refreshing;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final accessToken = _token((await _sessions.read())?.accessToken);
    if (accessToken != null) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode != 401) {
      handler.next(err);
      return;
    }

    final options = err.requestOptions;
    if (options.extra[retriedExtraKey] == true) {
      await _clear();
      handler.next(err);
      return;
    }

    final refreshToken = _token((await _sessions.read())?.refreshToken);
    if (refreshToken == null) {
      if (_bearer(options) != null) {
        await _clear();
      }
      handler.next(err);
      return;
    }

    try {
      final refreshed = await _refreshOnce(refreshToken);
      _controller.adoptSession(refreshed);
      options.extra[retriedExtraKey] = true;
      options.headers['Authorization'] = 'Bearer ${refreshed.accessToken}';
      handler.resolve(await _client.fetchApi(options));
    } on FumoClientError catch (error) {
      if (error.isUnauthorized) {
        await _clear();
      }
      handler.next(err);
    } on DioException catch (error) {
      if (_isUnauthorized(error)) {
        await _clear();
      }
      handler.next(error);
    }
  }

  Future<AuthSession> _refreshOnce(String refreshToken) {
    final refreshing = _refreshing;
    if (refreshing != null) {
      return refreshing;
    }
    final future = _repository.refreshSession(refreshToken);
    _refreshing = future;
    return future.whenComplete(() {
      if (identical(_refreshing, future)) {
        _refreshing = null;
      }
    });
  }

  Future<void> _clear() async {
    await _sessions.clear();
    _controller.clearLocalSession();
  }

  bool _isUnauthorized(DioException error) {
    final custom = error.error;
    return error.response?.statusCode == 401 ||
        (custom is FumoClientError && custom.isUnauthorized);
  }

  String? _token(String? value) {
    final token = value?.trim() ?? '';
    return token.isEmpty ? null : token;
  }

  String? _bearer(RequestOptions options) {
    final value = options.headers['Authorization'];
    if (value is! String || !value.startsWith('Bearer ')) {
      return null;
    }
    return _token(value.substring('Bearer '.length));
  }
}
