import 'json_utils.dart';

class Vehicle {
  const Vehicle({
    required this.id,
    required this.customerId,
    required this.bikeModelId,
    required this.vin,
    required this.registrationNo,
    required this.purchaseDate,
    required this.odometerKm,
    this.bikeModelName,
  });

  final String id;
  final String customerId;
  final String bikeModelId;
  final String vin;
  final String registrationNo;

  /// Nullable: `vehicles.purchase_date` is optional server-side (a dealer can
  /// onboard a vehicle before digging out the invoice date).
  final DateTime? purchaseDate;
  final int odometerKm;

  /// Denormalised from the API's nested `bike_model`, so the garage card can
  /// name the bike without a second catalog lookup.
  final String? bikeModelName;

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    final model = asMap(json['bike_model']);
    return Vehicle(
      id: json['id'] as String,
      customerId: asString(json['customer_id']),
      bikeModelId: asString(json['bike_model_id']),
      vin: asString(json['vin']),
      registrationNo: asString(json['registration_no']),
      purchaseDate: asDateOrNull(json['purchase_date']),
      odometerKm: asInt(json['odometer_km']),
      bikeModelName: model.isEmpty
          ? null
          : [asString(model['name']), asString(model['variant'])]
              .where((s) => s.isNotEmpty)
              .join(' '),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'customer_id': customerId,
        'bike_model_id': bikeModelId,
        'vin': vin,
        'registration_no': registrationNo,
        'purchase_date': purchaseDate?.toIso8601String(),
        'odometer_km': odometerKm,
      };
}
