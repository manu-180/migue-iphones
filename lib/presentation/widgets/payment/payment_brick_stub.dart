// lib/presentation/widgets/payment/payment_brick_stub.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PaymentBrickContainer extends ConsumerWidget {
  final String preferenceId;
  final String orderId;
  final Function(Map<String, dynamic>) onPaymentResult;

  const PaymentBrickContainer({
    super.key,
    required this.preferenceId,
    required this.orderId,
    required this.onPaymentResult,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Center(child: Text("Bricks no soportado en esta plataforma"));
  }
}