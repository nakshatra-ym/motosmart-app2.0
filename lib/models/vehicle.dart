class Vehicle {
  const Vehicle({
    required this.id,
    required this.customerId,
    required this.bikeModelId,
    required this.vin,
    required this.registrationNo,
    required this.purchaseDate,
    required this.odometerKm,
  });

  final String id;
  final String customerId;
  final String bikeModelId;
  final String vin;
  final String registrationNo;
  final DateTime purchaseDate;
  final int odometerKm;

  factory Vehicle.fromJson(Map<String, dynamic> json) => Vehicle(
        id: json['id'] as String,
        customerId: json['customer_id'] as String,
        bikeModelId: json['bike_model_id'] as String,
        vin: json['vin'] as String,
        registrationNo: json['registration_no'] as String,
        purchaseDate: DateTime.parse(json['purchase_date'] as String),
        odometerKm: json['odometer_km'] as int,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'customer_id': customerId,
        'bike_model_id': bikeModelId,
        'vin': vin,
        'registration_no': registrationNo,
        'purchase_date': purchaseDate.toIso8601String(),
        'odometer_km': odometerKm,
      };
}
