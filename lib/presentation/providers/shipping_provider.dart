// lib/presentation/providers/shipping_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:migue_iphones/domain/models/shipping_models.dart';

// --- Estado de la cotización ---
final shippingRatesProvider = StateNotifierProvider<ShippingRatesNotifier, AsyncValue<List<ShippingRate>>>((ref) {
  return ShippingRatesNotifier();
});

class ShippingRatesNotifier extends StateNotifier<AsyncValue<List<ShippingRate>>> {
  ShippingRatesNotifier() : super(const AsyncData([]));

  Future<void> calculateRates({required String zipCode}) async {
    state = const AsyncLoading();
    
    // SIMULACIÓN DE API (Para que pruebes la UI)
    await Future.delayed(const Duration(seconds: 1));
    
    final mockRates = [
      ShippingRate(
        carrierName: "Correo Argentino",
        serviceName: "Clásico",
        price: 0,
        minDays: 3,
        maxDays: 6,
      ),
      ShippingRate(
        carrierName: "Andreani",
        serviceName: "Prioritario",
        price: 0,
        minDays: 1,
        maxDays: 3,
      ),
    ];

    state = AsyncData(mockRates);
  }
  
  void clearRates() {
    state = const AsyncData([]);
  }
}

// Tarifa seleccionada por el usuario
final selectedShippingRateProvider = StateProvider<ShippingRate?>((ref) => null);