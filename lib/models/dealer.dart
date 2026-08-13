class Dealer {
  const Dealer({
    required this.id,
    required this.name,
    required this.code,
    required this.city,
    required this.address,
    required this.phone,
  });

  final String id;
  final String name;
  final String code;
  final String city;
  final String address;
  final String phone;

  factory Dealer.fromJson(Map<String, dynamic> json) => Dealer(
        id: json['id'] as String,
        name: json['name'] as String,
        code: json['code'] as String,
        city: json['city'] as String,
        address: json['address'] as String,
        phone: json['phone'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'code': code,
        'city': city,
        'address': address,
        'phone': phone,
      };
}
