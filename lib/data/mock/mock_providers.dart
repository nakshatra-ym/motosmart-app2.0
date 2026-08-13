import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'mock_data_store.dart';

/// One store for the app's lifetime so every mock repository sees the same
/// leads/employees/dealers — a plain (non-autoDispose) Provider, so it
/// survives widget tree rebuilds instead of resetting demo data mid-flow.
final mockDataStoreProvider = Provider<MockDataStore>((ref) {
  return MockDataStore();
});
