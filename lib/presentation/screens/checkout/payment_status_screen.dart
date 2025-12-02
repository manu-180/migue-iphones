// lib/presentation/screens/checkout/payment_status_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

class PaymentStatusScreen extends StatelessWidget {
  final String status;
  final String? externalReference;

  const PaymentStatusScreen({
    super.key,
    required this.status,
    this.externalReference,
  });

  @override
  Widget build(BuildContext context) {
    String title = '';
    String message = '';
    String lottieAsset = '';
    Color color = Colors.black;

    // Lógica simple basada en el status de MP
    if (status == 'approved' || status == 'success') {
      title = '¡Pago Exitoso!';
      message = 'Tu pedido #${externalReference ?? ""} ha sido registrado correctamente.';
      lottieAsset = 'assets/animations/carritoconfirmado.json'; // Reusa tu lottie existente
      color = Colors.green;
    } else if (status == 'pending' || status == 'in_process') {
      title = 'Pago Pendiente';
      message = 'Estamos esperando la confirmación del pago.';
      lottieAsset = 'assets/animations/carritoconfirmado.json'; // O busca uno de reloj
      color = Colors.orange;
    } else {
      title = 'Pago Rechazado';
      message = 'Hubo un problema con tu pago. Intenta nuevamente.';
      lottieAsset = 'assets/animations/carritoconfirmado.json'; // O busca uno de error
      color = Colors.red;
    }

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 200, child: Lottie.asset(lottieAsset, repeat: false)),
              const SizedBox(height: 20),
              Text(title, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
              const SizedBox(height: 10),
              Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 40),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
                onPressed: () => context.go('/'),
                child: const Text('Volver al Inicio'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}