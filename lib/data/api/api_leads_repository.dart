import '../../core/network/api_client.dart';
import '../../features/leads/data/leads_repository.dart';
import '../../models/bike_model.dart';
import '../../models/customer.dart';
import '../../models/lead_conversion.dart';
import '../../models/enums.dart';
import '../../models/json_utils.dart';
import '../../models/lead.dart';
import '../../models/lead_followup.dart';

/// [LeadsRepository] against the real API: `/leads`, `/followups`,
/// `/ai/classify-lead`, and `/public/models` for the model dropdown.
class ApiLeadsRepository implements LeadsRepository {
  const ApiLeadsRepository(this._api);

  final ApiClient _api;

  @override
  Future<List<Lead>> listLeads({
    LeadStatus? status,
    String? query,
    bool? dueOnly,
  }) async {
    final rows = await _api.getList(
      '/leads',
      query: {
        'status': status?.value,
        'q': (query != null && query.isNotEmpty) ? query : null,
        // The API's `due` filter takes today|overdue|upcoming; the app's boolean
        // "only show what needs work" maps onto overdue.
        'due': dueOnly == true ? 'overdue' : null,
        'limit': 200,
      },
    );
    return rows.map(Lead.fromJson).toList();
  }

  @override
  Future<Lead> getLead(String id) async {
    return Lead.fromJson(await _api.getObject('/leads/$id'));
  }

  @override
  Future<Lead> createLead({
    required String customerName,
    required String mobile,
    required LeadSource source,
    String? interestedModelId,
    String? currentBike,
    DateTime? tentativePurchaseDate,
    String? notes,
  }) async {
    final response = await _api.post('/leads', body: {
      'customer_name': customerName,
      'mobile': mobile,
      'source': source.value,
      if (interestedModelId != null) 'interested_model_id': interestedModelId,
      if (currentBike != null) 'current_bike': currentBike,
      if (tentativePurchaseDate != null)
        'tentative_purchase_date': dateOnly(tentativePurchaseDate),
      if (notes != null) 'notes': notes,
      // Classify inline so the list shows an intent badge immediately, instead
      // of the app making a second round trip to fill it in.
      'classify': true,
    });
    // Creation wraps the lead so duplicate-mobile advisories can ride along.
    return Lead.fromJson(asMap(response['lead']));
  }

  @override
  Future<Lead> updateLead(
    String id, {
    LeadStatus? status,
    String? interestedModelId,
    String? currentBike,
    DateTime? tentativePurchaseDate,
    String? notes,
  }) async {
    final response = await _api.patch('/leads/$id', body: {
      if (status != null) 'status': status.value,
      if (interestedModelId != null) 'interested_model_id': interestedModelId,
      if (currentBike != null) 'current_bike': currentBike,
      if (tentativePurchaseDate != null)
        'tentative_purchase_date': dateOnly(tentativePurchaseDate),
      if (notes != null) 'notes': notes,
    });
    return Lead.fromJson(response);
  }

  @override
  Future<LeadConversion> convertLead(String id, {required String email}) async {
    final response = await _api.post(
      '/leads/$id/convert',
      body: {if (email.isNotEmpty) 'email': email},
    );
    return LeadConversion.fromJson(
      response,
      Customer.fromJson(asMap(response['customer'])),
    );
  }

  @override
  Future<List<LeadFollowup>> listFollowups(String leadId) async {
    final rows = await _api.getList('/leads/$leadId/followups');
    return rows.map(LeadFollowup.fromJson).toList();
  }

  @override
  Future<LeadFollowup> createFollowup(
    String leadId, {
    required String nextAction,
    required DateTime scheduledDate,
  }) async {
    final response = await _api.post('/leads/$leadId/followups', body: {
      'next_action': nextAction,
      'scheduled_date': dateOnly(scheduledDate),
    });
    return LeadFollowup.fromJson(response);
  }

  @override
  Future<LeadFollowup> updateFollowup(
    String followupId, {
    bool? completed,
    String? outcomeNote,
    String? nextAction,
    DateTime? scheduledDate,
  }) async {
    final response = await _api.patch('/followups/$followupId', body: {
      if (completed != null) 'completed': completed,
      if (outcomeNote != null) 'outcome_note': outcomeNote,
      if (nextAction != null) 'next_action': nextAction,
      if (scheduledDate != null) 'scheduled_date': dateOnly(scheduledDate),
    });
    return LeadFollowup.fromJson(response);
  }

  @override
  Future<AiIntent> classifyLead(String id) async {
    final response = await _api.post('/ai/classify-lead', body: {'lead_id': id});
    // The endpoint never fails on Bedrock trouble — it falls back to a
    // heuristic and still returns an intent, so there is nothing to guard here.
    return AiIntent.fromValue(asString(response['intent']));
  }

  @override
  Future<List<BikeModel>> listBikeModels() async {
    // The catalog lives on the unauthenticated funnel router; it is the same
    // `bike_models` table the dealer dropdown needs.
    final rows = await _api.getList(
      '/public/models',
      query: {'available_only': false, 'limit': 100},
    );
    return rows.map(BikeModel.fromJson).toList();
  }

  @override
  Future<bool> hasDuplicateMobile(String mobile, {String? excludingLeadId}) async {
    if (mobile.trim().isEmpty) return false;
    // Reuses the list endpoint's search rather than a bespoke route: `q` matches
    // name, mobile, or notes, so the hits are narrowed to the mobile field here.
    final rows = await _api.getList('/leads', query: {'q': mobile.trim(), 'limit': 50});
    return rows.any((row) {
      if (excludingLeadId != null && row['id'] == excludingLeadId) return false;
      return asString(row['mobile']).contains(mobile.trim());
    });
  }
}
