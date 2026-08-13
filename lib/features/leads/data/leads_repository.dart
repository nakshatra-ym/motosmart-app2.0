import '../../../models/bike_model.dart';
import '../../../models/customer.dart';
import '../../../models/enums.dart';
import '../../../models/lead.dart';
import '../../../models/lead_followup.dart';

/// Mirrors PLAN_backend.md's `/leads` + `/followups` + `/ai/classify-lead`
/// routers. Widgets never call dio/mock storage directly — only through
/// this interface, via Riverpod providers.
abstract class LeadsRepository {
  Future<List<Lead>> listLeads({LeadStatus? status, String? query, bool? dueOnly});

  Future<Lead> getLead(String id);

  /// Walk-in / field capture: `POST /leads`, self-assigns to the current
  /// dealer-staff user.
  Future<Lead> createLead({
    required String customerName,
    required String mobile,
    required LeadSource source,
    String? interestedModelId,
    String? currentBike,
    DateTime? tentativePurchaseDate,
    String? notes,
  });

  Future<Lead> updateLead(
    String id, {
    LeadStatus? status,
    String? interestedModelId,
    String? currentBike,
    DateTime? tentativePurchaseDate,
    String? notes,
  });

  /// `POST /leads/{id}/convert` — creates a customer record, marks the lead
  /// CLOSED_WON.
  Future<Customer> convertLead(String id, {required String email});

  Future<List<LeadFollowup>> listFollowups(String leadId);

  Future<LeadFollowup> createFollowup(
    String leadId, {
    required String nextAction,
    required DateTime scheduledDate,
  });

  Future<LeadFollowup> updateFollowup(
    String followupId, {
    bool? completed,
    String? outcomeNote,
    String? nextAction,
    DateTime? scheduledDate,
  });

  /// `POST /ai/classify-lead` — persists the returned intent onto the lead.
  Future<AiIntent> classifyLead(String id);

  /// Reference data for the "interested model" dropdown.
  Future<List<BikeModel>> listBikeModels();

  /// Duplicate-mobile warning (Phase 4 good-to-have, cheap to support now).
  Future<bool> hasDuplicateMobile(String mobile, {String? excludingLeadId});
}
