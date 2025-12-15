import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'payment_repository.g.dart';

class PaymentRepository {
  final SupabaseClient _client;

  PaymentRepository(this._client);

  Future<Map<String, dynamic>> processPayment({
    required Map<String, dynamic> rawData,
    required double currentAmount,
    required String orderId,
  }) async {
    // 1. Normalización de datos (Lógica de negocio pura)
    final Map<String, dynamic> processedData = Map.from(rawData);

    // Aplanar formData si viene anidado (comportamiento errático de MP bricks)
    if (processedData.containsKey('formData') && processedData['formData'] is Map) {
      final innerData = Map<String, dynamic>.from(processedData['formData']);
      processedData.addAll(innerData);
    }

    // 2. Normalización de claves (camelCase vs snake_case)
    if (processedData['payment_method_id'] == null && processedData['paymentMethodId'] != null) {
      processedData['payment_method_id'] = processedData['paymentMethodId'];
    }
    if (processedData['issuer_id'] == null && processedData['issuerId'] != null) {
      processedData['issuer_id'] = processedData['issuerId'];
    }

    // 3. Construcción del payload para la Edge Function
    final body = {
      ...processedData,
      'transaction_amount': currentAmount,
      'external_reference': orderId,
      // Aseguramos que el payer siempre tenga estructura válida
      'payer': {
        'email': processedData['payer']?['email'] ?? 'unknown@email.com',
        'identification': processedData['payer']?['identification']
      }
    };

    try {
      // 4. Llamada a Infraestructura (Supabase Edge Function)
      final response = await _client.functions.invoke(
        'process-payment',
        body: body,
      );

      return response.data as Map<String, dynamic>;
    } catch (e) {
      // Aquí podrías loguear el error a un servicio externo (Sentry, Crashlytics)
      throw Exception('Error procesando el pago en backend: $e');
    }
  }
}

@riverpod
PaymentRepository paymentRepository(PaymentRepositoryRef ref) {
  return PaymentRepository(Supabase.instance.client);
}