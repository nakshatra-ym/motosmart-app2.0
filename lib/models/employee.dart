import 'json_utils.dart';

class Employee {
  const Employee({
    required this.id,
    required this.dealerId,
    required this.name,
    required this.phone,
    required this.email,
    required this.isActive,
  });

  final String id;
  final String dealerId;
  final String name;
  final String phone;
  final String email;
  final bool isActive;

  factory Employee.fromJson(Map<String, dynamic> json) => Employee(
        id: json['id'] as String,
        dealerId: asString(json['dealer_id']),
        name: asString(json['name']),
        phone: asString(json['phone']),
        email: asString(json['email']),
        isActive: json['is_active'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'dealer_id': dealerId,
        'name': name,
        'phone': phone,
        'email': email,
        'is_active': isActive,
      };
}
