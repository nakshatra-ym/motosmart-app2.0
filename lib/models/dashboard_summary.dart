import 'json_utils.dart';
import 'lead_followup.dart';

/// A follow-up joined with its lead's customer name, exactly the shape
/// `GET /dashboard/summary` returns server-side (see PLAN_backend.md).
class FollowupWithLead {
  const FollowupWithLead({
    required this.followup,
    required this.leadCustomerName,
    required this.leadMobile,
  });

  final LeadFollowup followup;
  final String leadCustomerName;
  final String leadMobile;

  factory FollowupWithLead.fromJson(Map<String, dynamic> json) => FollowupWithLead(
        followup: LeadFollowup.fromJson(asMap(json['followup'])),
        leadCustomerName: asString(json['lead_customer_name']),
        leadMobile: asString(json['lead_mobile']),
      );

  Map<String, dynamic> toJson() => {
        'followup': followup.toJson(),
        'lead_customer_name': leadCustomerName,
        'lead_mobile': leadMobile,
      };
}

class DashboardSummary {
  const DashboardSummary({
    required this.newLeadsCount,
    required this.followUpLeadsCount,
    required this.closedThisMonthCount,
    required this.hotLeadsCount,
    required this.todaysFollowups,
  });

  final int newLeadsCount;
  final int followUpLeadsCount;
  final int closedThisMonthCount;
  final int hotLeadsCount;
  final List<FollowupWithLead> todaysFollowups;

  int get openLeadsCount => newLeadsCount + followUpLeadsCount;

  /// Maps `GET /dashboard/summary` (see `DashboardSummaryOut`). The backend
  /// reports statuses and intents as breakdown maps rather than flat counters,
  /// so the two per-bucket figures are read out of those.
  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    final byStatus = asMap(json['leads_by_status']);
    final byIntent = asMap(json['leads_by_intent']);
    return DashboardSummary(
      newLeadsCount: asInt(json['new_leads']),
      followUpLeadsCount: asInt(byStatus['FOLLOW_UP']),
      closedThisMonthCount: asInt(json['closed_this_month']),
      hotLeadsCount: asInt(byIntent['HOT']),
      todaysFollowups: asMapList(json['todays_followup_items'])
          .map(FollowupWithLead.fromJson)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'new_leads_count': newLeadsCount,
        'follow_up_leads_count': followUpLeadsCount,
        'closed_this_month_count': closedThisMonthCount,
        'hot_leads_count': hotLeadsCount,
        'todays_followups': todaysFollowups.map((e) => e.toJson()).toList(),
      };
}
