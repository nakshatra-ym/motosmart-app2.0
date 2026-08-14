import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motosmart_app/core/auth/api_auth_repository.dart';
import 'package:motosmart_app/core/network/api_client.dart';
import 'package:motosmart_app/core/network/api_exception.dart';

import 'fakes/fake_token_storage.dart';

/// Captures what would go over the wire and replies with a canned Cognito
/// response, so the request encoding can be asserted without a network call.
class _CapturingAdapter implements HttpClientAdapter {
  _CapturingAdapter({required this.status, required this.body})
      : _sequence = const [];

  /// Replies with each entry in turn, for tests that need the two-call
  /// InitiateAuth -> RespondToAuthChallenge sequence.
  _CapturingAdapter.sequence(List<(int, String)> sequence)
      : status = 200,
        body = '',
        _sequence = sequence;

  final int status;
  final String body;
  final List<(int, String)> _sequence;

  int _calls = 0;
  RequestOptions? captured;
  String? capturedBody;
  final capturedBodies = <String>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    captured = options;
    if (requestStream != null) {
      final chunks = await requestStream.toList();
      capturedBody = utf8.decode(chunks.expand((c) => c).toList());
      capturedBodies.add(capturedBody!);
    }
    final (replyStatus, replyBody) = _sequence.isEmpty
        ? (status, body)
        : _sequence[_calls.clamp(0, _sequence.length - 1)];
    _calls++;
    return ResponseBody.fromString(
      replyBody,
      replyStatus,
      headers: {
        Headers.contentTypeHeader: ['application/x-amz-json-1.1'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

ApiAuthRepository _repoWith(_CapturingAdapter adapter) {
  final cognitoDio = Dio()..httpClientAdapter = adapter;
  // The ApiClient is unused on the paths under test (no /me call is reached).
  return ApiAuthRepository(
    ApiClient(Dio()),
    FakeTokenStorage(),
    cognitoDio: cognitoDio,
  );
}

void main() {
  test('OTP request is sent as JSON, not url-encoded form', () async {
    // Cognito's protocol is application/x-amz-json-1.1. dio only treats
    // application/json (or +json) as JSON, so handing it a Map would produce
    // `AuthFlow=USER_AUTH&ClientId=...` and Cognito answers with
    // SerializationException. This is the regression guard for that.
    final adapter = _CapturingAdapter(
      status: 200,
      body: jsonEncode({
        'ChallengeName': 'EMAIL_OTP',
        'Session': 'session-token',
        'ChallengeParameters': {'CODE_DELIVERY_DELIVERY_MEDIUM': 'EMAIL'},
      }),
    );

    await _repoWith(adapter).requestOtp('someone@gmail.com');

    final body = adapter.capturedBody;
    expect(body, isNotNull);
    expect(body, startsWith('{'), reason: 'body must be JSON, not form-encoded');
    expect(body, isNot(contains('AuthFlow=')));

    final decoded = jsonDecode(body!) as Map<String, dynamic>;
    expect(decoded['AuthFlow'], 'USER_AUTH');
    expect((decoded['AuthParameters'] as Map)['USERNAME'], 'someone@gmail.com');
    expect((decoded['AuthParameters'] as Map)['PREFERRED_CHALLENGE'], 'EMAIL_OTP');

    // The action goes in X-Amz-Target, not the path.
    expect(
      adapter.captured!.headers['X-Amz-Target'],
      'AWSCognitoIdentityProviderService.InitiateAuth',
    );
    expect(adapter.captured!.uri.host, contains('cognito-idp'));
  });

  test('every identifier asks for EMAIL_OTP, the pool\'s only factor', () async {
    // Asking for SMS_OTP does not fail loudly: the pool answers
    // SELECT_CHALLENGE with AvailableChallenges ['EMAIL_OTP'], and a code
    // submitted against that session goes nowhere. Requesting the factor that
    // exists keeps the dead end unreachable.
    final adapter = _CapturingAdapter(
      status: 200,
      body: jsonEncode({'ChallengeName': 'EMAIL_OTP', 'Session': 's'}),
    );

    await _repoWith(adapter).requestOtp('+919999900201');

    final decoded = jsonDecode(adapter.capturedBody!) as Map<String, dynamic>;
    expect((decoded['AuthParameters'] as Map)['PREFERRED_CHALLENGE'], 'EMAIL_OTP');
  });

  test('Cognito errors are surfaced, not swallowed into a generic message',
      () async {
    // The body arrives as a String because of the x-amz-json-1.1 content type;
    // reading it as a Map hid every real cause behind "Could not sign in".
    final adapter = _CapturingAdapter(
      status: 400,
      body: jsonEncode({
        '__type': 'UserNotFoundException',
        'message': 'User does not exist.',
      }),
    );

    await expectLater(
      _repoWith(adapter).requestOtp('nobody@gmail.com'),
      throwsA(
        isA<ApiException>().having(
          (e) => e.message,
          'message',
          contains('No account found'),
        ),
      ),
    );
  });

  test('an unparseable failure still reports something actionable', () async {
    final adapter = _CapturingAdapter(status: 500, body: '<html>gateway</html>');

    await expectLater(
      _repoWith(adapter).requestOtp('someone@gmail.com'),
      throwsA(
        isA<ApiException>().having(
          (e) => e.message,
          'message',
          contains('HTTP 500'),
        ),
      ),
    );
  });

  test('confirmOtp submits the code under the challenge-specific key', () async {
    final storage = FakeTokenStorage();
    final adapter = _CapturingAdapter(
      status: 200,
      body: jsonEncode({
        'AuthenticationResult': {
          // Three dot-separated segments so DioClient routes it as a Bearer JWT.
          'IdToken': 'header.payload.signature',
          'AccessToken': 'a.b.c',
        },
      }),
    );
    final repo = ApiAuthRepository(
      ApiClient(Dio()),
      storage,
      cognitoDio: Dio()..httpClientAdapter = adapter,
    );

    // loadSession() then calls GET /me on a Dio with no adapter configured, so
    // the call fails - the assertion here is about what happened before that.
    await expectLater(
      repo.confirmOtp(identifier: 'someone@gmail.com', otp: '123456'),
      throwsA(anything),
    );

    final decoded = jsonDecode(adapter.capturedBody!) as Map<String, dynamic>;
    expect(decoded['ChallengeName'], 'EMAIL_OTP');
    // Cognito wants the code under EMAIL_OTP_CODE; `ANSWER` (the custom-challenge
    // key) fails with "Missing required parameter EMAIL_OTP_CODE".
    final responses = decoded['ChallengeResponses'] as Map;
    expect(responses['EMAIL_OTP_CODE'], '123456');
    expect(responses.containsKey('ANSWER'), isFalse);
    // Token is cleared when the profile lookup fails, so no half-signed-in state.
    expect(await storage.readToken(), isNull);
  });

  test('the challenge Cognito issued decides the code parameter', () async {
    // Cognito can answer with a different challenge than the preferred one, so
    // the key is taken from its response rather than guessed from the identifier.
    final adapter = _CapturingAdapter.sequence([
      (200, jsonEncode({'ChallengeName': 'SMS_OTP', 'Session': 'sess'})),
      (200, jsonEncode({'AuthenticationResult': {'IdToken': 'a.b.c'}})),
    ]);
    final repo = ApiAuthRepository(
      ApiClient(Dio()),
      FakeTokenStorage(),
      cognitoDio: Dio()..httpClientAdapter = adapter,
    );

    // An email identifier would normally prefer EMAIL_OTP.
    await repo.requestOtp('someone@gmail.com');
    await expectLater(
      repo.confirmOtp(identifier: 'someone@gmail.com', otp: '87654321'),
      throwsA(anything), // the /me lookup afterwards has no adapter
    );

    final confirm = jsonDecode(adapter.capturedBodies.last) as Map<String, dynamic>;
    expect(confirm['ChallengeName'], 'SMS_OTP');
    expect(confirm['Session'], 'sess');
    expect((confirm['ChallengeResponses'] as Map)['SMS_OTP_CODE'], '87654321');
  });

  test('8-digit Cognito codes are passed through intact', () async {
    final adapter = _CapturingAdapter.sequence([
      (200, jsonEncode({'ChallengeName': 'EMAIL_OTP', 'Session': 'sess'})),
      (200, jsonEncode({'AuthenticationResult': {'IdToken': 'a.b.c'}})),
    ]);
    final repo = ApiAuthRepository(
      ApiClient(Dio()),
      FakeTokenStorage(),
      cognitoDio: Dio()..httpClientAdapter = adapter,
    );

    await repo.requestOtp('someone@gmail.com');
    await expectLater(
      repo.confirmOtp(identifier: 'someone@gmail.com', otp: '37847513'),
      throwsA(anything),
    );

    final confirm = jsonDecode(adapter.capturedBodies.last) as Map<String, dynamic>;
    expect((confirm['ChallengeResponses'] as Map)['EMAIL_OTP_CODE'], '37847513');
  });
}
