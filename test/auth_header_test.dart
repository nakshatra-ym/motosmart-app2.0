import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motosmart_app/core/network/dio_client.dart';

import 'fakes/fake_token_storage.dart';

/// One build serves both sign-in paths, so the request interceptor has to decide
/// per stored credential whether it is a Cognito JWT (`Authorization: Bearer`)
/// or a seeded dev identifier (`X-Dev-User`).
///
/// Getting that wrong is quiet and confusing — an email sent as a bearer token
/// comes back as "Malformed token header" — hence these checks. The dotted
/// customer identifier is the case that actually broke.
class _StubAdapter implements HttpClientAdapter {
  RequestOptions? captured;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    captured = options;
    return ResponseBody.fromString('{}', 200, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }

  @override
  void close({bool force = false}) {}
}

Future<Map<String, dynamic>> headersFor(String token) async {
  final storage = FakeTokenStorage();
  await storage.saveToken(token);
  final client = DioClient(storage);
  final adapter = _StubAdapter();
  client.dio.httpClientAdapter = adapter;
  await client.dio.get('https://example.test/me');
  return adapter.captured!.headers;
}

void main() {
  test('a dotted email identifier still uses the dev header', () async {
    // Three dot-separated parts, but it is an email, not a token.
    final headers = await headersFor('test.customer@ymsli-demo.example');
    expect(headers['X-Dev-User'], 'test.customer@ymsli-demo.example:');
    expect(headers.containsKey('Authorization'), isFalse);
  });

  test('a plain email identifier uses the dev header', () async {
    final headers = await headersFor('rohan@ymsli-demo.example');
    expect(headers['X-Dev-User'], 'rohan@ymsli-demo.example:');
  });

  test('a phone identifier uses the dev header', () async {
    final headers = await headersFor('+919999900201');
    expect(headers['X-Dev-User'], '+919999900201:');
  });

  test('a real JWT is sent as a bearer token', () async {
    const jwt = 'eyJraWQiOiJhYmMiLCJhbGciOiJSUzI1NiJ9.eyJzdWIiOiIxMjMifQ.c2lnbmF0dXJl';
    final headers = await headersFor(jwt);
    expect(headers['Authorization'], 'Bearer $jwt');
    expect(headers.containsKey('X-Dev-User'), isFalse);
  });

  test('the ngrok interstitial opt-out is always sent', () async {
    final headers = await headersFor('rohan@ymsli-demo.example');
    expect(headers['ngrok-skip-browser-warning'], 'true');
  });
}
