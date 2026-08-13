/// Shared enums mirroring the backend's Postgres text enums (PLAN_backend.md).
/// Keep the `.value` strings in sync with the API contract so swapping the
/// mock repositories for real dio calls later needs no model changes.
library;

enum LeadSource {
  walkIn('WALK_IN'),
  testRide('TEST_RIDE'),
  app('APP'),
  field('FIELD');

  const LeadSource(this.value);
  final String value;

  static LeadSource fromValue(String value) =>
      LeadSource.values.firstWhere((e) => e.value == value, orElse: () => LeadSource.walkIn);

  String get label => switch (this) {
        LeadSource.walkIn => 'Walk-in',
        LeadSource.testRide => 'Test ride',
        LeadSource.app => 'App',
        LeadSource.field => 'Field',
      };
}

enum LeadStatus {
  newLead('NEW'),
  followUp('FOLLOW_UP'),
  closedWon('CLOSED_WON'),
  closedLost('CLOSED_LOST');

  const LeadStatus(this.value);
  final String value;

  static LeadStatus fromValue(String value) =>
      LeadStatus.values.firstWhere((e) => e.value == value, orElse: () => LeadStatus.newLead);

  String get label => switch (this) {
        LeadStatus.newLead => 'New',
        LeadStatus.followUp => 'Follow-up',
        LeadStatus.closedWon => 'Closed (Won)',
        LeadStatus.closedLost => 'Closed (Lost)',
      };
}

enum AiIntent {
  hot('HOT'),
  warm('WARM'),
  cold('COLD');

  const AiIntent(this.value);
  final String value;

  static AiIntent fromValue(String value) =>
      AiIntent.values.firstWhere((e) => e.value == value, orElse: () => AiIntent.warm);

  static AiIntent? tryFromValue(String? value) {
    if (value == null) return null;
    try {
      return AiIntent.values.firstWhere((e) => e.value == value);
    } catch (_) {
      return null;
    }
  }
}

enum StockStatus {
  inStock('IN_STOCK'),
  // The backend's enum member is LOW_STOCK (see app/models/enums.py); the Dart
  // name stays `limited` because the UI already reads it that way.
  limited('LOW_STOCK'),
  outOfStock('OUT_OF_STOCK');

  const StockStatus(this.value);
  final String value;

  static StockStatus fromValue(String value) => StockStatus.values
      .firstWhere((e) => e.value == value, orElse: () => StockStatus.inStock);

  String get label => switch (this) {
        StockStatus.inStock => 'In stock',
        StockStatus.limited => 'Limited stock',
        StockStatus.outOfStock => 'Out of stock',
      };
}

enum UserRole {
  dealerStaff('DEALER_STAFF'),
  customer('CUSTOMER');

  const UserRole(this.value);
  final String value;

  static UserRole fromValue(String value) =>
      UserRole.values.firstWhere((e) => e.value == value, orElse: () => UserRole.dealerStaff);
}

enum TestRideStatus {
  requested('REQUESTED'),
  confirmed('CONFIRMED'),
  completed('COMPLETED'),
  cancelled('CANCELLED');

  const TestRideStatus(this.value);
  final String value;

  static TestRideStatus fromValue(String value) => TestRideStatus.values
      .firstWhere((e) => e.value == value, orElse: () => TestRideStatus.requested);

  String get label => switch (this) {
        TestRideStatus.requested => 'Requested',
        TestRideStatus.confirmed => 'Confirmed',
        TestRideStatus.completed => 'Completed',
        TestRideStatus.cancelled => 'Cancelled',
      };
}

enum ServiceRequestStatus {
  open('OPEN'),
  inProgress('IN_PROGRESS'),
  resolved('RESOLVED');

  const ServiceRequestStatus(this.value);
  final String value;

  static ServiceRequestStatus fromValue(String value) => ServiceRequestStatus.values
      .firstWhere((e) => e.value == value, orElse: () => ServiceRequestStatus.open);

  String get label => switch (this) {
        ServiceRequestStatus.open => 'Open',
        ServiceRequestStatus.inProgress => 'In progress',
        ServiceRequestStatus.resolved => 'Resolved',
      };
}

/// AI-assigned bucket for a service request (see the backend's `TicketCategory`).
enum TicketCategory {
  engine('ENGINE', 'Engine'),
  brakes('BRAKES', 'Brakes'),
  electrical('ELECTRICAL', 'Electrical'),
  transmission('TRANSMISSION', 'Transmission'),
  suspension('SUSPENSION', 'Suspension'),
  tyres('TYRES', 'Tyres'),
  body('BODY', 'Body'),
  periodicService('PERIODIC_SERVICE', 'Periodic service'),
  other('OTHER', 'Other');

  const TicketCategory(this.value, this.label);
  final String value;
  final String label;

  static TicketCategory? tryFromValue(String? value) {
    if (value == null) return null;
    for (final c in TicketCategory.values) {
      if (c.value == value) return c;
    }
    return null;
  }
}

/// How fast the desk should get to a ticket. `urgent` means stop riding.
enum TicketPriority {
  urgent('URGENT', 'Urgent'),
  high('HIGH', 'High'),
  normal('NORMAL', 'Normal'),
  low('LOW', 'Low');

  const TicketPriority(this.value, this.label);
  final String value;
  final String label;

  /// Sort key so the dealer queue can put the dangerous ones first.
  int get rank => switch (this) {
        TicketPriority.urgent => 0,
        TicketPriority.high => 1,
        TicketPriority.normal => 2,
        TicketPriority.low => 3,
      };

  static TicketPriority? tryFromValue(String? value) {
    if (value == null) return null;
    for (final p in TicketPriority.values) {
      if (p.value == value) return p;
    }
    return null;
  }
}

enum MessageSenderType {
  customer('CUSTOMER'),
  dealer('DEALER');

  const MessageSenderType(this.value);
  final String value;

  static MessageSenderType fromValue(String value) =>
      value == 'DEALER' ? MessageSenderType.dealer : MessageSenderType.customer;
}

enum ChatRole {
  user('USER'),
  assistant('ASSISTANT');

  const ChatRole(this.value);
  final String value;

  static ChatRole fromValue(String value) =>
      value == 'ASSISTANT' ? ChatRole.assistant : ChatRole.user;
}

enum NotificationType {
  newLead('NEW_LEAD'),
  testRide('TEST_RIDE'),
  serviceReply('SERVICE_REPLY'),
  followupDue('FOLLOWUP_DUE');

  const NotificationType(this.value);
  final String value;

  static NotificationType fromValue(String value) => NotificationType.values
      .firstWhere((e) => e.value == value, orElse: () => NotificationType.newLead);
}
