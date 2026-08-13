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
        name: json['name'] as String,
        phone: json['phone'] as String,
        email: json['email'] as String?,
        onboardingDealerId: json['onboarding_dealer_id'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
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
