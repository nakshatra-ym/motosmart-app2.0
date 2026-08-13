import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/network_providers.dart';
import '../../../data/api/api_public_repository.dart';

import '../../../data/mock/mock_providers.dart';
import '../../../data/mock/mock_public_repository.dart';
import '../../../models/bike_model.dart';
import 'public_repository.dart';

final publicRepositoryProvider = Provider<PublicRepository>((ref) {
  if (ref.watch(useMockDataProvider)) {
    return MockPublicRepository(ref.watch(mockDataStoreProvider));
  }
  return ApiPublicRepository(ref.watch(apiClientProvider));
});

final publicModelsProvider = FutureProvider<List<BikeModel>>((ref) async {
  return ref.watch(publicRepositoryProvider).listModels();
});

final publicModelDetailProvider =
    FutureProvider.autoDispose.family<BikeModel, String>((ref, id) async {
  return ref.watch(publicRepositoryProvider).getModel(id);
});
