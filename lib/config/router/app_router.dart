// lib/config/router/app_router.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:migue_iphones/presentation/screens/checkout/payment_status_screen.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

// Layouts y Screens
import 'package:migue_iphones/presentation/layouts/main_layout.dart';
import 'package:migue_iphones/presentation/screens/home/home_screen.dart';
import 'package:migue_iphones/presentation/screens/product/product_screen.dart';
import 'package:migue_iphones/presentation/screens/cart/cart_screen.dart';
import 'package:migue_iphones/presentation/screens/checkout/checkout_screen.dart';

// IMPORTANTE: Asegúrate de que esta ruta sea la correcta donde guardaste el archivo nuevo

part 'app_router.g.dart';

@Riverpod(keepAlive: true)
GoRouter appRouter(AppRouterRef ref) { // 1. CAMBIO: Usar Ref en lugar de AppRouterRef
  return GoRouter(
    initialLocation: '/',
    routes: [
      // 1. HOME
      GoRoute(
        path: '/',
        name: HomeScreen.name,
        pageBuilder: (context, state) {
          return const NoTransitionPage(
            child: MainLayout(
              showFilters: true,
              child: HomeScreen(),
            ),
          );
        },
      ),

      // 2. PRODUCTO DETALLE
      GoRoute(
        path: '/product/:id',
        name: ProductScreen.name,
        pageBuilder: (context, state) {
          final productId = state.pathParameters['id'] ?? '0';
          return NoTransitionPage(
            child: MainLayout(
              child: ProductScreen(productId: productId),
            ),
          );
        },
      ),

      // 3. CARRITO
      GoRoute(
        path: '/cart',
        name: CartScreen.name,
        builder: (context, state) => const CartScreen(),
      ),

      // 4. CHECKOUT (Brick)
      GoRoute(
        path: '/checkout',
        name: CheckoutScreen.name,
        builder: (context, state) {
          final prefId = state.uri.queryParameters['preferenceId'] ?? '';
          final orderId = state.uri.queryParameters['orderId'] ?? '';
          return CheckoutScreen(preferenceId: prefId, orderId: orderId);
        },
      ),

      GoRoute(
        path: '/success',
        builder: (context, state) => SuccessPaymentScreen( // <--- Asegúrate que se llame SuccessPaymentScreen
          status: 'success',
          // CORRECCIÓN: Usamos 'paymentId', no 'externalReference'
          paymentId: state.uri.queryParameters['external_reference'] ?? state.uri.queryParameters['collection_id'],
        ),
      ),
      GoRoute(
        path: '/failure',
        builder: (context, state) => SuccessPaymentScreen(
          status: 'failure',
          paymentId: state.uri.queryParameters['external_reference'],
        ),
      ),
      GoRoute(
        path: '/pending',
        builder: (context, state) => SuccessPaymentScreen(
          status: 'pending',
          paymentId: state.uri.queryParameters['external_reference'],
        ),
      ),
    ],
    
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(child: Text('Página no encontrada: ${state.uri}')),
    ),
  );
}