// lib/presentation/screens/checkout/checkout_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:migue_iphones/presentation/widgets/payment/payment_brick_container.dart';

class CheckoutScreen extends StatelessWidget {
  static const String name = 'checkout_screen';
  
  final String preferenceId;
  final String orderId;

  const CheckoutScreen({
    super.key,
    required this.preferenceId,
    required this.orderId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Completar Pago'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  const Text(
                    "Ingresa los datos de tu tarjeta",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  // Aquí vive el formulario de MP
                  PaymentBrickContainer(
                    preferenceId: preferenceId,
                    orderId: orderId,
                    onPaymentResult: (result) {
                      final status = result['status'];
                      // Redirige según el resultado
                      if (status == 'approved') {
                        context.go('/success?status=$status&external_reference=$orderId');
                      } else if (status == 'rejected') {
                        context.go('/failure?status=$status&external_reference=$orderId');
                      } else {
                        context.go('/pending?status=$status&external_reference=$orderId');
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}