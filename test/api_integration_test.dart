@Timeout(Duration(minutes: 4))
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:motosmart_app/core/network/api_client.dart';
import 'package:motosmart_app/core/network/dio_client.dart';
import 'package:motosmart_app/data/api/api_chatbot_repository.dart';
import 'package:motosmart_app/data/api/api_dashboard_repository.dart';
import 'package:motosmart_app/data/api/api_incentives_repository.dart';
import 'package:motosmart_app/data/api/api_leads_repository.dart';
import 'package:motosmart_app/data/api/api_notifications_repository.dart';
import 'package:motosmart_app/data/api/api_public_repository.dart';
import 'package:motosmart_app/data/api/api_service_repository.dart';
import 'package:motosmart_app/data/api/api_test_ride_repository.dart';
import 'package:motosmart_app/data/api/api_tickets_repository.dart';
import 'package:motosmart_app/data/api/api_vehicles_repository.dart';
import 'package:motosmart_app/features/vehicles/data/telemetry_summary.dart';
import 'package:motosmart_app/models/enums.dart';

import 'fakes/fake_token_storage.dart';

/// End-to-end checks for the dio-backed repositories against a **running**
/// backend (`uvicorn app.main:app` with `AUTH_DEV_MODE=true`, seeded).
///
/// Skipped unless `RUN_API_TESTS=1`, so the default `flutter test` run stays
/// hermetic and green with no server around:
///
///     RUN_API_TESTS=1 flutter test test/api_integration_test.dart
///
/// This is the check that actually proves the frontend/backend contract: every
/// response is parsed through the same models and repositories the app uses, so
/// a field rename or type change on either side fails here.
const _dealerIdentifier = 'rohan@ymsli-demo.example';
const _customerIdentifier = 'test.customer@ymsli-demo.example';

ApiClient _clientFor(String identifier) {
  final storage = FakeTokenStorage();
  // In dev-auth mode the stored "token" is the identifier, which DioClient
  // sends as `X-Dev-User: <identifier>:`.
  storage.saveToken(identifier);
  return ApiClient(DioClient(storage).dio);
}

void main() {
  final enabled = Platform.environment['RUN_API_TESTS'] == '1';

  group('dealer repositories', skip: enabled ? null : 'set RUN_API_TESTS=1', () {
    late ApiClient api;

    setUp(() => api = _clientFor(_dealerIdentifier));

    test('dashboard summary parses', () async {
      final summary = await ApiDashboardRepository(api).getSummary();
      expect(summary.newLeadsCount, greaterThanOrEqualTo(0));
      expect(summary.openLeadsCount, greaterThanOrEqualTo(summary.newLeadsCount));
      // Seeded data has overdue follow-ups, which is what the home worklist shows.
      expect(summary.todaysFollowups, isNotEmpty);
      expect(summary.todaysFollowups.first.leadCustomerName, isNotEmpty);
    });

    test('leads list, detail, and follow-ups parse', () async {
      final repo = ApiLeadsRepository(api);
      final leads = await repo.listLeads();
      expect(leads, isNotEmpty);

      final lead = leads.first;
      expect(lead.customerName, isNotEmpty);
      expect(lead.mobile, isNotEmpty);
      // Would be null if StockStatus/enum decoding silently fell back.
      expect(LeadStatus.values, contains(lead.status));

      final detail = await repo.getLead(lead.id);
      expect(detail.id, lead.id);

      await repo.listFollowups(lead.id); // shape check; may legitimately be empty
    });

    test('status filter and search reach the API', () async {
      final repo = ApiLeadsRepository(api);
      final newOnly = await repo.listLeads(status: LeadStatus.newLead);
      expect(newOnly.every((l) => l.status == LeadStatus.newLead), isTrue);

      final all = await repo.listLeads();
      final hits = await repo.listLeads(query: all.first.customerName);
      expect(hits, isNotEmpty);
    });

    test('bike models parse, including string-encoded Decimal prices', () async {
      final models = await ApiLeadsRepository(api).listBikeModels();
      expect(models, isNotEmpty);
      // `price` arrives as "139900.00"; asDouble must have coerced it.
      expect(models.every((m) => m.price > 0), isTrue);
      expect(models.map((m) => m.stockStatus).toSet(), isNotEmpty);
    });

    test('creating a lead classifies it and returns the row', () async {
      final repo = ApiLeadsRepository(api);
      final created = await repo.createLead(
        customerName: 'Integration Probe',
        mobile: '+919999900123',
        source: LeadSource.walkIn,
        notes: 'Booking today, finance approved, asking on-road price.',
        tentativePurchaseDate: DateTime.now().add(const Duration(days: 5)),
      );
      expect(created.customerName, 'Integration Probe');
      expect(created.status, LeadStatus.newLead);
      // `classify: true` means the badge is filled in on creation.
      expect(created.aiIntent, isNotNull);

      final updated = await repo.updateLead(created.id, status: LeadStatus.followUp);
      expect(updated.status, LeadStatus.followUp);

      final followup = await repo.createFollowup(
        created.id,
        nextAction: 'Call back with the on-road quote.',
        scheduledDate: DateTime.now().add(const Duration(days: 1)),
      );
      expect(followup.leadId, created.id);

      final done = await repo.updateFollowup(followup.id, completed: true);
      expect(done.completed, isTrue);

      expect(await repo.hasDuplicateMobile('+919999900123'), isTrue);
    });

    test('notifications, test rides, incentives, and tickets parse', () async {
      await ApiNotificationsRepository(api).list();
      await ApiTestRideRepository(api).listTestRides();
      await ApiTicketsRepository(api).listTickets();

      final incentives =
          await ApiIncentivesRepository(api).getSummary(month: DateTime.now());
      expect(incentives.dealerTotal, greaterThanOrEqualTo(0));
    });
  });

  group('public funnel', skip: enabled ? null : 'set RUN_API_TESTS=1', () {
    // No identifier: the guest funnel is unauthenticated.
    final api = ApiClient(DioClient(FakeTokenStorage()).dio);

    test('catalog, availability, and exchange estimate parse', () async {
      final repo = ApiPublicRepository(api);
      final models = await repo.listModels();
      expect(models, isNotEmpty);

      final model = await repo.getModel(models.first.id);
      expect(model.id, models.first.id);

      await repo.checkAvailability(models.first.id);

      final estimate = await repo.estimateExchangeValue(
        brand: 'Yamaha',
        model: 'FZ-S',
        year: DateTime.now().year - 3,
        condition: 'GOOD',
      );
      expect(estimate.estimatedValue, greaterThan(0));
      expect(estimate.note, isNotEmpty);
    });

    test('booking a test ride auto-creates the lead server-side', () async {
      final repo = ApiPublicRepository(api);
      final models = await repo.listModels();

      final booking = await repo.bookTestRide(
        bikeModelId: models.first.id,
        name: 'Integration Guest',
        mobile: '+919999900456',
        preferredDate: DateTime.now().add(const Duration(days: 3)),
        preferredTime: '10:30 AM',
      );
      expect(booking.name, 'Integration Guest');
      expect(booking.status, TestRideStatus.requested);
      // Proves the round-robin transaction ran: the booking carries its lead.
      expect(booking.linkedLeadId, isNotNull);
      expect(booking.dealerId, isNotEmpty);
    });
  });

  group('ticket thread, both directions',
      skip: enabled ? null : 'set RUN_API_TESTS=1', () {
    test('customer and dealer chat, and each side gets notified', () async {
      final customerApi = _clientFor(_customerIdentifier);
      final dealerApi = _clientFor(_dealerIdentifier);

      final vehicles = await ApiVehiclesRepository(customerApi).myVehicles();
      final customerRepo = ApiServiceRepository(customerApi);
      final dealerRepo = ApiTicketsRepository(dealerApi);
      final dealerNotifications = ApiNotificationsRepository(dealerApi);
      final customerNotifications = ApiNotificationsRepository(customerApi);

      int unread(List<dynamic> items) => items.where((n) => !n.isRead).length;
      final dealerBefore = unread(await dealerNotifications.list());

      // 1. Customer opens a ticket -> the desk is told.
      final ticket = await customerRepo.createRequest(
        vehicleId: vehicles.first.id,
        type: 'Electrical issue',
        description: 'Indicator on the left side has stopped blinking.',
      );
      expect(
        unread(await dealerNotifications.list()),
        greaterThan(dealerBefore),
        reason: 'opening a ticket must notify the dealer',
      );

      // 2. The dealer sees it in their queue.
      final queue = await dealerRepo.listTickets();
      expect(queue.any((t) => t.id == ticket.id), isTrue);

      // 3. Dealer replies -> customer is told, and the ticket starts moving.
      final customerBefore = unread(await customerNotifications.list());
      await dealerRepo.sendMessage(ticket.id, 'Please bring it in tomorrow at 11.');
      expect(
        unread(await customerNotifications.list()),
        greaterThan(customerBefore),
        reason: 'a dealer reply must notify the customer',
      );
      expect(
        (await dealerRepo.getTicket(ticket.id)).status,
        ServiceRequestStatus.inProgress,
        reason: 'a dealer reply starts work on an OPEN ticket',
      );

      // 4. Customer replies -> the desk is told again.
      final dealerMid = unread(await dealerNotifications.list());
      await customerRepo.sendMessage(ticket.id, 'Sure, I will be there.');
      expect(
        unread(await dealerNotifications.list()),
        greaterThan(dealerMid),
        reason: 'a customer reply must notify the dealer',
      );

      // 5. Both sides read the same thread, in order.
      final asCustomer = await customerRepo.listMessages(ticket.id);
      final asDealer = await dealerRepo.listMessages(ticket.id);
      expect(asCustomer.length, asDealer.length);
      expect(asCustomer.map((m) => m.senderType), [
        MessageSenderType.customer,
        MessageSenderType.dealer,
        MessageSenderType.customer,
      ]);
      expect(asDealer.last.message, 'Sure, I will be there.');
      // Names are resolved server-side despite sender_id having no FK.
      expect(asDealer.every((m) => (m.senderId).isNotEmpty), isTrue);
    });
  });

  group('customer repositories', skip: enabled ? null : 'set RUN_API_TESTS=1', () {
    late ApiClient api;

    setUp(() => api = _clientFor(_customerIdentifier));

    test('garage, service status, and history parse', () async {
      final repo = ApiVehiclesRepository(api);
      final vehicles = await repo.myVehicles();
      expect(vehicles, isNotEmpty);

      final vehicle = vehicles.first;
      expect(vehicle.registrationNo, isNotEmpty);

      final status = await repo.serviceStatus(vehicle.id);
      expect(status.currentOdometerKm, greaterThan(0));
      // Seeded vehicle has one past service, so the flat last_service_* fields
      // must have been rebuilt into a record.
      expect(status.lastService, isNotNull);

      final history = await repo.serviceHistory(vehicle.id);
      expect(history, isNotEmpty);
    });

    test('service request thread round-trips', () async {
      final vehicles = await ApiVehiclesRepository(api).myVehicles();
      final repo = ApiServiceRepository(api);

      final request = await repo.createRequest(
        vehicleId: vehicles.first.id,
        type: 'Periodic Service',
        description: 'Integration probe: odd noise from the front brake.',
        preferredDate: DateTime.now().add(const Duration(days: 2)),
      );
      expect(request.status, ServiceRequestStatus.open);

      final message = await repo.sendMessage(request.id, 'Any update on this?');
      expect(message.senderType, MessageSenderType.customer);

      final messages = await repo.listMessages(request.id);
      expect(messages, isNotEmpty);

      expect((await repo.listRequests()).any((r) => r.id == request.id), isTrue);
    });

    test('OBD readings get an AI summary, flagged when faulty', () async {
      final vehicles = await ApiVehiclesRepository(api).myVehicles();
      final repo = ApiTelemetrySummaryRepository(api);

      final healthy = await repo.summarise(
        vehicleId: vehicles.first.id,
        readings: const TelemetryReadings(
          rpm: 3200,
          coolantTempC: 82,
          speedKph: 45,
          batteryVoltage: 13.8,
          throttlePositionPct: 22,
          fuelLevelPct: 64,
          healthLevel: 'green',
        ),
      );
      expect(healthy.summary, isNotEmpty);
      expect(healthy.isActionable, isFalse);
      expect(healthy.suggestedDescription, isNull);

      final faulty = await repo.summarise(
        vehicleId: vehicles.first.id,
        readings: const TelemetryReadings(
          rpm: 6100,
          coolantTempC: 118,
          speedKph: 12,
          batteryVoltage: 11.4,
          fuelLevelPct: 8,
          dtcCodes: ['P0217'],
          healthLevel: 'red',
          healthReasons: ['Coolant temperature above safe range'],
        ),
      );
      // Overheating with a live fault code must offer the ticket route.
      expect(faulty.isActionable, isTrue);
      expect(faulty.suggestedDescription, isNotNull);
      expect(faulty.obdContext, contains('P0217'));
    });

    test('a ticket raised from the dashboard carries diagnostics and triage',
        () async {
      final vehicles = await ApiVehiclesRepository(api).myVehicles();
      final repo = ApiServiceRepository(api);

      final request = await repo.createRequest(
        vehicleId: vehicles.first.id,
        type: 'Brake issue',
        description: 'Front brake is not stopping the bike at all.',
        obdContext: 'Captured from the OBD port:\n- Fault codes: C1234',
      );

      // AI triage runs on creation; a brake complaint is never below High.
      expect(request.aiCategory, TicketCategory.brakes);
      expect(
        request.aiPriority,
        anyOf(TicketPriority.urgent, TicketPriority.high),
      );
      expect(request.aiSummary, isNotEmpty);

      // Description and diagnostics both land in the thread.
      final messages = await repo.listMessages(request.id);
      expect(messages.length, greaterThanOrEqualTo(2));
      expect(messages.any((m) => m.message.contains('C1234')), isTrue);
    });

    test('routine work is triaged low, engine trouble is not', () async {
      final vehicles = await ApiVehiclesRepository(api).myVehicles();
      final repo = ApiServiceRepository(api);

      final routine = await repo.createRequest(
        vehicleId: vehicles.first.id,
        type: 'General service',
        description: 'Periodic service due, please change engine oil.',
      );
      expect(routine.aiCategory, TicketCategory.periodicService);
      expect(routine.aiPriority, TicketPriority.low);

      final engine = await repo.createRequest(
        vehicleId: vehicles.first.id,
        type: 'Engine noise',
        description: 'Engine is overheating and losing power on inclines.',
      );
      expect(engine.aiCategory, TicketCategory.engine);
      expect(engine.aiPriority, isNot(TicketPriority.low));
    });

    test('chatbot persists both turns and returns a reply', () async {
      final repo = ApiChatbotRepository(api);
      final reply = await repo.sendMessage('When is my next service due?');
      expect(reply.role, ChatRole.assistant);
      expect(reply.content, isNotEmpty);

      final history = await repo.history();
      expect(history, isNotEmpty);
      expect(history.any((m) => m.role == ChatRole.user), isTrue);
    });
  });
}
