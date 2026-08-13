import 'package:dio/dio.dart';

import 'api_exception.dart';

/// Thin typed wrapper over dio, so repositories deal in maps and lists and
/// never in `Response`/`DioException`.
///
/// Every method funnels failures through [_rethrow], which unwraps the
/// [ApiException] that `DioClient`'s interceptor attached. That keeps the
/// guarantee the screens rely on: a repository only ever throws [ApiException],
/// whether the failure came from HTTP, the socket, or JSON decoding.
class ApiClient {
  const ApiClient(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> getObject(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    final response = await _send(() => _dio.get(path, queryParameters: _clean(query)));
    return _asObject(response.data, path);
  }

  Future<List<Map<String, dynamic>>> getList(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    final response = await _send(() => _dio.get(path, queryParameters: _clean(query)));
    return _asList(response.data, path);
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Object? body,
    Map<String, dynamic>? query,
  }) async {
    final response =
        await _send(() => _dio.post(path, data: body, queryParameters: _clean(query)));
    return _asObject(response.data, path);
  }

  Future<Map<String, dynamic>> patch(String path, {Object? body}) async {
    final response = await _send(() => _dio.patch(path, data: body));
    return _asObject(response.data, path);
  }

  /// For endpoints whose body is irrelevant (e.g. mark-as-read).
  Future<void> patchVoid(String path, {Object? body}) async {
    await _send(() => _dio.patch(path, data: body));
  }

  Future<Response<dynamic>> _send(Future<Response<dynamic>> Function() call) async {
    try {
      return await call();
    } on DioException catch (error) {
      _rethrow(error);
    }
  }

  /// Always throws — [Never] lets callers use it as an expression.
  Never _rethrow(DioException error) {
    final mapped = error.error;
    if (mapped is ApiException) throw mapped;
    throw ApiException(
      error.message ?? 'Something went wrong. Please try again.',
      statusCode: error.response?.statusCode,
    );
  }

  Map<String, dynamic> _asObject(Object? data, String path) {
    if (data is Map) return data.cast<String, dynamic>();
    throw ApiException('Unexpected response from $path.');
  }

  List<Map<String, dynamic>> _asList(Object? data, String path) {
    if (data is List) {
      return data.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
    }
    throw ApiException('Unexpected response from $path.');
  }

  /// Drops null values so an unset filter doesn't become `?status=null`.
  Map<String, dynamic>? _clean(Map<String, dynamic>? query) {
    if (query == null) return null;
    final cleaned = <String, dynamic>{};
    query.forEach((key, value) {
      if (value != null) cleaned[key] = value;
    });
    return cleaned.isEmpty ? null : cleaned;
  }
}
