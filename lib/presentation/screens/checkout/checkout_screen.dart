// lib/presentation/screens/checkout/checkout_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:migue_iphones/presentation/widgets/payment/payment_brick_container.dart';
import 'package:migue_iphones/presentation/widgets/shared/custom_app_bar.dart'; // Asegúrate de importar tu AppBar

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
      backgroundColor: Colors.white, // Fondo limpio
      body: Column(
        children: [
          // 1. EL APPBAR DE SIEMPRE
          const CustomAppBar(showFilters: false), // Sin filtros, solo logo y carrito
          
          // 2. CONTENIDO SCROLLABLE
          Expanded(
            child: SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 40.0),
                    child: Column(
                      children: [
                        // Título amigable
                        Text(
                          "Finalizar Compra",
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: Colors.black87
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "Ingresa los datos de tu tarjeta de forma segura.",
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                        const SizedBox(height: 40),
                        
                        // 3. EL FORMULARIO DE MERCADO PAGO
                        PaymentBrickContainer(
                          preferenceId: preferenceId,
                          orderId: orderId,
                          onPaymentResult: (result) {
                            final status = result['status'];
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
          ),
        ],
      ),
    );
  }
}