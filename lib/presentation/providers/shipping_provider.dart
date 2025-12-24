// lib/presentation/providers/shipping_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:migue_iphones/domain/models/shipping_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final shippingRatesProvider = StateNotifierProvider<ShippingRatesNotifier, AsyncValue<List<ShippingRate>>>((ref) {
  return ShippingRatesNotifier();
});

class ShippingRatesNotifier extends StateNotifier<AsyncValue<List<ShippingRate>>> {
  ShippingRatesNotifier() : super(const AsyncData([]));

  // ACTUALIZADO: Recibe todos los parámetros necesarios
  Future<void> calculateRates({
    required String zipCode, 
    required String city, 
    required String stateName,
    required double totalWeight
  }) async {
    state = const AsyncLoading();
    
    try {
      final supabase = Supabase.instance.client;
      
      // Enviamos el paquete completo a la Edge Function
      final response = await supabase.functions.invoke(
        'calculate-shipping',
        body: {
          'zipCode': zipCode,
          'city': city,
          'state': stateName,
          'weight': totalWeight
        },
      );

      if (response.status != 200) {
        throw Exception("Error del servidor: ${response.status}");
      }

      final List<dynamic> data = response.data;
      
      // Convertimos el JSON en objetos ShippingRate
      final rates = data.map((r) => ShippingRate(
        carrierName: r['carrier_name'],
        serviceName: r['service_level'],
        price: (r['total_price'] as num).toDouble(),
        minDays: r['min_days'] ?? 2,
        maxDays: r['max_days'] ?? 5,
      )).toList();

      state = AsyncData(rates);

    } catch (e, stack) {
      // Si falla, guardamos el error para que la UI sepa
      state = AsyncError(e, stack);
    }
  }
  
  void clearRates() {
    state = const AsyncData([]);
  }
}

final selectedShippingRateProvider = StateProvider<ShippingRate?>((ref) => null);