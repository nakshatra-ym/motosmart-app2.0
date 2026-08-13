import '../../models/enums.dart';
import '../../models/lead.dart';

/// Stands in for the backend's `services/ai.py: classify_lead` (Bedrock).
///
/// Same contract as the real thing: takes the lead's notes + tentative
/// purchase date, returns HOT/WARM/COLD. The backend's rule is "stub-friendly
/// so the demo never breaks" — this mock *is* that stub, just running
/// client-side. Swapping in the real `POST /ai/classify-lead` call later
/// only changes `LeadsRepository.classifyLead`'s implementation.
class AiClassifyService {
  static const _urgentWords = [
    'ready',
    'book',
    'today',
    'this week',
    'confirmed',
    'urgent',
    'asap',
    'twice',
    'loved',
    'keen',
  ];

  static const _coldWords = [
    'price shopping',
    'postponed',
    'casual',
    'budget conscious',
    'slow to respond',
    'indefinitely',
    'competitor',
  ];

  Future<AiIntent> classify(Lead lead) async {
    // Simulate model latency so the UI's loading state is visible in demos.
    await Future.delayed(const Duration(milliseconds: 700));

    final notes = (lead.notes ?? '').toLowerCase();
    var score = 0;

    for (final word in _urgentWords) {
      if (notes.contains(word)) score += 2;
    }
    for (final word in _coldWords) {
      if (notes.contains(word)) score -= 2;
    }

    final daysToPurchase = lead.tentativePurchaseDate == null
        ? 60
        : lead.tentativePurchaseDate!.difference(DateTime.now()).inDays;
    if (daysToPurchase <= 7) {
      score += 3;
    } else if (daysToPurchase <= 21) {
      score += 1;
    } else if (daysToPurchase > 45) {
      score -= 2;
    }

    if (lead.source == LeadSource.testRide) score += 1;

    if (score >= 3) return AiIntent.hot;
    if (score <= -2) return AiIntent.cold;
    return AiIntent.warm;
  }
}
