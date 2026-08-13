/// Typed error every repository throws, so screens only ever need to render
/// one error shape regardless of whether the failure came from dio, the
/// mock layer, or a parsing error.
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() => message;
}
