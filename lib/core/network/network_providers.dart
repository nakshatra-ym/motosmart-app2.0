import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_controller.dart';
import '../config/env.dart';
import 'api_client.dart';
import 'dio_client.dart';

/// Whether repositories resolve to their in-memory mock implementations.
///
/// Defaults to the build-time [Env.useMockData], but lives in a provider so the
/// widget tests — which assert against the mock demo data — can force mock mode
/// with a single override instead of restating every repository provider.
final useMockDataProvider = Provider<bool>((ref) => Env.useMockData);

/// One dio instance (and therefore one connection pool + one auth interceptor)
/// for the app's lifetime.
final dioClientProvider = Provider<DioClient>((ref) {
  return DioClient(ref.watch(tokenStorageProvider));
});

/// The handle every API-backed repository takes.
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(ref.watch(dioClientProvider).dio);
});
