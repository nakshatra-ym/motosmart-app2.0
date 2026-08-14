import '../../core/network/api_exception.dart';
import '../../features/leads/data/leads_repository.dart';
import '../../models/bike_model.dart';
import '../../models/customer.dart';
import '../../models/lead_conversion.dart';
import '../../models/enums.dart';
import '../../models/lead.dart';
import '../../models/lead_followup.dart';
import 'ai_classify_service.dart';
import 'mock_data_store.dart';

class MockLeadsRepository implements LeadsRepository {
  MockLeadsRepository(
    this._store,
    this._aiService, {
    required String Function() currentEmployeeId,
    required String Function() currentDealerId,
  })  : _currentEmployeeId = currentEmployeeId,
        _currentDealerId = currentDealerId;

  final MockDataStore _store;
  final AiClassifyService _aiService;
  final String Function() _currentEmployeeId;
  final String Function() _currentDealerId;

  Future<void> _simulateLatency() => Future.delayed(const Duration(milliseconds: 350));

  @override
  Future<List<Lead>> listLeads({LeadStatus? status, String? query, bool? dueOnly}) async {
    await _simulateLatency();
    final dealerId = _currentDealerId();
    var results = _store.leads.where((l) => l.dealerId == dealerId);

    if (status != null) {
      results = results.where((l) => l.status == status);
    }
    if (query != null && query.trim().isNotEmpty) {
      final q = query.trim().toLowerCase();
      results = results.where(
        (l) => l.customerName.toLowerCase().contains(q) || l.mobile.contains(q),
      );
    }
    if (dueOnly == true) {
      final followupLeadIds = _store.followups
          .where((f) => !f.completed && !f.scheduledDate.isAfter(DateTime.now()))
          .map((f) => f.leadId)
          .toSet();
      results = results.where((l) => followupLeadIds.contains(l.id));
    }

    final list = results.toList()..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list;
  }

  @override
  Future<Lead> getLead(String id) async {
    await _simulateLatency();
    return _findLead(id);
  }

  Lead _findLead(String id) {
    try {
      return _store.leads.firstWhere((l) => l.id == id);
    } catch (_) {
      throw const ApiException('Lead not found.', statusCode: 404);
    }
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
    await _simulateLatency();
    final now = DateTime.now();
    final lead = Lead(
      id: _store.newId('LEAD'),
      dealerId: _currentDealerId(),
      assignedEmployeeId: _currentEmployeeId(),
      customerName: customerName,
      mobile: mobile,
      source: source,
      interestedModelId: interestedModelId,
      currentBike: currentBike,
      tentativePurchaseDate: tentativePurchaseDate,
      status: LeadStatus.newLead,
      aiIntent: null,
      notes: notes,
      convertedCustomerId: null,
      createdAt: now,
      updatedAt: now,
    );
    _store.leads.add(lead);
    return lead;
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
    await _simulateLatency();
    final index = _store.leads.indexWhere((l) => l.id == id);
    if (index == -1) throw const ApiException('Lead not found.', statusCode: 404);
    final updated = _store.leads[index].copyWith(
      status: status,
      interestedModelId: interestedModelId,
      currentBike: currentBike,
      tentativePurchaseDate: tentativePurchaseDate,
      notes: notes,
      updatedAt: DateTime.now(),
    );
    _store.leads[index] = updated;
    return updated;
  }

  @override
  Future<LeadConversion> convertLead(
    String id, {
    required String email,
    String? registrationNo,
    String? bikeModelId,
  }) async {
    await _simulateLatency();
    final index = _store.leads.indexWhere((l) => l.id == id);
    if (index == -1) throw const ApiException('Lead not found.', statusCode: 404);
    final lead = _store.leads[index];

    final customer = Customer(
      id: _store.newId('CUST'),
      name: lead.customerName,
      phone: lead.mobile,
      email: email,
      onboardingDealerId: lead.dealerId,
      createdAt: DateTime.now(),
    );
    _store.customers.add(customer);

    _store.leads[index] = lead.copyWith(
      status: LeadStatus.closedWon,
      convertedCustomerId: customer.id,
      updatedAt: DateTime.now(),
    );

    // Offline mode has no Cognito to fail against.
    return LeadConversion(customer: customer, invited: true);
  }

  @override
  Future<List<LeadFollowup>> listFollowups(String leadId) async {
    await _simulateLatency();
    final list = _store.followups.where((f) => f.leadId == leadId).toList()
      ..sort((a, b) => b.scheduledDate.compareTo(a.scheduledDate));
    return list;
  }

  @override
  Future<LeadFollowup> createFollowup(
    String leadId, {
    required String nextAction,
    required DateTime scheduledDate,
  }) async {
    await _simulateLatency();
    _findLead(leadId); // validates existence
    final followup = LeadFollowup(
      id: _store.newId('FU'),
      leadId: leadId,
      employeeId: _currentEmployeeId(),
      nextAction: nextAction,
      scheduledDate: scheduledDate,
      completed: false,
      outcomeNote: null,
      createdAt: DateTime.now(),
    );
    _store.followups.add(followup);

    // Capturing a follow-up moves a NEW lead into FOLLOW_UP, mirroring the
    // backend's status transition on the first scheduled follow-up.
    final leadIndex = _store.leads.indexWhere((l) => l.id == leadId);
    if (leadIndex != -1 && _store.leads[leadIndex].status == LeadStatus.newLead) {
      _store.leads[leadIndex] =
          _store.leads[leadIndex].copyWith(status: LeadStatus.followUp, updatedAt: DateTime.now());
    }

    return followup;
  }

  @override
  Future<LeadFollowup> updateFollowup(
    String followupId, {
    bool? completed,
    String? outcomeNote,
    String? nextAction,
    DateTime? scheduledDate,
  }) async {
    await _simulateLatency();
    final index = _store.followups.indexWhere((f) => f.id == followupId);
    if (index == -1) throw const ApiException('Follow-up not found.', statusCode: 404);
    final updated = _store.followups[index].copyWith(
      completed: completed,
      outcomeNote: outcomeNote,
      nextAction: nextAction,
      scheduledDate: scheduledDate,
    );
    _store.followups[index] = updated;
    return updated;
  }

  @override
  Future<AiIntent> classifyLead(String id) async {
    final lead = _findLead(id);
    final intent = await _aiService.classify(lead);
    final index = _store.leads.indexWhere((l) => l.id == id);
    _store.leads[index] = _store.leads[index].copyWith(
      aiIntent: intent,
      updatedAt: DateTime.now(),
    );
    return intent;
  }

  @override
  Future<List<BikeModel>> listBikeModels() async {
    await _simulateLatency();
    return List.unmodifiable(_store.bikeModels);
  }

  @override
  Future<bool> hasDuplicateMobile(String mobile, {String? excludingLeadId}) async {
    await _simulateLatency();
    return _store.leads.any((l) => l.mobile == mobile && l.id != excludingLeadId);
  }
}
