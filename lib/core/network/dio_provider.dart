import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'dio_provider.g.dart';

@riverpod
Dio dio(DioRef ref) {
  final d = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  d.interceptors.add(_RetryInterceptor(d));
  d.interceptors.add(LogInterceptor(
    requestBody: false,
    responseBody: false,
  ));

  return d;
}

class _RetryInterceptor extends Interceptor {
  _RetryInterceptor(this._dio);
  final Dio _dio;

  static const _maxRetries = 3;
  static const _retryStatuses = {429, 500, 502, 503, 504};

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final attempt = err.requestOptions.extra['_retryCount'] as int? ?? 0;
    final status = err.response?.statusCode;

    if (attempt < _maxRetries && _retryStatuses.contains(status)) {
      final delay = Duration(milliseconds: 500 * (1 << attempt)); // exponential
      await Future<void>.delayed(delay);

      final options = err.requestOptions
        ..extra['_retryCount'] = attempt + 1;

      try {
        final res = await _dio.fetch<dynamic>(options);
        return handler.resolve(res);
      } on DioException catch (e) {
        return handler.next(e);
      }
    }

    handler.next(err);
  }
}
