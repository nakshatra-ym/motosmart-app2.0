import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/mock/mock_providers.dart';
import 'auth_repository.dart';
import 'mock_auth_repository.dart';
import 'session.dart';
import 'token_storage.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

/// Swap this override at app start once the real backend/Cognito is live —
/// nothing downstream (controller, router, screens) needs to change.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return MockAuthRepository(
    ref.watch(mockDataStoreProvider),
    ref.watch(tokenStorageProvider),
  );
});

/// Holds the current [Session], or null when signed out. The router's
/// redirect guard and every dealer screen read this.
class AuthController extends AsyncNotifier<Session?> {
  @override
  Future<Session?> build() async {
    // Mock mode always starts signed out — there's no persisted session to
    // restore without a real token-verification round trip. Swapping in a
    // real AuthRepository can restore from TokenStorage here instead.
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
