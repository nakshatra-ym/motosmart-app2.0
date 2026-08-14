import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motosmart_app/features/dashboard/data/dashboard_providers.dart';
import 'package:motosmart_app/features/dashboard/presentation/dealer_dashboard_screen.dart';
import 'package:motosmart_app/models/dashboard_summary.dart';
import 'package:motosmart_app/models/lead_followup.dart';

/// The dashboard has to hold its shape on a small phone, a large phone and a
/// tablet, at the reader's font size — a metric tile that overflows is the bug
/// this file exists to catch.
void main() {
  final summary = DashboardSummary(
    newLeadsCount: 12,
    followUpLeadsCount: 7,
    closedThisMonthCount: 148,
    hotLeadsCount: 9,
    todaysFollowups: [
      FollowupWithLead(
        followup: LeadFollowup(
          id: 'f1',
          leadId: 'l1',
          employeeId: 'e1',
          scheduledDate: DateTime(2026, 8, 14),
          nextAction: 'Call about the finance quote and the exchange valuation',
          completed: false,
          outcomeNote: null,
          createdAt: DateTime(2026, 8, 13),
        ),
        leadCustomerName: 'Ramachandran Venkataraghavan',
        leadMobile: '+919999900123',
      ),
    ],
  );

  Future<void> pumpAt(WidgetTester tester, Size size, {double textScale = 1.0}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dashboardSummaryProvider.overrideWith((ref) async => summary),
        ],
        child: MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: size,
              textScaler: TextScaler.linear(textScale),
            ),
            child: const DealerDashboardScreen(),
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

  testWidgets('all four metrics are present and share one grid', (tester) async {
    await pumpAt(tester, const Size(411, 891));
    expect(tester.takeException(), isNull);

    for (final label in ['Hot leads', 'New', 'Follow-ups', 'Closed']) {
      expect(find.text(label), findsOneWidget, reason: '$label tile missing');
    }

    // Two columns on a phone: the tiles must line up in a pair of x positions,
    // which is what the old mismatched flex ratios broke.
    final xs = <double>{
      for (final label in ['Hot leads', 'New', 'Follow-ups', 'Closed'])
        double.parse(tester.getTopLeft(find.text(label)).dx.toStringAsFixed(1)),
    };
    expect(xs.length, 2, reason: 'expected two column positions, got $xs');
  });
}
