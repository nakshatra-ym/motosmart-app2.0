import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motosmart_app/features/public/data/public_providers.dart';
import 'package:motosmart_app/features/public/presentation/public_catalog_screen.dart';
import 'package:motosmart_app/models/bike_model.dart';
import 'package:motosmart_app/models/enums.dart';

/// The landing page is the first thing a judge or a customer sees, on whatever
/// device they happen to hold. It has to hold its shape at every width and at
/// the reader's font size.
void main() {
  const models = [
    BikeModel(
      id: '1',
      name: 'RayZR',
      variant: '125 Hybrid',
      category: 'Scooter',
      price: 87900,
      imageUrl: null,
      brochureUrl: null,
      engineCc: 125,
      stockStatus: StockStatus.inStock,
      isAvailable: true,
    ),
    BikeModel(
      id: '2',
      name: 'Fascino',
      variant: '125 Hybrid',
      category: 'Scooter',
      price: 89900,
      imageUrl: null,
      brochureUrl: null,
      engineCc: 125,
      stockStatus: StockStatus.limited,
      isAvailable: true,
    ),
    BikeModel(
      id: '3',
      name: 'FZ-X',
      variant: 'FI',
      category: 'Street',
      price: 134900,
      imageUrl: null,
      brochureUrl: null,
      engineCc: 149,
      stockStatus: StockStatus.inStock,
      isAvailable: true,
    ),
    BikeModel(
      id: '4',
      name: 'R15',
      variant: 'V4',
      category: 'Sport',
      price: 192900,
      imageUrl: null,
      brochureUrl: null,
      engineCc: 155,
      stockStatus: StockStatus.inStock,
      isAvailable: true,
    ),
    BikeModel(
      id: '5',
      name: 'R3',
      variant: 'Standard',
      category: 'Sport',
      price: 429900,
      imageUrl: null,
      brochureUrl: null,
      engineCc: 321,
      stockStatus: StockStatus.outOfStock,
      isAvailable: false,
    ),
  ];

  Future<void> pumpAt(WidgetTester tester, Size size, {double textScale = 1.0}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          publicModelsProvider.overrideWith((ref) async => models),
        ],
        child: MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: size,
              textScaler: TextScaler.linear(textScale),
            ),
            child: const PublicCatalogScreen(),
          ),
        ),
      ),
    );
    // Not pumpAndSettle: the page's ambient animations never settle.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
  }

  final sizes = <String, Size>{
    'small phone': const Size(320, 640),
    'phone': const Size(411, 891),
    'large phone': const Size(480, 1000),
    'tablet portrait': const Size(800, 1280),
    'tablet landscape': const Size(1280, 800),
  };

  sizes.forEach((name, size) {
    testWidgets('lays out without overflow on a $name', (tester) async {
      await pumpAt(tester, size);
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('survives a large system font size', (tester) async {
    await pumpAt(tester, const Size(360, 780), textScale: 1.4);
    expect(tester.takeException(), isNull);
  });

  testWidgets('opens on the dearest machine that can actually be ridden',
      (tester) async {
    await pumpAt(tester, const Size(411, 891));

    // R3 is dearer but sold out, so R15 leads the page instead.
    expect(find.text('R15 V4'), findsOneWidget);
    expect(find.text('ex-showroom'), findsOneWidget);

    // R3 keeps its place in the lineup further down.
    await tester.scrollUntilVisible(
      find.text('R3 Standard'),
      200,
      // The family bar is a Scrollable too; the page is the outer one.
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('R3 Standard'), findsOneWidget);
  });

  testWidgets('the way in is named for everyone, and both actions are offered',
      (tester) async {
    await pumpAt(tester, const Size(411, 891));

    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Book a test ride'), findsOneWidget);
    expect(find.text('Value my bike'), findsOneWidget);
  });

  testWidgets('filtering by family narrows the lineup', (tester) async {
    await pumpAt(tester, const Size(411, 891));
    expect(find.text('RayZR 125 Hybrid'), findsOneWidget);

    await tester.tap(find.text('Sport'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(tester.takeException(), isNull);
    // Scooters are gone; the sport pair remains, R15 at the head.
    expect(find.text('RayZR 125 Hybrid'), findsNothing);
    expect(find.text('R15 V4'), findsOneWidget);
  });

  testWidgets('every machine states its displacement', (tester) async {
    await pumpAt(tester, const Size(800, 1280));
    expect(tester.takeException(), isNull);

    for (final cc in ['125', '149', '155', '321']) {
      expect(find.text(cc), findsWidgets, reason: '$cc plate missing');
    }
  });
}
