import 'package:dio/dio.dart';

import '../auth/token_storage.dart';
import '../config/env.dart';
import 'api_exception.dart';

/// Real dio-backed client for once PLAN_backend.md's API is deployed.
/// Not used while `Env.useMockData` is true — repositories talk to the
/// in-memory mock layer instead. When ready to go live, flip the env flag
/// and swap the mock repository implementations for ones that call
/// `DioClient.instance` methods; screens don't change.
class DioClient {
  DioClient(this._tokenStorage)
      : dio = Dio(
          BaseOptions(
            baseUrl: Env.apiBaseUrl,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 15),
          ),
        ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _tokenStorage.readToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) {
          handler.reject(_mapError(error));
        },
      ),
    );
  }

  final Dio dio;
  final TokenStorage _tokenStorage;

  DioException _mapError(DioException error) {
    final status = error.response?.statusCode;
    final serverMessage = error.response?.data is Map
        ? (error.response?.data as Map)['detail']?.toString()
        : null;

    final message = serverMessage ??
        switch (error.type) {
          DioExceptionType.connectionTimeout ||
          DioExceptionType.sendTimeout ||
          DioExceptionType.receiveTimeout =>
            'The request timed out. Check your connection and try again.',
          DioExceptionType.connectionError =>
            'Could not reach the server. Check your connection.',
          _ => 'Something went wrong. Please try again.',
        };

    return error.copyWith(error: ApiException(message, statusCode: status));
  }
}
