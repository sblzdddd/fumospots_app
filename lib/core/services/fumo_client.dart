import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

import '../config/fumospots_config.dart';
import 'fumo_client_error.dart';
import 'interceptors/fumo_error_interceptor.dart';

class FumoClient {
  FumoClient() : this._(GetIt.instance<FumospotsConfig>());

  FumoClient._(FumospotsConfig config)
    : _api = Dio(
        BaseOptions(
          baseUrl: _normalizeBaseUrl(config.siteUrl),
          responseType: ResponseType.json,
          headers: const {'Accept': 'application/json'},
        ),
      ),
      _auth = Dio(
        BaseOptions(
          baseUrl: _normalizeBaseUrl(config.supabaseUrl),
          responseType: ResponseType.json,
          headers: {
            'Accept': 'application/json',
            'apikey': config.supabaseAnonKey,
            'Authorization': 'Bearer ${config.supabaseAnonKey}',
          },
        ),
      ) {
    final errors = FumoErrorInterceptor(fallbackKey: fallbackExtraKey);
    _api.interceptors.add(errors);
    _auth.interceptors.add(errors);
  }

  void postInitialize(Interceptor interceptor) {
    _api.interceptors.insert(0, interceptor);
  }

  Future<Response<dynamic>> fetchApi(RequestOptions options) {
    return _api.fetch<dynamic>(options);
  }

  static const fallbackExtraKey = 'fallback';

  final Dio _api;
  final Dio _auth;

  Future<Response<T>> get<T>(
    String path, {
    bool isAuth = false,
    Map<String, dynamic>? queryParameters,
    Options? options,
    String fallback = 'Request failed.',
  }) {
    return _request(
      () => _dio(isAuth).get<T>(
        path,
        queryParameters: queryParameters,
        options: _withFallback(options, fallback),
      ),
    );
  }

  Future<Response<T>> post<T>(
    String path, {
    bool isAuth = false,
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    String fallback = 'Request failed.',
  }) {
    return _request(
      () => _dio(isAuth).post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: _withFallback(options, fallback),
      ),
    );
  }

  Future<Response<T>> put<T>(
    String path, {
    bool isAuth = false,
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    String fallback = 'Request failed.',
  }) {
    return _request(
      () => _dio(isAuth).put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: _withFallback(options, fallback),
      ),
    );
  }

  Dio _dio(bool isAuth) => isAuth ? _auth : _api;

  Options _withFallback(Options? options, String fallback) {
    return (options ?? Options()).copyWith(
      extra: {...?options?.extra, fallbackExtraKey: fallback},
    );
  }

  Future<Response<T>> _request<T>(Future<Response<T>> Function() send) async {
    try {
      return await send();
    } on DioException catch (error) {
      final custom = error.error;
      if (custom is FumoClientError) {
        throw custom;
      }
      throw FumoClientError(
        error.message ?? 'Request failed.',
        statusCode: error.response?.statusCode,
      );
    }
  }

  static String _normalizeBaseUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.endsWith('/')) {
      return trimmed.substring(0, trimmed.length - 1);
    }
    return trimmed;
  }
}
