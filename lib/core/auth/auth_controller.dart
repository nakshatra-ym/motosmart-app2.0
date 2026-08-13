import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/mock/mock_providers.dart';
import '../network/network_providers.dart';
import 'api_auth_repository.dart';
import 'auth_repository.dart';
import 'mock_auth_repository.dart';
import 'session.dart';
import 'token_storage.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

/// Mock or real, decided by [useMockDataProvider]. Nothing downstream
/// (controller, router, screens) changes between the two.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (ref.watch(useMockDataProvider)) {
    return MockAuthRepository(
      ref.watch(mockDataStoreProvider),
      ref.watch(tokenStorageProvider),
    );
  }
  return ApiAuthRepository(
    ref.watch(apiClientProvider),
    ref.watch(tokenStorageProvider),
  );
});

/// Holds the current [Session], or null when signed out. The router's
/// redirect guard and every dealer screen read this.
class AuthController extends AsyncNotifier<Session?> {
  @override
  Future<Session?> build() async {
    final repository = ref.read(authRepositoryProvider);

    // Against the real API a stored token is re-validated by fetching the
    // profile, so a warm start lands straight in the right shell. A rejected or
    // expired token just means "signed out" — the router sends them to /login.
    if (repository is ApiAuthRepository) {
      final token = await ref.read(tokenStorageProvider).readToken();
      if (token == null || token.isEmpty) return null;
      try {
        return await repository.loadSession();
      } catch (_) {
        await repository.signOut();
        return null;
      }
    }

    // Mock mode always starts signed out — there's no persisted session to
    // restore without a real token-verification round trip.
    return null;
  }

  Future<void> requestOtp(String identifier) {
    return ref.read(authRepositoryProvider).requestOtp(identifier);
  }

  Future<void> confirmOtp({required String identifier, required String otp}) async {
    final session =
        await ref.read(authRepositoryProvider).confirmOtp(identifier: identifier, otp: otp);
    state = AsyncData(session);
  }

  Future<void> signOut() async {
    await ref.read(authRepositoryProvider).signOut();
    state = const AsyncData(null);
  }
}

final authControllerProvider = AsyncNotifierProvider<AuthController, Session?>(
  AuthController.new,
);
