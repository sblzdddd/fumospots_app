import 'package:dio/dio.dart';

import '../fumo_client_error.dart';

class FumoErrorInterceptor extends Interceptor {
  final String fallbackKey;
  
  const FumoErrorInterceptor({this.fallbackKey = 'fallback'});

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final fallback = err.requestOptions.extra[fallbackKey];
    handler.reject(
      err.copyWith(
        error: _fromDio(
          err,
          fallback is String && fallback.trim().isNotEmpty
              ? fallback
              : 'Request failed.',
        ),
      ),
    );
  }

  FumoClientError _fromDio(DioException error, String fallback) {
    final data = error.response?.data;
    String? message;
    if (data is Map) {
      for (final key in const [
        'msg',
        'error_description',
        'statusMessage',
        'message',
      ]) {
        final value = data[key];
        if (value is String && value.trim().isNotEmpty) {
          message = value.trim();
          break;
        }
      }
    }
    return FumoClientError(
      message ?? fallback,
      statusCode: error.response?.statusCode,
    );
  }
}
