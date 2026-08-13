import 'json_utils.dart';

class Customer {
  const Customer({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.onboardingDealerId,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String phone;
  final String? email;
  final String onboardingDealerId;
  final DateTime createdAt;

  factory Customer.fromJson(Map<String, dynamic> json) => Customer(
        id: json['id'] as String,
        name: asString(json['name']),
        phone: asString(json['phone']),
        email: json['email'] as String?,
        // Nullable server-side for a self-registered customer.
        onboardingDealerId: asString(json['onboarding_dealer_id']),
        createdAt: asDate(json['created_at']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'email': email,
        'onboarding_dealer_id': onboardingDealerId,
        'created_at': createdAt.toIso8601String(),
      };
}
