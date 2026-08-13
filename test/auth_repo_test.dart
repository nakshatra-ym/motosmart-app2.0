import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motosmart_app/core/auth/auth_controller.dart';

import 'fakes/fake_token_storage.dart';

void main() {
  test('mock auth request+confirm otp works', () async {
    final container = ProviderContainer(
      overrides: [tokenStorageProvider.overrideWithValue(FakeTokenStorage())],
    );
    addTearDown(container.dispose);

    await container.read(authControllerProvider.future); // let build() settle

    final notifier = container.read(authControllerProvider.notifier);
    await notifier.requestOtp('rohit.sharma@ymsli.demo');
    await notifier.confirmOtp(identifier: 'rohit.sharma@ymsli.demo', otp: '123456');

    final session = container.read(authControllerProvider).valueOrNull;
    expect(session, isNotNull);
    expect(session!.employee!.name, 'Rohit Sharma');
  });
}
