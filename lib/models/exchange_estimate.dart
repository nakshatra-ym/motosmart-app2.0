import 'json_utils.dart';

/// Result of `POST /public/exchange-value` — a rough trade-in estimate for
/// the customer's current bike, used to nudge the exchange conversation.
class ExchangeEstimate {
  const ExchangeEstimate({
    required this.brand,
    required this.model,
    required this.year,
    required this.estimatedValue,
    required this.note,
  });

  final String brand;
  final String model;
  final int year;
  final double estimatedValue;
  final String note;

  /// Maps `ExchangeEstimateOut`. The API's advisory text is `disclaimer`; a
  /// heuristic estimate (no reference row matched) says so up front.
  factory ExchangeEstimate.fromJson(Map<String, dynamic> json) => ExchangeEstimate(
        brand: asString(json['brand']),
        model: asString(json['model']),
        year: asInt(json['year']),
        estimatedValue: asDouble(json['estimated_value']),
        note: asString(
          json['note'] ?? json['disclaimer'],
          fallback: 'Indicative only. Confirmed after physical inspection.',
        ),
      );

  Map<String, dynamic> toJson() => {
        'brand': brand,
        'model': model,
        'year': year,
        'estimated_value': estimatedValue,
        'note': note,
      };
}
