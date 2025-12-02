// lib/domain/models/shipping_models.dart

class ShippingRate {
  final String carrierName; // Ej: "Correo Argentino"
  final String serviceName; // Ej: "Clásico"
  final double price;
  final int minDays;
  final int maxDays;

  ShippingRate({
    required this.carrierName,
    required this.serviceName,
    required this.price,
    required this.minDays,
    required this.maxDays,
  });

  factory ShippingRate.fromJson(Map<String, dynamic> json) {
    return ShippingRate(
      carrierName: json['carrier_name'] ?? '',
      serviceName: json['service_name'] ?? '',
      price: (json['price'] as num).toDouble(),
      minDays: json['min_days'] ?? 3,
      maxDays: json['max_days'] ?? 7,
    );
  }
}