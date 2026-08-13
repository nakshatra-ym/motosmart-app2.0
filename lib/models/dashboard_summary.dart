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
        followup: LeadFollowup.fromJson(json['followup'] as Map<String, dynamic>),
        leadCustomerName: json['lead_customer_name'] as String,
        leadMobile: json['lead_mobile'] as String,
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

  factory DashboardSummary.fromJson(Map<String, dynamic> json) => DashboardSummary(
        newLeadsCount: json['new_leads_count'] as int,
        followUpLeadsCount: json['follow_up_leads_count'] as int,
        closedThisMonthCount: json['closed_this_month_count'] as int,
        hotLeadsCount: json['hot_leads_count'] as int,
        todaysFollowups: (json['todays_followups'] as List)
            .map((e) => FollowupWithLead.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'new_leads_count': newLeadsCount,
        'follow_up_leads_count': followUpLeadsCount,
        'closed_this_month_count': closedThisMonthCount,
        'hot_leads_count': hotLeadsCount,
        'todays_followups': todaysFollowups.map((e) => e.toJson()).toList(),
      };
}
