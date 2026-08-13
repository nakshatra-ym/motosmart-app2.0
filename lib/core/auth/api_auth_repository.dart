import 'dart:convert';

import 'package:dio/dio.dart';

import '../../models/customer.dart';
import '../../models/employee.dart';
import '../../models/enums.dart';
import '../../models/json_utils.dart';
import '../config/env.dart';
import '../network/api_client.dart';
import '../network/api_exception.dart';
import 'auth_repository.dart';
import 'session.dart';
import 'token_storage.dart';

/// Real sign-in. Both auth paths coexist in a single build, chosen **per
/// identifier** rather than by a build-time switch:
///
/// * **Real Cognito OTP** — the default for any normal address. Talks to the
///   Cognito Identity Provider API directly with dio rather than pulling in
///   `amplify_flutter` (PLAN_frontend.md allows either, and this keeps the
///   dependency list as it is). The passwordless USER_AUTH flow is two calls:
///   `InitiateAuth` sends the code, `RespondToAuthChallenge` exchanges it for
///   tokens. Requires a pool user whose `sub` matches `employees.cognito_sub`
///   or `customers.cognito_sub`.
///
/// * **Dev shortcut** — only for the seeded demo accounts, i.e. identifiers
///   ending in [_devIdentifierSuffix], and only while [Env.authDevMode] is on.
///   Cognito is skipped: the identifier is stored as the token and sent as
///   `X-Dev-User`, and `GET /me` decides the role. Those accounts exist only in
///   Postgres (their `@ymsli-demo.example` addresses are unroutable, so a real
///   OTP could never arrive), which is exactly why they need this path. The OTP
///   screen still appears and accepts any code, so the flow looks identical.
///
/// Keeping the decision per identifier means one APK demos real OTP *and* the
/// full set of seeded dealer/customer accounts.
class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository(this._api, this._tokenStorage, {Dio? cognitoDio})
      : _cognitoDio = cognitoDio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 15),
                // Cognito's JSON protocol. Set as `contentType` rather than a
                // raw header so dio's transformer doesn't overwrite it with
                // application/json when serialising the body.
                contentType: 'application/x-amz-json-1.1',
              ),
            );

  /// Cognito's regional endpoint. Passed as an absolute URL on each call
  /// instead of a `baseUrl` + empty path, which dio resolves inconsistently.
  static String get _cognitoEndpoint =>
      'https://cognito-idp.${Env.cognitoRegion}.amazonaws.com/';

  final ApiClient _api;
  final TokenStorage _tokenStorage;
  final Dio _cognitoDio;

  /// Email domain of the accounts seeded by `scripts/seed.py`. It is a reserved
  /// example domain, so mail to it cannot be delivered — these accounts are
  /// Postgres-only and must use the dev shortcut.
  static const _devIdentifierSuffix = '@ymsli-demo.example';

  /// Dev shortcut applies only to seeded demo accounts; every other identifier
  /// goes through real Cognito OTP.
  ///
  /// Static so the OTP screen can ask the same question — whether this sign-in
  /// accepts the canned demo code or a real emailed one — without restating the
  /// rule and letting the two drift apart.
  static bool usesDevShortcut(String identifier) =>
      Env.authDevMode && identifier.trim().toLowerCase().endsWith(_devIdentifierSuffix);

  bool _usesDevShortcut(String identifier) => usesDevShortcut(identifier);

  /// Carried between [requestOtp] and [confirmOtp]; Cognito requires the
  /// challenge session string from the first call in the second.
  String? _challengeSession;

  /// The challenge Cognito actually issued (`EMAIL_OTP` / `SMS_OTP`). Taken from
  /// the InitiateAuth response rather than assumed, because it decides the name
  /// of the parameter the code must be submitted under.
  String? _challengeName;

  /// Cognito expects the code under a challenge-specific key — `EMAIL_OTP_CODE`
  /// or `SMS_OTP_CODE`. (`ANSWER` belongs to the custom/select-challenge flows;
  /// sending it here fails with "Missing required parameter EMAIL_OTP_CODE".)
  static String _codeParameterFor(String challenge) =>
      challenge == 'SMS_OTP' ? 'SMS_OTP_CODE' : 'EMAIL_OTP_CODE';

  @override
  Future<void> requestOtp(String identifier) async {
    final id = identifier.trim();
    if (id.isEmpty) {
      throw const ApiException('Enter your email or phone number.');
    }

    if (_usesDevShortcut(id)) {
      // Nothing to send, but the identifier is still checked so a typo fails
      // here (on the login screen) rather than after the OTP step.
      await _assertProfileExists(id);
      return;
    }

    final response = await _cognitoCall('InitiateAuth', {
      'AuthFlow': 'USER_AUTH',
      'ClientId': Env.cognitoAppClientId,
      'AuthParameters': {'USERNAME': id, 'PREFERRED_CHALLENGE': _challengeFor(id)},
    });
    _challengeSession = response['Session'] as String?;
    _challengeName = response['ChallengeName'] as String?;
  }

  @override
  Future<Session> confirmOtp({
    required String identifier,
    required String otp,
  }) async {
    final id = identifier.trim();

    if (_usesDevShortcut(id)) {
      // The dev header is the identifier itself; there is no code to verify.
      await _tokenStorage.saveToken(id);
      try {
        return await loadSession();
      } catch (_) {
        // Never leave a token behind for an identity the API rejected.
        await _tokenStorage.clearToken();
        rethrow;
      }
    }

    if (otp.trim().isEmpty) {
      throw const ApiException('Enter the code we sent you.');
    }

    final challenge = _challengeName ?? _challengeFor(id);
    final response = await _cognitoCall('RespondToAuthChallenge', {
      'ClientId': Env.cognitoAppClientId,
      'ChallengeName': challenge,
      'Session': _challengeSession,
      'ChallengeResponses': {
        'USERNAME': id,
        _codeParameterFor(challenge): otp.trim(),
      },
    });

    final result = asMap(response['AuthenticationResult']);
    // The backend verifies either token; the ID token is preferred because it
    // carries `cognito:groups`, which is how the API resolves the role.
    final token = asString(result['IdToken'], fallback: asString(result['AccessToken']));
    if (token.isEmpty) {
      throw const ApiException('Sign-in did not return a token. Please try again.');
    }

    await _tokenStorage.saveToken(token);
    _challengeSession = null;
    _challengeName = null;
    try {
      return await loadSession();
    } catch (_) {
      await _tokenStorage.clearToken();
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    _challengeSession = null;
    _challengeName = null;
    await _tokenStorage.clearToken();
  }

  /// Builds the [Session] from `GET /me`. Also used on app start to restore a
  /// stored token, which is why it is public.
  Future<Session> loadSession() async {
    final me = await _api.getObject('/me');
    final token = await _tokenStorage.readToken() ?? '';
    final role = UserRole.fromValue(asString(me['role']));

    final employeeJson = asMap(me['employee']);
    final customerJson = asMap(me['customer']);

    return Session(
      token: token,
      role: role,
      employee: employeeJson.isEmpty ? null : Employee.fromJson(employeeJson),
      customer: customerJson.isEmpty ? null : Customer.fromJson(customerJson),
    );
  }

  /// Dev-mode preflight: confirms the identifier maps to a profile before the
  /// OTP screen, by briefly storing it so the interceptor can attach the header.
  Future<void> _assertProfileExists(String identifier) async {
    final previous = await _tokenStorage.readToken();
    await _tokenStorage.saveToken(identifier);
    try {
      await _api.getObject('/me');
    } on ApiException catch (error) {
      if (error.statusCode == 403 || error.statusCode == 404) {
        throw const ApiException(
          'No account found for that email or phone number.',
          statusCode: 404,
        );
      }
      rethrow;
    } finally {
      // Restore whatever was there; confirmOtp stores it properly.
      if (previous == null) {
        await _tokenStorage.clearToken();
      } else {
        await _tokenStorage.saveToken(previous);
      }
    }
  }

  /// Cognito routes an email identifier to EMAIL_OTP and anything else (a phone
  /// number) to SMS_OTP.
  String _challengeFor(String identifier) =>
      identifier.contains('@') ? 'EMAIL_OTP' : 'SMS_OTP';

  Future<Map<String, dynamic>> _cognitoCall(
    String action,
    Map<String, dynamic> body,
  ) async {
    if (Env.cognitoAppClientId.isEmpty) {
      throw const ApiException(
        'Cognito is not configured in this build. Pass COGNITO_APP_CLIENT_ID, '
        'or run with AUTH_DEV_MODE=true.',
      );
    }
    try {
      final response = await _cognitoDio.post(
        _cognitoEndpoint,
        // Encoded here rather than handed over as a Map: dio only treats
        // `application/json` (or `+json`) as JSON, so it would url-encode the
        // Map for Cognito's `application/x-amz-json-1.1` and the service would
        // reject it with SerializationException. A String is passed through.
        data: jsonEncode(body),
        options: Options(
          headers: {'X-Amz-Target': 'AWSCognitoIdentityProviderService.$action'},
        ),
      );
      // Cognito replies with x-amz-json-1.1, which dio does not decode
      // automatically the way it does application/json.
      final data = response.data;
      return data is String ? asMap(jsonDecode(data)) : asMap(data);
    } on DioException catch (error) {
      throw ApiException(_cognitoMessage(error), statusCode: error.response?.statusCode);
    }
  }

  /// Cognito reports failures as `{"__type": "...", "message": "..."}`; the type
  /// is mapped to something a signing-in user can act on.
  ///
  /// The body arrives as a **String** (content-type x-amz-json-1.1, which dio
  /// does not auto-decode), so it is parsed here — reading it as a Map directly
  /// silently discarded every Cognito error and surfaced only the generic
  /// fallback.
  String _cognitoMessage(DioException error) {
    final raw = error.response?.data;
    Map<String, dynamic> data = const {};
    if (raw is Map) {
      data = raw.cast<String, dynamic>();
    } else if (raw is String && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) data = decoded.cast<String, dynamic>();
      } catch (_) {
        // Not JSON - fall through to the status/type based message below.
      }
    }
    final type = asString(data['__type']);
    final message = asString(data['message']);

    if (type.contains('UserNotFound')) {
      return 'No account found for that email or phone number.';
    }
    if (type.contains('NotAuthorized')) {
      return 'That code was not accepted. Request a new one and try again.';
    }
    if (type.contains('CodeMismatch')) {
      return 'Incorrect code. Please try again.';
    }
    if (type.contains('ExpiredCode')) {
      return 'That code has expired. Request a new one.';
    }
    if (type.contains('LimitExceeded') || type.contains('TooManyRequests')) {
      return 'Too many attempts. Please wait a moment and try again.';
    }
    if (message.isNotEmpty) return message;
    if (type.isNotEmpty) return 'Sign-in failed: $type';
    // Nothing parseable came back - report what actually happened rather than a
    // blanket message, so a transport failure is distinguishable from a refusal.
    final status = error.response?.statusCode;
    if (status != null) return 'Sign-in failed (HTTP $status).';
    return 'Could not reach the sign-in service (${error.type.name}).';
  }
}
