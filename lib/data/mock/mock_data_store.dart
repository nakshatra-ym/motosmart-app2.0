import 'package:uuid/uuid.dart';

import '../../models/app_notification.dart';
import '../../models/bike_model.dart';
import '../../models/chat_message.dart';
import '../../models/customer.dart';
import '../../models/dashboard_summary.dart';
import '../../models/dealer.dart';
import '../../models/employee.dart';
import '../../models/enums.dart';
import '../../models/lead.dart';
import '../../models/lead_followup.dart';
import '../../models/service_message.dart';
import '../../models/service_record.dart';
import '../../models/service_request.dart';
import '../../models/test_ride_booking.dart';
import '../../models/vehicle.dart';

/// In-memory stand-in for PLAN_backend.md's Postgres tables + `scripts/seed.py`.
///
/// Lives for the app's lifetime behind a single Riverpod provider so every
/// mock repository reads/writes the same data. No real PII — all
/// dummy/masked data per the hackathon's DPDP note.
class MockDataStore {
  MockDataStore() {
    _seed();
  }

  static const _uuid = Uuid();

  final List<Dealer> dealers = [];
  final List<Employee> employees = [];
  final List<BikeModel> bikeModels = [];
  final List<Lead> leads = [];
  final List<LeadFollowup> followups = [];
  final List<Customer> customers = [];
  final List<TestRideBooking> testRideBookings = [];
  final List<AppNotification> notifications = [];
  final List<Vehicle> vehicles = [];
  final List<ServiceRecord> serviceRecords = [];
  final List<ServiceRequest> serviceRequests = [];
  final List<ServiceMessage> serviceMessages = [];

  /// Chatbot history per customer — not modeled as a full
  /// `chatbot_conversations` table since Phase 3 only needs one running
  /// conversation per customer for the demo.
  final Map<String, List<ChatMessage>> chatHistoryByCustomer = {};

  /// Round-robin pointer per dealer, mirroring `dealers.last_assigned_employee_id`.
  final Map<String, String?> _lastAssignedByDealer = {};

  late Dealer defaultDealer;

  void _seed() {
    final now = DateTime.now();

    defaultDealer = const Dealer(
      id: 'DLR-1',
      name: 'YMSLI Whitefield Motors',
      code: 'WF01',
      city: 'Bengaluru',
      address: 'Plot 14, ITPL Main Road, Whitefield',
      phone: '08066550001',
    );
    dealers.add(defaultDealer);

    employees.addAll(const [
      Employee(
        id: 'EMP-1',
        dealerId: 'DLR-1',
        name: 'Rohit Sharma',
        phone: '9876500001',
        email: 'rohit.sharma@ymsli.demo',
        isActive: true,
      ),
      Employee(
        id: 'EMP-2',
        dealerId: 'DLR-1',
        name: 'Priya Nair',
        phone: '9876500002',
        email: 'priya.nair@ymsli.demo',
        isActive: true,
      ),
      Employee(
        id: 'EMP-3',
        dealerId: 'DLR-1',
        name: 'Arjun Verma',
        phone: '9876500003',
        email: 'arjun.verma@ymsli.demo',
        isActive: true,
      ),
      Employee(
        id: 'EMP-4',
        dealerId: 'DLR-1',
        name: 'Sneha Iyer',
        phone: '9876500004',
        email: 'sneha.iyer@ymsli.demo',
        isActive: true,
      ),
      Employee(
        id: 'EMP-5',
        dealerId: 'DLR-1',
        name: 'Karan Mehta',
        phone: '9876500005',
        email: 'karan.mehta@ymsli.demo',
        isActive: true,
      ),
    ]);

    bikeModels.addAll([
      BikeModel(
        id: 'BIKE-1',
        name: 'YZF-R15',
        variant: 'V4 M',
        category: 'Sports',
        price: 299000,
        engineCc: 155,
        imageUrl: null,
        brochureUrl: null,
        stockStatus: StockStatus.inStock,
        isAvailable: true,
      ),
      BikeModel(
        id: 'BIKE-2',
        name: 'MT-15',
        variant: 'V2',
        category: 'Naked Sports',
        price: 179000,
        engineCc: 155,
        imageUrl: null,
        brochureUrl: null,
        stockStatus: StockStatus.inStock,
        isAvailable: true,
      ),
      BikeModel(
        id: 'BIKE-3',
        name: 'FZ-S FI',
        variant: 'V4',
        category: 'Commuter',
        price: 129000,
        engineCc: 149,
        imageUrl: null,
        brochureUrl: null,
        stockStatus: StockStatus.inStock,
        isAvailable: true,
      ),
      BikeModel(
        id: 'BIKE-4',
        name: 'FZS-FI',
        variant: 'Hybrid',
        category: 'Commuter',
        price: 132000,
        engineCc: 149,
        imageUrl: null,
        brochureUrl: null,
        stockStatus: StockStatus.limited,
        isAvailable: true,
      ),
      BikeModel(
        id: 'BIKE-5',
        name: 'Fascino',
        variant: '125 Hybrid',
        category: 'Scooter',
        price: 89000,
        engineCc: 125,
        imageUrl: null,
        brochureUrl: null,
        stockStatus: StockStatus.inStock,
        isAvailable: true,
      ),
      BikeModel(
        id: 'BIKE-6',
        name: 'RayZR',
        variant: '125 Hybrid',
        category: 'Scooter',
        price: 91000,
        engineCc: 125,
        imageUrl: null,
        brochureUrl: null,
        stockStatus: StockStatus.inStock,
        isAvailable: true,
      ),
      BikeModel(
        id: 'BIKE-7',
        name: 'Aerox',
        variant: '155',
        category: 'Sports Scooter',
        price: 154000,
        engineCc: 155,
        imageUrl: null,
        brochureUrl: null,
        stockStatus: StockStatus.limited,
        isAvailable: true,
      ),
      BikeModel(
        id: 'BIKE-8',
        name: 'YZF R3',
        variant: '',
        category: 'Sports',
        price: 460000,
        engineCc: 321,
        imageUrl: null,
        brochureUrl: null,
        stockStatus: StockStatus.outOfStock,
        isAvailable: false,
      ),
      BikeModel(
        id: 'BIKE-9',
        name: 'MT-09',
        variant: '',
        category: 'Naked Sports',
        price: 1030000,
        engineCc: 890,
        imageUrl: null,
        brochureUrl: null,
        stockStatus: StockStatus.outOfStock,
        isAvailable: false,
      ),
      BikeModel(
        id: 'BIKE-10',
        name: 'Saluto',
        variant: 'RX',
        category: 'Commuter',
        price: 78000,
        engineCc: 110,
        imageUrl: null,
        brochureUrl: null,
        stockStatus: StockStatus.inStock,
        isAvailable: true,
      ),
    ]);

    // ---- Leads: mixed statuses / sources / assignees / intents ----
    final leadSeed = <Map<String, Object?>>[
      {
        'name': 'Deepak Kulkarni',
        'mobile': '9900011001',
        'emp': 'EMP-1',
        'bike': 'BIKE-1',
        'status': LeadStatus.newLead,
        'source': LeadSource.walkIn,
        'intent': null,
        'currentBike': 'Honda Unicorn (2018)',
        'notes': 'Wants EMI options, comparing with R3. Visits gym near showroom daily.',
        'createdDaysAgo': 0,
        'purchaseInDays': 20,
      },
      {
        'name': 'Ananya Rao',
        'mobile': '9900011002',
        'emp': 'EMP-2',
        'bike': 'BIKE-7',
        'status': LeadStatus.followUp,
        'source': LeadSource.testRide,
        'intent': AiIntent.hot,
        'currentBike': 'Activa 5G',
        'notes': 'Loved the test ride, asked about exchange value same day. Ready to book this week.',
        'createdDaysAgo': 3,
        'purchaseInDays': 5,
      },
      {
        'name': 'Suresh Pillai',
        'mobile': '9900011003',
        'emp': 'EMP-3',
        'bike': 'BIKE-3',
        'status': LeadStatus.followUp,
        'source': LeadSource.walkIn,
        'intent': AiIntent.warm,
        'currentBike': null,
        'notes': 'First bike buyer, budget conscious, wants to see FZ-S vs FZS-FI.',
        'createdDaysAgo': 6,
        'purchaseInDays': 30,
      },
      {
        'name': 'Meera Joseph',
        'mobile': '9900011004',
        'emp': 'EMP-1',
        'bike': 'BIKE-5',
        'status': LeadStatus.newLead,
        'source': LeadSource.field,
        'intent': null,
        'currentBike': 'Bicycle',
        'notes': 'College student, mother enquiring on her behalf. Casual enquiry only.',
        'createdDaysAgo': 1,
        'purchaseInDays': 90,
      },
      {
        'name': 'Vikram Chauhan',
        'mobile': '9900011005',
        'emp': 'EMP-4',
        'bike': 'BIKE-9',
        'status': LeadStatus.followUp,
        'source': LeadSource.app,
        'intent': AiIntent.warm,
        'currentBike': 'Royal Enfield Classic 350',
        'notes': 'Upgrading, wants a demo ride slot next weekend.',
        'createdDaysAgo': 4,
        'purchaseInDays': 45,
      },
      {
        'name': 'Kavya Menon',
        'mobile': '9900011006',
        'emp': 'EMP-2',
        'bike': 'BIKE-6',
        'status': LeadStatus.closedWon,
        'source': LeadSource.walkIn,
        'intent': AiIntent.hot,
        'currentBike': 'Jupiter',
        'notes': 'Booked and converted, vehicle delivery pending.',
        'createdDaysAgo': 14,
        'purchaseInDays': -2,
      },
      {
        'name': 'Farhan Ali',
        'mobile': '9900011007',
        'emp': 'EMP-5',
        'bike': 'BIKE-2',
        'status': LeadStatus.closedLost,
        'source': LeadSource.walkIn,
        'intent': AiIntent.cold,
        'currentBike': 'Pulsar 150',
        'notes': 'Went with a competitor brand due to price.',
        'createdDaysAgo': 20,
        'purchaseInDays': -10,
      },
      {
        'name': 'Ritika Bose',
        'mobile': '9900011008',
        'emp': 'EMP-3',
        'bike': 'BIKE-1',
        'status': LeadStatus.newLead,
        'source': LeadSource.testRide,
        'intent': null,
        'currentBike': null,
        'notes': 'Enquired via test ride booking on the public site.',
        'createdDaysAgo': 0,
        'purchaseInDays': 15,
      },
      {
        'name': 'Manoj Tiwari',
        'mobile': '9900011009',
        'emp': 'EMP-4',
        'bike': 'BIKE-10',
        'status': LeadStatus.followUp,
        'source': LeadSource.field,
        'intent': AiIntent.cold,
        'currentBike': 'None',
        'notes': 'Price shopping across three dealers, slow to respond.',
        'createdDaysAgo': 10,
        'purchaseInDays': 60,
      },
      {
        'name': 'Sanya Kapoor',
        'mobile': '9900011010',
        'emp': 'EMP-1',
        'bike': 'BIKE-4',
        'status': LeadStatus.followUp,
        'source': LeadSource.walkIn,
        'intent': null,
        'currentBike': 'Access 125',
        'notes': 'Wants a color she saw on Instagram, checking availability.',
        'createdDaysAgo': 2,
        'purchaseInDays': 12,
      },
      {
        'name': 'Rahul Deshmukh',
        'mobile': '9900011011',
        'emp': 'EMP-5',
        'bike': 'BIKE-8',
        'status': LeadStatus.newLead,
        'source': LeadSource.walkIn,
        'intent': AiIntent.warm,
        'currentBike': 'YZF-R15 V3',
        'notes': 'Upgrading within the family, wants finance quote comparison.',
        'createdDaysAgo': 1,
        'purchaseInDays': 40,
      },
      {
        'name': 'Divya Shetty',
        'mobile': '9900011012',
        'emp': 'EMP-2',
        'bike': 'BIKE-5',
        'status': LeadStatus.closedWon,
        'source': LeadSource.app,
        'intent': AiIntent.hot,
        'currentBike': 'None',
        'notes': 'First vehicle purchase, converted after two follow-ups.',
        'createdDaysAgo': 25,
        'purchaseInDays': -5,
      },
      {
        'name': 'Imran Sheikh',
        'mobile': '9900011013',
        'emp': 'EMP-3',
        'bike': 'BIKE-2',
        'status': LeadStatus.followUp,
        'source': LeadSource.testRide,
        'intent': AiIntent.hot,
        'currentBike': 'FZ-S V3',
        'notes': 'Very keen, asked for on-road price breakup twice.',
        'createdDaysAgo': 2,
        'purchaseInDays': 7,
      },
      {
        'name': 'Neha Agarwal',
        'mobile': '9900011014',
        'emp': 'EMP-4',
        'bike': 'BIKE-7',
        'status': LeadStatus.newLead,
        'source': LeadSource.walkIn,
        'intent': null,
        'currentBike': 'Dio',
        'notes': 'Wants a scooter with better mileage than her current one.',
        'createdDaysAgo': 0,
        'purchaseInDays': 25,
      },
      {
        'name': 'Gaurav Bhatt',
        'mobile': '9900011015',
        'emp': 'EMP-5',
        'bike': 'BIKE-3',
        'status': LeadStatus.closedLost,
        'source': LeadSource.field,
        'intent': AiIntent.cold,
        'currentBike': 'CB Shine',
        'notes': 'Postponed purchase indefinitely due to budget change.',
        'createdDaysAgo': 18,
        'purchaseInDays': -3,
      },
    ];

    for (var i = 0; i < leadSeed.length; i++) {
      final seed = leadSeed[i];
      final id = 'LEAD-${i + 1}';
      final createdAt = now.subtract(Duration(days: seed['createdDaysAgo'] as int));
      leads.add(Lead(
        id: id,
        dealerId: 'DLR-1',
        assignedEmployeeId: seed['emp'] as String,
        customerName: seed['name'] as String,
        mobile: seed['mobile'] as String,
        source: seed['source'] as LeadSource,
        interestedModelId: seed['bike'] as String,
        currentBike: seed['currentBike'] as String?,
        tentativePurchaseDate: now.add(Duration(days: seed['purchaseInDays'] as int)),
        status: seed['status'] as LeadStatus,
        aiIntent: seed['intent'] as AiIntent?,
        notes: seed['notes'] as String?,
        convertedCustomerId: null,
        createdAt: createdAt,
        updatedAt: createdAt,
      ));
    }

    // ---- Follow-ups: give FOLLOW_UP leads a mix of overdue / due-today / upcoming ----
    final followUpLeadIds = leads
        .where((l) => l.status == LeadStatus.followUp)
        .map((l) => l.id)
        .toList();
    final offsets = [-2, 0, 0, 1, 3, -1, 2]; // days relative to now
    for (var i = 0; i < followUpLeadIds.length; i++) {
      final lead = leads.firstWhere((l) => l.id == followUpLeadIds[i]);
      final offsetDays = offsets[i % offsets.length];
      followups.add(LeadFollowup(
        id: 'FU-${i + 1}',
        leadId: lead.id,
        employeeId: lead.assignedEmployeeId!,
        nextAction: _nextActionFor(i),
        scheduledDate: DateTime(now.year, now.month, now.day).add(Duration(days: offsetDays)),
        completed: false,
        outcomeNote: null,
        createdAt: lead.createdAt,
      ));
    }

    // A couple of already-completed follow-ups for history/timeline realism.
    followups.add(LeadFollowup(
      id: 'FU-${followUpLeadIds.length + 1}',
      leadId: 'LEAD-6',
      employeeId: 'EMP-2',
      nextAction: 'Confirm booking amount and finance provider',
      scheduledDate: now.subtract(const Duration(days: 5)),
      completed: true,
      outcomeNote: 'Customer confirmed, booking amount collected.',
      createdAt: now.subtract(const Duration(days: 6)),
    ));

    _seedCustomerSide(now);
  }

  // ---- Phase 3: onboarded customers, vehicles, service history/requests ----
  void _seedCustomerSide(DateTime now) {
    customers.addAll([
      Customer(
        id: 'CUST-1',
        name: 'Naveen Kumar',
        phone: '9911100001',
        email: 'naveen.kumar@customer.demo',
        onboardingDealerId: 'DLR-1',
        createdAt: now.subtract(const Duration(days: 100)),
      ),
      Customer(
        id: 'CUST-2',
        name: 'Priyanka Das',
        phone: '9911100002',
        email: 'priyanka.das@customer.demo',
        onboardingDealerId: 'DLR-1',
        createdAt: now.subtract(const Duration(days: 60)),
      ),
    ]);

    vehicles.addAll([
      Vehicle(
        id: 'VEH-1',
        customerId: 'CUST-1',
        bikeModelId: 'BIKE-1',
        vin: 'MD9YZFR15X1234501',
        registrationNo: 'KA05AB1234',
        purchaseDate: now.subtract(const Duration(days: 100)),
        odometerKm: 3200,
      ),
      Vehicle(
        id: 'VEH-2',
        customerId: 'CUST-2',
        bikeModelId: 'BIKE-5',
        vin: 'MD9FASC0Y1234502',
        registrationNo: 'KA03CD5678',
        purchaseDate: now.subtract(const Duration(days: 60)),
        odometerKm: 850,
      ),
    ]);

    serviceRecords.addAll([
      ServiceRecord(
        id: 'SR-1',
        vehicleId: 'VEH-1',
        serviceDate: now.subtract(const Duration(days: 70)),
        odometerKm: 1000,
        serviceType: 'First free service',
        cost: 0,
        nextServiceDate: now.subtract(const Duration(days: 10)),
        nextServiceKm: 3000,
      ),
      ServiceRecord(
        id: 'SR-2',
        vehicleId: 'VEH-2',
        serviceDate: now.subtract(const Duration(days: 20)),
        odometerKm: 500,
        serviceType: 'First free service',
        cost: 0,
        nextServiceDate: now.add(const Duration(days: 40)),
        nextServiceKm: 3000,
      ),
    ]);

    serviceRequests.addAll([
      ServiceRequest(
        id: 'SVCREQ-1',
        vehicleId: 'VEH-1',
        customerId: 'CUST-1',
        dealerId: 'DLR-1',
        type: 'Engine noise',
        description: 'Unusual knocking sound when idling for the last two days.',
        status: ServiceRequestStatus.inProgress,
        preferredDate: now.add(const Duration(days: 2)),
        createdAt: now.subtract(const Duration(days: 3)),
      ),
      ServiceRequest(
        id: 'SVCREQ-2',
        vehicleId: 'VEH-2',
        customerId: 'CUST-2',
        dealerId: 'DLR-1',
        type: 'General query',
        description: 'When is my next free service due?',
        status: ServiceRequestStatus.resolved,
        preferredDate: null,
        createdAt: now.subtract(const Duration(days: 10)),
      ),
    ]);

    serviceMessages.addAll([
      ServiceMessage(
        id: 'SVCMSG-1',
        serviceRequestId: 'SVCREQ-1',
        senderType: MessageSenderType.customer,
        senderId: 'CUST-1',
        message: 'Hi, my bike has been making a knocking sound when idling for two days now.',
        createdAt: now.subtract(const Duration(days: 3)),
      ),
      ServiceMessage(
        id: 'SVCMSG-2',
        serviceRequestId: 'SVCREQ-1',
        senderType: MessageSenderType.dealer,
        senderId: 'EMP-2',
        message: "Thanks for reaching out — we've scheduled a diagnostic check on your preferred date.",
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      ServiceMessage(
        id: 'SVCMSG-3',
        serviceRequestId: 'SVCREQ-2',
        senderType: MessageSenderType.customer,
        senderId: 'CUST-2',
        message: 'When is my next free service due?',
        createdAt: now.subtract(const Duration(days: 10)),
      ),
      ServiceMessage(
        id: 'SVCMSG-4',
        serviceRequestId: 'SVCREQ-2',
        senderType: MessageSenderType.dealer,
        senderId: 'EMP-3',
        message: 'Your next free service is due around 3,000 km or 40 days from your last visit, whichever comes first.',
        createdAt: now.subtract(const Duration(days: 9)),
      ),
    ]);
  }

  static String _nextActionFor(int i) {
    const actions = [
      'Call to confirm test ride slot',
      'Share finance/EMI quote',
      'Follow up on exchange value discussion',
      'Confirm color/variant availability',
      'Send on-road price breakup',
      'Check if family decision is finalized',
      'Remind about ongoing festive offer',
    ];
    return actions[i % actions.length];
  }

  String newId(String prefix) => '$prefix-${_uuid.v4().substring(0, 8)}';

  Employee employeeById(String id) => employees.firstWhere((e) => e.id == id);

  BikeModel? bikeModelById(String? id) {
    if (id == null) return null;
    try {
      return bikeModels.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }

  Employee? findEmployeeByIdentifier(String identifier) {
    final normalized = identifier.trim().toLowerCase();
    for (final e in employees) {
      if (e.email.toLowerCase() == normalized || e.phone == normalized) {
        return e;
      }
    }
    return null;
  }

  Customer? findCustomerByIdentifier(String identifier) {
    final normalized = identifier.trim().toLowerCase();
    for (final c in customers) {
      if (c.email?.toLowerCase() == normalized || c.phone == normalized) {
        return c;
      }
    }
    return null;
  }

  List<Vehicle> vehiclesForCustomer(String customerId) =>
      vehicles.where((v) => v.customerId == customerId).toList();

  /// Mirrors PLAN_backend.md's assignment algorithm: rotate through active
  /// employees at the dealer, self-healing if the stored pointer no longer
  /// matches an active candidate.
  Employee? _nextRoundRobinAssignee(String dealerId) {
    final candidates = employees.where((e) => e.dealerId == dealerId && e.isActive).toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    if (candidates.isEmpty) return null;
    final lastId = _lastAssignedByDealer[dealerId];
    final lastIndex = candidates.indexWhere((e) => e.id == lastId);
    final assignee = candidates[(lastIndex + 1) % candidates.length];
    _lastAssignedByDealer[dealerId] = assignee.id;
    return assignee;
  }

  AppNotification _notify({
    required String recipientEmployeeId,
    required NotificationType type,
    required String title,
    required String body,
    required Map<String, dynamic> payload,
  }) {
    final notification = AppNotification(
      id: newId('NOTIF'),
      recipientType: NotificationRecipientType.employee,
      recipientId: recipientEmployeeId,
      type: type,
      title: title,
      body: body,
      payload: payload,
      isRead: false,
      createdAt: DateTime.now(),
    );
    notifications.add(notification);
    return notification;
  }

  /// `POST /public/test-rides` as one transaction: book the slot, round-robin
  /// assign a salesperson, auto-create the linked lead, notify the assignee.
  TestRideBooking bookTestRide({
    required String bikeModelId,
    required String name,
    required String mobile,
    required DateTime preferredDate,
    required String preferredTime,
    String? dealerId,
  }) {
    final resolvedDealerId = dealerId ?? defaultDealer.id;
    final assignee = _nextRoundRobinAssignee(resolvedDealerId);
    final now = DateTime.now();

    final lead = Lead(
      id: newId('LEAD'),
      dealerId: resolvedDealerId,
      assignedEmployeeId: assignee?.id,
      customerName: name,
      mobile: mobile,
      source: LeadSource.testRide,
      interestedModelId: bikeModelId,
      currentBike: null,
      tentativePurchaseDate: null,
      status: LeadStatus.newLead,
      aiIntent: null,
      notes: 'Booked a test ride via the public site for $preferredTime on '
          '${preferredDate.toIso8601String().split('T').first}.',
      convertedCustomerId: null,
      createdAt: now,
      updatedAt: now,
    );
    leads.add(lead);

    final booking = TestRideBooking(
      id: newId('TR'),
      bikeModelId: bikeModelId,
      name: name,
      mobile: mobile,
      preferredDate: preferredDate,
      preferredTime: preferredTime,
      dealerId: resolvedDealerId,
      status: TestRideStatus.requested,
      linkedLeadId: lead.id,
      createdAt: now,
    );
    testRideBookings.add(booking);

    if (assignee != null) {
      final bike = bikeModelById(bikeModelId);
      _notify(
        recipientEmployeeId: assignee.id,
        type: NotificationType.testRide,
        title: 'New test ride request',
        body: '$name wants to test ride ${bike?.displayName ?? 'a bike'} on $preferredTime.',
        payload: {'leadId': lead.id, 'bookingId': booking.id},
      );
    }

    return booking;
  }

  DashboardSummary dashboardSummaryFor(String employeeId) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final myLeads = leads.where((l) => l.assignedEmployeeId == employeeId);

    final newCount = myLeads.where((l) => l.status == LeadStatus.newLead).length;
    final followUpCount = myLeads.where((l) => l.status == LeadStatus.followUp).length;
    final closedThisMonth = myLeads
        .where((l) =>
            (l.status == LeadStatus.closedWon || l.status == LeadStatus.closedLost) &&
            l.updatedAt.year == now.year &&
            l.updatedAt.month == now.month)
        .length;
    final hotCount = myLeads.where((l) => l.aiIntent == AiIntent.hot).length;

    final todaysFollowups = followups
        .where((f) =>
            f.employeeId == employeeId &&
            !f.completed &&
            !f.scheduledDate.isAfter(todayStart.add(const Duration(days: 1))))
        .map((f) {
          final lead = leads.firstWhere((l) => l.id == f.leadId);
          return FollowupWithLead(
            followup: f,
            leadCustomerName: lead.customerName,
            leadMobile: lead.mobile,
          );
        })
        .toList()
      ..sort((a, b) => a.followup.scheduledDate.compareTo(b.followup.scheduledDate));

    return DashboardSummary(
      newLeadsCount: newCount,
      followUpLeadsCount: followUpCount,
      closedThisMonthCount: closedThisMonth,
      hotLeadsCount: hotCount,
      todaysFollowups: todaysFollowups,
    );
  }
}
