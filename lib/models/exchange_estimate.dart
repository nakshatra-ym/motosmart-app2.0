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

  factory ExchangeEstimate.fromJson(Map<String, dynamic> json) => ExchangeEstimate(
        brand: json['brand'] as String,
        model: json['model'] as String,
        year: json['year'] as int,
        estimatedValue: (json['estimated_value'] as num).toDouble(),
        note: json['note'] as String,
      );

  Map<String, dynamic> toJson() => {
        'brand': brand,
        'model': model,
        'year': year,
        'estimated_value': estimatedValue,
        'note': note,
      };
}
