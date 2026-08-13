import 'package:motosmart_app/core/auth/token_storage.dart';

/// Test double for [TokenStorage] — avoids touching the real
/// `flutter_secure_storage` platform channel, which has no mock handler
/// registered in the widget-test harness and would otherwise hang forever.
class FakeTokenStorage extends TokenStorage {
  final _values = <String, String>{};

  @override
  Future<String?> readToken() async => _values['auth_token'];

  @override
  Future<void> saveToken(String token) async => _values['auth_token'] = token;

  @override
  Future<void> clearToken() async => _values.remove('auth_token');
}
