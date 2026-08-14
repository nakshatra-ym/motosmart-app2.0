import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:motosmart_app/core/auth/auth_controller.dart';
import 'package:motosmart_app/core/network/network_providers.dart';
import 'package:motosmart_app/main.dart';

import 'fakes/fake_token_storage.dart';

Widget buildTestApp() {
  return ProviderScope(
    overrides: [
      tokenStorageProvider.overrideWithValue(FakeTokenStorage()),
      // These tests assert against the in-memory demo data, so they pin the app
      // to mock mode regardless of the build-time default.
      useMockDataProvider.overrideWithValue(true),
    ],
    child: const MotoSmartApp(),
  );
}

/// From the public catalog (the app's home route), taps through to the
/// login + OTP screens and signs in as [identifier].
Future<void> signInAsDealer(WidgetTester tester, String identifier) async {
  await tester.tap(find.text('Dealer login'));
  await tester.pumpAndSettle();

  await tester.enterText(find.byType(TextFormField).last, identifier);
  await tester.tap(find.text('Continue with OTP'));
  await tester.pumpAndSettle();

  await tester.enterText(find.byType(TextFormField).last, '123456');
  await tester.tap(find.text('Verify & Continue'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('App boots to the public catalog', (WidgetTester tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    expect(find.text('Yamaha Bikes'), findsOneWidget);
    expect(find.text('Dealer login'), findsOneWidget);
    expect(find.text('YZF-R15 V4 M'), findsOneWidget);
  });

  testWidgets('Login -> OTP -> dealer dashboard happy path', (WidgetTester tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    await signInAsDealer(tester, 'rohit.sharma@ymsli.demo');

    expect(find.text('Hi, Rohit'), findsOneWidget);
    expect(find.text('New leads'), findsOneWidget);
  });

  testWidgets('Dealer can capture a new enquiry end-to-end', (WidgetTester tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    await signInAsDealer(tester, 'priya.nair@ymsli.demo');

    // Go to the Leads tab, then open the new-enquiry form.
    await tester.tap(find.text('Leads'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(find.text('New enquiry'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextFormField, 'Customer name *'), 'Test Customer');
    await tester.enterText(find.widgetWithText(TextFormField, 'Mobile number *'), '9998887771');

    for (var i = 0; i < 4; i++) {
      await tester.drag(find.byType(ListView), const Offset(0, -400));
      await tester.pump();
    }
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save enquiry'));
    await tester.pumpAndSettle();

    expect(find.text('Test Customer'), findsOneWidget);
  });

  testWidgets('Guest can book a test ride without logging in', (WidgetTester tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Test ride').first);
    await tester.pumpAndSettle();

    expect(find.text('Book a test ride'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextFormField, 'Your name *'), 'Guest Rider');
    await tester.enterText(find.widgetWithText(TextFormField, 'Mobile number *'), '9887766554');

    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('MT-15 V2').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Request test ride'));
    await tester.pumpAndSettle();

    expect(find.text('Test ride requested!'), findsOneWidget);

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    expect(find.text('Yamaha Bikes'), findsOneWidget);
  });
}
