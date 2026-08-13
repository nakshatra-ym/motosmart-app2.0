import 'json_utils.dart';

class LeadFollowup {
  const LeadFollowup({
    required this.id,
    required this.leadId,
    required this.employeeId,
    required this.nextAction,
    required this.scheduledDate,
    required this.completed,
    required this.outcomeNote,
    required this.createdAt,
  });

  final String id;
  final String leadId;
  final String employeeId;
  final String nextAction;
  final DateTime scheduledDate;
  final bool completed;
  final String? outcomeNote;
  final DateTime createdAt;

  bool get isOverdue => !completed && scheduledDate.isBefore(DateTime.now());

  bool get isDueToday {
    final now = DateTime.now();
    return !completed &&
        scheduledDate.year == now.year &&
        scheduledDate.month == now.month &&
        scheduledDate.day == now.day;
  }

  LeadFollowup copyWith({
    bool? completed,
    String? outcomeNote,
    String? nextAction,
    DateTime? scheduledDate,
  }) {
    return LeadFollowup(
      id: id,
      leadId: leadId,
      employeeId: employeeId,
      nextAction: nextAction ?? this.nextAction,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      completed: completed ?? this.completed,
      outcomeNote: outcomeNote ?? this.outcomeNote,
      createdAt: createdAt,
    );
  }

  factory LeadFollowup.fromJson(Map<String, dynamic> json) => LeadFollowup(
        id: json['id'] as String,
        leadId: json['lead_id'] as String,
        // Nullable server-side: a follow-up can outlive the employee row.
        employeeId: asString(json['employee_id']),
        nextAction: asString(json['next_action']),
        scheduledDate: asDate(json['scheduled_date']),
        completed: json['completed'] as bool? ?? false,
        outcomeNote: json['outcome_note'] as String?,
        createdAt: asDate(json['created_at']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'lead_id': leadId,
        'employee_id': employeeId,
        'next_action': nextAction,
        'scheduled_date': scheduledDate.toIso8601String(),
        'completed': completed,
        'outcome_note': outcomeNote,
        'created_at': createdAt.toIso8601String(),
      };
}
