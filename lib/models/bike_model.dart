import 'enums.dart';
import 'json_utils.dart';

class BikeModel {
  const BikeModel({
    required this.id,
    required this.name,
    required this.variant,
    required this.category,
    required this.price,
    required this.engineCc,
    required this.imageUrl,
    required this.brochureUrl,
    required this.stockStatus,
    required this.isAvailable,
  });

  final String id;
  final String name;
  final String variant;
  final String category;
  final double price;
  final int engineCc;
  final String? imageUrl;
  final String? brochureUrl;
  final StockStatus stockStatus;
  final bool isAvailable;

  String get displayName => variant.isEmpty ? name : '$name $variant';

  factory BikeModel.fromJson(Map<String, dynamic> json) => BikeModel(
        id: json['id'] as String,
        name: json['name'] as String,
        variant: asString(json['variant']),
        category: asString(json['category']),
        price: asDouble(json['price']),
        engineCc: asInt(json['engine_cc']),
        imageUrl: json['image_url'] as String?,
        brochureUrl: json['brochure_url'] as String?,
        stockStatus: StockStatus.fromValue(asString(json['stock_status'])),
        isAvailable: json['is_available'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'variant': variant,
        'category': category,
        'price': price,
        'engine_cc': engineCc,
        'image_url': imageUrl,
        'brochure_url': brochureUrl,
        'stock_status': stockStatus.value,
        'is_available': isAvailable,
      };
}
