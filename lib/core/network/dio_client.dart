import 'package:dio/dio.dart';

import '../auth/token_storage.dart';
import '../config/env.dart';
import 'api_exception.dart';

/// The dio instance every API-backed repository shares.
///
/// Two auth modes, decided by [Env.authDevMode]:
///
///  * **Cognito (production)** — the stored value is a real JWT and goes out as
///    `Authorization: Bearer <jwt>`.
///  * **Dev shortcut** — the stored value is the account's identifier and goes
///    out as `X-Dev-User: <identifier>:`, which the backend maps to a profile
///    row without verifying a signature. The trailing colon means "no explicit
///    group", so `get_current_user` probes both the employee and customer
///    tables and the role comes back from `GET /me`. The backend refuses this
///    header unless it is running with `ENVIRONMENT=development` and
///    `AUTH_DEV_MODE=true`, so it cannot be turned on against a real deploy.
class DioClient {
  DioClient(this._tokenStorage)
      : dio = Dio(
          BaseOptions(
            baseUrl: Env.apiBaseUrl,
            connectTimeout: const Duration(seconds: 10),
            // The AI endpoints (telemetry summary, DTC explanation, lead
            // classification) call Bedrock and legitimately take 5-10s; 15s left
            // almost no headroom, so a slightly slow model looked like a network
            // failure to the user. Connect timeout stays short — an unreachable
            // server should still fail fast.
            receiveTimeout: const Duration(seconds: 45),
            headers: {
              // ngrok's free tier serves an HTML interstitial instead of the
              // real response for requests it thinks came from a browser. This
              // header opts out, so JSON decoding can't trip over HTML when the
              // backend is tunnelled. Harmless on any other host.
              'ngrok-skip-browser-warning': 'true',
            },
            // Non-2xx is surfaced through onError so it maps to ApiException in
            // one place rather than being re-checked at every call site.
            validateStatus: (status) => status != null && status >= 200 && status < 300,
          ),
        ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _tokenStorage.readToken();
          if (token != null && token.isNotEmpty) {
            // A single build supports both sign-in paths, so the header is
            // chosen by what was actually stored: a Cognito JWT gets Bearer, a
            // seeded demo identifier gets the dev header. Deciding here (rather
            // than on a build flag) is what lets real OTP and the demo accounts
            // coexist in one APK.
            if (_looksLikeJwt(token)) {
              options.headers['Authorization'] = 'Bearer $token';
            } else if (Env.authDevMode) {
              options.headers['X-Dev-User'] = '$token:';
            }
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

  /// A JWT is exactly three **base64url** segments separated by dots.
  ///
  /// Counting dots alone is not enough: `test.customer@ymsli-demo.example` also
  /// splits into three parts and would be mistaken for a token, which sends the
  /// dev identifier as a bearer token and gets it rejected as a malformed JWT.
  /// Base64url has no `@` and no `.` inside a segment, so the character class
  /// settles it.
  static final _jwtPattern =
      RegExp(r'^[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]*$');

  static bool _looksLikeJwt(String token) => _jwtPattern.hasMatch(token);

  DioException _mapError(DioException error) {
    final status = error.response?.statusCode;
    final data = error.response?.data;

    // FastAPI puts the message in `detail`, which is a string for HTTPException
    // and a list of field errors for a 422 validation failure.
    String? serverMessage;
    if (data is Map) {
      final detail = data['detail'];
      if (detail is String) {
        serverMessage = detail;
      } else if (detail is List && detail.isNotEmpty) {
        serverMessage = detail
            .whereType<Map>()
            .map((e) => e['msg']?.toString() ?? '')
            .where((s) => s.isNotEmpty)
            .join('\n');
        if (serverMessage.isEmpty) serverMessage = null;
      }
    }

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
