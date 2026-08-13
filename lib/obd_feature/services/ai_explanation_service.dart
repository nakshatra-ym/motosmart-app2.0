import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/obd_reading.dart';
import '../data/dtc_codes.dart';

/// The AI layer's job is narrow and honest: turn a known DTC + current
/// sensor context into a natural-language explanation a rider can
/// actually understand and act on. It does NOT diagnose faults itself —
/// the rule engine already did that deterministically. This is
/// composition/communication, which is exactly where an LLM adds real
/// value instead of duplicating what a lookup table already knows.
///
/// Swap the endpoint/model below for whatever you're provisioned with
/// (Anthropic API directly, or via AWS Bedrock) — the prompt and parsing
/// logic stay the same either way.
class AiExplanationService {
  final String apiKey;
  final String model;

  AiExplanationService({
    required this.apiKey,
    this.model = 'claude-sonnet-4-6',
  });

  Future<String> explainFault(String dtcCode, ObdReading reading) async {
    final info = lookupDtc(dtcCode);

    final prompt = '''
You are a motorcycle service assistant speaking directly to a rider (not a mechanic).
Explain this diagnostic finding in 2-3 short, plain-language sentences.
Avoid jargon. Be reassuring but clear about urgency. Do not repeat the raw code back verbatim as the whole answer.

Diagnostic code: ${info.code}
Technical meaning: ${info.description}
Severity: ${info.severity.name}
Current readings: RPM ${reading.rpm}, coolant ${reading.coolantTempC.toStringAsFixed(1)}°C, battery ${reading.batteryVoltage.toStringAsFixed(2)}V, speed ${reading.speedKph.toStringAsFixed(0)} km/h

Respond with ONLY the explanation text, no preamble, no markdown.
''';

    try {
      final response = await http.post(
        Uri.parse('https://api.anthropic.com/v1/messages'),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': model,
          'max_tokens': 200,
          'messages': [
            {'role': 'user', 'content': prompt},
          ],
        }),
      );

      if (response.statusCode != 200) {
        return _fallback(info.description);
      }

      final data = jsonDecode(response.body);
      final text = (data['content'] as List)
          .map((block) => block['text'] ?? '')
          .join('\n')
          .trim();

      return text.isEmpty ? _fallback(info.description) : text;
    } catch (_) {
      // Network hiccup during a live demo shouldn't break the UI —
      // fall back to the deterministic description instead.
      return _fallback(info.description);
    }
  }

  String _fallback(String technicalDescription) =>
      'Note: $technicalDescription. (AI explanation unavailable — showing technical description.)';
}
