import 'json_utils.dart';

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
        name: asString(json['name']),
        // city/address/phone are all nullable server-side.
        code: asString(json['code']),
        city: asString(json['city']),
        address: asString(json['address']),
        phone: asString(json['phone']),
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
