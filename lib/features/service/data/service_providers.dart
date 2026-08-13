import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../data/mock/mock_providers.dart';
import '../../../data/mock/mock_service_repository.dart';
import '../../../models/service_message.dart';
import '../../../models/service_request.dart';
import 'service_repository.dart';

final serviceRepositoryProvider = Provider<ServiceRepository>((ref) {
  return MockServiceRepository(
    ref.watch(mockDataStoreProvider),
    currentCustomerId: () => ref.read(authControllerProvider).valueOrNull?.customer?.id,
    currentDealerId: () =>
        ref.read(authControllerProvider).valueOrNull?.customer?.onboardingDealerId ?? 'DLR-1',
  );
});

final serviceRequestsListProvider = FutureProvider.autoDispose<List<ServiceRequest>>((ref) async {
  return ref.watch(serviceRepositoryProvider).listRequests();
});

final serviceRequestDetailProvider =
    FutureProvider.autoDispose.family<ServiceRequest, String>((ref, id) async {
  return ref.watch(serviceRepositoryProvider).getRequest(id);
});

final serviceMessagesProvider =
    FutureProvider.autoDispose.family<List<ServiceMessage>, String>((ref, requestId) async {
  return ref.watch(serviceRepositoryProvider).listMessages(requestId);
});
