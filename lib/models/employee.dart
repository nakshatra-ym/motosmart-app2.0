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
        dealerId: json['dealer_id'] as String,
        name: json['name'] as String,
        phone: json['phone'] as String,
        email: json['email'] as String,
        isActive: json['is_active'] as bool,
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
